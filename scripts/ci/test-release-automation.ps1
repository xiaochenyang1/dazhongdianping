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

function Assert-ThrowsLike {
    param(
        [scriptblock]$Action,
        [string]$Pattern,
        [string]$Message
    )

    try {
        & $Action | Out-Null
    }
    catch {
        if ($_.Exception.Message -match $Pattern) {
            return
        }
        throw "$Message. Unexpected error: $($_.Exception.Message)"
    }
    throw $Message
}

Assert-True (Test-Path -LiteralPath $packageScriptPath) "scripts/ci/package-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $deployScriptPath) "scripts/ci/deploy-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $rollbackScriptPath) "scripts/ci/rollback-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $releaseWorkflowPath) ".github/workflows/release.yml must exist"
Assert-True (Test-Path -LiteralPath $rollbackWorkflowPath) ".github/workflows/rollback.yml must exist"

$packageDryRunText = (& $packageScriptPath -DryRun) -join "`n"
$deployDryRunText = (& $deployScriptPath -DryRun) -join "`n"
$rollbackDryRunText = (& $rollbackScriptPath -DryRun) -join "`n"
$packageScript = Get-Content -LiteralPath $packageScriptPath -Raw
$deployScript = Get-Content -LiteralPath $deployScriptPath -Raw
$rollbackScript = Get-Content -LiteralPath $rollbackScriptPath -Raw
$releaseWorkflow = Get-Content -LiteralPath $releaseWorkflowPath -Raw
$rollbackWorkflow = Get-Content -LiteralPath $rollbackWorkflowPath -Raw

Assert-ThrowsLike {
    & $deployScriptPath `
        -ReleaseBundle "missing.zip" `
        -Environment "test" `
        -RemoteHost "deploy.example.com" `
        -RemoteUser "deploy" `
        -RemoteRoot "/srv/../root"
} "RemoteRoot must be" "deploy release must reject unsafe remote paths before connecting"
Assert-ThrowsLike {
    & $rollbackScriptPath `
        -Environment "test" `
        -RemoteHost "deploy.example.com" `
        -RemoteUser "deploy" `
        -RemoteRoot "/srv/dazhongdianping" `
        -TargetVersion "v1'; touch injected; '"
} "Release version contains unsupported characters" "rollback release must reject unsafe target versions before connecting"

Assert-True ($packageDryRunText -match "backend.*jar") "package release dry-run must mention backend jar packaging"
Assert-True ($packageDryRunText -match "web.*dist") "package release dry-run must mention web dist packaging"
Assert-True ($packageDryRunText -match "admin-web.*dist") "package release dry-run must mention admin-web dist packaging"
Assert-True ($packageDryRunText -match "merchant-web.*dist") "package release dry-run must mention merchant-web dist packaging"
Assert-True ($packageDryRunText -match "PUBLIC_SITE_URL.*PRERENDER_API_BASE_URL") "package release dry-run must describe conditional real SEO snapshot packaging"
Assert-True ($packageDryRunText -match "SHA-256 checksum") "package release dry-run must mention checksum generation"
Assert-True ($deployDryRunText -match "SSH") "deploy release dry-run must mention SSH transport"
Assert-True ($deployDryRunText -match "SHA-256 integrity before extracting") "deploy release dry-run must describe integrity verification before extraction"
Assert-True ($deployDryRunText -match "current") "deploy release dry-run must mention switching the current release"
Assert-True ($deployDryRunText -match "smoke") "deploy release dry-run must mention smoke checks"
Assert-True ($deployDryRunText -match "merchant-web") "deploy release dry-run must mention the merchant-web service"
Assert-True ($rollbackDryRunText -match "previous stable release") "rollback dry-run must mention the previous stable release"
Assert-True ($rollbackDryRunText -match "smoke") "rollback dry-run must mention smoke checks"
Assert-True ($rollbackDryRunText -match "merchant-web") "rollback dry-run must mention the merchant-web service"
Assert-True ($packageScript -match 'ForEach-Object \{ Write-Host \$_ \}') "package release must keep native build logs out of its returned bundle path"
Assert-True ($packageScript -match 'merchant-web') "package release must build and package merchant-web"
Assert-True ($packageScript -match 'Get-FileHash\s+-Algorithm\s+SHA256') "package release must calculate the bundle SHA-256"
Assert-True ($packageScript -match '\.sha256') "package release must emit a .sha256 checksum file"
Assert-True ($deployScript -match 'DEPLOY_SSH_PORT') "deploy release must accept the configured SSH port"
Assert-True ($deployScript -match 'Get-FileHash\s+-Algorithm\s+SHA256') "deploy release must calculate the local bundle SHA-256"
Assert-True ($deployScript -match 'sha256sum\s+--check') "deploy release must verify the uploaded bundle with remote sha256sum"
Assert-True ($deployScript.IndexOf("sha256sum --check") -lt $deployScript.IndexOf("rm -rf")) "deploy release must verify integrity before deleting or extracting a release directory"
Assert-True ($deployScript -match 'Assert-SafeRemoteRoot') "deploy release must validate the remote root before using it in shell commands"
Assert-True ($deployScript -match 'Assert-SafeReleaseVersion') "deploy release must validate the release version"
Assert-True ($deployScript -match 'Assert-SafeServiceNames') "deploy release must validate systemd service names"
Assert-True ($rollbackScript -match 'DEPLOY_SSH_PORT') "rollback release must accept the configured SSH port"
Assert-True ($rollbackScript -match 'Assert-SafeRemoteRoot') "rollback release must validate the remote root before using it in shell commands"
Assert-True ($rollbackScript -match 'Assert-SafeReleaseVersion') "rollback release must validate an explicit target version"
Assert-True ($rollbackScript -match 'Assert-SafeServiceNames') "rollback release must validate systemd service names"
Assert-True ($rollbackScript -match 'Resolved rollback version contains unsupported characters') "rollback release must validate an automatically resolved target on the remote host"
Assert-True ($deployScript -match 'DEPLOY_MERCHANT_SERVICE') "deploy release must restart the configured merchant-web service"
Assert-True ($rollbackScript -match 'DEPLOY_MERCHANT_SERVICE') "rollback release must restart the configured merchant-web service"

