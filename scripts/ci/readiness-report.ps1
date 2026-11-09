[CmdletBinding()]
param(
    [Alias("Environment")]
    [ValidateSet("test", "pre", "prod")]
    [string]$TargetEnvironment,
    [ValidateSet("CN", "EU")]
    [string]$Region,
    [string]$Repository,
    [string]$CommitSha,
    [string]$CiSnapshotPath,
    [string]$EnvironmentSnapshotPath,
    [string]$TargetSnapshotPath,
    [string]$OutputDirectory = "artifacts/readiness",
    [switch]$ReportOnly,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$environmentPreflightPath = Join-Path $PSScriptRoot "github-environment-preflight.ps1"
$targetPreflightPath = Join-Path $PSScriptRoot "target-host-preflight.ps1"
$requiredCiJobs = @("verify", "database-migration-integration")
$allowedEnvironmentVariableNames = @(
    "DEPLOY_SSH_HOST", "DEPLOY_SSH_PORT", "DEPLOY_SSH_USER", "DEPLOY_REMOTE_ROOT",
    "DEPLOY_BACKEND_SERVICE", "DEPLOY_WEB_SERVICE", "DEPLOY_ADMIN_SERVICE", "DEPLOY_MERCHANT_SERVICE",
    "DEPLOY_SMOKE_URLS", "DEPLOY_RUNTIME_ENV_FILE", "DEPLOY_DB_DEFAULTS_FILE",
    "DEPLOY_DB_MIGRATION_MODE", "DEPLOY_DB_BASELINE_VERSION", "DEPLOY_RELEASE_RETENTION_COUNT",
    "VITE_API_BASE_URL", "VITE_WS_BASE_URL", "VITE_STRIPE_PUBLISHABLE_KEY",
    "PUBLIC_SITE_URL", "PRERENDER_API_BASE_URL", "PRERENDER_REGIONS",
    "PUBLIC_SITE_URL_CN", "PRERENDER_API_BASE_URL_CN", "PUBLIC_SITE_URL_EU", "PRERENDER_API_BASE_URL_EU"
)
$allowedEnvironmentSecretNames = @(
    "DEPLOY_SSH_HOST", "DEPLOY_SSH_USER", "DEPLOY_REMOTE_ROOT", "DEPLOY_RUNTIME_ENV_FILE",
    "DEPLOY_DB_DEFAULTS_FILE", "DEPLOY_KNOWN_HOSTS", "DEPLOY_SSH_PRIVATE_KEY"
)
$allowedTargetCheckNames = @(
    "input", "operating-system", "deployment-tools", "java-runtime", "release-root", "release-layout",
    "disk-space", "runtime-env-file", "runtime-env-permissions", "database-defaults-file",
    "database-defaults-permissions", "runtime-config", "mysql-connectivity", "systemd-services",
    "sudo-policy", "redis-connectivity", "elasticsearch-connectivity", "s3-connectivity",
    "smtp-connectivity", "twilio-connectivity", "stripe-connectivity"
)

if (-not $TargetEnvironment) { $TargetEnvironment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "EU" } }
if (-not $CommitSha) {
    $CommitSha = (& git -C $repoRoot rev-parse HEAD 2>$null).Trim()
}

function Resolve-RepositoryName {
    param([string]$ExplicitRepository)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepository)) {
        if ($ExplicitRepository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
            throw "Repository must use owner/name syntax"
        }
        return $ExplicitRepository
    }
    $origin = (& git -C $repoRoot remote get-url origin 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and $origin -match 'github[.]com[:/](?<repository>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+?)(?:[.]git)?$') {
        return $Matches.repository
    }
    throw "Repository must be supplied when Git origin is not a GitHub repository"
}

function Read-JsonSnapshot {
    param([string]$Path, [string]$Name)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Name snapshot file does not exist"
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 20
    }
    catch {
        throw "$Name snapshot is invalid JSON"
    }
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

function Get-AllowedNames {
    param([object[]]$Values, [string[]]$Allowed, [string]$UnknownName)

    return @($Values | ForEach-Object {
        $name = [string]$_
        if ($name -in $Allowed) { $name } else { $UnknownName }
    } | Sort-Object -Unique)
}

