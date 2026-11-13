$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\release-source-preflight.ps1"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-release-source-preflight-" + [Guid]::NewGuid().ToString("N"))
$snapshotPath = Join-Path $fixtureRoot "source.json"
$commitSha = "a" * 40
$githubEnvironmentNames = @("GITHUB_REPOSITORY", "GITHUB_SHA", "GITHUB_REF_TYPE", "GITHUB_REF_NAME")
$originalGitHubEnvironment = @{}
foreach ($name in $githubEnvironmentNames) {
    $originalGitHubEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

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

function Write-Snapshot {
    param(
        [string]$RefName = "main",
        [string]$RunConclusion = "success",
        [string]$VerifyConclusion = "success",
        [string]$MigrationConclusion = "success",
        [switch]$MissingMigrationJob,
        [switch]$IncludeNewerFailure
    )

    $runs = @(
        [ordered]@{
            id = 12345
            name = "ci"
            path = ".github/workflows/ci.yml"
            event = "push"
            head_branch = $RefName
            head_sha = $commitSha
            conclusion = $RunConclusion
            created_at = "2026-11-13T00:00:00Z"
            html_url = "https://github.com/owner/repo/actions/runs/12345"
        }
    )
    if ($IncludeNewerFailure) {
        $runs += [ordered]@{
            id = 12346
            name = "ci"
            path = ".github/workflows/ci.yml"
            event = "push"
            head_branch = $RefName
            head_sha = $commitSha
            conclusion = "failure"
            created_at = "2026-11-13T01:00:00Z"
            html_url = "https://github.com/owner/repo/actions/runs/12346"
        }
    }
    $jobs = @([ordered]@{ name = "verify"; conclusion = $VerifyConclusion })
    if (-not $MissingMigrationJob) {
        $jobs += [ordered]@{ name = "database-migration-integration"; conclusion = $MigrationConclusion }
    }
    [ordered]@{
        workflow_runs = $runs
        jobs = $jobs
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $snapshotPath -Encoding utf8
}

try {
    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "release source preflight script must exist"
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null

    $dryRun = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType branch `
        -RefName main `
        -DryRun `
        -Json | ConvertFrom-Json
    Assert-True ($dryRun.mode -eq "DryRun") "dry run must identify its mode"
    Assert-True (-not $dryRun.mutatedExternalState) "source preflight must be read-only"
    Assert-True ($dryRun.requiredJobs.Count -eq 2) "source preflight must require both blocking CI jobs"

    Write-Snapshot
    $ready = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType branch `
        -RefName main `
        -SnapshotPath $snapshotPath `
        -Json | ConvertFrom-Json
    Assert-True $ready.ready "successful main CI must allow the exact source"
    Assert-True ($ready.runId -eq 12345) "ready report must identify the selected CI run"
    Assert-True ($ready.requiredJobs.Count -eq 2) "ready report must include both required jobs"

    $env:GITHUB_REPOSITORY = "owner/repo"
    $env:GITHUB_SHA = $commitSha
    $env:GITHUB_REF_TYPE = "branch"
    $env:GITHUB_REF_NAME = "main"
    $workflowDefaults = & $scriptPath -SnapshotPath $snapshotPath -Json | ConvertFrom-Json
    Assert-True $workflowDefaults.ready "workflow-provided GitHub environment values must drive source verification"

    $tagName = "eu-pre-rc-20261113-2"
    Write-Snapshot -RefName $tagName
    $tagReady = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType tag `
        -RefName $tagName `
        -SnapshotPath $snapshotPath `
        -Json | ConvertFrom-Json
    Assert-True $tagReady.ready "a successful eu-pre-rc tag CI must be releasable"

    Assert-ThrowsLike {
        & $scriptPath -Repository owner/repo -CommitSha $commitSha -RefType branch -RefName feature/unsafe -DryRun
    } "only accept the main branch" "manual releases must reject feature branches"
    Assert-ThrowsLike {
        & $scriptPath -Repository owner/repo -CommitSha $commitSha -RefType tag -RefName v1.0.0 -DryRun
    } "only accept the main branch" "manual releases must reject non-candidate tags"

    Write-Snapshot -RunConclusion failure
    $failedRun = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType branch `
        -RefName main `
        -SnapshotPath $snapshotPath `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True (-not $failedRun.ready -and $failedRun.reason -eq "ci-run-not-successful") "failed CI must block manual release"

    Write-Snapshot -VerifyConclusion failure
    $failedJob = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType branch `
        -RefName main `
        -SnapshotPath $snapshotPath `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True ($failedJob.reason -eq "required-job-not-successful") "a failed required job must block manual release"

    Write-Snapshot -MissingMigrationJob
    Assert-ThrowsLike {
        & $scriptPath `
            -Repository owner/repo `
            -CommitSha $commitSha `
            -RefType branch `
            -RefName main `
            -SnapshotPath $snapshotPath
    } "required-job-not-successful" "a missing required job must fail strict mode"

    Write-Snapshot -IncludeNewerFailure
    $latestRun = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $commitSha `
        -RefType branch `
        -RefName main `
        -SnapshotPath $snapshotPath `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True ($latestRun.runId -eq 12346 -and -not $latestRun.ready) "the latest completed matching CI run must determine readiness"

    Write-Snapshot
    $wrongCommit = "b" * 40
    $missingRun = & $scriptPath `
        -Repository owner/repo `
        -CommitSha $wrongCommit `
        -RefType branch `
        -RefName main `
        -SnapshotPath $snapshotPath `
        -ReportOnly `
        -Json | ConvertFrom-Json
    Assert-True ($missingRun.reason -eq "ci-run-missing") "CI evidence for another SHA must not authorize release"

    Write-Output "release source preflight contract passed"
}
finally {
    foreach ($name in $githubEnvironmentNames) {
        [Environment]::SetEnvironmentVariable($name, $originalGitHubEnvironment[$name], "Process")
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
