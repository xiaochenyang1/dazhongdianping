[CmdletBinding()]
param(
    [string]$CandidateVersion,
    [string]$OutputDirectory = "artifacts/candidate-verification",
    [string]$MysqlDatabaseName,
    [switch]$AllowDirtySource,
    [switch]$KeepMysqlDatabase,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$verifyAllPath = Join-Path $PSScriptRoot "verify-all.ps1"
$startedAt = [DateTimeOffset]::UtcNow
$stage = "preflight"
$failure = $null
$sourceSha = $null
$ready = $false
$resolvedVersion = $CandidateVersion
$databaseName = $MysqlDatabaseName

function Get-EnvironmentValue {
    param([string]$Name, [string]$DefaultValue)

    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) { return $DefaultValue }
    return $value.Trim()
}

function Get-EnvironmentPort {
    param([string]$Name, [int]$DefaultValue)

    $raw = Get-EnvironmentValue -Name $Name -DefaultValue "$DefaultValue"
    $port = 0
    if (-not [int]::TryParse($raw, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
        throw "$Name must be an integer between 1 and 65535"
    }
    return $port
}

function Get-HttpEndpoint {
    param([string]$Name, [string]$Value)

    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @("http", "https") -or
        [string]::IsNullOrWhiteSpace($uri.Host) -or
        -not [string]::IsNullOrWhiteSpace($uri.UserInfo)) {
        throw "$Name must be an absolute HTTP(S) URL without embedded credentials"
    }
    return [pscustomobject]@{ HostName = $uri.Host; Port = $uri.Port }
}

function Assert-TcpReachable {
    param([string]$Name, [string]$TargetHost, [int]$Port)

    $client = [Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($TargetHost, $Port)
        if (-not $task.Wait([TimeSpan]::FromSeconds(3)) -or -not $client.Connected) {
            throw "$Name service is not reachable"
        }
    }
    catch {
        throw "$Name service is not reachable"
    }
    finally {
        $client.Dispose()
    }
}

function Assert-RequiredEnvironmentValues {
    param([string[]]$Names)

    $missing = @($Names | Where-Object {
        [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_, "Process"))
    })
    if ($missing.Count -gt 0) {
        throw "Candidate verification requires environment values: $($missing -join ', ')"
    }
}

function Get-SourceCommit {
    $sha = (& git -C $repoRoot rev-parse --verify HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or $sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Candidate verification requires a Git source commit"
    }
    return $sha
}

function Assert-CleanSource {
    if ($AllowDirtySource) { return }

    $changes = @(& git -C $repoRoot status --porcelain --untracked-files=all)
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect the Git working tree" }
    if ($changes.Count -gt 0) {
        throw "Candidate verification requires a clean working tree; use -AllowDirtySource only for non-candidate development checks"
    }
}

