$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('dzdp-package-layout-' + [Guid]::NewGuid().ToString('N'))
$fixtureScript = Join-Path $fixtureRoot 'scripts/ci/package-release.ps1'
$runningOnWindows = [Environment]::OSVersion.Platform -eq 'Win32NT'
$environmentNames = @(
    'DEPLOY_ENVIRONMENT', 'GITHUB_SHA', 'PRERENDER_REGION', 'PRERENDER_REGIONS',
    'PUBLIC_SITE_URL', 'PRERENDER_API_BASE_URL', 'PUBLIC_SITE_URL_CN', 'PUBLIC_SITE_URL_EU',
    'PRERENDER_API_BASE_URL_CN', 'PRERENDER_API_BASE_URL_EU',
    'VITE_API_BASE_URL', 'VITE_WS_BASE_URL', 'VITE_STRIPE_PUBLISHABLE_KEY'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}

function Assert-Layout {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# Only builders are stubbed. The real packaging script copies files, creates
# the ZIP and manifests, and hashes migrations in an isolated fixture repo.
function npm {
    $command = $args[-1]
    Set-Content -LiteralPath (Join-Path (Get-Location) 'dist/index.html') -Value "$($env:PRERENDER_REGION):$command" -Encoding utf8
    $global:LASTEXITCODE = 0
}

function Read-ZipText {
    param($Archive, [string]$Name)
    $entry = $Archive.GetEntry($Name)
    Assert-Layout ($null -ne $entry) "Release ZIP is missing $Name"
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd().Trim() }
    finally { $reader.Dispose() }
}

function Test-Bundle {
    param([string]$Bundle, [bool]$WithSnapshots)
    $checksum = (Get-FileHash -LiteralPath $Bundle -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecar = (Get-Content -LiteralPath "$Bundle.sha256" -Raw).Trim().Split(' ')[0]
    Assert-Layout ($checksum -eq $sidecar) 'Release checksum must match the actual ZIP'
    $archive = [IO.Compression.ZipFile]::OpenRead($Bundle)
    try {
        $names = @($archive.Entries.FullName)
        Assert-Layout ($names -contains 'backend/fixture.jar') 'Backend JAR must be packaged'
        foreach ($frontend in @('web', 'admin-web', 'merchant-web')) {
            Assert-Layout ($names -contains "$frontend/dist/index.html") "Missing deployable $frontend/dist/index.html"
            Assert-Layout ($names -contains "$frontend/dist/assets/app.js") "Missing $frontend assets"
        }
        Assert-Layout (@($names | Where-Object { $_ -match '(^|/)__(base-web-dist|seo-)' }).Count -eq 0) 'Temporary build directories must not leak into the ZIP'
        Assert-Layout ((Read-ZipText $archive 'web/dist/index.html') -eq 'EU:build') 'The serving Web dist must retain the base region build'
        $manifest = Read-ZipText $archive 'release-manifest.json' | ConvertFrom-Json
        Assert-Layout ($manifest.commitSha -eq $env:GITHUB_SHA) 'Manifest must identify the candidate SHA'
        $migrationLines = (Read-ZipText $archive 'database/migrations.sha256') -split '\r?\n'
        Assert-Layout ($manifest.databaseMigrations.count -eq $migrationLines.Count) 'Migration count must match the archive manifest'
        foreach ($line in $migrationLines) {
            $expected, $fileName = $line -split '  ', 2
            $entry = $archive.GetEntry("database/migrations/$fileName")
            Assert-Layout ($null -ne $entry) "Missing migration $fileName"
            $stream = $entry.Open()
            try { $actual = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant() }
            finally { $stream.Dispose() }
            Assert-Layout ($actual -eq $expected) "Packaged migration checksum mismatch: $fileName"
        }
        if ($WithSnapshots) {
            Assert-Layout ($manifest.seoSnapshots.Count -eq 2) 'Both regional SEO snapshots must be declared'
            foreach ($region in @('CN', 'EU')) {
                Assert-Layout ((Read-ZipText $archive "web/seo-snapshots/$region/index.html") -eq "${region}:build:prerender:data") "SEO snapshot $region must keep its own content"
            }
        }
        else {
            Assert-Layout (-not $manifest.seoSnapshot.enabled) 'An unconfigured local package must not claim real SEO snapshots'
        }
    }
    finally { $archive.Dispose() }
}

try {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $null) }
    $env:GITHUB_SHA = '0123456789012345678901234567890123456789'
    $env:PRERENDER_REGION = 'EU'
    foreach ($directory in @('scripts/ci', 'sql/mysql', 'backend/target', 'web/dist/assets', 'admin-web/dist/assets', 'merchant-web/dist/assets')) {
        New-Item -ItemType Directory -Path (Join-Path $fixtureRoot $directory) -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/ci/package-release.ps1') -Destination $fixtureScript
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/ci/mysql-migrate.sh') -Destination (Join-Path $fixtureRoot 'scripts/ci/mysql-migrate.sh')
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'sql/mysql') -File |
        Where-Object { $_.Name -match '_migration\.sql$|^migrations\.sha256$' } |
        Copy-Item -Destination (Join-Path $fixtureRoot 'sql/mysql')
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'backend/target/fixture.jar') -Value 'fixture'
    foreach ($frontend in @('web', 'admin-web', 'merchant-web')) {
        Set-Content -LiteralPath (Join-Path $fixtureRoot "$frontend/dist/assets/app.js") -Value 'fixture'
    }
    $wrapper = Join-Path $fixtureRoot $(if ($runningOnWindows) { 'backend/mvnw.cmd' } else { 'backend/mvnw' })
    if ($runningOnWindows) { Set-Content -LiteralPath $wrapper -Value '@exit /b 0' -Encoding ascii }
    else {
        [IO.File]::WriteAllText($wrapper, "#!/bin/sh`nexit 0`n")
        [IO.File]::SetUnixFileMode($wrapper, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
    }
    $outputDir = Join-Path $fixtureRoot 'output'
    $bundle = & $fixtureScript -Version 'layout-local' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $false

    $env:PRERENDER_REGIONS = 'CN,EU'
    $env:PUBLIC_SITE_URL_CN = 'https://cn.example.test'
    $env:PUBLIC_SITE_URL_EU = 'https://eu.example.test'
    $env:PRERENDER_API_BASE_URL_CN = 'https://api.cn.example.test'
    $env:PRERENDER_API_BASE_URL_EU = 'https://api.eu.example.test'
    $bundle = & $fixtureScript -Version 'layout-regional' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $true
    Write-Output 'release package layout integration passed (local and regional SEO bundles)'
}
finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name]) }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
