param(
    [string]$Version,
    [string]$OutputDir,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$webDir = Join-Path $repoRoot "web"
$adminDir = Join-Path $repoRoot "admin-web"
$merchantDir = Join-Path $repoRoot "merchant-web"
$migrationSourceDir = Join-Path $repoRoot "sql\mysql"
$migrationManifestSource = Join-Path $migrationSourceDir "migrations.sha256"
$migrationRunnerSource = Join-Path $PSScriptRoot "mysql-migrate.sh"
$deployEnvironment = $env:DEPLOY_ENVIRONMENT
$viteApiBaseUrl = $env:VITE_API_BASE_URL
$viteWebSocketBaseUrl = $env:VITE_WS_BASE_URL
$viteStripePublishableKey = $env:VITE_STRIPE_PUBLISHABLE_KEY
$publicSiteUrl = $env:PUBLIC_SITE_URL
$prerenderApiBaseUrl = $env:PRERENDER_API_BASE_URL
$prerenderRegion = if ($env:PRERENDER_REGION) { $env:PRERENDER_REGION } else { "EU" }
$originalPrerenderRegion = $env:PRERENDER_REGION
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })

if (-not $Version) {
    if ($env:APP_RELEASE_VERSION) {
        $Version = $env:APP_RELEASE_VERSION
    }
    elseif ($env:GITHUB_SHA) {
        $Version = $env:GITHUB_SHA.Substring(0, [Math]::Min(12, $env:GITHUB_SHA.Length))
    }
    else {
        $Version = [System.DateTimeOffset]::UtcNow.ToString("yyyyMMddHHmmss")
    }
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $repoRoot "artifacts"
}

if ($Version -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
    throw "Release version contains unsupported characters: $Version"
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            throw "$FilePath exited with code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-VerifiedMigrationEntries {
    if (-not (Test-Path -LiteralPath $migrationManifestSource)) {
        throw "Migration manifest not found: $migrationManifestSource"
    }
    if (-not (Test-Path -LiteralPath $migrationRunnerSource)) {
        throw "Migration runner not found: $migrationRunnerSource"
    }

    $entries = @()
    $expectedVersion = 3
    foreach ($line in (Get-Content -LiteralPath $migrationManifestSource)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            throw "Migration manifest must not contain blank lines"
        }
        $match = [regex]::Match($line, '^([0-9a-f]{64})  ([0-9]{2,}_[A-Za-z0-9_]+_migration\.sql)$')
        if (-not $match.Success) {
            throw "Invalid migration manifest line"
        }
        $versionNumber = [int]($match.Groups[2].Value.Split('_')[0])
        if ($versionNumber -ne $expectedVersion) {
            throw "Migration versions must be contiguous from 03; expected $expectedVersion, found $versionNumber"
        }
        $fileName = $match.Groups[2].Value
        $sourcePath = Join-Path $migrationSourceDir $fileName
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Migration declared by the manifest was not found: $fileName"
        }
        $actualChecksum = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash.ToLowerInvariant()
        if ($actualChecksum -ne $match.Groups[1].Value) {
            throw "Migration checksum does not match the source manifest: $fileName"
        }
        $entries += [pscustomobject]@{
            Version = $versionNumber
            FileName = $fileName
            SourcePath = $sourcePath
            Checksum = $actualChecksum
        }
        $expectedVersion++
    }

    if ($entries.Count -eq 0) {
        throw "Migration manifest must declare at least one incremental migration"
    }
    $incrementalFiles = @(Get-ChildItem -LiteralPath $migrationSourceDir -File -Filter "*_migration.sql" |
        Sort-Object Name)
    if ($incrementalFiles.Count -ne $entries.Count) {
        throw "Migration manifest and incremental SQL file count differ"
    }
    for ($index = 0; $index -lt $entries.Count; $index++) {
        if ($incrementalFiles[$index].Name -ne $entries[$index].FileName) {
            throw "Incremental SQL file is missing from the migration manifest: $($incrementalFiles[$index].Name)"
        }
    }
    return $entries
}

