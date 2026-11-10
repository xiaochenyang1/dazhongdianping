$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowPath = Join-Path $repoRoot ".github\workflows\readiness.yml"

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) { throw $Message }
}

Assert-True (Test-Path -LiteralPath $workflowPath -PathType Leaf) "readiness workflow must exist"
$workflow = Get-Content -LiteralPath $workflowPath -Raw

foreach ($required in @(
    "workflow_dispatch:",
    "environment:",
    "region:",
    "commit_sha:",
    "actions: read",
    "contents: read",
    "deployments: read",
    "environment: `${{ inputs.environment }}",
    "DEPLOY_RUNTIME_ENV_FILE: `${{ secrets.DEPLOY_RUNTIME_ENV_FILE }}",
    "READINESS_COMMIT_SHA: `${{ inputs.commit_sha }}",
    "Prepare SSH for read-only target audit",
    "github-environment-preflight.ps1",
    "deployment-branch-policies?per_page=100",
    "deployment_branch_policies",
    "readiness-report.ps1",
    "-ReportOnly",
    "Upload readiness evidence",
    "Enforce readiness gate",
    "retention-days: 30"
)) {
    Assert-True ($workflow.Contains($required)) "readiness workflow must contain $required"
}

Assert-True ($workflow -match 'if: always\(\)[\s\S]+Upload readiness evidence') "readiness evidence upload must survive blocked checks"
Assert-True ($workflow.IndexOf("Upload readiness evidence", [StringComparison]::Ordinal) -lt
    $workflow.IndexOf("Enforce readiness gate", [StringComparison]::Ordinal)) "readiness evidence must upload before the final gate fails"
Assert-True ($workflow -notmatch 'deploy-release[.]ps1|rollback-release[.]ps1|package-release[.]ps1') "readiness workflow must not package, deploy, or roll back"
Assert-True ($workflow -notmatch 'DEPLOY_SSH_PRIVATE_KEY.*GITHUB_OUTPUT|DEPLOY_KNOWN_HOSTS.*GITHUB_OUTPUT') "readiness workflow must never write secret bodies to outputs"
foreach ($name in @("DEPLOY_SSH_HOST", "DEPLOY_SSH_USER", "DEPLOY_REMOTE_ROOT", "DEPLOY_RUNTIME_ENV_FILE", "DEPLOY_DB_DEFAULTS_FILE")) {
    Assert-True ($workflow.Contains("$name`: `${{ secrets.$name }}")) "readiness workflow must mask private deployment metadata $name"
    Assert-True (-not $workflow.Contains("$name`: `${{ vars.$name }}")) "readiness workflow must not expose private deployment metadata $name as a variable"
}
Assert-True ($workflow -notmatch '"\$\{\{ inputs[.]commit_sha \}\}"') "shell bodies must consume the commit through an environment variable"

Write-Output "readiness workflow contract passed"
