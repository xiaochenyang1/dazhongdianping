$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\remote-browser-acceptance.ps1"
$realBackendSpecPath = Join-Path $repoRoot "web\e2e\real-backend-flow.spec.ts"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-remote-browser-acceptance-" + [Guid]::NewGuid().ToString("N"))
$binDirectory = Join-Path $fixtureRoot "bin"
$reportDirectory = Join-Path $fixtureRoot "reports"
$expectedCommit = "a" * 40
$credentialNames = @(
    "PLAYWRIGHT_E2E_ADMIN_ACCOUNT",
    "PLAYWRIGHT_E2E_ADMIN_PASSWORD",
    "PLAYWRIGHT_E2E_MERCHANT_ACCOUNT",
    "PLAYWRIGHT_E2E_MERCHANT_PASSWORD"
)
$originalCredentials = @{}
$originalRuntimeCommit = $env:DZDP_REMOTE_BROWSER_TEST_COMMIT

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    try {
        & $Action | Out-Null
    }
    catch {
        if ($_.Exception.Message -match $Pattern) { return }
        throw "$Message. Unexpected error: $($_.Exception.Message)"
    }
    throw $Message
}

function Invoke-WebRequest {
    param($Uri, $Headers, [switch]$UseBasicParsing, $MaximumRedirection, $TimeoutSec)
    $payload = @{
        code = 0
        data = @{
            version = "fixture-release"
            commitSha = $env:DZDP_REMOTE_BROWSER_TEST_COMMIT
            buildEnvironment = "test"
            buildRegion = "EU"
            migrationVersion = 31
            runtimeMode = "test"
            builtAtUtc = "2026-11-13T00:00:00Z"
        }
    }
    return [pscustomobject]@{
        StatusCode = 200
        Content = ($payload | ConvertTo-Json -Depth 5 -Compress)
    }
}

$baseParameters = @{
    WebBaseUrl = "https://web.fixture.test"
    AdminBaseUrl = "https://admin.fixture.test"
    MerchantBaseUrl = "https://merchant.fixture.test"
    BackendBaseUrl = "https://api.fixture.test"
    ExpectedCommitSha = $expectedCommit
    AllowRemoteMutations = $true
}

