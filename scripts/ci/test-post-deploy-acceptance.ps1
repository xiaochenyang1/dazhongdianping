$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "post-deploy-acceptance.ps1"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-post-deploy-acceptance-" + [Guid]::NewGuid().ToString("N"))
$remoteRoot = Join-Path $fixtureRoot "remote"
$releaseDir = Join-Path $remoteRoot "releases/release-31"
$binDir = Join-Path $fixtureRoot "bin"
$reportDir = Join-Path $fixtureRoot "reports"
$expectedCommit = "a" * 40
$originalPath = $env:PATH
$originalCommit = $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT
$originalMissingEndpoint = $env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-WebRequest {
    param($Uri, $Headers, [switch]$UseBasicParsing, $MaximumRedirection, $TimeoutSec)
    $uriText = [string]$Uri
    $body = if ($uriText.EndsWith("/actuator/health")) {
        @{ status = "UP" }
    }
    elseif ($uriText.EndsWith("/api/c/v1/release-info")) {
        if ($env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING -eq "true") { throw "HTTP 404" }
        @{ code = 0; data = @{
            version = "release-31"
            commitSha = $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT
            buildEnvironment = "pre"
            buildRegion = "EU"
            migrationVersion = 31
            runtimeMode = "pre"
            builtAtUtc = "2026-11-09T12:00:00Z"
        } }
    }
    elseif ($uriText.EndsWith("/api/c/v1/launch-config")) {
        @{ code = 0; data = @{ region = "EU"; creatorRewards = $false; seckill = $false; groupBuy = $false } }
    }
    else {
        return [pscustomobject]@{ StatusCode = 200; Content = "ok" }
    }
    return [pscustomobject]@{ StatusCode = 200; Content = ($body | ConvertTo-Json -Depth 5 -Compress) }
}

