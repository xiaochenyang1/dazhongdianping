$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$preflightPath = Join-Path $PSScriptRoot 'release-bundle-preflight.ps1'
$deployPath = Join-Path $PSScriptRoot 'deploy-release.ps1'
. $preflightPath
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('dzdp-bundle-preflight-' + [Guid]::NewGuid().ToString('N'))
$script:fixtureCount = 0
$script:rejectionCount = 0
$transportState = @{ Attempts = 0 }
$fixtureSha = 'a' * 40

function Assert-BundleTest {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# Exercise the real deployment entry point, but stop before it can acquire a
# transport executable. Valid bundles must reach this guard; invalid ones must not.
function Get-Command {
    param([string]$Name, [string]$CommandType)
    if ($Name -in @('ssh', 'scp')) {
        $transportState.Attempts++
        throw 'TEST_TRANSPORT_BOUNDARY'
    }
    Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
}

function New-TestBundle {
    param(
        [scriptblock]$ManifestEdit = {},
        [scriptblock]$EntriesEdit = {},
        [string]$ExtraEntry = '',
        [switch]$Symlink,
        [switch]$NoSidecar,
        [switch]$WrongSidecar
    )
    $script:fixtureCount++
    $directory = Join-Path $fixtureRoot $script:fixtureCount
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $name = 'dazhongdianping-release-fixture.zip'
    $bundle = Join-Path $directory $name
    $sql = 'SELECT 1;'
    $sqlHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($sql))).ToLowerInvariant()
    $manifest = @{
        version = 'fixture'; bundleName = $name; commitSha = $fixtureSha; buildEnvironment = 'pre'
        backendJar = 'fixture.jar'; frontends = @('web', 'admin-web', 'merchant-web')
        databaseMigrations = @{
            runner = 'database/mysql-migrate.sh'; manifest = 'database/migrations.sha256'
            directory = 'database/migrations'; startVersion = 3; endVersion = 3; count = 1
        }
        webRuntime = @{
            defaultRegion = 'EU'; apiBaseUrl = 'https://api.example.test'
            webSocketBaseUrl = 'wss://api.example.test/ws'; stripeConfigured = $true; stripeMode = 'test'
        }
        seoSnapshot = @{ enabled = $true }
        seoSnapshots = @(@{
            region = 'EU'; directory = 'web/seo-snapshots/EU'
            siteUrl = 'https://eu.example.test'; apiBaseUrl = 'https://api.example.test'
        })
    }
    & $ManifestEdit $manifest
    $entries = [ordered]@{
        'release-manifest.json' = ($manifest | ConvertTo-Json -Depth 10)
        'release-version.txt' = 'fixture'
        'backend/fixture.jar' = 'test jar'
        'database/mysql-migrate.sh' = '# test runner'
        'database/migrations.sha256' = "$sqlHash  03_fixture_migration.sql"
        'database/migrations/03_fixture_migration.sql' = $sql
        'web/seo-snapshots/EU/index.html' = '<html>EU snapshot</html>'
    }
    foreach ($frontend in @('web', 'admin-web', 'merchant-web')) {
        $entries["$frontend/dist/index.html"] = '<html>test</html>'
        $entries["$frontend/dist/assets/app.js"] = 'test();'
    }
    & $EntriesEdit $entries
    $archive = [IO.Compression.ZipFile]::Open($bundle, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($pair in $entries.GetEnumerator()) {
            $entry = $archive.CreateEntry($pair.Key)
            $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
            try { $writer.Write([string]$pair.Value) }
            finally { $writer.Dispose() }
        }
        if ($ExtraEntry) {
            $entry = $archive.CreateEntry($ExtraEntry)
            if ($Symlink) { $entry.ExternalAttributes = [int](-1577123840) } # Unix S_IFLNK | 0777, shifted 16.
        }
    }
    finally { $archive.Dispose() }
    if (-not $NoSidecar) {
        $digest = (Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($WrongSidecar) { $digest = '0' * 64 }
        Set-Content -LiteralPath "$bundle.sha256" -Value "$digest  $name" -Encoding ascii
    }
    return $bundle
}

