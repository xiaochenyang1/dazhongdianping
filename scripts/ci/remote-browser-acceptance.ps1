[CmdletBinding()]
param(
    [string]$WebBaseUrl,
    [string]$AdminBaseUrl,
    [string]$MerchantBaseUrl,
    [string]$BackendBaseUrl,
    [string]$ExpectedCommitSha,
    [string]$TargetEnvironment = "test",
    [string]$Region = "EU",
    [string]$BrowserChannel = "chrome",
    [string]$OutputDirectory = "artifacts/remote-browser-acceptance",
    [string]$NodeExecutable = "node",
    [switch]$AllowRemoteMutations,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$webDirectory = Join-Path $repoRoot "web"
$playwrightCli = Join-Path $webDirectory "node_modules\@playwright\test\cli.js"
$specPath = "e2e/real-backend-flow.spec.ts"
$expectedTests = 13

function Get-ValidatedHttpsOrigin {
    param([string]$Name, [string]$Value)

    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [Uri]::TryCreate($Value.Trim(), [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -cne "https" -or
        [string]::IsNullOrWhiteSpace($uri.Host) -or
        -not [string]::IsNullOrWhiteSpace($uri.UserInfo) -or
        -not [string]::IsNullOrWhiteSpace($uri.Query) -or
        -not [string]::IsNullOrWhiteSpace($uri.Fragment) -or
        $uri.AbsolutePath -cne "/") {
        throw "$Name must be an HTTPS origin without credentials, path, query, or fragment"
    }
    if ($uri.IsLoopback -or $uri.Host -match '(?i)(^|\.)localhost$') {
        throw "$Name must not use a loopback host"
    }
    return $uri.GetLeftPart([UriPartial]::Authority)
}

function Assert-RequiredEnvironmentValues {
    param([string[]]$Names)

    $missing = @($Names | Where-Object {
        [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_, "Process"))
    })
    if ($missing.Count -gt 0) {
        throw "Remote browser acceptance requires environment values: $($missing -join ', ')"
    }
}

function Resolve-OutputDirectory {
    if ([IO.Path]::IsPathRooted($OutputDirectory)) {
        return [IO.Path]::GetFullPath($OutputDirectory)
    }
    return [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
}

function Write-RedactedReports {
    param(
        [string]$Directory,
        [System.Collections.IDictionary]$Values
    )

    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $jsonPath = Join-Path $Directory "remote-browser-acceptance-test-EU.json"
    $markdownPath = Join-Path $Directory "remote-browser-acceptance-test-EU.md"
    $Values | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding utf8

    $result = if ($Values.ready) { "ready" } else { "blocked" }
    @(
        "# Remote browser acceptance",
        "",
        "- Result: **$result**",
        "- Environment/region: $($Values.environment)/$($Values.region)",
        "- Expected commit: $($Values.expectedCommitSha)",
        "- Release identity matched: $($Values.releaseIdentityMatched)",
        "- Remote test mutation authorized: $($Values.mutationAuthorized)",
        "- Remote test execution started: $($Values.mutatedRemoteTest)",
        "- Failed stage: $($Values.failedStage)",
        "",
        "| Expected | Passed | Failed | Skipped | Flaky | Duration (ms) |",
        "| ---: | ---: | ---: | ---: | ---: | ---: |",
        "| $($Values.expectedTests) | $($Values.passed) | $($Values.failed) | $($Values.skipped) | $($Values.flaky) | $($Values.durationMilliseconds) |"
    ) | Set-Content -LiteralPath $markdownPath -Encoding utf8

    return [pscustomobject]@{ Json = $jsonPath; Markdown = $markdownPath }
}

if ($TargetEnvironment -cne "test" -or $Region -cne "EU") {
    throw "Remote browser acceptance is restricted to test/EU"
}
if (-not $AllowRemoteMutations) {
    throw "Remote browser acceptance requires -AllowRemoteMutations"
}
if ($ExpectedCommitSha -cnotmatch '^[0-9a-fA-F]{40}$') {
    throw "ExpectedCommitSha must be a full 40-character Git SHA"
}
if ($BrowserChannel -notmatch '^[A-Za-z0-9._-]+$') {
    throw "BrowserChannel contains unsupported characters"
}

$validatedOrigins = [ordered]@{
    Web = Get-ValidatedHttpsOrigin -Name "WebBaseUrl" -Value $WebBaseUrl
    Admin = Get-ValidatedHttpsOrigin -Name "AdminBaseUrl" -Value $AdminBaseUrl
    Merchant = Get-ValidatedHttpsOrigin -Name "MerchantBaseUrl" -Value $MerchantBaseUrl
    Backend = Get-ValidatedHttpsOrigin -Name "BackendBaseUrl" -Value $BackendBaseUrl
}
$ExpectedCommitSha = $ExpectedCommitSha.ToLowerInvariant()

if ($DryRun) {
    $plan = [ordered]@{
        schemaVersion = 1
        mode = "DryRun"
        environment = "test"
        region = "EU"
        expectedCommitSha = $ExpectedCommitSha
        expectedTests = $expectedTests
        originsValidated = $true
        releaseIdentityRequired = $true
        requiredCredentialNames = @(
            "PLAYWRIGHT_E2E_ADMIN_ACCOUNT",
            "PLAYWRIGHT_E2E_ADMIN_PASSWORD",
            "PLAYWRIGHT_E2E_MERCHANT_ACCOUNT",
            "PLAYWRIGHT_E2E_MERCHANT_PASSWORD"
        )
        mutationAuthorized = $true
        mutatedRemoteTest = $false
        writesRedactedEvidence = $true
    }
    if ($Json) {
        $plan | ConvertTo-Json -Depth 4
    }
    else {
        Write-Output "Plan: verify the test/EU release identity, run all 13 real-backend browser tests, and write redacted evidence."
        Write-Output "Safety: remote mutations are explicitly authorized; pre/prod and loopback or non-HTTPS origins are rejected."
    }
    exit 0
}

$environmentNames = @(
    "PLAYWRIGHT_REAL_BACKEND",
    "PLAYWRIGHT_EXTERNAL_SERVERS",
    "PLAYWRIGHT_REMOTE_ACCEPTANCE",
    "PLAYWRIGHT_EXPECTED_COMMIT_SHA",
    "PLAYWRIGHT_WEB_BASE_URL",
    "PLAYWRIGHT_ADMIN_BASE_URL",
    "PLAYWRIGHT_MERCHANT_BASE_URL",
    "PLAYWRIGHT_BACKEND_BASE_URL",
    "PLAYWRIGHT_CHANNEL",
    "PLAYWRIGHT_OUTPUT_DIR",
    "PLAYWRIGHT_JSON_OUTPUT_NAME"
)
$originalEnvironment = @{}
foreach ($name in $environmentNames) {
    $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

$stage = "release-identity"
$releaseIdentityMatched = $false
$playwrightStarted = $false
$passed = 0
$failed = 0
$skipped = 0
$flaky = 0
$durationMilliseconds = 0
$ready = $false
$failure = $null
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-remote-browser-" + [Guid]::NewGuid().ToString("N"))
$rawJsonPath = Join-Path $temporaryRoot "playwright-results.json"
$playwrightOutput = Join-Path $temporaryRoot "playwright-output"

try {
    $releaseResponse = Invoke-WebRequest `
        -Uri "$($validatedOrigins.Backend)/api/c/v1/release-info" `
        -Headers @{ "X-Region" = "EU" } `
        -UseBasicParsing `
        -MaximumRedirection 0 `
        -TimeoutSec 20
    if ([int]$releaseResponse.StatusCode -ne 200) {
        throw "Release identity endpoint did not return HTTP 200"
    }
    $releasePayload = $releaseResponse.Content | ConvertFrom-Json
    if ([int]$releasePayload.code -ne 0 -or $null -eq $releasePayload.data) {
        throw "Release identity response is invalid"
    }
    if ([string]$releasePayload.data.commitSha -cne $ExpectedCommitSha -or
        [string]$releasePayload.data.buildEnvironment -cne "test" -or
        [string]$releasePayload.data.buildRegion -cne "EU" -or
        [string]$releasePayload.data.runtimeMode -cne "test") {
        throw "Remote release identity does not match test/EU and ExpectedCommitSha"
    }
    $releaseIdentityMatched = $true

    $stage = "credentials"
    Assert-RequiredEnvironmentValues -Names @(
        "PLAYWRIGHT_E2E_ADMIN_ACCOUNT",
        "PLAYWRIGHT_E2E_ADMIN_PASSWORD",
        "PLAYWRIGHT_E2E_MERCHANT_ACCOUNT",
        "PLAYWRIGHT_E2E_MERCHANT_PASSWORD"
    )
    if (-not (Test-Path -LiteralPath $playwrightCli -PathType Leaf)) {
        throw "Playwright is not installed under web/node_modules"
    }
    $nodeCommand = Get-Command $NodeExecutable -CommandType Application -ErrorAction Stop | Select-Object -First 1

    New-Item -ItemType Directory -Path $temporaryRoot, $playwrightOutput -Force | Out-Null
    $playwrightEnvironment = [ordered]@{
        PLAYWRIGHT_REAL_BACKEND = "1"
        PLAYWRIGHT_EXTERNAL_SERVERS = "1"
        PLAYWRIGHT_REMOTE_ACCEPTANCE = "1"
        PLAYWRIGHT_EXPECTED_COMMIT_SHA = $ExpectedCommitSha
        PLAYWRIGHT_WEB_BASE_URL = $validatedOrigins.Web
        PLAYWRIGHT_ADMIN_BASE_URL = $validatedOrigins.Admin
        PLAYWRIGHT_MERCHANT_BASE_URL = $validatedOrigins.Merchant
        PLAYWRIGHT_BACKEND_BASE_URL = $validatedOrigins.Backend
        PLAYWRIGHT_CHANNEL = $BrowserChannel
        PLAYWRIGHT_OUTPUT_DIR = $playwrightOutput
        PLAYWRIGHT_JSON_OUTPUT_NAME = $rawJsonPath
    }
    foreach ($entry in $playwrightEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
    }

    $stage = "playwright"
    $playwrightStarted = $true
    $nativePreferenceExists = Test-Path Variable:PSNativeCommandUseErrorActionPreference
    if ($nativePreferenceExists) { $originalNativePreference = $PSNativeCommandUseErrorActionPreference }
    try {
        if ($nativePreferenceExists) { $PSNativeCommandUseErrorActionPreference = $false }
        Push-Location $webDirectory
        try {
            & $nodeCommand.Source $playwrightCli "test" $specPath "--config=playwright.config.ts" "--project=chromium" "--workers=1" "--reporter=json" *> $null
            $playwrightExitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if ($nativePreferenceExists) { $PSNativeCommandUseErrorActionPreference = $originalNativePreference }
    }

    if (Test-Path -LiteralPath $rawJsonPath -PathType Leaf) {
        $rawResults = Get-Content -LiteralPath $rawJsonPath -Raw | ConvertFrom-Json
        if ($null -eq $rawResults.stats) { throw "Playwright JSON reporter did not include stats" }
        $passed = [int]$rawResults.stats.expected
        $failed = [int]$rawResults.stats.unexpected
        $skipped = [int]$rawResults.stats.skipped
        $flaky = [int]$rawResults.stats.flaky
        $durationMilliseconds = [int][Math]::Round([double]$rawResults.stats.duration)
    }
    if ($playwrightExitCode -ne 0) {
        throw "Playwright acceptance failed"
    }

    $stage = "result-validation"
    if (($passed + $failed + $skipped + $flaky) -ne $expectedTests -or
        $passed -ne $expectedTests -or
        $failed -ne 0 -or
        $skipped -ne 0 -or
        $flaky -ne 0) {
        throw "Playwright acceptance did not produce 13 clean passes"
    }
    $stage = "complete"
    $ready = $true
}
catch {
    $failure = $_
}
finally {
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], "Process")
    }
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTimeOffset]::UtcNow.ToString("O")
    environment = "test"
    region = "EU"
    expectedCommitSha = $ExpectedCommitSha
    releaseIdentityMatched = $releaseIdentityMatched
    expectedTests = $expectedTests
    passed = $passed
    failed = $failed
    skipped = $skipped
    flaky = $flaky
    durationMilliseconds = $durationMilliseconds
    ready = $ready
    blocked = -not $ready
    mutationAuthorized = $true
    mutatedRemoteTest = $playwrightStarted
    failedStage = if ($ready) { $null } else { $stage }
}
$reportPaths = Write-RedactedReports -Directory (Resolve-OutputDirectory) -Values $report

if ($Json) {
    $report | ConvertTo-Json -Depth 4
}
else {
    Write-Output "remote browser acceptance JSON: $($reportPaths.Json)"
    Write-Output "remote browser acceptance Markdown: $($reportPaths.Markdown)"
}
if (-not $ready) {
    throw "Remote browser acceptance blocked at $stage"
}
if (-not $Json) {
    Write-Output "remote browser acceptance ready for test/EU"
}
