$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$packageScriptPath = Join-Path $repoRoot "scripts\ci\package-release.ps1"
$deployScriptPath = Join-Path $repoRoot "scripts\ci\deploy-release.ps1"
$rollbackScriptPath = Join-Path $repoRoot "scripts\ci\rollback-release.ps1"
$releaseWorkflowPath = Join-Path $repoRoot ".github\workflows\release.yml"
$rollbackWorkflowPath = Join-Path $repoRoot ".github\workflows\rollback.yml"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $packageScriptPath) "scripts/ci/package-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $deployScriptPath) "scripts/ci/deploy-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $rollbackScriptPath) "scripts/ci/rollback-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $releaseWorkflowPath) ".github/workflows/release.yml must exist"
Assert-True (Test-Path -LiteralPath $rollbackWorkflowPath) ".github/workflows/rollback.yml must exist"

$packageDryRunText = (& $packageScriptPath -DryRun) -join "`n"
$deployDryRunText = (& $deployScriptPath -DryRun) -join "`n"
$rollbackDryRunText = (& $rollbackScriptPath -DryRun) -join "`n"
$releaseWorkflow = Get-Content -LiteralPath $releaseWorkflowPath -Raw
$rollbackWorkflow = Get-Content -LiteralPath $rollbackWorkflowPath -Raw

Assert-True ($packageDryRunText -match "backend.*jar") "package release dry-run must mention backend jar packaging"
Assert-True ($packageDryRunText -match "web.*dist") "package release dry-run must mention web dist packaging"
Assert-True ($packageDryRunText -match "admin-web.*dist") "package release dry-run must mention admin-web dist packaging"
Assert-True ($deployDryRunText -match "SSH") "deploy release dry-run must mention SSH transport"
Assert-True ($deployDryRunText -match "current") "deploy release dry-run must mention switching the current release"
Assert-True ($deployDryRunText -match "smoke") "deploy release dry-run must mention smoke checks"
Assert-True ($rollbackDryRunText -match "previous stable release") "rollback dry-run must mention the previous stable release"
Assert-True ($rollbackDryRunText -match "smoke") "rollback dry-run must mention smoke checks"

Assert-True ($releaseWorkflow -match "workflow_run:") "release workflow must react to workflow_run events"
Assert-True ($releaseWorkflow -match "workflow_dispatch:") "release workflow must support manual dispatch"
Assert-True ($releaseWorkflow -match "deploy-test") "release workflow must define deploy-test"
Assert-True ($releaseWorkflow -match "deploy-pre") "release workflow must define deploy-pre"
Assert-True ($releaseWorkflow -match "deploy-prod") "release workflow must define deploy-prod"
Assert-True ($releaseWorkflow -match "package-release\.ps1") "release workflow must package a release bundle"
Assert-True ($releaseWorkflow -match "deploy-release\.ps1") "release workflow must invoke deploy-release.ps1"
Assert-True ($releaseWorkflow -match "environment:\s*test") "release workflow must use the test environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*pre") "release workflow must use the pre environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*prod") "release workflow must use the prod environment gate"

Assert-True ($rollbackWorkflow -match "workflow_dispatch:") "rollback workflow must be manually dispatched"
Assert-True ($rollbackWorkflow -match "rollback-release\.ps1") "rollback workflow must invoke rollback-release.ps1"
Assert-True ($rollbackWorkflow -match "environment:") "rollback workflow must declare an environment gate"

Write-Output "release automation contract passed"
