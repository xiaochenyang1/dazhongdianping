$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$preflightPath = Join-Path $repoRoot "scripts\ci\github-environment-preflight.ps1"

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

function ConvertTo-VariableJson {
    param([hashtable]$Values)

    return @($Values.GetEnumerator() | Sort-Object Key | ForEach-Object {
        [pscustomobject]@{ name = $_.Key; value = [string]$_.Value }
    }) | ConvertTo-Json -Compress
}

function ConvertTo-SecretJson {
    param([string[]]$Names)

    return @($Names | Sort-Object | ForEach-Object {
        [pscustomobject]@{ name = $_ }
    }) | ConvertTo-Json -Compress
}

Assert-True (Test-Path -LiteralPath $preflightPath) "GitHub Environment preflight script must exist"

$readyVariables = @{
    DEPLOY_SSH_HOST = "pre.example.com"
    DEPLOY_SSH_PORT = "22"
    DEPLOY_SSH_USER = "deploy"
    DEPLOY_REMOTE_ROOT = "/opt/dazhongdianping"
    DEPLOY_BACKEND_SERVICE = "dzdp-backend"
    DEPLOY_WEB_SERVICE = "dzdp-web"
    DEPLOY_ADMIN_SERVICE = "dzdp-admin-web"
    DEPLOY_MERCHANT_SERVICE = "dzdp-merchant-web"
    DEPLOY_SMOKE_URLS = "https://api.example.com/actuator/health,https://www.example.com/health"
    DEPLOY_DB_DEFAULTS_FILE = "/etc/dazhongdianping/mysql-release.cnf"
    DEPLOY_DB_MIGRATION_MODE = "apply"
    DEPLOY_RELEASE_RETENTION_COUNT = "5"
    VITE_API_BASE_URL = "https://api.example.com"
    VITE_WS_BASE_URL = "wss://api.example.com/ws"
    VITE_STRIPE_PUBLISHABLE_KEY = "pk_test_fixture"
    PUBLIC_SITE_URL = "https://www.example.com"
    PRERENDER_API_BASE_URL = "https://api.example.com"
}
$readyVariablesJson = ConvertTo-VariableJson -Values $readyVariables
$readySecretsJson = ConvertTo-SecretJson -Names @("DEPLOY_KNOWN_HOSTS", "DEPLOY_SSH_PRIVATE_KEY")

$readyReport = & $preflightPath `
    -Environment pre `
    -Repository owner/repo `
    -VariablesJson $readyVariablesJson `
    -SecretsJson $readySecretsJson `
    -ReportOnly `
    -Json | ConvertFrom-Json
Assert-True $readyReport.Ready "complete pre environment fixture must be ready"
Assert-True ($readyReport.MissingVariables.Count -eq 0) "ready fixture must not report missing variables"
Assert-True ($readyReport.MissingSecrets.Count -eq 0) "ready fixture must not report missing secrets"
Assert-True ($readyReport.InvalidVariables.Count -eq 0) "ready fixture must not report invalid variables"

$multiRegionVariables = $readyVariables.Clone()
$multiRegionVariables.Remove("PUBLIC_SITE_URL")
$multiRegionVariables.Remove("PRERENDER_API_BASE_URL")
$multiRegionVariables.PRERENDER_REGIONS = "CN,EU"
$multiRegionVariables.PUBLIC_SITE_URL_CN = "https://cn.example.com"
$multiRegionVariables.PRERENDER_API_BASE_URL_CN = "https://api-cn.example.com"
$multiRegionVariables.PUBLIC_SITE_URL_EU = "https://eu.example.com"
$multiRegionVariables.PRERENDER_API_BASE_URL_EU = "https://api-eu.example.com"
$multiRegionReport = & $preflightPath `
    -Environment pre `
    -VariablesJson (ConvertTo-VariableJson -Values $multiRegionVariables) `
    -SecretsJson $readySecretsJson `
    -ReportOnly `
    -Json | ConvertFrom-Json
Assert-True $multiRegionReport.Ready "complete multi-region SEO fixture must be ready"

$missingVariables = @{
    DEPLOY_SSH_PORT = "22"
    DEPLOY_BACKEND_SERVICE = "dzdp-backend"
    DEPLOY_WEB_SERVICE = "dzdp-web"
    DEPLOY_ADMIN_SERVICE = "dzdp-admin-web"
    DEPLOY_MERCHANT_SERVICE = "dzdp-merchant-web"
    DEPLOY_DB_MIGRATION_MODE = "apply"
}
$missingVariablesJson = ConvertTo-VariableJson -Values $missingVariables
$missingReportText = (& $preflightPath `
    -Environment pre `
    -VariablesJson $missingVariablesJson `
    -SecretsJson "[]" `
    -ReportOnly) -join "`n"
