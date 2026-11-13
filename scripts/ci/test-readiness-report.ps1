$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\readiness-report.ps1"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-readiness-report-" + [Guid]::NewGuid().ToString("N"))
$snapshotRoot = Join-Path $fixtureRoot "snapshots"
$reportRoot = Join-Path $fixtureRoot "reports"
$commitSha = "a" * 40
$ciPath = Join-Path $snapshotRoot "ci.json"
$environmentPath = Join-Path $snapshotRoot "environment.json"
$targetPath = Join-Path $snapshotRoot "target.json"

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

function Write-Snapshots {
    param(
        [string]$CiConclusion = "success",
        [string]$VerifyConclusion = "success",
        [bool]$EnvironmentReady = $true,
        [string[]]$EnvironmentMissingVariables = @(),
        [string[]]$EnvironmentMissingSecrets = @(),
        [object[]]$EnvironmentWarnings = @(),
        [bool]$TargetReady = $true,
        [string]$SnapshotEnvironment = "pre"
    )

    [ordered]@{
        schemaVersion = 1
        commitSha = $commitSha
        workflowName = "ci"
        event = "push"
        headBranch = "main"
        conclusion = $CiConclusion
        runId = 12345
        runUrl = "https://github.com/owner/repo/actions/runs/12345"
        jobs = @(
            @{ name = "verify"; conclusion = $VerifyConclusion; url = "https://github.com/owner/repo/jobs/1" },
            @{ name = "database-migration-integration"; conclusion = "success"; url = "https://github.com/owner/repo/jobs/2" }
        )
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ciPath -Encoding utf8
    [ordered]@{
        Environment = $SnapshotEnvironment
        Ready = $EnvironmentReady
        MissingVariables = $EnvironmentMissingVariables
        MissingSecrets = $EnvironmentMissingSecrets
        InvalidVariables = @()
        MissingProtectionRules = @()
        InvalidProtectionRules = @()
        Warnings = $EnvironmentWarnings
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $environmentPath -Encoding utf8
    [ordered]@{
        Environment = $SnapshotEnvironment
        Region = "EU"
        Ready = $TargetReady
        MutatedTarget = $false
        Passed = if ($TargetReady) { 1 } else { 0 }
        Failed = if ($TargetReady) { 0 } else { 1 }
        Warnings = 0
        Checks = @(
            @{ Name = "mysql-connectivity"; Status = if ($TargetReady) { "PASS" } else { "FAIL" }; Message = "PRIVATE-VALUE must not be copied" }
        )
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $targetPath -Encoding utf8
}

try {
    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "readiness report script must exist"
    New-Item -ItemType Directory -Path $snapshotRoot, $reportRoot -Force | Out-Null
    Write-Snapshots

    $dryRunRaw = (& $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -DryRun `
        -Json) -join "`n"
    $dryRun = $dryRunRaw | ConvertFrom-Json
    Assert-True ($dryRun.Mode -eq "DryRun") "dry run must identify its mode"
    Assert-True (-not $dryRun.MutatesExternalState) "dry run must state that it does not mutate external state"

    $readyRaw = (& $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -Json) -join "`n"
    $ready = $readyRaw | ConvertFrom-Json
    Assert-True $ready.ready "complete evidence must be ready"
    Assert-True $ready.readyForDeployment "complete evidence must be ready for deployment"
    Assert-True (-not $ready.mutatedExternalState) "report generation must not mutate external state"
    Assert-True $ready.sections.automatedTests.ready "successful main CI must pass"
    Assert-True $ready.sections.githubEnvironment.ready "complete hardened environment must pass"
    Assert-True $ready.sections.targetHost.ready "complete target preflight must pass"
    $jsonPath = Join-Path $reportRoot "readiness-pre-EU-$($commitSha.Substring(0, 12)).json"
    $markdownPath = Join-Path $reportRoot "readiness-pre-EU-$($commitSha.Substring(0, 12)).md"
    Assert-True (Test-Path -LiteralPath $jsonPath -PathType Leaf) "readiness must write JSON evidence"
    Assert-True (Test-Path -LiteralPath $markdownPath -PathType Leaf) "readiness must write Markdown evidence"
    Assert-True ((Get-Content -LiteralPath $markdownPath -Raw) -match 'Result: \*\*ready\*\*') "Markdown must state the ready result"
    foreach ($forbidden in @("PRIVATE-VALUE", "SECRET-VALUE", "TOKEN-VALUE", "host.example.test", "/etc/dazhongdianping")) {
        Assert-True ($readyRaw -notmatch $forbidden) "readiness output must remain redacted"
        Assert-True ((Get-Content -LiteralPath $jsonPath -Raw) -notmatch $forbidden) "JSON evidence must remain redacted"
    }

    Write-Snapshots -VerifyConclusion failure
    $failedCiRaw = (& $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -ReportOnly `
        -Json) -join "`n"
    $failedCi = $failedCiRaw | ConvertFrom-Json
    Assert-True (-not $failedCi.ready) "a failed required CI job must block readiness"
    Assert-True (-not $failedCi.sections.automatedTests.ready) "failed CI evidence must identify the automated-test gate"
    Assert-ThrowsLike {
        & $scriptPath `
            -Environment pre `
            -Region EU `
            -Repository owner/repo `
            -CommitSha $commitSha `
            -CiSnapshotPath $ciPath `
            -EnvironmentSnapshotPath $environmentPath `
            -TargetSnapshotPath $targetPath `
            -OutputDirectory $reportRoot
    } "report is blocked" "strict mode must fail blocked readiness"

    Write-Snapshots -EnvironmentWarnings @(@{ Name = "can_admins_bypass"; Message = "must not be copied" })
    $warningReport = & $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True (-not $warningReport.ready) "environment hardening warnings must block full readiness"
    Assert-True ("can_admins_bypass" -in @($warningReport.sections.githubEnvironment.hardeningWarnings)) "report must preserve warning names without warning details"
    Assert-True (($warningReport | ConvertTo-Json -Depth 10) -notmatch 'must not be copied') "report must not copy external warning details"

    Write-Snapshots -EnvironmentReady $false -EnvironmentMissingSecrets @("DEPLOY_SSH_HOST", "DEPLOY_RUNTIME_ENV_FILE")
    $missingSecretReport = & $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True ("DEPLOY_SSH_HOST" -in @($missingSecretReport.sections.githubEnvironment.missingSecrets)) "readiness must preserve the SSH host secret name"
    Assert-True ("DEPLOY_RUNTIME_ENV_FILE" -in @($missingSecretReport.sections.githubEnvironment.missingSecrets)) "readiness must preserve the runtime path secret name"

    Write-Snapshots `
        -SnapshotEnvironment test `
        -EnvironmentReady $false `
        -EnvironmentMissingVariables @("REMOTE_ACCEPTANCE_WEB_BASE_URL", "REMOTE_ACCEPTANCE_BACKEND_BASE_URL") `
        -EnvironmentMissingSecrets @("PLAYWRIGHT_E2E_ADMIN_ACCOUNT", "PLAYWRIGHT_E2E_MERCHANT_PASSWORD")
    $testAcceptanceMissingReport = & $scriptPath `
        -Environment test `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True ("REMOTE_ACCEPTANCE_WEB_BASE_URL" -in @($testAcceptanceMissingReport.sections.githubEnvironment.missingVariables)) "test readiness must preserve remote acceptance variable names"
    Assert-True ("REMOTE_ACCEPTANCE_BACKEND_BASE_URL" -in @($testAcceptanceMissingReport.sections.githubEnvironment.missingVariables)) "test readiness must preserve backend acceptance origin names"
    Assert-True ("PLAYWRIGHT_E2E_ADMIN_ACCOUNT" -in @($testAcceptanceMissingReport.sections.githubEnvironment.missingSecrets)) "test readiness must preserve admin acceptance credential names"
    Assert-True ("PLAYWRIGHT_E2E_MERCHANT_PASSWORD" -in @($testAcceptanceMissingReport.sections.githubEnvironment.missingSecrets)) "test readiness must preserve merchant acceptance credential names"

    Write-Snapshots -TargetReady $false
    $targetBlocked = & $scriptPath `
        -Environment pre `
        -Region EU `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -CiSnapshotPath $ciPath `
        -EnvironmentSnapshotPath $environmentPath `
        -TargetSnapshotPath $targetPath `
        -OutputDirectory $reportRoot `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True (-not $targetBlocked.sections.targetHost.ready) "failed target-host evidence must block readiness"

    Assert-ThrowsLike {
        & $scriptPath `
            -Environment test `
            -Region CN `
            -Repository owner/repo `
            -CommitSha $commitSha `
            -DryRun
    } "fixed to region EU" "test readiness must reject non-EU regions"

    Write-Output "readiness report contract passed"
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