Assert-True ($releaseWorkflow -match "workflow_run:") "release workflow must react to workflow_run events"
Assert-True ($releaseWorkflow -match "workflow_dispatch:") "release workflow must support manual dispatch"
Assert-True ($releaseWorkflow -match "deploy-test") "release workflow must define deploy-test"
Assert-True ($releaseWorkflow -match "deploy-pre") "release workflow must define deploy-pre"
Assert-True ($releaseWorkflow -match "deploy-prod") "release workflow must define deploy-prod"
Assert-True ($releaseWorkflow -match "Check test deployment configuration") "release workflow must skip an unconfigured automatic test deployment"
Assert-True ($releaseWorkflow -match "steps\.deployment-config\.outputs\.configured") "release workflow must guard automatic test deployment steps"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_HOST") "release workflow must map environment SSH host configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_PORT") "release workflow must map environment SSH port configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_USER") "release workflow must map environment SSH user configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_REMOTE_ROOT") "release workflow must map environment remote root configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_MERCHANT_SERVICE") "release workflow must map the merchant-web service"
Assert-True ($releaseWorkflow -match "merchant-web/package-lock\.json") "release workflow must cache merchant-web dependencies"
Assert-True ($releaseWorkflow -match "npm ci --prefix merchant-web") "release workflow must install merchant-web dependencies"
Assert-True ($releaseWorkflow -match "Release bundle path was not produced") "release workflow must validate the packaged bundle path"
Assert-True ($releaseWorkflow -match "package-release\.ps1") "release workflow must package a release bundle"
Assert-True ($releaseWorkflow -match "PUBLIC_SITE_URL") "release workflow must pass the public SEO site URL"
Assert-True ($releaseWorkflow -match "PRERENDER_API_BASE_URL") "release workflow must pass the real SEO snapshot API base URL"
Assert-True ($releaseWorkflow -match "deploy-release\.ps1") "release workflow must invoke deploy-release.ps1"
Assert-True ($releaseWorkflow -match "environment:\s*test") "release workflow must use the test environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*pre") "release workflow must use the pre environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*prod") "release workflow must use the prod environment gate"

Assert-True ($rollbackWorkflow -match "workflow_dispatch:") "rollback workflow must be manually dispatched"
Assert-True ($rollbackWorkflow -match "rollback-release\.ps1") "rollback workflow must invoke rollback-release.ps1"
Assert-True ($rollbackWorkflow -match "environment:") "rollback workflow must declare an environment gate"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_HOST") "rollback workflow must map environment SSH host configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_PORT") "rollback workflow must map environment SSH port configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_USER") "rollback workflow must map environment SSH user configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_REMOTE_ROOT") "rollback workflow must map environment remote root configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_MERCHANT_SERVICE") "rollback workflow must map the merchant-web service"

Write-Output "release automation contract passed"