foreach ($expected in @(
    "DEPLOY_DB_DEFAULTS_FILE",
    "DEPLOY_REMOTE_ROOT",
    "DEPLOY_SMOKE_URLS",
    "DEPLOY_SSH_HOST",
    "DEPLOY_SSH_USER",
    "PRERENDER_API_BASE_URL",
    "PUBLIC_SITE_URL",
    "VITE_API_BASE_URL",
    "VITE_STRIPE_PUBLISHABLE_KEY",
    "VITE_WS_BASE_URL"
)) {
    Assert-True ($missingReportText -match "\[missing variable\] $expected") "missing fixture must identify $expected"
}
foreach ($expected in @("DEPLOY_KNOWN_HOSTS", "DEPLOY_SSH_PRIVATE_KEY")) {
    Assert-True ($missingReportText -match "\[missing secret\]\s+$expected") "missing fixture must identify $expected"
}
Assert-True ($missingReportText -notmatch 'dzdp-backend') "preflight output must not echo variable values"
Assert-ThrowsLike {
    & $preflightPath `
        -Environment pre `
        -VariablesJson $missingVariablesJson `
        -SecretsJson "[]"
} "not ready for deployment" "incomplete environment must fail without ReportOnly"

$invalidVariables = $readyVariables.Clone()
$invalidVariables.DEPLOY_SSH_HOST = "ssh://deploy@example.com/path"
$invalidVariables.DEPLOY_SSH_PORT = "70000"
$invalidVariables.DEPLOY_REMOTE_ROOT = "/"
$invalidVariables.DEPLOY_SMOKE_URLS = "http://user:pass@example.com/health"
$invalidVariables.DEPLOY_DB_DEFAULTS_FILE = "/etc/../root.cnf"
$invalidVariables.DEPLOY_DB_MIGRATION_MODE = "drop"
$invalidVariables.DEPLOY_RELEASE_RETENTION_COUNT = "0"
$invalidVariables.DEPLOY_BACKEND_SERVICE = "dzdp backend"
$invalidVariables.VITE_API_BASE_URL = "http://api.example.com"
$invalidVariables.VITE_WS_BASE_URL = "https://api.example.com/ws"
$invalidVariables.VITE_STRIPE_PUBLISHABLE_KEY = "pk_live_must_not_be_printed"
$invalidVariables.PUBLIC_SITE_URL = "https://user:secret@example.com"
$invalidReport = & $preflightPath `
    -Environment pre `
    -VariablesJson (ConvertTo-VariableJson -Values $invalidVariables) `
    -SecretsJson $readySecretsJson `
    -ReportOnly `
    -Json | ConvertFrom-Json
$invalidNames = @($invalidReport.InvalidVariables | ForEach-Object { $_.Name })
foreach ($expected in @(
    "DEPLOY_SSH_HOST",
    "DEPLOY_SSH_PORT",
    "DEPLOY_REMOTE_ROOT",
    "DEPLOY_SMOKE_URLS",
    "DEPLOY_DB_DEFAULTS_FILE",
    "DEPLOY_DB_MIGRATION_MODE",
    "DEPLOY_RELEASE_RETENTION_COUNT",
    "DEPLOY_BACKEND_SERVICE",
    "VITE_API_BASE_URL",
    "VITE_WS_BASE_URL",
    "VITE_STRIPE_PUBLISHABLE_KEY",
    "PUBLIC_SITE_URL"
)) {
    Assert-True ($expected -in $invalidNames) "invalid fixture must reject $expected"
}
$invalidReportJson = $invalidReport | ConvertTo-Json -Depth 5
Assert-True ($invalidReportJson -notmatch 'pk_live_must_not_be_printed') "JSON report must not expose invalid variable values"
Assert-True ($invalidReportJson -notmatch 'user:secret') "JSON report must not expose URL credentials"

$prodVariables = $readyVariables.Clone()
$prodVariables.VITE_STRIPE_PUBLISHABLE_KEY = "pk_live_fixture"
$prodReport = & $preflightPath `
    -Environment prod `
    -VariablesJson (ConvertTo-VariableJson -Values $prodVariables) `
    -SecretsJson $readySecretsJson `
    -ReportOnly `
    -Json | ConvertFrom-Json
Assert-True $prodReport.Ready "prod fixture must accept a live Stripe publishable key"

Assert-ThrowsLike {
    & $preflightPath -VariablesJson "[]"
} "must be supplied together" "offline snapshots must supply variables and secrets together"

Write-Output "GitHub Environment preflight contract passed"
