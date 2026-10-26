param(
    [string]$BundlePath,
    [Alias('Environment')][string]$BundleEnvironment,
    [Alias('Region')][string]$BundleRegion,
    [Alias('ExpectedCommitSha')][string]$BundleCommitSha,
    [Alias('ArtifactOnly')][switch]$CheckArtifactOnly
)

$ErrorActionPreference = 'Stop'

function Assert-DzdpReleaseUrl {
    param([string]$Name, [string]$Value, [string]$Scheme = 'https', [switch]$OriginOnly)
    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match 'CHANGE_ME|xxxxx|\s' -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne $Scheme -or [string]::IsNullOrWhiteSpace($uri.Host) -or
        $uri.IsLoopback -or $uri.Port -lt 1 -or $uri.Port -gt 65535 -or
        $uri.UserInfo -or $uri.Query -or $uri.Fragment) {
        throw "$Name must be an absolute $Scheme URL without credentials, placeholders, query, fragment, or loopback host"
    }
    if ($OriginOnly -and $uri.AbsolutePath -cne '/') { throw "$Name must be an origin without a path" }
}

function Read-DzdpBundleText {
    param($Archive, [string]$Name)
    $entry = $Archive.GetEntry($Name)
    if ($null -eq $entry) { throw "Release bundle is missing $Name" }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd() }
    finally { $reader.Dispose() }
}