function Get-LiveCiSnapshot {
    $null = Get-Command gh -CommandType Application -ErrorAction Stop
    $runs = Invoke-GhJson -Arguments @(
        "api", "repos/$Repository/actions/runs?head_sha=$CommitSha&status=completed&per_page=100"
    ) -Operation "list CI runs"
    $run = @($runs.workflow_runs | Where-Object {
        [string]$_.name -ceq "ci" -and
        [string]$_.event -ceq "push" -and
        [string]$_.head_branch -ceq "main" -and
        [string]$_.head_sha -ceq $CommitSha
    } | Sort-Object created_at -Descending | Select-Object -First 1)
    if ($run.Count -eq 0) {
        return [pscustomobject]@{
            schemaVersion = 1
            commitSha = $CommitSha
            workflowName = "ci"
            event = ""
            headBranch = ""
            conclusion = "missing"
            runId = $null
            runUrl = $null
            jobs = @()
        }
    }
    $selectedRun = $run[0]
    $jobsResponse = Invoke-GhJson -Arguments @(
        "api", "repos/$Repository/actions/runs/$($selectedRun.id)/jobs?per_page=100"
    ) -Operation "list CI jobs"
    return [pscustomobject]@{
        schemaVersion = 1
        commitSha = [string]$selectedRun.head_sha
        workflowName = [string]$selectedRun.name
        event = [string]$selectedRun.event
        headBranch = [string]$selectedRun.head_branch
        conclusion = [string]$selectedRun.conclusion
        runId = [long]$selectedRun.id
        runUrl = [string]$selectedRun.html_url
        jobs = @($jobsResponse.jobs | ForEach-Object {
            [pscustomobject]@{
                name = [string]$_.name
                conclusion = [string]$_.conclusion
                url = [string]$_.html_url
            }
        })
    }
}

function Get-LiveEnvironmentSnapshot {
    $raw = (& $environmentPreflightPath `
        -Environment $TargetEnvironment `
        -Repository $Repository `
        -ReportOnly `
        -Json) -join "`n"
    return $raw | ConvertFrom-Json -Depth 20
}

function Get-LiveTargetSnapshot {
    $raw = (& $targetPreflightPath `
        -Environment $TargetEnvironment `
        -Region $Region `
        -ReportOnly `
        -Json) -join "`n"
    return $raw | ConvertFrom-Json -Depth 20
}

if ($TargetEnvironment -notin @("test", "pre", "prod")) {
    throw "TargetEnvironment must be test, pre, or prod"
}
if ($Region -notin @("CN", "EU")) {
    throw "Region must be CN or EU"
}
if ($TargetEnvironment -eq "test" -and $Region -ne "EU") {
    throw "The test environment is fixed to region EU"
}
if ($CommitSha -cnotmatch '^[0-9a-f]{40}$') {
    throw "CommitSha must be a lowercase full 40-character Git SHA"
}
$Repository = Resolve-RepositoryName -ExplicitRepository $Repository

if ($DryRun) {
    $dryRunReport = [pscustomobject]@{
        SchemaVersion = 1
        Mode = "DryRun"
        Environment = $TargetEnvironment
        Region = $Region
        CommitSha = $CommitSha
        MutatesExternalState = $false
        Evidence = @("main CI jobs", "GitHub Environment audit", "target-host preflight")
        Outputs = @("redacted JSON", "Markdown")
    }
    if ($Json) { $dryRunReport | ConvertTo-Json -Depth 5 }
    else {
        Write-Output "Readiness report DryRun: $TargetEnvironment/$Region @ $CommitSha"
        Write-Output "[plan only] Read CI and environment state, run the read-only target preflight, and write redacted JSON/Markdown evidence."
    }
    exit 0
}

$sectionErrors = [Collections.Generic.List[string]]::new()
try {
    $ciSnapshot = if ($CiSnapshotPath) {
        Read-JsonSnapshot -Path $CiSnapshotPath -Name "CI"
    }
    else {
        Get-LiveCiSnapshot
    }
}
catch {
    $sectionErrors.Add("automated-tests")
    $ciSnapshot = [pscustomobject]@{
        commitSha = $CommitSha
        workflowName = "ci"
        event = ""
        headBranch = ""
        conclusion = "error"
        runId = $null
        runUrl = $null
        jobs = @()
    }
}

try {
    $environmentSnapshot = if ($EnvironmentSnapshotPath) {
        Read-JsonSnapshot -Path $EnvironmentSnapshotPath -Name "Environment"
    }
    else {
        Get-LiveEnvironmentSnapshot
    }
}
catch {
    $sectionErrors.Add("github-environment")
    $environmentSnapshot = [pscustomobject]@{
        Environment = $TargetEnvironment
        Ready = $false
        MissingVariables = @()
        MissingSecrets = @()
        InvalidVariables = @()
        MissingProtectionRules = @()
        InvalidProtectionRules = @()
        Warnings = @()
    }
}