function Assert-HttpsBuildUrl {
    param(
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^https://[^\s]+$') {
        throw "$Name must be an absolute HTTPS URL for a deployment build"
    }
}

function Assert-ReleaseFrontendConfiguration {
    if ([string]::IsNullOrWhiteSpace($deployEnvironment)) {
        return
    }
    if ($deployEnvironment -notin @("test", "pre", "prod")) {
        throw "DEPLOY_ENVIRONMENT must be test, pre, or prod"
    }

    Assert-HttpsBuildUrl -Name "VITE_API_BASE_URL" -Value $viteApiBaseUrl
    Assert-HttpsBuildUrl -Name "PUBLIC_SITE_URL" -Value $publicSiteUrl
    Assert-HttpsBuildUrl -Name "PRERENDER_API_BASE_URL" -Value $prerenderApiBaseUrl
    if ([string]::IsNullOrWhiteSpace($viteWebSocketBaseUrl) -or
        $viteWebSocketBaseUrl -notmatch '^wss://[^\s]+$') {
        throw "VITE_WS_BASE_URL must be an absolute WSS URL for a deployment build"
    }

    $stripePrefix = if ($deployEnvironment -eq "prod") { "pk_live_" } else { "pk_test_" }
    if ([string]::IsNullOrWhiteSpace($viteStripePublishableKey) -or
        -not $viteStripePublishableKey.StartsWith($stripePrefix, [System.StringComparison]::Ordinal)) {
        throw "VITE_STRIPE_PUBLISHABLE_KEY must match DEPLOY_ENVIRONMENT=$deployEnvironment"
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. For deployment builds, validate VITE_API_BASE_URL, VITE_WS_BASE_URL, VITE_STRIPE_PUBLISHABLE_KEY, PUBLIC_SITE_URL, and PRERENDER_API_BASE_URL."
    Write-Output "2. Run backend tests and build the jar with backend/mvnw.cmd package."
    Write-Output "3. Build web dist with npm run build under web."
    Write-Output "4. Build admin-web dist with npm run build under admin-web."
    Write-Output "5. Build merchant-web dist with npm run build under merchant-web."
    Write-Output "6. If PUBLIC_SITE_URL and PRERENDER_API_BASE_URL are configured, build real SEO snapshots for PRERENDER_REGION=$prerenderRegion."
    Write-Output "7. Verify and package only sql/mysql/03+ incremental migrations with their source-controlled SHA-256 manifest and MySQL runner."
    Write-Output "8. Assemble backend jar + web dist + admin-web dist + merchant-web dist + database migrations into a release bundle under $OutputDir."
    Write-Output "9. Write a release manifest for version $Version."
    Write-Output "10. Generate a SHA-256 checksum beside the release bundle."
    exit 0
}

Assert-ReleaseFrontendConfiguration
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-release-" + [System.Guid]::NewGuid().ToString("N"))
$bundlePath = Join-Path (Resolve-Path $OutputDir) "dazhongdianping-release-$Version.zip"
$checksumPath = "$bundlePath.sha256"

try {
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
    $migrationEntries = @(Get-VerifiedMigrationEntries)
    # Keep all Web builds and optional snapshots on the same release region.
    $env:PRERENDER_REGION = $prerenderRegion

    Invoke-Native -FilePath $mvnw -Arguments @("-q", "package") -WorkingDirectory $backendDir
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $webDir
    $seoSnapshotEnabled = -not [string]::IsNullOrWhiteSpace($publicSiteUrl) -and
        -not [string]::IsNullOrWhiteSpace($prerenderApiBaseUrl)
    if ($seoSnapshotEnabled) {
        Invoke-Native -FilePath "npm" -Arguments @("run", "build:prerender:data") -WorkingDirectory $webDir
    }
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $adminDir
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $merchantDir

    $backendJar = Get-ChildItem -File -LiteralPath (Join-Path $backendDir "target") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "-(sources|javadoc)\.jar$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $backendJar) {
        throw "Packaged backend jar was not found under backend/target"
    }

    $backendOutputDir = Join-Path $stagingDir "backend"
    $webOutputDir = Join-Path $stagingDir "web"
    $adminOutputDir = Join-Path $stagingDir "admin-web"
    $merchantOutputDir = Join-Path $stagingDir "merchant-web"
    $databaseOutputDir = Join-Path $stagingDir "database"
    $migrationOutputDir = Join-Path $databaseOutputDir "migrations"
    New-Item -ItemType Directory -Path $backendOutputDir, $webOutputDir, $adminOutputDir, $merchantOutputDir, $migrationOutputDir -Force | Out-Null

    Copy-Item -LiteralPath $backendJar.FullName -Destination (Join-Path $backendOutputDir $backendJar.Name)
    Copy-Item -LiteralPath (Join-Path $webDir "dist") -Destination $webOutputDir -Recurse
    Copy-Item -LiteralPath (Join-Path $adminDir "dist") -Destination $adminOutputDir -Recurse
    Copy-Item -LiteralPath (Join-Path $merchantDir "dist") -Destination $merchantOutputDir -Recurse
    foreach ($entry in $migrationEntries) {
        Copy-Item -LiteralPath $entry.SourcePath -Destination (Join-Path $migrationOutputDir $entry.FileName)
    }
    Copy-Item -LiteralPath $migrationManifestSource -Destination (Join-Path $databaseOutputDir "migrations.sha256")
    Copy-Item -LiteralPath $migrationRunnerSource -Destination (Join-Path $databaseOutputDir "mysql-migrate.sh")

    $manifest = [ordered]@{
        version = $Version
        builtAtUtc = [System.DateTimeOffset]::UtcNow.ToString("o")
        commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { "" }
        bundleName = [System.IO.Path]::GetFileName($bundlePath)
        backendJar = $backendJar.Name
        frontends = @("web", "admin-web", "merchant-web")
        databaseMigrations = [ordered]@{
            runner = "database/mysql-migrate.sh"
            manifest = "database/migrations.sha256"
            directory = "database/migrations"
            startVersion = $migrationEntries[0].Version
            endVersion = $migrationEntries[$migrationEntries.Count - 1].Version
            count = $migrationEntries.Count
        }
        webRuntime = [ordered]@{
            apiBaseUrl = if ($viteApiBaseUrl) { $viteApiBaseUrl } else { "" }
            webSocketBaseUrl = if ($viteWebSocketBaseUrl) { $viteWebSocketBaseUrl } else { "" }
            stripeConfigured = -not [string]::IsNullOrWhiteSpace($viteStripePublishableKey)
        }
        seoSnapshot = [ordered]@{
            enabled = $seoSnapshotEnabled
            siteUrl = if ($seoSnapshotEnabled) { $publicSiteUrl } else { "" }
            apiBaseUrl = if ($seoSnapshotEnabled) { $prerenderApiBaseUrl } else { "" }
            region = if ($seoSnapshotEnabled) { $prerenderRegion } else { "" }
            generatedAtUtc = if ($seoSnapshotEnabled) { [System.DateTimeOffset]::UtcNow.ToString("o") } else { "" }
        }
    }
    $manifestPath = Join-Path $stagingDir "release-manifest.json"
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Set-Content -LiteralPath (Join-Path $stagingDir "release-version.txt") -Value $Version -Encoding ascii

    if (Test-Path -LiteralPath $bundlePath) {
        Remove-Item -LiteralPath $bundlePath -Force
    }
    if (Test-Path -LiteralPath $checksumPath) {
        Remove-Item -LiteralPath $checksumPath -Force
    }
    Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $bundlePath

    $bundleSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $bundlePath).Hash.ToLowerInvariant()
    "$bundleSha256  $([System.IO.Path]::GetFileName($bundlePath))" |
        Set-Content -LiteralPath $checksumPath -Encoding ascii

    Write-Output $bundlePath
}
finally {
    $env:PRERENDER_REGION = $originalPrerenderRegion
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
