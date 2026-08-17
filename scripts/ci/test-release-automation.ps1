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
    & $packageScriptPath -Version "../unsafe" -DryRun
} "Release version contains unsupported characters" "package release must reject unsafe versions before creating output paths"
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
Assert-True ($packageDryRunText -match "PRERENDER_REGIONS") "package release dry-run must describe multi-region SEO snapshot packaging"
Assert-True ($packageDryRunText -match "VITE_API_BASE_URL.*VITE_WS_BASE_URL.*VITE_STRIPE_PUBLISHABLE_KEY") "package release dry-run must describe Web runtime configuration validation"
Assert-True ($packageDryRunText -match "SHA-256 checksum") "package release dry-run must mention checksum generation"
Assert-True ($deployDryRunText -match "SSH") "deploy release dry-run must mention SSH transport"
Assert-True ($deployDryRunText -match "SHA-256 integrity before extracting") "deploy release dry-run must describe integrity verification before extraction"
Assert-True ($deployDryRunText -match "current") "deploy release dry-run must mention switching the current release"
Assert-True ($deployDryRunText -match "smoke") "deploy release dry-run must mention smoke checks"
Assert-True ($deployDryRunText -match "merchant-web") "deploy release dry-run must mention the merchant-web service"
Assert-True ($deployDryRunText -match "automatically restore the tracked previous release") "deploy release dry-run must describe automatic rollback after failed smoke checks"
Assert-True ($rollbackDryRunText -match "previous stable release") "rollback dry-run must mention the previous stable release"
Assert-True ($rollbackDryRunText -match "smoke") "rollback dry-run must mention smoke checks"
Assert-True ($rollbackDryRunText -match "merchant-web") "rollback dry-run must mention the merchant-web service"
Assert-True ($packageScript -match 'ForEach-Object \{ Write-Host \$_ \}') "package release must keep native build logs out of its returned bundle path"
Assert-True ($packageScript -notmatch '-DskipTests') "package release must not skip backend tests"
Assert-True ($packageScript -match 'merchant-web') "package release must build and package merchant-web"
Assert-True ($packageScript -match 'Get-FileHash\s+-Algorithm\s+SHA256') "package release must calculate the bundle SHA-256"
Assert-True ($packageScript -match '\.sha256') "package release must emit a .sha256 checksum file"
Assert-True ($packageScript -match 'migrations\.sha256') "package release must include the database migration manifest"
Assert-True ($packageScript -match 'mysql-migrate\.sh') "package release must include the database migration runner"
Assert-True ($packageScript -match 'Assert-ReleaseFrontendConfiguration') "deployment packaging must validate Web runtime configuration"
Assert-True ($packageScript -match 'pk_live_') "prod packaging must require a live Stripe publishable key"
Assert-True ($packageScript -match 'pk_test_') "test and pre packaging must require a test Stripe publishable key"
Assert-True ($packageScript -match 'webRuntime') "release manifest must record non-secret Web runtime metadata"
Assert-True ($packageScript -match 'seoSnapshot =') "release manifest must preserve the legacy SEO snapshot summary"
Assert-True ($packageScript -match 'seoSnapshots') "release manifest must record isolated SEO snapshot directories"
Assert-True ($packageScript -match 'PUBLIC_SITE_URL_\$Region') "multi-region SEO packaging must resolve per-region public site URLs"
Assert-True ($packageScript -match 'PRERENDER_API_BASE_URL_\$Region') "multi-region SEO packaging must resolve per-region API URLs"
Assert-True ($packageScript -match 'release-version.txt') "release package must include an immutable version marker"
Assert-True ($packageScript -match 'Release version contains unsupported characters') "package release must validate the version before constructing output paths"
Assert-True ($deployScript -match 'DEPLOY_SSH_PORT') "deploy release must accept the configured SSH port"
Assert-True ($deployScript -match 'Get-FileHash\s+-Algorithm\s+SHA256') "deploy release must calculate the local bundle SHA-256"
Assert-True ($deployScript -match 'sha256sum\s+--check') "deploy release must verify the uploaded bundle with remote sha256sum"
Assert-True ($deployScript.IndexOf("sha256sum --check") -lt $deployScript.IndexOf("rm -rf")) "deploy release must verify integrity before deleting or extracting a release directory"
Assert-True ($deployScript -match 'Assert-SafeRemoteRoot') "deploy release must validate the remote root before using it in shell commands"
Assert-True ($deployScript -match 'Assert-SafeReleaseVersion') "deploy release must validate the release version"
Assert-True ($deployScript -match 'Assert-SafeServiceNames') "deploy release must validate systemd service names"
Assert-True ($deployScript -match 'remotePreviousPath') "deploy release must track the previously active release"
Assert-True ($deployScript -match 'active_release=.*readlink -f') "deploy release must resolve the active release"
Assert-True ($deployScript.IndexOf("active_release=") -lt $deployScript.IndexOf("rm -rf")) "deploy release must resolve the active release before replacing release files"
Assert-True ($deployScript -match 'rollback-release\.ps1') "deploy release must use the shared rollback script after failed smoke checks"
Assert-True ($deployScript -match 'Automatic rollback also failed') "deploy release must report both smoke and rollback failures"
Assert-True ($deployScript -match 'previous release was automatically restored') "deploy release must fail clearly after a successful automatic rollback"
Assert-True ($deployScript -match '-SmokeUrls \$SmokeUrls') "automatic rollback must verify the restored release with the same smoke endpoints"
Assert-True ($deployScript -notmatch '-SmokeUrls " "') "automatic rollback must not suppress rollback smoke checks"
Assert-True ($deployScript -match 'SmokeUrls must contain at least one HTTPS endpoint') "deploy release must require smoke endpoints"
Assert-True ($rollbackScript -match 'SmokeUrls must contain at least one HTTPS endpoint') "rollback release must require smoke endpoints"
Assert-True ($deployScript -match 'Scheme -ne "https"') "deploy release must reject non-HTTPS smoke endpoints"
Assert-True ($rollbackScript -match 'Scheme -ne "https"') "rollback release must reject non-HTTPS smoke endpoints"
Assert-True ($deployScript -match 'StatusCode -ge 200 -and \$response\.StatusCode -lt 300') "deploy smoke checks must only accept 2xx responses"
Assert-True ($rollbackScript -match 'StatusCode -ge 200 -and \$response\.StatusCode -lt 300') "rollback smoke checks must only accept 2xx responses"
Assert-True ($deployScript -match 'attempt -le 6') "deploy smoke checks must retry while services start"
Assert-True ($rollbackScript -match 'attempt -le 6') "rollback smoke checks must retry while services start"
Assert-True ($deployScript -match 'flock -w 300') "deploy release must take a host-level deployment lock"
Assert-True ($rollbackScript -match 'flock -w 300') "rollback release must take the shared host-level deployment lock"
Assert-True ($deployScript -match 'systemctl is-active --quiet') "deploy release must verify restarted services are active"
Assert-True ($deployScript -match 'release-version\.txt') "deploy release must verify the immutable version marker before migration"
Assert-True ($deployScript -match 'ReleaseRetentionCount') "deploy release must expose bounded remote release retention"
Assert-True ($rollbackScript -match 'ReleaseRetentionCount') "rollback release must expose bounded remote release retention"
Assert-True ($deployScript -match 'rm -rf --') "release retention must delete only validated release paths"
Assert-True ($deployScript -match 'DEPLOY_RELEASE_RETENTION_COUNT') "deploy release must accept the configured retention count"
Assert-True ($rollbackScript -match 'DEPLOY_RELEASE_RETENTION_COUNT') "rollback release must accept the configured retention count"
Assert-True ($rollbackScript -match 'systemctl is-active --quiet') "rollback release must verify restored services are active"
Assert-True ($rollbackScript -match 'DEPLOY_SSH_PORT') "rollback release must accept the configured SSH port"
Assert-True ($rollbackScript -match 'Assert-SafeRemoteRoot') "rollback release must validate the remote root before using it in shell commands"
Assert-True ($rollbackScript -match 'Assert-SafeReleaseVersion') "rollback release must validate an explicit target version"
Assert-True ($rollbackScript -match 'Assert-SafeServiceNames') "rollback release must validate systemd service names"
Assert-True ($rollbackScript -match 'Resolved rollback version contains unsupported characters') "rollback release must validate an automatically resolved target on the remote host"
Assert-True ($rollbackScript -match 'previous_release=.*readlink -f') "rollback release must prefer the tracked previous release"
Assert-True ($rollbackScript -match 'sort -nr') "rollback release fallback must order release directories by deployment time"
Assert-True ($rollbackScript -notmatch 'tail -n 2') "rollback release must not infer release history from lexical version order"
Assert-True ($deployScript -match 'DEPLOY_MERCHANT_SERVICE') "deploy release must restart the configured merchant-web service"
Assert-True ($rollbackScript -match 'DEPLOY_MERCHANT_SERVICE') "rollback release must restart the configured merchant-web service"
Assert-True ($deployScript -match 'DEPLOY_DB_DEFAULTS_FILE') "deploy release must accept the secret-managed database defaults path"
Assert-True ($deployScript -match 'DEPLOY_DB_MIGRATION_MODE') "deploy release must accept the database migration mode"
Assert-True ($deployScript -match 'DEPLOY_DB_BASELINE_VERSION') "deploy release must accept the explicit database baseline"
Assert-True ($deployScript -match 'mysql-migrate\.sh') "deploy release must invoke the database migration runner"
$migrationInvocationIndex = $deployScript.IndexOf('bash ''$remoteReleaseDir/database/mysql-migrate.sh''')
Assert-True ($migrationInvocationIndex -ge 0) "deploy release must contain the real remote migration invocation"
Assert-True ($migrationInvocationIndex -lt $deployScript.LastIndexOf('$remotePreviousPath')) "deploy release must migrate before changing previous"
Assert-True ($migrationInvocationIndex -lt $deployScript.LastIndexOf('$remoteCurrentPath')) "deploy release must migrate before switching current"
Assert-True ($migrationInvocationIndex -lt $deployScript.LastIndexOf('$restartCommand')) "deploy release must migrate before restarting services"