try {
    Assert-True (Test-Path -LiteralPath $scriptPath) "post-deploy acceptance script must exist"
    New-Item -ItemType Directory -Path $releaseDir, $binDir -Force | Out-Null
    $remoteRoot = (Resolve-Path -LiteralPath $remoteRoot).Path
    $releaseDir = (Resolve-Path -LiteralPath $releaseDir).Path
    Set-Content -LiteralPath (Join-Path $releaseDir "release-version.txt") -Value "release-31" -Encoding ascii
    @{
        version = "release-31"
        commitSha = $expectedCommit
        buildEnvironment = "pre"
        webRuntime = @{
            defaultRegion = "EU"
            apiBaseUrl = "https://api.example.test"
            webSocketBaseUrl = "wss://api.example.test"
        }
        databaseMigrations = @{ endVersion = 31 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $releaseDir "release-manifest.json") -Encoding utf8
    New-Item -ItemType SymbolicLink -Path (Join-Path $remoteRoot "current") -Target $releaseDir | Out-Null

    $sshPath = Join-Path $binDir "ssh"
    [IO.File]::WriteAllText($sshPath, "#!/bin/sh`nexec bash -s`n")
    if ([Environment]::OSVersion.Platform -ne "Win32NT") {
        [IO.File]::SetUnixFileMode($sshPath, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
    }
    $env:PATH = "$binDir$([IO.Path]::PathSeparator)$originalPath"
    $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = $expectedCommit

    $output = & $scriptPath `
        -Operation deploy `
        -Environment pre `
        -Region EU `
        -ExpectedVersion release-31 `
        -ExpectedCommitSha $expectedCommit `
        -RemoteHost fixture.invalid `
        -RemoteUser deploy `
        -RemoteRoot $remoteRoot `
        -SmokeUrls "https://eu.example.test/health,https://merchant.example.test/health" `
        -ReportDirectory $reportDir
    Assert-True (($output -join "`n") -match "post-deploy acceptance passed") "valid deployment evidence must pass"

    $jsonPath = Join-Path $reportDir "acceptance-deploy-pre-EU.json"
    $markdownPath = Join-Path $reportDir "acceptance-deploy-pre-EU.md"
    Assert-True (Test-Path -LiteralPath $jsonPath) "acceptance must write JSON evidence"
    Assert-True (Test-Path -LiteralPath $markdownPath) "acceptance must write Markdown evidence"
    $report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    Assert-True ($report.status -eq "passed") "valid evidence report must be passed"
    Assert-True ($report.remoteIdentity.commitSha -eq $expectedCommit) "report must preserve the verified source SHA"
    Assert-True (@($report.checks | Where-Object status -eq "passed").Count -eq 7) "report must record all required checks and smoke URLs"
    Assert-True ((Get-Content -LiteralPath $jsonPath -Raw) -notmatch "PRIVATE|SECRET|TOKEN") "report must not contain credential material"

    $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = "b" * 40
    $message = ""
    try {
        & $scriptPath `
            -Operation deploy `
            -Environment pre `
            -Region EU `
            -ExpectedVersion release-31 `
            -ExpectedCommitSha $expectedCommit `
            -RemoteHost fixture.invalid `
            -RemoteUser deploy `
            -RemoteRoot $remoteRoot `
            -SmokeUrls "https://eu.example.test/health" `
            -ReportDirectory $reportDir | Out-Null
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match "Post-deploy acceptance failed") "runtime identity mismatch must fail acceptance"
    $failedReport = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    Assert-True ($failedReport.status -eq "failed") "identity mismatch must still write failed evidence"
    Assert-True ("runtime-release-identity" -in @($failedReport.checks | Where-Object status -eq "failed" | ForEach-Object name)) "failed report must identify the runtime identity check"

    $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = $expectedCommit
    $env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING = "true"
    $rollbackOutput = & $scriptPath `
        -Operation rollback `
        -Environment pre `
        -Region EU `
        -ExpectedVersion release-31 `
        -RemoteHost fixture.invalid `
        -RemoteUser deploy `
        -RemoteRoot $remoteRoot `
        -SmokeUrls "https://eu.example.test/health" `
        -ReportDirectory $reportDir `
        -AllowMissingRuntimeIdentity
    Assert-True (($rollbackOutput -join "`n") -match "post-deploy acceptance warning") "rollback to an older release may warn when only the identity endpoint is absent"
    $rollbackReport = Get-Content -LiteralPath (Join-Path $reportDir "acceptance-rollback-pre-EU.json") -Raw | ConvertFrom-Json
    Assert-True ($rollbackReport.status -eq "warning") "missing legacy identity endpoint must be recorded as a rollback warning"

    $env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING = "false"
    $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = "b" * 40
    $message = ""
    try {
        & $scriptPath `
            -Operation rollback `
            -Environment pre `
            -Region EU `
            -ExpectedVersion release-31 `
            -RemoteHost fixture.invalid `
            -RemoteUser deploy `
            -RemoteRoot $remoteRoot `
            -SmokeUrls "https://eu.example.test/health" `
            -ReportDirectory $reportDir `
            -AllowMissingRuntimeIdentity | Out-Null
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match "Post-deploy acceptance failed") "rollback must not downgrade an identity mismatch to a warning"

    $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = $expectedCommit
    $message = ""
    try {
        & $scriptPath `
            -Operation deploy `
            -Environment pre `
            -Region EU `
            -ExpectedVersion release-31 `
            -ExpectedCommitSha $expectedCommit `
            -RemoteHost fixture.invalid `
            -RemoteUser deploy `
            -RemoteRoot $remoteRoot `
            -SmokeUrls "https://eu.example.test/health?token=PRIVATE" `
            -ReportDirectory $reportDir | Out-Null
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match "Post-deploy acceptance failed") "smoke URLs with query credentials must fail acceptance"
    $redactedReport = Get-Content -LiteralPath $jsonPath -Raw
    Assert-True ($redactedReport -notmatch "PRIVATE") "failed evidence must not persist rejected URL query values"

    $dryRun = (& $scriptPath -DryRun) -join "`n"
    Assert-True ($dryRun -match "JSON and Markdown") "dry-run must describe acceptance evidence output"
    Write-Output "post-deploy acceptance contract passed"
}
finally {
    $env:PATH = $originalPath
    if ($null -eq $originalCommit) { Remove-Item Env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT -ErrorAction SilentlyContinue }
    else { $env:DZDP_ACCEPTANCE_TEST_RUNTIME_COMMIT = $originalCommit }
    if ($null -eq $originalMissingEndpoint) { Remove-Item Env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING -ErrorAction SilentlyContinue }
    else { $env:DZDP_ACCEPTANCE_TEST_RELEASE_ENDPOINT_MISSING = $originalMissingEndpoint }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
