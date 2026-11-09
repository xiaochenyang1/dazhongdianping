param(
    [ValidateSet("deploy", "rollback")][string]$Operation = "deploy",
    [string]$Environment,
    [string]$Region,
    [string]$ExpectedVersion,
    [string]$ExpectedCommitSha,
    [string]$RemoteHost,
    [int]$RemotePort = 22,
    [string]$RemoteUser,
    [string]$RemoteRoot,
    [string]$SmokeUrls,
    [string]$ReportDirectory,
    [switch]$AllowMissingRuntimeIdentity,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$remotePortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("RemotePort")

if (-not $Environment) { $Environment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "EU" } }
if (-not $ExpectedCommitSha) { $ExpectedCommitSha = $env:DEPLOY_EXPECTED_COMMIT_SHA }
if (-not $RemoteHost) { $RemoteHost = if ($env:DEPLOY_SSH_HOST) { $env:DEPLOY_SSH_HOST } else { "" } }
if (-not $remotePortWasExplicitlySupplied -and $env:DEPLOY_SSH_PORT) { $RemotePort = [int]$env:DEPLOY_SSH_PORT }
if (-not $RemoteUser) { $RemoteUser = if ($env:DEPLOY_SSH_USER) { $env:DEPLOY_SSH_USER } else { "" } }
if (-not $RemoteRoot) { $RemoteRoot = if ($env:DEPLOY_REMOTE_ROOT) { $env:DEPLOY_REMOTE_ROOT } else { "" } }
if (-not $SmokeUrls) { $SmokeUrls = if ($env:DEPLOY_SMOKE_URLS) { $env:DEPLOY_SMOKE_URLS } else { "" } }
if (-not $ReportDirectory) {
    $ReportDirectory = if ($env:DEPLOY_ACCEPTANCE_REPORT_DIR) { $env:DEPLOY_ACCEPTANCE_REPORT_DIR } else { "artifacts/acceptance" }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Resolve the remote current release and read its non-secret release manifest over SSH."
    Write-Output "2. Verify version, commit SHA, environment, region, migration endpoint, HTTPS API URL, and WSS configuration."
    Write-Output "3. Check actuator health, public release identity, launch safety flags, and every configured HTTPS smoke URL."
    Write-Output "4. Write redacted JSON and Markdown evidence under the selected report directory."
    Write-Output "5. Fail deployment acceptance on any required mismatch; rollback may explicitly allow an older release without the identity endpoint."
    exit 0
}

$checks = [Collections.Generic.List[object]]::new()
$remoteIdentity = $null
$runtimeIdentity = $null
$failureMessage = ""

function Add-AcceptanceCheck {
    param([string]$Name, [string]$Status, [string]$Detail)
    $checks.Add([pscustomobject]@{
        name = $Name
        status = $Status
        detail = (($Detail -replace '[\r\n]+', ' ').Trim())
    })
}

function Assert-SafeRemoteRoot {
    param([string]$Value)
    if ($Value -eq "/" -or
        $Value -notmatch '^/[A-Za-z0-9._/-]+$' -or
        $Value -match '(^|/)\.{1,2}(/|$)' -or
        $Value.Contains("//")) {
        throw "RemoteRoot must be a non-root absolute path containing only safe path segments"
    }
}

function Assert-SafeReleaseVersion {
    param([string]$Value)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw "Release version contains unsupported characters: $Value"
    }
}

function Get-ValidatedUrl {
    param(
        [string]$Name,
        [string]$Value,
        [string]$Scheme,
        [switch]$OriginOnly,
        [switch]$NoQueryOrFragment
    )
    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne $Scheme -or [string]::IsNullOrWhiteSpace($uri.Host) -or
        $uri.IsLoopback -or $uri.UserInfo -or $uri.Port -lt 1 -or $uri.Port -gt 65535 -or
        ($NoQueryOrFragment -and ($uri.Query -or $uri.Fragment)) -or
        ($OriginOnly -and ($uri.AbsolutePath -cne "/" -or $uri.Query -or $uri.Fragment))) {
        throw "$Name must be an absolute $Scheme URL without credentials, query, fragment, or a loopback host"
    }
    return $uri
}