try {
    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "remote browser acceptance script must exist"
    Assert-True (Test-Path -LiteralPath $realBackendSpecPath -PathType Leaf) "real backend browser spec must exist"
    $scriptSource = Get-Content -LiteralPath $scriptPath -Raw
    $specSource = Get-Content -LiteralPath $realBackendSpecPath -Raw
    Assert-True ($scriptSource -match '"--workers=1"') "remote acceptance must serialize mutable browser tests"
    Assert-True ([regex]::Matches($specSource, '(?m)^\s*test\(').Count -eq 13) "remote acceptance must retain all 13 real backend tests"
    Assert-True ($specSource -match 'getSharedEuUser') "remote acceptance must reuse a synthetic EU user to stay within the default IP rate limit"

    $dryRunRaw = (& $scriptPath @baseParameters -DryRun -Json) -join "`n"
    $dryRun = $dryRunRaw | ConvertFrom-Json
    Assert-True ($dryRun.mode -eq "DryRun") "dry run must identify its mode"
    Assert-True ($dryRun.environment -eq "test" -and $dryRun.region -eq "EU") "remote acceptance must stay fixed to test/EU"
    Assert-True ($dryRun.expectedTests -eq 13) "dry run must declare all 13 browser tests"
    Assert-True $dryRun.originsValidated "dry run must validate every origin"
    Assert-True $dryRun.releaseIdentityRequired "dry run must require release identity matching"
    Assert-True $dryRun.mutationAuthorized "dry run must record explicit mutation authorization"
    Assert-True (-not $dryRun.mutatedRemoteTest) "dry run must not mutate the remote environment"
    Assert-True ($dryRun.requiredCredentialNames.Count -eq 4) "dry run must name the four required credential variables"
    Assert-True ($dryRunRaw -notmatch 'fixture\.test') "dry run JSON must not disclose target origins"

    Assert-ThrowsLike {
        & $scriptPath @baseParameters -AllowRemoteMutations:$false -DryRun
    } "requires -AllowRemoteMutations" "missing mutation authorization must be rejected"
    Assert-ThrowsLike {
        & $scriptPath @baseParameters -WebBaseUrl "http://web.fixture.test" -DryRun
    } "HTTPS origin" "HTTP origins must be rejected"
    Assert-ThrowsLike {
        & $scriptPath @baseParameters -WebBaseUrl "https://127.0.0.1" -DryRun
    } "loopback" "loopback origins must be rejected"
    Assert-ThrowsLike {
        & $scriptPath @baseParameters -BackendBaseUrl "https://api.fixture.test?token=PRIVATE" -DryRun
    } "HTTPS origin" "query-bearing origins must be rejected"
    Assert-ThrowsLike {
        & $scriptPath @baseParameters -TargetEnvironment pre -DryRun
    } "restricted to test/EU" "pre must be rejected"

    New-Item -ItemType Directory -Path $binDirectory -Force | Out-Null
    $runningOnWindows = [Environment]::OSVersion.Platform -eq "Win32NT"
    $nodePath = Join-Path $binDirectory $(if ($runningOnWindows) { "node.cmd" } else { "node" })
    if ($runningOnWindows) {
        [IO.File]::WriteAllText(
            $nodePath,
            "@echo off`r`n> `"%PLAYWRIGHT_JSON_OUTPUT_NAME%`" echo {`"stats`":{`"expected`":13,`"unexpected`":0,`"skipped`":0,`"flaky`":0,`"duration`":1234}}`r`nexit /b 0`r`n"
        )
    }
    else {
        [IO.File]::WriteAllText(
            $nodePath,
            "#!/bin/sh`nprintf '%s' '{`"stats`":{`"expected`":13,`"unexpected`":0,`"skipped`":0,`"flaky`":0,`"duration`":1234}}' > `"`$PLAYWRIGHT_JSON_OUTPUT_NAME`"`nexit 0`n"
        )
        [IO.File]::SetUnixFileMode(
            $nodePath,
            [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute
        )
    }

    $credentialValues = @{
        PLAYWRIGHT_E2E_ADMIN_ACCOUNT = "PRIVATE_ADMIN_ACCOUNT"
        PLAYWRIGHT_E2E_ADMIN_PASSWORD = "PRIVATE_ADMIN_PASSWORD"
        PLAYWRIGHT_E2E_MERCHANT_ACCOUNT = "PRIVATE_MERCHANT_ACCOUNT"
        PLAYWRIGHT_E2E_MERCHANT_PASSWORD = "PRIVATE_MERCHANT_PASSWORD"
    }
    foreach ($name in $credentialNames) {
        $originalCredentials[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
        [Environment]::SetEnvironmentVariable($name, $credentialValues[$name], "Process")
    }
    $env:DZDP_REMOTE_BROWSER_TEST_COMMIT = $expectedCommit

    $resultRaw = (& $scriptPath @baseParameters -NodeExecutable $nodePath -OutputDirectory $reportDirectory -Json) -join "`n"
    $result = $resultRaw | ConvertFrom-Json
    Assert-True $result.ready "13 clean Playwright passes must make remote acceptance ready"
    Assert-True (-not $result.blocked) "ready acceptance must not be blocked"
    Assert-True $result.releaseIdentityMatched "online release identity must match the expected commit"
    Assert-True $result.mutatedRemoteTest "executed acceptance must disclose remote test mutations"
    Assert-True ($result.passed -eq 13 -and $result.failed -eq 0 -and $result.skipped -eq 0 -and $result.flaky -eq 0) "report must retain only aggregate Playwright stats"

    $jsonPath = Join-Path $reportDirectory "remote-browser-acceptance-test-EU.json"
    $markdownPath = Join-Path $reportDirectory "remote-browser-acceptance-test-EU.md"
    Assert-True (Test-Path -LiteralPath $jsonPath -PathType Leaf) "acceptance must write JSON evidence"
    Assert-True (Test-Path -LiteralPath $markdownPath -PathType Leaf) "acceptance must write Markdown evidence"
    $evidence = (Get-Content -LiteralPath $jsonPath -Raw) + (Get-Content -LiteralPath $markdownPath -Raw)
    foreach ($sensitive in @(
        "https://",
        "fixture.test",
        "PRIVATE_ADMIN_ACCOUNT",
        "PRIVATE_ADMIN_PASSWORD",
        "PRIVATE_MERCHANT_ACCOUNT",
        "PRIVATE_MERCHANT_PASSWORD",
        "accessToken",
        "response body",
        "stack"
    )) {
        Assert-True ($evidence -notmatch [regex]::Escape($sensitive)) "redacted evidence must not contain $sensitive"
    }

    $env:DZDP_REMOTE_BROWSER_TEST_COMMIT = "b" * 40
    Assert-ThrowsLike {
        & $scriptPath @baseParameters -NodeExecutable $nodePath -OutputDirectory $reportDirectory -Json
    } "blocked at release-identity" "release identity mismatch must block before Playwright"
    $blocked = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    Assert-True (-not $blocked.ready -and $blocked.blocked) "identity mismatch evidence must be blocked"
    Assert-True (-not $blocked.releaseIdentityMatched) "identity mismatch must be explicit"
    Assert-True (-not $blocked.mutatedRemoteTest) "identity mismatch must block before remote mutations"

    Write-Output "remote browser acceptance contract passed"
}
finally {
    foreach ($name in $credentialNames) {
        if (-not $originalCredentials.ContainsKey($name) -or $null -eq $originalCredentials[$name]) {
            [Environment]::SetEnvironmentVariable($name, $null, "Process")
        }
        else {
            [Environment]::SetEnvironmentVariable($name, $originalCredentials[$name], "Process")
        }
    }
    if ($null -eq $originalRuntimeCommit) { Remove-Item Env:DZDP_REMOTE_BROWSER_TEST_COMMIT -ErrorAction SilentlyContinue }
    else { $env:DZDP_REMOTE_BROWSER_TEST_COMMIT = $originalRuntimeCommit }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
