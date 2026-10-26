$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('dzdp-package-layout-' + [Guid]::NewGuid().ToString('N'))
$fixtureScript = Join-Path $fixtureRoot 'scripts/ci/package-release.ps1'
$runningOnWindows = [Environment]::OSVersion.Platform -eq 'Win32NT'
$environmentNames = @(
    'DEPLOY_ENVIRONMENT', 'DEPLOY_REGION', 'GITHUB_SHA', 'APP_RELEASE_VERSION', 'APP_RELEASE_COMMIT_SHA',
    'DZDP_PACKAGE_BUILD_MARKER', 'PRERENDER_REGION', 'PRERENDER_REGIONS',
    'PUBLIC_SITE_URL', 'PRERENDER_API_BASE_URL', 'PUBLIC_SITE_URL_CN', 'PUBLIC_SITE_URL_EU',
    'PRERENDER_API_BASE_URL_CN', 'PRERENDER_API_BASE_URL_EU',
    'VITE_API_BASE_URL', 'VITE_WS_BASE_URL', 'VITE_STRIPE_PUBLISHABLE_KEY', 'VITE_DEFAULT_REGION'
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
    if ((Split-Path (Get-Location) -Leaf) -eq 'web') {
        Assert-Layout ($env:VITE_DEFAULT_REGION -eq $env:PRERENDER_REGION) 'Web runtime and SEO region must match'
    }
    Set-Content -LiteralPath (Join-Path (Get-Location) 'dist/index.html') -Value "$($env:PRERENDER_REGION):$command" -Encoding utf8
    Add-Content -LiteralPath $env:DZDP_PACKAGE_BUILD_MARKER -Value 'npm'
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
    param([string]$Bundle, [bool]$WithSnapshots, [string]$Region = 'EU')
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
        Assert-Layout ((Read-ZipText $archive 'web/dist/index.html') -eq "${Region}:build") 'The serving Web dist must retain the base region build'
        $manifest = Read-ZipText $archive 'release-manifest.json' | ConvertFrom-Json
        Assert-Layout ($manifest.webRuntime.defaultRegion -ceq $Region) 'Serving web must default to the selected region'
        Assert-Layout ($manifest.commitSha -ceq $script:fixtureSha) 'Manifest must identify the actual source SHA even when GITHUB_SHA is stale'
        Assert-Layout ($manifest.buildEnvironment -ceq [string]$env:DEPLOY_ENVIRONMENT) 'Manifest must record the actual build environment'
        if ($env:DEPLOY_ENVIRONMENT) {
            $expectedMode = if ($env:DEPLOY_ENVIRONMENT -eq 'prod') { 'live' } else { 'test' }
            Assert-Layout ($manifest.webRuntime.stripeConfigured -eq $true -and $manifest.webRuntime.stripeMode -ceq $expectedMode) 'Deployment manifest must record the Stripe mode without a key'
        }
        else {
            Assert-Layout (-not $manifest.webRuntime.stripeConfigured -and $manifest.webRuntime.stripeMode -ceq '') 'Technical packages must not claim configured Stripe'
        }
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

function Invoke-FixtureGit {
    & git -C $fixtureRoot @args
    if ($LASTEXITCODE -ne 0) { throw 'Fixture Git command failed' }
}

function Assert-PackageRejectedBeforeBuild {
    param([scriptblock]$Action, [string]$Pattern, [string]$ForbiddenValue = '')
    $before = @(Get-Content -LiteralPath $env:DZDP_PACKAGE_BUILD_MARKER -ErrorAction SilentlyContinue).Count
    $message = ''
    try { & $Action | Out-Null }
    catch { $message = $_.Exception.Message }
    Assert-Layout ($message -match $Pattern) "Packaging must fail with $Pattern"
    Assert-Layout (@(Get-Content -LiteralPath $env:DZDP_PACKAGE_BUILD_MARKER -ErrorAction SilentlyContinue).Count -eq $before) 'Invalid source or configuration must be rejected before any builder runs'
    if ($ForbiddenValue) { Assert-Layout (-not $message.Contains($ForbiddenValue)) 'Validation errors must not echo configuration values' }
}

try {
    foreach ($name in $environmentNames) { Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue }
    # workflow_run can expose a newer default-branch SHA than the checked-out CI source.
    $env:GITHUB_SHA = 'f' * 40
    foreach ($directory in @('scripts/ci', 'sql/mysql', 'backend/target', 'web/dist/assets', 'admin-web/dist/assets', 'merchant-web/dist/assets')) {
        New-Item -ItemType Directory -Path (Join-Path $fixtureRoot $directory) -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/ci/package-release.ps1') -Destination $fixtureScript
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/ci/release-bundle-preflight.ps1') -Destination (Join-Path $fixtureRoot 'scripts/ci/release-bundle-preflight.ps1')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/ci/mysql-migrate.sh') -Destination (Join-Path $fixtureRoot 'scripts/ci/mysql-migrate.sh')
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'sql/mysql') -File |
        Where-Object { $_.Name -match '_migration\.sql$|^migrations\.sha256$' } |
        Copy-Item -Destination (Join-Path $fixtureRoot 'sql/mysql')
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'backend/target/fixture.jar') -Value 'fixture'
    foreach ($frontend in @('web', 'admin-web', 'merchant-web')) {
        Set-Content -LiteralPath (Join-Path $fixtureRoot "$frontend/dist/assets/app.js") -Value 'fixture'
    }
    $wrapper = Join-Path $fixtureRoot $(if ($runningOnWindows) { 'backend/mvnw.cmd' } else { 'backend/mvnw' })
    if ($runningOnWindows) {
        [IO.File]::WriteAllText($wrapper, "@echo off`r`necho maven>>`"%DZDP_PACKAGE_BUILD_MARKER%`"`r`nexit /b 0`r`n")
    }
    else {
        [IO.File]::WriteAllText($wrapper, '#!/bin/sh' + "`n" + 'printf "maven\n" >> "$DZDP_PACKAGE_BUILD_MARKER"' + "`nexit 0`n")
        [IO.File]::SetUnixFileMode($wrapper, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
    }
    $outputDir = Join-Path $fixtureRoot 'output'
    $env:DZDP_PACKAGE_BUILD_MARKER = Join-Path $fixtureRoot 'build-marker.log'
    Set-Content -LiteralPath (Join-Path $fixtureRoot '.gitignore') -Value @('**/dist/', '**/target/', '/output/', '/build-marker.log') -Encoding ascii
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'source.txt') -Value 'tracked source' -Encoding ascii
    Invoke-FixtureGit -c init.defaultBranch=main init -q
    Invoke-FixtureGit config core.autocrlf false
    Invoke-FixtureGit add .
    Invoke-FixtureGit -c user.name=ReleaseFixture -c user.email=release-fixture@example.invalid commit -qm 'fixture source'
    $script:fixtureSha = Invoke-FixtureGit rev-parse HEAD
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'mismatch' -OutputDir $outputDir -CommitSha ('b' * 40) } 'does not match the checked-out source'
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'short-sha' -OutputDir $outputDir -CommitSha 'abc123' } 'full 40-character'
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'source.txt') -Value 'dirty source' -Encoding ascii
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'dirty' -OutputDir $outputDir } 'clean tracked source'
    Invoke-FixtureGit add source.txt
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'staged' -OutputDir $outputDir } 'clean tracked source'
    Invoke-FixtureGit restore --staged --worktree source.txt
    $untrackedSource = Join-Path $fixtureRoot 'web/untracked-source.ts'
    Set-Content -LiteralPath $untrackedSource -Value 'export const untracked = true' -Encoding ascii
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'untracked' -OutputDir $outputDir } 'untracked release inputs'
    Remove-Item -LiteralPath $untrackedSource
    # Local assessment reports do not participate in server builds.
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'reports') | Out-Null
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'reports/local.md') -Value 'local assessment'
    $bundle = & $fixtureScript -Version 'layout-local' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $false
    $originalDigest = (Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'layout-local' -OutputDir $outputDir } 'already exists'
    Assert-Layout ((Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash -ceq $originalDigest) 'Existing release bundles must never be overwritten'
    $orphanSidecar = Join-Path $outputDir 'dazhongdianping-release-orphan.zip.sha256'
    Set-Content -LiteralPath $orphanSidecar -Value 'existing checksum'
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'orphan' -OutputDir $outputDir } 'already exists'
    foreach ($name in @('PRERENDER_REGION', 'PRERENDER_REGIONS', 'VITE_DEFAULT_REGION', 'PUBLIC_SITE_URL', 'PRERENDER_API_BASE_URL')) {
        Assert-Layout (-not (Test-Path -LiteralPath "Env:$name")) "Local packaging must leave previously unset $name absent"
    }

    $env:PRERENDER_REGION = 'EU'
    $env:PRERENDER_REGIONS = 'CN,EU'
    $env:VITE_DEFAULT_REGION = 'CN'
    $env:PUBLIC_SITE_URL_CN = 'https://cn.example.test'
    $env:PUBLIC_SITE_URL_EU = 'https://eu.example.test'
    $env:PRERENDER_API_BASE_URL_CN = 'https://api.cn.example.test'
    $env:PRERENDER_API_BASE_URL_EU = 'https://api.eu.example.test'
    $env:APP_RELEASE_COMMIT_SHA = $script:fixtureSha
    $bundle = & $fixtureScript -Version 'layout-regional' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $true
    Assert-Layout ($env:PRERENDER_REGION -eq 'EU' -and $env:PRERENDER_REGIONS -eq 'CN,EU' -and $env:VITE_DEFAULT_REGION -eq 'CN') 'Regional packaging must restore explicitly configured regions'

    $env:DEPLOY_ENVIRONMENT = 'pre'
    $env:DEPLOY_REGION = 'EU'
    $env:VITE_API_BASE_URL = 'https://api.eu.example.test'
    $env:VITE_WS_BASE_URL = 'wss://api.eu.example.test/ws'
    $env:VITE_STRIPE_PUBLISHABLE_KEY = 'pk_test_fixture123'
    $bundle = & $fixtureScript -Version 'layout-pre' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $true
    $env:DEPLOY_REGION = 'CN'
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'region-mismatch' -OutputDir $outputDir } 'DEPLOY_REGION'
    $env:DEPLOY_REGION = 'EU'
    foreach ($key in @('pk_live_fixture123', 'pk_test_CHANGE_ME', 'pk_test_xxxxx')) {
        $env:VITE_STRIPE_PUBLISHABLE_KEY = $key
        Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'stripe-mismatch' -OutputDir $outputDir } 'VITE_STRIPE_PUBLISHABLE_KEY' $key
    }
    $env:VITE_STRIPE_PUBLISHABLE_KEY = 'pk_test_fixture123'
    foreach ($url in @('https://private-user:private-pass@api.eu.example.test', 'https://127.0.0.1', 'https://api.eu.example.test:99999', 'https://CHANGE_ME')) {
        $env:VITE_API_BASE_URL = $url
        Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'invalid-url' -OutputDir $outputDir } 'VITE_API_BASE_URL' $url
    }
    $env:VITE_API_BASE_URL = 'https://api.eu.example.test'
    $env:PUBLIC_SITE_URL_EU = 'https://eu.example.test/subpath'
    Assert-PackageRejectedBeforeBuild { & $fixtureScript -Version 'invalid-origin' -OutputDir $outputDir } 'PUBLIC_SITE_URL_EU'
    $env:PUBLIC_SITE_URL_EU = 'https://eu.example.test'
    $env:DEPLOY_ENVIRONMENT = 'prod'
    $env:DEPLOY_REGION = 'CN'
    $env:PRERENDER_REGION = 'CN'
    $env:VITE_STRIPE_PUBLISHABLE_KEY = 'pk_live_fixture123'
    $bundle = & $fixtureScript -Version 'layout-prod' -OutputDir $outputDir
    Test-Bundle -Bundle $bundle -WithSnapshots $true -Region 'CN'
    Write-Output 'release package integration passed (source provenance, pre-build rejection, technical/regional/pre/prod bundles)'
}
finally {
    foreach ($name in $environmentNames) {
        if ($null -eq $previousEnvironment[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item "Env:\$name" $previousEnvironment[$name]
        }
    }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