try {
    $targetSnapshot = if ($TargetSnapshotPath) {
        Read-JsonSnapshot -Path $TargetSnapshotPath -Name "Target"
    }
    else {
        Get-LiveTargetSnapshot
    }
}
catch {
    $sectionErrors.Add("target-host")
    $targetSnapshot = [pscustomobject]@{
        Environment = $TargetEnvironment
        Region = $Region
        Ready = $false
        MutatedTarget = $false
        Passed = 0
        Failed = 1
        Warnings = 0
        Checks = @()
    }
}

$ciJobs = @($ciSnapshot.jobs)
$ciJobReports = @($requiredCiJobs | ForEach-Object {
    $requiredName = $_
    $job = @($ciJobs | Where-Object { [string]$_.name -ceq $requiredName } | Select-Object -First 1)
    if ($job.Count -eq 0) {
        [pscustomobject]@{ Name = $requiredName; Conclusion = "missing"; Url = $null }
    }
    else {
        [pscustomobject]@{
            Name = $requiredName
            Conclusion = [string]$job[0].conclusion
            Url = Get-SafeGitHubUrl -Value ([string]$job[0].url)
        }
    }
})
$ciReady = [string]$ciSnapshot.commitSha -ceq $CommitSha -and
    [string]$ciSnapshot.workflowName -ceq "ci" -and
    [string]$ciSnapshot.event -ceq "push" -and
    [string]$ciSnapshot.headBranch -ceq "main" -and
    [string]$ciSnapshot.conclusion -ceq "success" -and
    @($ciJobReports | Where-Object Conclusion -ne "success").Count -eq 0 -and
    "automated-tests" -notin $sectionErrors

$missingVariables = Get-AllowedNames -Values @($environmentSnapshot.MissingVariables) -Allowed $allowedEnvironmentVariableNames -UnknownName "unknown-variable"
$missingSecrets = Get-AllowedNames -Values @($environmentSnapshot.MissingSecrets) -Allowed $allowedEnvironmentSecretNames -UnknownName "unknown-secret"
$invalidVariables = Get-AllowedNames -Values @($environmentSnapshot.InvalidVariables | ForEach-Object { [string]$_.Name }) -Allowed $allowedEnvironmentVariableNames -UnknownName "unknown-variable"
$missingProtectionRules = Get-AllowedNames -Values @($environmentSnapshot.MissingProtectionRules) -Allowed @("required_reviewers") -UnknownName "unknown-protection"
$invalidProtectionRules = Get-AllowedNames -Values @($environmentSnapshot.InvalidProtectionRules | ForEach-Object { [string]$_.Name }) -Allowed @("required_reviewers") -UnknownName "unknown-protection"
$allowedEnvironmentWarnings = @("can_admins_bypass", "deployment_branch_policy", "prevent_self_review")
$environmentWarnings = @($environmentSnapshot.Warnings | ForEach-Object {
    $name = [string]$_.Name
    if ($name -in $allowedEnvironmentWarnings) { $name } else { "unknown-warning" }
} | Sort-Object -Unique)
$environmentConfigurationReady = [bool]$environmentSnapshot.Ready -and
    $missingVariables.Count -eq 0 -and
    $missingSecrets.Count -eq 0 -and
    $invalidVariables.Count -eq 0 -and
    $missingProtectionRules.Count -eq 0 -and
    $invalidProtectionRules.Count -eq 0
$environmentReady = [string]$environmentSnapshot.Environment -ceq $TargetEnvironment -and
    $environmentConfigurationReady -and
    $environmentWarnings.Count -eq 0 -and
    "github-environment" -notin $sectionErrors
$targetMutationProperty = $targetSnapshot.PSObject.Properties["MutatedTarget"]
$targetCheckReports = @($targetSnapshot.Checks | ForEach-Object {
    $name = [string]$_.Name
    $status = ([string]$_.Status).ToUpperInvariant()
    [pscustomobject]@{
        name = if ($name -in $allowedTargetCheckNames) { $name } else { "unknown-check" }
        status = if ($status -in @("PASS", "FAIL", "WARN")) { $status } else { "UNKNOWN" }
    }
})
$targetCountsConsistent = ([int]$targetSnapshot.Passed + [int]$targetSnapshot.Failed + [int]$targetSnapshot.Warnings) -eq $targetCheckReports.Count
$targetReady = [string]$targetSnapshot.Environment -ceq $TargetEnvironment -and
    [string]$targetSnapshot.Region -ceq $Region -and
    $null -ne $targetMutationProperty -and
    [bool]$targetSnapshot.Ready -and
    -not [bool]$targetSnapshot.MutatedTarget -and
    [int]$targetSnapshot.Failed -eq 0 -and
    $targetCountsConsistent -and
    @($targetCheckReports | Where-Object status -in @("FAIL", "UNKNOWN")).Count -eq 0 -and
    "target-host" -notin $sectionErrors