function Resolve-OutputDirectory {
    if ([IO.Path]::IsPathRooted($OutputDirectory)) {
        return [IO.Path]::GetFullPath($OutputDirectory)
    }
    return [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
}

if (-not (Test-Path -LiteralPath $verifyAllPath -PathType Leaf)) {
    throw "verify-all.ps1 is missing"
}
if (-not [string]::IsNullOrWhiteSpace($CandidateVersion) -and
    $CandidateVersion -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
    throw "CandidateVersion contains unsupported characters"
}
if (-not [string]::IsNullOrWhiteSpace($MysqlDatabaseName) -and
    $MysqlDatabaseName -notmatch '^[A-Za-z][A-Za-z0-9_]{0,63}$') {
    throw "MysqlDatabaseName must use a safe MySQL identifier"
}

$requestedChecks = @(
    "contract-tests",
    "backend-tests",
    "web-tests-build",
    "admin-web-tests-build",
    "merchant-web-tests-build",
    "flutter-tests-analyze-build",
    "mysql-redis-smoke",
    "s3-storage-smoke",
    "browser-smoke",
    "browser-real-backend-e2e",
    "elasticsearch-smoke"
)

if ($DryRun) {
    $plan = [ordered]@{
        schemaVersion = 1
        mode = "DryRun"
        requiresCleanSource = -not $AllowDirtySource
        usesUniqueMysqlDatabase = [string]::IsNullOrWhiteSpace($MysqlDatabaseName)
        dropsMysqlDatabaseAfter = -not $KeepMysqlDatabase
        requiresRedis = $true
        requiresS3 = $true
        requiresElasticsearch = $true
        checks = $requestedChecks
        writesEvidence = $true
        mutatesTestServices = $false
    }
    if ($Json) {
        $plan | ConvertTo-Json -Depth 5
    }
    else {
        Write-Output "Plan: verify a clean source commit with all application, infrastructure, and browser gates."
        Write-Output "MySQL: use an isolated database and $(if ($KeepMysqlDatabase) { 'keep it for debugging' } else { 'drop it after the run' })."
        Write-Output "Evidence: write redacted JSON and Markdown under $OutputDirectory."
    }
    exit 0
}

$environmentNamesToRestore = @(
    "APP_STATE_STORE_PROVIDER",
    "APP_REDIS_HOST",
    "APP_REDIS_PORT",
    "APP_STATE_STORE_KEY_PREFIX"
)
$originalEnvironment = @{}
foreach ($name in $environmentNamesToRestore) {
    $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

try {
    $sourceSha = Get-SourceCommit
    Assert-CleanSource
    if ([string]::IsNullOrWhiteSpace($resolvedVersion)) {
        $resolvedVersion = "candidate-$($sourceSha.Substring(0, 12))"
    }
    if ([string]::IsNullOrWhiteSpace($databaseName)) {
        $databaseName = "dzdp_candidate_$($sourceSha.Substring(0, 8))_$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
    }

    Assert-RequiredEnvironmentValues -Names @(
        "APP_S3_ENDPOINT",
        "APP_S3_BUCKET",
        "APP_S3_ACCESS_KEY",
        "APP_S3_SECRET_KEY"
    )

    $mysqlHost = Get-EnvironmentValue -Name "APP_DB_HOST" -DefaultValue "127.0.0.1"
    $mysqlPort = Get-EnvironmentPort -Name "APP_DB_PORT" -DefaultValue 3306
    $redisHost = Get-EnvironmentValue -Name "APP_REDIS_HOST" -DefaultValue "127.0.0.1"
    $redisPort = Get-EnvironmentPort -Name "APP_REDIS_PORT" -DefaultValue 6379
    $s3 = Get-HttpEndpoint -Name "APP_S3_ENDPOINT" -Value ([Environment]::GetEnvironmentVariable("APP_S3_ENDPOINT", "Process"))
    $elasticsearch = Get-HttpEndpoint -Name "APP_SEARCH_BASE_URL" -Value (Get-EnvironmentValue -Name "APP_SEARCH_BASE_URL" -DefaultValue "http://127.0.0.1:9200")

    Assert-TcpReachable -Name "MySQL" -TargetHost $mysqlHost -Port $mysqlPort
    Assert-TcpReachable -Name "Redis" -TargetHost $redisHost -Port $redisPort
    Assert-TcpReachable -Name "S3" -TargetHost $s3.HostName -Port $s3.Port
    Assert-TcpReachable -Name "Elasticsearch" -TargetHost $elasticsearch.HostName -Port $elasticsearch.Port

    [Environment]::SetEnvironmentVariable("APP_STATE_STORE_PROVIDER", "redis", "Process")
    [Environment]::SetEnvironmentVariable("APP_REDIS_HOST", $redisHost, "Process")
    [Environment]::SetEnvironmentVariable("APP_REDIS_PORT", "$redisPort", "Process")
    [Environment]::SetEnvironmentVariable("APP_STATE_STORE_KEY_PREFIX", "dzdp:candidate:$($sourceSha.Substring(0, 12)):$([Guid]::NewGuid().ToString('N').Substring(0, 8))", "Process")

    $stage = "full-gate"
    $verifyParameters = @{
        IncludeMysqlSmoke = $true
        IncludeStorageSmoke = $true
        IncludeBrowserSmoke = $true
        IncludeBrowserE2E = $true
        IncludeElasticsearchSmoke = $true
        IncludeFlutter = $true
        MysqlSmokeDbName = $databaseName
        DropMysqlSmokeDatabaseAfter = -not $KeepMysqlDatabase
    }
    if ($Json) {
        & $verifyAllPath @verifyParameters | ForEach-Object { Write-Host $_ }
    }
    else {
        & $verifyAllPath @verifyParameters
    }
    if (-not $?) { throw "verify-all.ps1 failed" }
    $ready = $true
}
catch {
    $failure = $_
}
finally {
    foreach ($name in $environmentNamesToRestore) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], "Process")
    }

    $completedAt = [DateTimeOffset]::UtcNow
    $report = [ordered]@{
        schemaVersion = 1
        candidateVersion = $resolvedVersion
        commitSha = $sourceSha
        ready = $ready
        failedStage = if ($ready) { $null } else { $stage }
        startedAtUtc = $startedAt.ToString("O")
        completedAtUtc = $completedAt.ToString("O")
        sourcePolicy = if ($AllowDirtySource) { "development-dirty-allowed" } else { "clean-required" }
        checks = $requestedChecks
        temporaryMysqlDatabase = [ordered]@{
            generated = [string]::IsNullOrWhiteSpace($MysqlDatabaseName)
            cleanupRequested = -not $KeepMysqlDatabase
        }
        services = [ordered]@{
            mysql = $true
            redis = $true
            s3 = $true
            elasticsearch = $true
        }
        mutatedTestServices = $stage -eq "full-gate"
        persistentChangesExpected = [bool]$KeepMysqlDatabase
        limitations = @(
            "This report covers local or CI test services, not target-host deployment readiness.",
            "Passing candidate verification does not replace GitHub Environment, target-host, supplier delivery, backup restore, or rollback evidence."
        )
    }

    $resolvedOutputDirectory = Resolve-OutputDirectory
    New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null
    $safeVersion = if ([string]::IsNullOrWhiteSpace($resolvedVersion)) { "unknown" } else { $resolvedVersion }
    $shaPrefix = if ($sourceSha -and $sourceSha.Length -ge 12) { $sourceSha.Substring(0, 12) } else { "unknown" }
    $timestamp = $completedAt.ToString("yyyyMMddTHHmmssZ")
    $baseName = "candidate-verification-$safeVersion-$shaPrefix-$timestamp"
    $jsonPath = Join-Path $resolvedOutputDirectory "$baseName.json"
    $markdownPath = Join-Path $resolvedOutputDirectory "$baseName.md"
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding utf8

    $lines = @(
        "# Candidate verification report",
        "",
        "- Result: **$(if ($ready) { 'ready' } else { 'blocked' })**",
        "- Candidate: $safeVersion",
        "- Commit: $(if ($sourceSha) { $sourceSha } else { 'unavailable' })",
        "- Failed stage: $(if ($ready) { 'none' } else { $stage })",
        "- Temporary MySQL cleanup requested: $(-not $KeepMysqlDatabase)",
        "- Persistent changes expected: $([bool]$KeepMysqlDatabase)",
        "",
        "## Requested gates",
        ""
    )
    $lines += @($requestedChecks | ForEach-Object { "- $_" })
    $lines += @("", "## Limitations", "")
    $lines += @($report.limitations | ForEach-Object { "- $_" })
    $lines | Set-Content -LiteralPath $markdownPath -Encoding utf8

    if ($Json) {
        $report | ConvertTo-Json -Depth 8
    }
    else {
        Write-Output "candidate verification JSON: $jsonPath"
        Write-Output "candidate verification Markdown: $markdownPath"
        Write-Output "candidate verification result: $(if ($ready) { 'ready' } else { 'blocked' })"
    }
}

if ($null -ne $failure) {
    throw $failure
}
