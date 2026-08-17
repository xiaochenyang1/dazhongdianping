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
$prerenderRegionsRaw = $env:PRERENDER_REGIONS
$originalPrerenderRegion = $env:PRERENDER_REGION
$originalPrerenderRegions = $env:PRERENDER_REGIONS
$originalPublicSiteUrl = $env:PUBLIC_SITE_URL
$originalPrerenderApiBaseUrl = $env:PRERENDER_API_BASE_URL
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

function Get-PrerenderRegions {
    $raw = if ([string]::IsNullOrWhiteSpace($prerenderRegionsRaw)) {
        $prerenderRegion
    }
    else {
        $prerenderRegionsRaw
    }
    $regions = @($raw -split '[,\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim().ToUpperInvariant() } | Select-Object -Unique)
    if ($regions.Count -eq 0) {
        throw "PRERENDER_REGIONS must contain at least one region"
    }
    foreach ($region in $regions) {
        if ($region -notin @("CN", "EU")) {
            throw "PRERENDER_REGIONS only supports CN or EU, found: $region"
        }
    }
    return $regions
}

function Get-PrerenderConfiguration {
    param(
        [string]$Region,
        [int]$RegionCount
    )

    $regionSiteUrl = [System.Environment]::GetEnvironmentVariable("PUBLIC_SITE_URL_$Region")
    $regionApiBaseUrl = [System.Environment]::GetEnvironmentVariable("PRERENDER_API_BASE_URL_$Region")
    if ($RegionCount -eq 1) {
        if ([string]::IsNullOrWhiteSpace($regionSiteUrl)) { $regionSiteUrl = $publicSiteUrl }
        if ([string]::IsNullOrWhiteSpace($regionApiBaseUrl)) { $regionApiBaseUrl = $prerenderApiBaseUrl }
    }
    [pscustomobject]@{
        Region = $Region
        SiteUrl = $regionSiteUrl
        ApiBaseUrl = $regionApiBaseUrl
    }
}

$prerenderRegions = @(Get-PrerenderRegions)
$prerenderConfigurations = @($prerenderRegions | ForEach-Object {
    Get-PrerenderConfiguration -Region $_ -RegionCount $prerenderRegions.Count
})

function Assert-ReleaseFrontendConfiguration {
    if ([string]::IsNullOrWhiteSpace($deployEnvironment)) {
        return
    }
    if ($deployEnvironment -notin @("test", "pre", "prod")) {
        throw "DEPLOY_ENVIRONMENT must be test, pre, or prod"
    }

    Assert-HttpsBuildUrl -Name "VITE_API_BASE_URL" -Value $viteApiBaseUrl
    foreach ($configuration in $prerenderConfigurations) {
        Assert-HttpsBuildUrl -Name "PUBLIC_SITE_URL_$($configuration.Region)" -Value $configuration.SiteUrl
        Assert-HttpsBuildUrl -Name "PRERENDER_API_BASE_URL_$($configuration.Region)" -Value $configuration.ApiBaseUrl
    }
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
    Write-Output "6. If PUBLIC_SITE_URL and PRERENDER_API_BASE_URL (or their per-region forms) are configured, build isolated real SEO snapshots for PRERENDER_REGIONS=$($prerenderRegions -join ',')."
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
    $baseRegion = $prerenderRegions[0]
    $baseConfiguration = $prerenderConfigurations | Where-Object { $_.Region -eq $baseRegion } | Select-Object -First 1
    # Build the serving dist for the first region, then retain each additional
    # region under web/seo-snapshots/<region> so they cannot overwrite one another.
    $env:PRERENDER_REGION = $baseRegion
    $env:PUBLIC_SITE_URL = $baseConfiguration.SiteUrl
    $env:PRERENDER_API_BASE_URL = $baseConfiguration.ApiBaseUrl

    Invoke-Native -FilePath $mvnw -Arguments @("-q", "package") -WorkingDirectory $backendDir
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $webDir
    $baseWebDistDir = Join-Path $stagingDir "__base-web-dist"
    Copy-Item -LiteralPath (Join-Path $webDir "dist") -Destination $baseWebDistDir -Recurse
    $seoSnapshotEntries = @()
    foreach ($configuration in $prerenderConfigurations) {
        $seoSnapshotEnabled = -not [string]::IsNullOrWhiteSpace($configuration.SiteUrl) -and
            -not [string]::IsNullOrWhiteSpace($configuration.ApiBaseUrl)
        if (-not $seoSnapshotEnabled) {
            continue
        }
        $env:PRERENDER_REGION = $configuration.Region
        $env:PUBLIC_SITE_URL = $configuration.SiteUrl
        $env:PRERENDER_API_BASE_URL = $configuration.ApiBaseUrl
        Invoke-Native -FilePath "npm" -Arguments @("run", "build:prerender:data") -WorkingDirectory $webDir
        $snapshotDir = Join-Path $stagingDir ("__seo-" + $configuration.Region)
        Copy-Item -LiteralPath (Join-Path $webDir "dist") -Destination $snapshotDir -Recurse
        $seoSnapshotEntries += [pscustomobject]@{
            region = $configuration.Region
            siteUrl = $configuration.SiteUrl
            apiBaseUrl = $configuration.ApiBaseUrl
            directory = "web/seo-snapshots/$($configuration.Region)"
            generatedAtUtc = [System.DateTimeOffset]::UtcNow.ToString("o")
        }
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
    Copy-Item -LiteralPath $baseWebDistDir -Destination $webOutputDir -Recurse
    if ($seoSnapshotEntries.Count -gt 0) {
        $seoOutputDir = Join-Path $webOutputDir "seo-snapshots"
        New-Item -ItemType Directory -Path $seoOutputDir -Force | Out-Null
        foreach ($entry in $seoSnapshotEntries) {
            Copy-Item -LiteralPath (Join-Path $stagingDir ("__seo-" + $entry.region)) -Destination (Join-Path $seoOutputDir $entry.region) -Recurse
        }
    }
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
            enabled = $seoSnapshotEntries.Count -gt 0
            siteUrl = if ($seoSnapshotEntries.Count -gt 0) { $seoSnapshotEntries[0].siteUrl } else { "" }
            apiBaseUrl = if ($seoSnapshotEntries.Count -gt 0) { $seoSnapshotEntries[0].apiBaseUrl } else { "" }
            region = if ($seoSnapshotEntries.Count -gt 0) { $seoSnapshotEntries[0].region } else { "" }
            generatedAtUtc = if ($seoSnapshotEntries.Count -gt 0) { $seoSnapshotEntries[0].generatedAtUtc } else { "" }
        }
        seoSnapshots = @($seoSnapshotEntries)
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
    $env:PRERENDER_REGIONS = $originalPrerenderRegions
    $env:PUBLIC_SITE_URL = $originalPublicSiteUrl
    $env:PRERENDER_API_BASE_URL = $originalPrerenderApiBaseUrl
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