$overallReady = $ciReady -and $environmentReady -and $targetReady

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
    repository = $Repository
    environment = $TargetEnvironment
    region = $Region
    commitSha = $CommitSha
    ready = $overallReady
    readyForDeployment = $overallReady
    mutatedExternalState = $false
    sections = [ordered]@{
        automatedTests = [ordered]@{
            ready = $ciReady
            workflow = "ci"
            event = [string]$ciSnapshot.event
            branch = [string]$ciSnapshot.headBranch
            conclusion = [string]$ciSnapshot.conclusion
            runId = $ciSnapshot.runId
            runUrl = Get-SafeGitHubUrl -Value ([string]$ciSnapshot.runUrl)
            requiredJobs = $ciJobReports
            error = if ("automated-tests" -in $sectionErrors) { "CI evidence could not be collected" } else { $null }
        }
        githubEnvironment = [ordered]@{
            ready = $environmentReady
            configurationReady = $environmentConfigurationReady
            missingVariables = $missingVariables
            missingSecrets = $missingSecrets
            invalidVariables = $invalidVariables
            missingProtectionRules = $missingProtectionRules
            invalidProtectionRules = $invalidProtectionRules
            hardeningWarnings = $environmentWarnings
            error = if ("github-environment" -in $sectionErrors) { "GitHub Environment evidence could not be collected" } else { $null }
        }
        targetHost = [ordered]@{
            ready = $targetReady
            mutatedTarget = [bool]$targetSnapshot.MutatedTarget
            passed = [int]$targetSnapshot.Passed
            failed = [int]$targetSnapshot.Failed
            warnings = [int]$targetSnapshot.Warnings
            checks = $targetCheckReports
            error = if ("target-host" -in $sectionErrors) { "Target-host evidence could not be collected" } else { $null }
        }
    }
    limitations = @(
        "This report does not deploy or mutate GitHub or target-host state.",
        "Network reachability does not replace credentialed S3, Elasticsearch, SMTP, Twilio, or Stripe smoke tests.",
        "A ready report does not replace post-deploy acceptance, backup restore, or rollback evidence."
    )
}

$resolvedOutputDirectory = if ([IO.Path]::IsPathRooted($OutputDirectory)) {
    [IO.Path]::GetFullPath($OutputDirectory)
}
else {
    [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
}
New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null
$baseName = "readiness-$TargetEnvironment-$Region-$($CommitSha.Substring(0, 12))"
$jsonPath = Join-Path $resolvedOutputDirectory "$baseName.json"
$markdownPath = Join-Path $resolvedOutputDirectory "$baseName.md"
$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding utf8

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Deployment readiness report")
$lines.Add("")
$lines.Add("- Result: **$(if ($overallReady) { 'ready' } else { 'blocked' })**")
$lines.Add("- Environment/region: $TargetEnvironment/$Region")
$lines.Add("- Commit: $CommitSha")
$lines.Add("- External state changed: no")
$lines.Add("")
$lines.Add("| Gate | Ready | Detail |")
$lines.Add("| --- | --- | --- |")
$lines.Add("| Automated tests | $ciReady | CI conclusion: $([string]$ciSnapshot.conclusion) |")
$lines.Add("| GitHub Environment | $environmentReady | Missing variables: $($missingVariables.Count); missing secrets: $($missingSecrets.Count); hardening warnings: $($environmentWarnings.Count) |")
$lines.Add("| Target host | $targetReady | Passed: $([int]$targetSnapshot.Passed); failed: $([int]$targetSnapshot.Failed); warnings: $([int]$targetSnapshot.Warnings) |")
$lines.Add("")
$lines.Add("## Required CI jobs")
$lines.Add("")
foreach ($job in $ciJobReports) {
    $lines.Add("- $($job.Name): $($job.Conclusion)")
}
$lines.Add("")
$lines.Add("## Limitations")
$lines.Add("")
foreach ($limitation in $report.limitations) { $lines.Add("- $limitation") }
$lines | Set-Content -LiteralPath $markdownPath -Encoding utf8

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    Write-Output "readiness JSON: $jsonPath"
    Write-Output "readiness Markdown: $markdownPath"
    if ($overallReady) {
        Write-Output "[ready] CI, GitHub Environment, and target-host gates passed for $CommitSha."
    }
    else {
        Write-Output "[blocked] CI ready: $ciReady; GitHub Environment ready: $environmentReady; target host ready: $targetReady."
    }
}

if (-not $overallReady -and -not $ReportOnly) {
    throw "Deployment readiness report is blocked"
}
