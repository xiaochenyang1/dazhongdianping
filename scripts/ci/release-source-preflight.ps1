[CmdletBinding()]
param(
    [string]$Repository,
    [string]$CommitSha,
    [ValidateSet("branch", "tag")]
    [string]$RefType,
    [string]$RefName,
    [string]$SnapshotPath,
    [switch]$ReportOnly,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$requiredJobs = @("verify", "database-migration-integration")

function Resolve-RepositoryName {
    param([string]$ExplicitRepository)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepository)) {
        if ($ExplicitRepository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
            throw "Repository must use owner/name syntax"
        }
        return $ExplicitRepository
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_REPOSITORY)) {
        return Resolve-RepositoryName -ExplicitRepository $env:GITHUB_REPOSITORY
    }
    $origin = (& git -C $repoRoot remote get-url origin 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and $origin -match 'github[.]com[:/](?<repository>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+?)(?:[.]git)?$') {
        return $Matches.repository
    }
    throw "Repository must be supplied when Git origin is not a GitHub repository"
}

function Invoke-GhJson {
    param([string[]]$Arguments, [string]$Operation)

    $output = @(& gh @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub operation '$Operation' failed"
    }
    try {
        return ($output -join "`n") | ConvertFrom-Json -Depth 20
    }
    catch {
        throw "GitHub operation '$Operation' returned invalid JSON"
    }
}

function Read-Snapshot {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Release source snapshot file does not exist"
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 20
    }
    catch {
        throw "Release source snapshot is invalid JSON"
    }
}

function Get-SafeGitHubUrl {
    param([AllowNull()][string]$Value)

    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -cne "https" -or
        $uri.Host -cne "github.com" -or
        -not [string]::IsNullOrWhiteSpace($uri.UserInfo) -or
        -not [string]::IsNullOrWhiteSpace($uri.Query) -or
        -not [string]::IsNullOrWhiteSpace($uri.Fragment)) {
        return $null
    }
    return $uri.AbsoluteUri
}

if (-not $CommitSha) {
    $CommitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { (& git -C $repoRoot rev-parse HEAD 2>$null).Trim() }
}
if (-not $RefType) { $RefType = $env:GITHUB_REF_TYPE }
if (-not $RefName) { $RefName = $env:GITHUB_REF_NAME }
$Repository = Resolve-RepositoryName -ExplicitRepository $Repository

if ($CommitSha -cnotmatch '^[0-9a-f]{40}$') {
    throw "CommitSha must be a lowercase full 40-character Git SHA"
}
if ($RefType -eq "branch") {
    if ($RefName -cne "main") {
        throw "Manual releases only accept the main branch or an eu-pre-rc-* tag"
    }
}
elseif ($RefType -eq "tag") {
    if ($RefName -cnotmatch '^eu-pre-rc-[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw "Manual releases only accept the main branch or an eu-pre-rc-* tag"
    }
}
else {
    throw "RefType must be branch or tag"
}

if ($DryRun) {
    $plan = [ordered]@{
        schemaVersion = 1
        mode = "DryRun"
        repository = $Repository
        commitSha = $CommitSha
        refType = $RefType
        refName = $RefName
        requiredWorkflow = "ci"
        requiredJobs = $requiredJobs
        mutatedExternalState = $false
    }
    if ($Json) { $plan | ConvertTo-Json -Depth 5 }
    else { Write-Output "Plan: require a successful ci push run and both required jobs for the exact manual release ref and commit." }
    exit 0
}

$selectedRun = $null
$jobs = @()
$evidenceError = $false
try {
    if ($SnapshotPath) {
        $snapshot = Read-Snapshot -Path $SnapshotPath
        $runs = @($snapshot.workflow_runs)
    }
    else {
        $null = Get-Command gh -CommandType Application -ErrorAction Stop
        $runsResponse = Invoke-GhJson -Arguments @(
            "api", "repos/$Repository/actions/runs?head_sha=$CommitSha&status=completed&per_page=100"
        ) -Operation "list CI runs"
        $runs = @($runsResponse.workflow_runs)
    }

    $matchingRuns = @($runs | Where-Object {
        [string]$_.name -ceq "ci" -and
        [string]$_.path -ceq ".github/workflows/ci.yml" -and
        [string]$_.event -ceq "push" -and
        [string]$_.head_branch -ceq $RefName -and
        [string]$_.head_sha -ceq $CommitSha
    } | Sort-Object created_at -Descending)
    if ($matchingRuns.Count -gt 0) {
        $selectedRun = $matchingRuns[0]
        if ($SnapshotPath) {
            $jobs = @($snapshot.jobs)
        }
        else {
            $jobsResponse = Invoke-GhJson -Arguments @(
                "api", "repos/$Repository/actions/runs/$($selectedRun.id)/jobs?per_page=100"
            ) -Operation "list CI jobs"
            $jobs = @($jobsResponse.jobs)
        }
    }
}
catch {
    $evidenceError = $true
}

$jobReports = @($requiredJobs | ForEach-Object {
    $requiredName = $_
    $matches = @($jobs | Where-Object { [string]$_.name -ceq $requiredName })
    if ($matches.Count -ne 1) {
        [ordered]@{ name = $requiredName; conclusion = if ($matches.Count -eq 0) { "missing" } else { "duplicate" } }
    }
    else {
        [ordered]@{ name = $requiredName; conclusion = [string]$matches[0].conclusion }
    }
})

$reason = if ($evidenceError) {
    "evidence-error"
}
elseif ($null -eq $selectedRun) {
    "ci-run-missing"
}
elseif ([string]$selectedRun.conclusion -cne "success") {
    "ci-run-not-successful"
}
elseif (@($jobReports | Where-Object conclusion -ne "success").Count -gt 0) {
    "required-job-not-successful"
}
else {
    $null
}
$ready = $null -eq $reason
$report = [ordered]@{
    schemaVersion = 1
    repository = $Repository
    commitSha = $CommitSha
    refType = $RefType
    refName = $RefName
    ready = $ready
    blocked = -not $ready
    reason = $reason
    workflow = "ci"
    runId = if ($null -eq $selectedRun) { $null } else { $selectedRun.id }
    runUrl = if ($null -eq $selectedRun) { $null } else { Get-SafeGitHubUrl -Value ([string]$selectedRun.html_url) }
    requiredJobs = $jobReports
    mutatedExternalState = $false
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
}
elseif ($ready) {
    Write-Output "[ready] Exact release source CI and required jobs passed for $RefType $RefName @ $CommitSha."
}
else {
    Write-Output "[blocked] Release source CI verification failed: $reason."
}

if (-not $ready -and -not $ReportOnly) {
    throw "Release source preflight is blocked: $reason"
}