function Invoke-TestDeployment {
    param([string]$Bundle, [string]$ExpectedSha = $fixtureSha, [string]$Environment = 'pre', [string]$Region = 'EU')
    & $deployPath -ReleaseBundle $Bundle -ExpectedCommitSha $ExpectedSha -Environment $Environment -Region $Region `
        -RemoteHost 'deploy.example.test' -RemoteUser 'deploy' -RemotePort 22 -RemoteRoot '/srv/dzdp' `
        -SmokeUrls 'https://eu.example.test/health' -DatabaseDefaultsFile '/etc/dzdp/mysql.cnf' `
        -DatabaseMigrationMode 'verify' -ReleaseRetentionCount 5
}

function Assert-Rejected {
    param([string]$Bundle, [string]$Pattern, [string]$ExpectedSha = $fixtureSha, [string]$Environment = 'pre', [string]$Region = 'EU')
    $before = $transportState.Attempts
    $message = ''
    try { Test-DzdpReleaseBundle -Path $Bundle -TargetEnvironment $Environment -TargetRegion $Region -ExpectedSha $ExpectedSha | Out-Null }
    catch { $message = $_.Exception.Message }
    Assert-BundleTest ($message -match $Pattern) "Preflight expected '$Pattern', got '$message'"
    $message = ''
    try { Invoke-TestDeployment -Bundle $Bundle -ExpectedSha $ExpectedSha -Environment $Environment -Region $Region | Out-Null }
    catch { $message = $_.Exception.Message }
    Assert-BundleTest ($message -match $Pattern) "Deployment expected '$Pattern', got '$message'"
    Assert-BundleTest ($transportState.Attempts -eq $before) 'Rejected bundles must not reach SSH/SCP'
    $script:rejectionCount++
}

try {
    $valid = New-TestBundle
    $verified = Test-DzdpReleaseBundle -Path $valid -TargetEnvironment pre -TargetRegion EU -ExpectedSha $fixtureSha
    Assert-BundleTest ($verified.ArtifactVerified -and $verified.BuildConfigurationVerified -and $verified.CommitSha -ceq $fixtureSha) 'A valid pre bundle must pass'
    $message = ''
    try { Invoke-TestDeployment -Bundle $valid | Out-Null }
    catch { $message = $_.Exception.Message }
    Assert-BundleTest ($message -eq 'TEST_TRANSPORT_BOUNDARY' -and $transportState.Attempts -eq 1) "A valid bundle must reach transport only after verification: $message"

    $test = New-TestBundle -ManifestEdit { param($m) $m.buildEnvironment = 'test' }
    Test-DzdpReleaseBundle -Path $test -TargetEnvironment test -TargetRegion EU -ExpectedSha $fixtureSha | Out-Null
    $prod = New-TestBundle -ManifestEdit { param($m) $m.buildEnvironment = 'prod'; $m.webRuntime.stripeMode = 'live' }
    Test-DzdpReleaseBundle -Path $prod -TargetEnvironment prod -TargetRegion EU -ExpectedSha $fixtureSha | Out-Null
    Assert-Rejected $prod 'buildEnvironment'
    Assert-Rejected $valid 'buildEnvironment' -Environment prod
    Assert-Rejected $valid 'defaultRegion' -Region CN
    Assert-Rejected $valid 'commitSha does not match' -ExpectedSha ('b' * 40)
    Assert-Rejected $valid 'full 40-character' -ExpectedSha 'short-sha'
    Assert-Rejected $valid 'Environment must be' -Environment staging
    Assert-Rejected $valid 'Region must be' -Region XX
    Assert-Rejected (Join-Path $fixtureRoot 'missing.zip') 'existing ZIP'
    Assert-Rejected (New-TestBundle -NoSidecar) 'sidecar is missing'
    Assert-Rejected (New-TestBundle -WrongSidecar) 'sidecar does not match'

    $technical = New-TestBundle -ManifestEdit {
        param($m)
        $m.buildEnvironment = ''; $m.webRuntime.apiBaseUrl = ''; $m.webRuntime.webSocketBaseUrl = ''
        $m.webRuntime.stripeConfigured = $false; $m.webRuntime.stripeMode = ''
        $m.seoSnapshot.enabled = $false; $m.seoSnapshots = @()
    }
    $artifact = & $preflightPath -BundlePath $technical -ExpectedCommitSha $fixtureSha -ArtifactOnly
    Assert-BundleTest ($artifact.ArtifactVerified -and -not $artifact.BuildConfigurationVerified) 'Artifact-only checks must not claim deployment readiness'
    Assert-Rejected $technical 'buildEnvironment'
    # A missing expected SHA must fail regardless of an inherited environment.
    $previousSha = $env:DEPLOY_EXPECTED_COMMIT_SHA
    try {
        Remove-Item Env:DEPLOY_EXPECTED_COMMIT_SHA -ErrorAction SilentlyContinue
        Assert-Rejected $valid 'ExpectedCommitSha must identify' -ExpectedSha ''
    }
    finally {
        if ($null -eq $previousSha) { Remove-Item Env:DEPLOY_EXPECTED_COMMIT_SHA -ErrorAction SilentlyContinue }
        else { $env:DEPLOY_EXPECTED_COMMIT_SHA = $previousSha }
    }

    $manifestCases = @(
        @{ Pattern = 'version, filename'; Edit = { param($m) $m.version = 'other' } }
        @{ Pattern = 'version, filename'; Edit = { param($m) $m.bundleName = 'other.zip' } }
        @{ Pattern = 'full source commit'; Edit = { param($m) $m.commitSha = '' } }
        @{ Pattern = 'three frontends'; Edit = { param($m) $m.frontends = @('web', 'admin-web') } }
        @{ Pattern = 'three frontends'; Edit = { param($m) $m.frontends = @('web', 'web', 'admin-web') } }
        @{ Pattern = 'backend JAR'; Edit = { param($m) $m.backendJar = '../other.jar' } }
        @{ Pattern = 'database layout'; Edit = { param($m) $m.databaseMigrations.runner = '../runner.sh' } }
        @{ Pattern = 'metadata do not match'; Edit = { param($m) $m.databaseMigrations.endVersion = 26 } }
        @{ Pattern = 'metadata do not match'; Edit = { param($m) $m.databaseMigrations.count = 2 } }
        @{ Pattern = 'Stripe configuration'; Edit = { param($m) $m.webRuntime.stripeConfigured = $false } }
        @{ Pattern = 'Stripe configuration'; Edit = { param($m) $m.webRuntime.stripeConfigured = 'true' } }
        @{ Pattern = 'Stripe configuration'; Edit = { param($m) $m.webRuntime.stripeMode = 'live' } }
        @{ Pattern = 'configured SEO snapshot'; Edit = { param($m) $m.seoSnapshot.enabled = $false } }
        @{ Pattern = 'configured SEO snapshot'; Edit = { param($m) $m.seoSnapshots = @() } }
        @{ Pattern = 'configured SEO snapshot'; Edit = { param($m) $m.seoSnapshots += $m.seoSnapshots[0] } }
        @{ Pattern = 'declared regional SEO'; Edit = { param($m) $m.seoSnapshots[0].directory = 'web/seo-snapshots/CN' } }
        @{ Pattern = 'origin without a path'; Edit = { param($m) $m.seoSnapshots[0].siteUrl = 'https://eu.example.test/path' } }
    )
    foreach ($case in $manifestCases) { Assert-Rejected (New-TestBundle -ManifestEdit $case.Edit) $case.Pattern }
    foreach ($url in @('http://api.example.test', 'https://127.0.0.1', 'https://user:private@api.example.test', 'https://api.example.test:99999', 'https://CHANGE_ME', 'https://api.example.test?token=private')) {
        $bundle = New-TestBundle -ManifestEdit { param($m) $m.webRuntime.apiBaseUrl = $url }
        Assert-Rejected $bundle 'webRuntime.apiBaseUrl must be'
        $message = ''
        try { Test-DzdpReleaseBundle -Path $bundle -TargetEnvironment pre -TargetRegion EU -ExpectedSha $fixtureSha | Out-Null }
        catch { $message = $_.Exception.Message }
        Assert-BundleTest (-not $message.Contains($url)) 'URL rejection must not echo credentials or query values'
    }
    Assert-Rejected (New-TestBundle -ManifestEdit { param($m) $m.webRuntime.webSocketBaseUrl = 'ws://api.example.test/ws' }) 'webRuntime.webSocketBaseUrl must be'

    foreach ($member in @('release-manifest.json', 'release-version.txt', 'database/migrations.sha256')) {
        Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove($member) }) 'missing'
    }
    foreach ($frontend in @('web', 'admin-web', 'merchant-web')) {
        Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove("$frontend/dist/index.html") }) 'dist or JavaScript assets'
        Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove("$frontend/dist/assets/app.js") }) 'dist or JavaScript assets'
    }
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove('backend/fixture.jar') }) 'backend JAR'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove('database/mysql-migrate.sh') }) 'database layout'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove('web/seo-snapshots/EU/index.html') }) 'regional SEO snapshot'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e['release-version.txt'] = 'other' }) 'version, filename'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e['database/migrations/03_fixture_migration.sql'] = 'SELECT 2;' }) 'migration checksum'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e.Remove('database/migrations/03_fixture_migration.sql') }) 'missing a declared migration'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e['database/migrations.sha256'] = $e['database/migrations.sha256'].Replace('03_fixture', '04_fixture') }) 'contiguous from 03'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e['database/migrations/04_extra_migration.sql'] = 'SELECT 2;' }) 'metadata do not match'
    Assert-Rejected (New-TestBundle -EntriesEdit { param($e) $e['database/01_schema.sql'] = 'DROP TABLE example;' }) 'metadata do not match'
    foreach ($path in @('../outside', '/absolute', 'web/../outside', 'web\outside', 'web//outside', 'C:outside')) {
        Assert-Rejected (New-TestBundle -ExtraEntry $path) 'unsafe path or symbolic link'
    }
    Assert-Rejected (New-TestBundle -ExtraEntry 'release-manifest.json') 'duplicate paths'
    Assert-Rejected (New-TestBundle -ExtraEntry 'link' -Symlink) 'unsafe path or symbolic link'
    Write-Output "release bundle preflight passed ($script:rejectionCount rejections before transport; valid test/pre/prod and technical bundles)"
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