Assert-True ($releaseWorkflow -match "workflow_run:") "release workflow must react to workflow_run events"
Assert-True ($releaseWorkflow -match "workflow_dispatch:") "release workflow must support manual dispatch"
Assert-True ($releaseWorkflow -match "permissions:\s*contents:\s*read") "release workflow must use a read-only contents token"
Assert-True ($releaseWorkflow -notmatch "printf[^\r\n]*\$\{\{\s*secrets\.") "release workflow must not interpolate secrets directly into shell commands"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_SSH_PRIVATE_KEY:\s*\$\{\{\s*secrets\.DEPLOY_SSH_PRIVATE_KEY\s*\}\}")).Count -eq 6) "release workflow must scope SSH private key through configuration and SSH step environments"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_KNOWN_HOSTS:\s*\$\{\{\s*secrets\.DEPLOY_KNOWN_HOSTS\s*\}\}")).Count -eq 6) "release workflow must scope known hosts through configuration and SSH step environments"
Assert-True ($releaseWorkflow -match "deploy-test") "release workflow must define deploy-test"
Assert-True ($releaseWorkflow -match "deploy-pre") "release workflow must define deploy-pre"
Assert-True ($releaseWorkflow -match "deploy-prod") "release workflow must define deploy-prod"
Assert-True ($releaseWorkflow -match "Check test deployment configuration") "release workflow must skip an unconfigured automatic test deployment"
Assert-True ($releaseWorkflow -match "Check pre deployment configuration") "release workflow must fail fast when pre deployment configuration is incomplete"
Assert-True ($releaseWorkflow -match "Check prod deployment configuration") "release workflow must fail fast when prod deployment configuration is incomplete"
Assert-True ($releaseWorkflow -match "steps\.deployment-config\.outputs\.configured") "release workflow must guard automatic test deployment steps"
Assert-True (([regex]::Matches($releaseWorkflow, "seo_configured=true")).Count -eq 3) "release workflow must validate SEO configuration per deployment job"
Assert-True (([regex]::Matches($releaseWorkflow, "PUBLIC_SITE_URL_CN")).Count -ge 3) "release workflow must check the CN SEO site URL when multi-region packaging is enabled"
Assert-True (([regex]::Matches($releaseWorkflow, "PRERENDER_API_BASE_URL_EU")).Count -ge 3) "release workflow must check the EU SEO API URL when multi-region packaging is enabled"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_SMOKE_URLS")).Count -ge 6) "release workflow must require and pass deployment smoke endpoints"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_HOST") "release workflow must map environment SSH host configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_PORT") "release workflow must map environment SSH port configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_SSH_USER") "release workflow must map environment SSH user configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_REMOTE_ROOT") "release workflow must map environment remote root configuration"
Assert-True ($releaseWorkflow -match "vars\.DEPLOY_MERCHANT_SERVICE") "release workflow must map the merchant-web service"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_DB_DEFAULTS_FILE")).Count -ge 3) "release workflow must map database defaults for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_DB_MIGRATION_MODE")).Count -ge 3) "release workflow must map migration mode for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "DEPLOY_DB_BASELINE_VERSION")).Count -ge 3) "release workflow must map migration baseline for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "VITE_API_BASE_URL")).Count -ge 3) "release workflow must map the Web API base URL for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "VITE_WS_BASE_URL")).Count -ge 3) "release workflow must map the WebSocket base URL for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "VITE_STRIPE_PUBLISHABLE_KEY")).Count -ge 3) "release workflow must map the Stripe publishable key for test, pre, and prod"
Assert-True ($releaseWorkflow -match "merchant-web/package-lock\.json") "release workflow must cache merchant-web dependencies"
Assert-True ($releaseWorkflow -match "npm ci --prefix merchant-web") "release workflow must install merchant-web dependencies"
Assert-True ($releaseWorkflow -match "Release bundle path was not produced") "release workflow must validate the packaged bundle path"
Assert-True ($releaseWorkflow -match "Release bundle checksum was not produced") "release workflow must validate the packaged checksum path"
Assert-True ($releaseWorkflow -match "package-release\.ps1") "release workflow must package a release bundle"
Assert-True (([regex]::Matches($releaseWorkflow, "actions/upload-artifact@v4")).Count -eq 3) "release workflow must upload server artifacts for test, pre, and prod"
Assert-True (([regex]::Matches($releaseWorkflow, "retention-days:\s*30")).Count -eq 3) "server release artifacts must be retained for 30 days"
Assert-True (([regex]::Matches($releaseWorkflow, "steps\.package\.outputs\.checksum")).Count -eq 3) "each server artifact must include its checksum sidecar"
Assert-True ($releaseWorkflow -match "PUBLIC_SITE_URL") "release workflow must pass the public SEO site URL"
Assert-True ($releaseWorkflow -match "PRERENDER_API_BASE_URL") "release workflow must pass the real SEO snapshot API base URL"
Assert-True (([regex]::Matches($releaseWorkflow, "PRERENDER_REGIONS:")).Count -eq 3) "release workflow must expose optional multi-region SEO packaging"
Assert-True (([regex]::Matches($releaseWorkflow, "PUBLIC_SITE_URL_CN:")).Count -eq 3) "release workflow must expose the CN SEO site URL"
Assert-True (([regex]::Matches($releaseWorkflow, "PUBLIC_SITE_URL_EU:")).Count -eq 3) "release workflow must expose the EU SEO site URL"
Assert-True ($releaseWorkflow -match "deploy-release\.ps1") "release workflow must invoke deploy-release.ps1"
Assert-True ($releaseWorkflow -match "environment:\s*test") "release workflow must use the test environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*pre") "release workflow must use the pre environment gate"
Assert-True ($releaseWorkflow -match "environment:\s*prod") "release workflow must use the prod environment gate"
Assert-True ($releaseWorkflow -match "group:\s*release-test-EU") "test deployments must use the shared test/EU concurrency group"
Assert-True ($releaseWorkflow -match 'group:\s*release-pre-\$\{\{ inputs\.region \}\}') "pre deployments must serialize by region"
Assert-True ($releaseWorkflow -match 'group:\s*release-prod-\$\{\{ inputs\.region \}\}') "prod deployments must serialize by region"
Assert-True (([regex]::Matches($releaseWorkflow, "cancel-in-progress:\s*false")).Count -eq 3) "release jobs must queue instead of cancelling an active deployment"