function Get-ValidatedSmokeUrls {
    param([string]$Value)
    $urls = @($Value -split "[,\r\n]+" |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($urls.Count -eq 0) { throw "SmokeUrls must contain at least one HTTPS endpoint" }
    foreach ($url in $urls) {
        [void](Get-ValidatedUrl -Name "Smoke URL" -Value $url -Scheme "https" -NoQueryOrFragment)
    }
    return $urls
}

function Invoke-RemoteManifestRead {
    param([string]$SshPath, [string[]]$SshArguments)
    $script = @"
set -euo pipefail
test -L '$RemoteRoot/current' || { echo 'Current release must be a symlink' >&2; exit 1; }
current_release=`$(readlink -f '$RemoteRoot/current')
release_root=`$(readlink -f '$RemoteRoot/releases')
case "`$current_release" in
  "`$release_root"/*) ;;
  *) echo 'Current release points outside the managed releases directory' >&2; exit 1 ;;
esac
test -f "`$current_release/release-version.txt" || { echo 'Current release version marker is missing' >&2; exit 1; }
test -f "`$current_release/release-manifest.json" || { echo 'Current release manifest is missing' >&2; exit 1; }
printf '%s\n' "`$current_release"
cat "`$current_release/release-manifest.json"
"@
    $output = @($script.Replace("`r`n", "`n") | & $SshPath @SshArguments)
    if ($LASTEXITCODE -ne 0) { throw "$SshPath exited with code $LASTEXITCODE while reading the current release manifest" }
    if ($output.Count -lt 2) { throw "Remote current release did not return a manifest" }
    $currentPath = [string]$output[0]
    $manifestText = ($output[1..($output.Count - 1)] -join "`n")
    $manifest = $manifestText | ConvertFrom-Json
    return [pscustomobject]@{ CurrentPath = $currentPath; Manifest = $manifest }
}

function Invoke-JsonGet {
    param([string]$Uri, [hashtable]$Headers = @{})
    $response = Invoke-WebRequest -Uri $Uri -Headers $Headers -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "HTTP $($response.StatusCode)"
    }
    if ([string]::IsNullOrWhiteSpace([string]$response.Content)) { throw "Response body is empty" }
    return ([string]$response.Content | ConvertFrom-Json)
}

function Invoke-SmokeGet {
    param([string]$Uri)
    $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "HTTP $($response.StatusCode)"
    }
    return "HTTP $($response.StatusCode)"
}

function Write-AcceptanceReports {
    param([string]$ErrorMessage)
    New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
    $failed = @($checks | Where-Object { $_.status -eq "failed" }).Count
    $warnings = @($checks | Where-Object { $_.status -eq "warning" }).Count
    $overall = if ($failed -gt 0 -or $ErrorMessage) { "failed" } elseif ($warnings -gt 0) { "warning" } else { "passed" }
    $safeEnvironment = if ($Environment -match '^[a-z]+$') { $Environment } else { "unknown" }
    $safeRegion = if ($Region -in @("CN", "EU")) { $Region } else { "unknown" }
    $baseName = "acceptance-$Operation-$safeEnvironment-$safeRegion"
    $jsonPath = Join-Path $ReportDirectory "$baseName.json"
    $markdownPath = Join-Path $ReportDirectory "$baseName.md"
    $report = [ordered]@{
        schemaVersion = 1
        generatedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
        operation = $Operation
        environment = $Environment
        region = $Region
        status = $overall
        expectedVersion = $ExpectedVersion
        expectedCommitSha = $ExpectedCommitSha
        remoteIdentity = $remoteIdentity
        runtimeIdentity = $runtimeIdentity
        checks = @($checks)
        error = $ErrorMessage
    }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding utf8
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add("# Post-deploy acceptance report")
    $lines.Add("")
    $lines.Add("- Result: **$overall**")
    $lines.Add("- Operation: $Operation")
    $lines.Add("- Environment/region: $Environment/$Region")
    if ($remoteIdentity) {
        $lines.Add("- Remote release: $($remoteIdentity.version)")
        $lines.Add("- Commit: $($remoteIdentity.commitSha)")
        $lines.Add("- Migration: $($remoteIdentity.migrationVersion)")
    }
    $lines.Add("")
    $lines.Add("| Check | Status | Detail |")
    $lines.Add("| --- | --- | --- |")
    foreach ($check in $checks) {
        $detail = ([string]$check.detail).Replace("|", "\|")
        $lines.Add("| $($check.name) | $($check.status) | $detail |")
    }
    if ($ErrorMessage) {
        $lines.Add("")
        $lines.Add("Failure: $($ErrorMessage -replace '[\r\n]+', ' ')")
    }
    $lines | Set-Content -LiteralPath $markdownPath -Encoding utf8
    return [pscustomobject]@{ Json = $jsonPath; Markdown = $markdownPath; Status = $overall }
}

try {
    if ($Environment -notin @("test", "pre", "prod")) { throw "Environment must be test, pre, or prod" }
    if ($Region -notin @("CN", "EU")) { throw "Region must be CN or EU" }
    if ($RemotePort -lt 1 -or $RemotePort -gt 65535) { throw "RemotePort must be between 1 and 65535" }
    foreach ($pair in @{ RemoteHost = $RemoteHost; RemoteUser = $RemoteUser; RemoteRoot = $RemoteRoot }.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace([string]$pair.Value)) { throw "$($pair.Key) must be supplied" }
    }
    Assert-SafeRemoteRoot -Value $RemoteRoot
    $RemoteRoot = $RemoteRoot.TrimEnd("/")
    if ($ExpectedVersion) { Assert-SafeReleaseVersion -Value $ExpectedVersion }
    if ($ExpectedCommitSha -and $ExpectedCommitSha -notmatch '^[0-9a-fA-F]{40}$') {
        throw "ExpectedCommitSha must be a full 40-character Git SHA"
    }
    $validatedSmokeUrls = @(Get-ValidatedSmokeUrls -Value $SmokeUrls)

    $sshPath = (Get-Command ssh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $remoteAddress = "$RemoteUser@$RemoteHost"
    $sshArguments = @('-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', '-p', "$RemotePort", '--', $remoteAddress, 'bash', '-s')
    try {
        $remote = Invoke-RemoteManifestRead -SshPath $sshPath -SshArguments $sshArguments
        $manifest = $remote.Manifest
        $remoteIdentity = [ordered]@{
            version = [string]$manifest.version
            commitSha = [string]$manifest.commitSha
            buildEnvironment = [string]$manifest.buildEnvironment
            buildRegion = [string]$manifest.webRuntime.defaultRegion
            migrationVersion = [int]$manifest.databaseMigrations.endVersion
        }
        if ((Split-Path -Leaf $remote.CurrentPath) -cne $remoteIdentity.version) { throw "Current release path does not match its manifest version" }
        if ($ExpectedVersion -and $remoteIdentity.version -cne $ExpectedVersion) { throw "Remote release version does not match ExpectedVersion" }
        if ($ExpectedCommitSha -and $remoteIdentity.commitSha -cne $ExpectedCommitSha.ToLowerInvariant()) { throw "Remote release commit does not match ExpectedCommitSha" }
        if ($remoteIdentity.commitSha -cnotmatch '^[0-9a-f]{40}$') { throw "Remote release manifest commit SHA is invalid" }
        if ($remoteIdentity.buildEnvironment -cne $Environment) { throw "Remote release environment does not match the target environment" }
        if ($remoteIdentity.buildRegion -cne $Region) { throw "Remote release region does not match the target region" }
        if ($remoteIdentity.migrationVersion -lt 3) { throw "Remote release migration endpoint is invalid" }
        Add-AcceptanceCheck -Name "remote-manifest" -Status "passed" -Detail "current release manifest matches version, commit, environment, region, and migration metadata"
    }
    catch {
        Add-AcceptanceCheck -Name "remote-manifest" -Status "failed" -Detail $_.Exception.Message
        throw
    }

    $apiUri = Get-ValidatedUrl -Name "webRuntime.apiBaseUrl" -Value ([string]$manifest.webRuntime.apiBaseUrl) -Scheme "https" -NoQueryOrFragment
    $wssUri = Get-ValidatedUrl -Name "webRuntime.webSocketBaseUrl" -Value ([string]$manifest.webRuntime.webSocketBaseUrl) -Scheme "wss" -OriginOnly
    Add-AcceptanceCheck -Name "https-wss-configuration" -Status "passed" -Detail "HTTPS API and credential-free WSS endpoints are configured for $($apiUri.Host) / $($wssUri.Host)"
    $apiBaseUrl = $apiUri.AbsoluteUri.TrimEnd("/")

    try {
        $health = Invoke-JsonGet -Uri "$apiBaseUrl/actuator/health"
        if ([string]$health.status -cne "UP") { throw "Actuator status is not UP" }
        Add-AcceptanceCheck -Name "actuator-health" -Status "passed" -Detail "public backend health is UP"
    }
    catch {
        Add-AcceptanceCheck -Name "actuator-health" -Status "failed" -Detail $_.Exception.Message
        throw
    }

    $releaseResponse = $null
    try {
        $releaseResponse = Invoke-JsonGet -Uri "$apiBaseUrl/api/c/v1/release-info" -Headers @{ "X-Region" = $Region }
    }
    catch {
        if ($Operation -eq "rollback" -and $AllowMissingRuntimeIdentity) {
            Add-AcceptanceCheck -Name "runtime-release-identity" -Status "warning" -Detail "rollback target does not expose the release identity endpoint: $($_.Exception.Message)"
        }
        else {
            Add-AcceptanceCheck -Name "runtime-release-identity" -Status "failed" -Detail $_.Exception.Message
            throw
        }
    }
    if ($null -ne $releaseResponse) {
        try {
            if ([int]$releaseResponse.code -ne 0 -or $null -eq $releaseResponse.data) { throw "Release identity response is invalid" }
        $runtimeIdentity = $releaseResponse.data
        if ([string]$runtimeIdentity.version -cne $remoteIdentity.version -or
            [string]$runtimeIdentity.commitSha -cne $remoteIdentity.commitSha -or
            [string]$runtimeIdentity.buildEnvironment -cne $Environment -or
            [string]$runtimeIdentity.buildRegion -cne $Region -or
            [int]$runtimeIdentity.migrationVersion -ne [int]$remoteIdentity.migrationVersion -or
            [string]$runtimeIdentity.runtimeMode -cne $Environment) {
            throw "Runtime release identity does not match the active manifest and target environment"
        }
        Add-AcceptanceCheck -Name "runtime-release-identity" -Status "passed" -Detail "online backend version and commit match the active release manifest"
        }
        catch {
            Add-AcceptanceCheck -Name "runtime-release-identity" -Status "failed" -Detail $_.Exception.Message
            throw
        }
    }

    try {
        $launch = Invoke-JsonGet -Uri "$apiBaseUrl/api/c/v1/launch-config" -Headers @{ "X-Region" = $Region }
        if ([int]$launch.code -ne 0 -or [string]$launch.data.region -cne $Region) { throw "Launch configuration region is invalid" }
        if ([bool]$launch.data.creatorRewards -or [bool]$launch.data.seckill -or [bool]$launch.data.groupBuy) {
            throw "Deferred launch capabilities must remain disabled during base pre-release acceptance"
        }
        Add-AcceptanceCheck -Name "launch-safety" -Status "passed" -Detail "creator rewards, seckill, and group-buy remain disabled in $Region"
    }
    catch {
        Add-AcceptanceCheck -Name "launch-safety" -Status "failed" -Detail $_.Exception.Message
        throw
    }

    foreach ($url in $validatedSmokeUrls) {
        try {
            $detail = Invoke-SmokeGet -Uri $url
            Add-AcceptanceCheck -Name "https-smoke" -Status "passed" -Detail "$detail from $url"
        }
        catch {
            Add-AcceptanceCheck -Name "https-smoke" -Status "failed" -Detail "${url}: $($_.Exception.Message)"
            throw
        }
    }
}
catch {
    $failureMessage = $_.Exception.Message
}

$reportResult = Write-AcceptanceReports -ErrorMessage $failureMessage
Write-Output "acceptance JSON: $($reportResult.Json)"
Write-Output "acceptance Markdown: $($reportResult.Markdown)"
if ($reportResult.Status -eq "failed") { throw "Post-deploy acceptance failed: $failureMessage" }
Write-Output "post-deploy acceptance $($reportResult.Status) for $Environment/$Region"