function Test-DzdpReleaseBundle {
    param(
        [string]$Path,
        [string]$TargetEnvironment,
        [string]$TargetRegion,
        [string]$ExpectedSha,
        [switch]$ArtifactOnly
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Release bundle must be an existing ZIP file' }
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $name = [IO.Path]::GetFileName($resolved)
    $match = [regex]::Match($name, '^dazhongdianping-release-([A-Za-z0-9][A-Za-z0-9._-]{0,127})\.zip$')
    if (-not $match.Success) { throw 'Release bundle name must match dazhongdianping-release-<version>.zip' }
    $version = $match.Groups[1].Value
    if (-not $ArtifactOnly) {
        if ($TargetEnvironment -cnotin @('test', 'pre', 'prod')) { throw 'Environment must be test, pre, or prod' }
        if ($TargetRegion -cnotin @('CN', 'EU')) { throw 'Region must be CN or EU' }
        if ([string]::IsNullOrWhiteSpace($ExpectedSha)) { throw 'ExpectedCommitSha must identify the verified source commit before deployment' }
    }
    if ($ExpectedSha -and $ExpectedSha -notmatch '^[0-9a-fA-F]{40}$') { throw 'ExpectedCommitSha must be a full 40-character Git SHA' }
    if (-not (Test-Path -LiteralPath "$resolved.sha256" -PathType Leaf)) { throw 'Release bundle SHA-256 sidecar is missing' }
    $sidecar = (Get-Content -LiteralPath "$resolved.sha256" -Raw).Trim()
    $digest = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash.ToLowerInvariant()
    if ($sidecar -cne "$digest  $name") { throw 'Release bundle SHA-256 sidecar does not match the ZIP' }

    $archive = [IO.Compression.ZipFile]::OpenRead($resolved)
    try {
        $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($entry in $archive.Entries) {
            $member = $entry.FullName
            if (-not $names.Add($member)) { throw 'Release bundle contains duplicate paths' }
            if ([string]::IsNullOrWhiteSpace($member) -or $member.StartsWith('/') -or $member.Contains('\') -or $member.Contains('//') -or
                $member -match '[:\x00-\x1f\x7f]' -or ($member.Split('/') | Where-Object { $_ -in @('.', '..') }) -or
                (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) {
                throw 'Release bundle contains an unsafe path or symbolic link'
            }
        }
        $manifest = Read-DzdpBundleText $archive 'release-manifest.json' | ConvertFrom-Json
        if ($manifest.version -cne $version -or $manifest.bundleName -cne $name -or
            (Read-DzdpBundleText $archive 'release-version.txt').Trim() -cne $version) {
            throw 'Release bundle version, filename, and manifest do not match'
        }
        if ($manifest.commitSha -cnotmatch '^[0-9a-f]{40}$') { throw 'Release manifest must contain a full source commit SHA' }
        if ($ExpectedSha -and $manifest.commitSha -cne $ExpectedSha.ToLowerInvariant()) { throw 'Release manifest commitSha does not match ExpectedCommitSha' }
        $frontends = @($manifest.frontends)
        if ($frontends.Count -ne 3 -or (Compare-Object $frontends @('web', 'admin-web', 'merchant-web') -CaseSensitive)) {
            throw 'Release manifest must declare all three frontends exactly once'
        }
        foreach ($frontend in $frontends) {
            if (-not $names.Contains("$frontend/dist/index.html") -or
                -not @($names | Where-Object { $_ -like "$frontend/dist/assets/*.js" }).Count) {
                throw "Release bundle is missing $frontend dist or JavaScript assets"
            }
        }
        if ($manifest.backendJar -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*\.jar$' -or
            -not $names.Contains("backend/$($manifest.backendJar)")) { throw 'Release bundle is missing its declared backend JAR' }
        $db = $manifest.databaseMigrations
        if ($db.runner -cne 'database/mysql-migrate.sh' -or $db.manifest -cne 'database/migrations.sha256' -or
            $db.directory -cne 'database/migrations' -or -not $names.Contains($db.runner)) {
            throw 'Release manifest database layout is invalid'
        }
        $lines = @((Read-DzdpBundleText $archive $db.manifest).TrimEnd("`r", "`n") -split '\r?\n')
        $migrationNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $expectedVersion = 3
        foreach ($line in $lines) {
            $migration = [regex]::Match($line, '^([0-9a-f]{64})  ([0-9]{2,}_[A-Za-z0-9_]+_migration\.sql)$')
            if (-not $migration.Success -or [int]$migration.Groups[2].Value.Split('_')[0] -ne $expectedVersion) {
                throw 'Release bundle migration manifest must be contiguous from 03'
            }
            $member = "database/migrations/$($migration.Groups[2].Value)"
            [void]$migrationNames.Add($member)
            $entry = $archive.GetEntry($member)
            if ($null -eq $entry) { throw 'Release bundle is missing a declared migration' }
            $stream = $entry.Open()
            try { $actual = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant() }
            finally { $stream.Dispose() }
            if ($actual -cne $migration.Groups[1].Value) { throw 'Release bundle migration checksum does not match' }
            $expectedVersion++
        }
        $sqlFiles = @($names | Where-Object { $_ -like 'database/migrations/*.sql' })
        if ($sqlFiles.Count -ne $migrationNames.Count -or ($sqlFiles | Where-Object { -not $migrationNames.Contains($_) }) -or
            [int]$db.startVersion -ne 3 -or [int]$db.endVersion -ne ($expectedVersion - 1) -or [int]$db.count -ne $lines.Count -or
            ($names | Where-Object { $_ -match '(^|/)(01_schema|02_seed_data)\.sql$' })) {
            throw 'Release bundle migrations and manifest metadata do not match'
        }
        if (-not $ArtifactOnly) {
            if ($manifest.buildEnvironment -cne $TargetEnvironment) { throw 'Release manifest buildEnvironment must match the deployment environment; rebuild with real deployment configuration' }
            $runtime = $manifest.webRuntime
            if ($runtime.defaultRegion -cne $TargetRegion) { throw 'Release manifest defaultRegion does not match the deployment region' }
            Assert-DzdpReleaseUrl 'webRuntime.apiBaseUrl' $runtime.apiBaseUrl
            Assert-DzdpReleaseUrl 'webRuntime.webSocketBaseUrl' $runtime.webSocketBaseUrl 'wss'
            $stripeMode = if ($TargetEnvironment -eq 'prod') { 'live' } else { 'test' }
            if ($runtime.stripeConfigured -isnot [bool] -or -not $runtime.stripeConfigured -or $runtime.stripeMode -cne $stripeMode) {
                throw 'Release manifest Stripe configuration must match the deployment environment'
            }
            $snapshots = @($manifest.seoSnapshots | Where-Object { $_.region -ceq $TargetRegion })
            if ($manifest.seoSnapshot.enabled -isnot [bool] -or -not $manifest.seoSnapshot.enabled -or $snapshots.Count -ne 1) {
                throw 'Release bundle must contain a configured SEO snapshot for the deployment region'
            }
            $snapshot = $snapshots[0]
            Assert-DzdpReleaseUrl 'seoSnapshot.siteUrl' $snapshot.siteUrl -OriginOnly
            Assert-DzdpReleaseUrl 'seoSnapshot.apiBaseUrl' $snapshot.apiBaseUrl
            if ($snapshot.directory -cne "web/seo-snapshots/$TargetRegion" -or
                -not $names.Contains("$($snapshot.directory)/index.html")) { throw 'Release bundle is missing the declared regional SEO snapshot' }
        }
        return [pscustomobject]@{
            ArtifactVerified = $true
            BuildConfigurationVerified = -not $ArtifactOnly
            Version = $version
            CommitSha = $manifest.commitSha
            DefaultRegion = $manifest.webRuntime.defaultRegion
            MigrationCount = $lines.Count
            Sha256 = $digest
        }
    }
    finally { $archive.Dispose() }
}

if ($MyInvocation.InvocationName -ne '.') {
    Test-DzdpReleaseBundle -Path $BundlePath -TargetEnvironment $BundleEnvironment -TargetRegion $BundleRegion -ExpectedSha $BundleCommitSha -ArtifactOnly:$CheckArtifactOnly
}