Assert-True ($rollbackWorkflow -match "workflow_dispatch:") "rollback workflow must be manually dispatched"
Assert-True ($rollbackWorkflow -match "Check rollback configuration") "rollback workflow must fail fast when its environment is incomplete"
Assert-True ($rollbackWorkflow -match "permissions:\s*contents:\s*read") "rollback workflow must use a read-only contents token"
Assert-True ($rollbackWorkflow -notmatch "printf[^\r\n]*\$\{\{\s*secrets\.") "rollback workflow must not interpolate secrets directly into shell commands"
Assert-True ($rollbackWorkflow -match "DEPLOY_SSH_PRIVATE_KEY:\s*\$\{\{\s*secrets\.DEPLOY_SSH_PRIVATE_KEY\s*\}\}") "rollback workflow must scope SSH private key through the step environment"
Assert-True ($rollbackWorkflow -match "DEPLOY_KNOWN_HOSTS:\s*\$\{\{\s*secrets\.DEPLOY_KNOWN_HOSTS\s*\}\}") "rollback workflow must scope known hosts through the step environment"
Assert-True ($rollbackWorkflow -match "rollback-release\.ps1") "rollback workflow must invoke rollback-release.ps1"
Assert-True ($rollbackWorkflow -match "environment:") "rollback workflow must declare an environment gate"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_HOST") "rollback workflow must map environment SSH host configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_PORT") "rollback workflow must map environment SSH port configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_SSH_USER") "rollback workflow must map environment SSH user configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_REMOTE_ROOT") "rollback workflow must map environment remote root configuration"
Assert-True ($rollbackWorkflow -match "vars\.DEPLOY_MERCHANT_SERVICE") "rollback workflow must map the merchant-web service"
Assert-True ($rollbackWorkflow -match "DEPLOY_SMOKE_URLS") "rollback workflow must require smoke endpoints"
Assert-True ($rollbackWorkflow -match 'group:\s*release-\$\{\{ inputs\.environment \}\}-\$\{\{ inputs\.region \}\}') "rollback must share the environment/region deployment concurrency group"
Assert-True ($rollbackWorkflow -match "cancel-in-progress:\s*false") "rollback must queue instead of interrupting an active deployment"

Write-Output "release automation contract passed"
