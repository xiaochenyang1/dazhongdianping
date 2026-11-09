$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$bootstrapPath = Join-Path $repoRoot "scripts\ci\github-environment-bootstrap.ps1"
$examplePath = Join-Path $repoRoot "deploy\github-environment.config.example.json"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-github-environment-bootstrap-" + [Guid]::NewGuid().ToString("N"))
$privateRoot = Join-Path $fixtureRoot "private"
$binRoot = Join-Path $fixtureRoot "bin"
$configPath = Join-Path $fixtureRoot "github-environment.pre.json"
$privateKeyPath = Join-Path $privateRoot "id_ed25519"
$knownHostsPath = Join-Path $privateRoot "known_hosts"
$originalPath = $env:PATH
$testEnvironmentNames = @(
    "DZDP_GH_LOG",
    "DZDP_GH_VARIABLES_JSON",
    "DZDP_GH_SECRETS_JSON",
    "DZDP_GH_PROTECTION_JSON",
    "DZDP_GH_POLICY_CREATED",
    "DZDP_GH_LIVE_POLICIES_JSON",
    "DZDP_GH_ENVIRONMENT_PAYLOAD",
    "DZDP_GH_POLICY_PAYLOADS"
)
$previousEnvironment = @{}

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

function New-ReadyVariables {
    param([string]$Environment = "pre")

    return [ordered]@{
        DEPLOY_SSH_HOST = "$Environment.example.test"
        DEPLOY_SSH_PORT = "22"
        DEPLOY_SSH_USER = "deploy"
        DEPLOY_REMOTE_ROOT = "/opt/dazhongdianping"
        DEPLOY_BACKEND_SERVICE = "dzdp-backend"
        DEPLOY_WEB_SERVICE = "dzdp-web"
        DEPLOY_ADMIN_SERVICE = "dzdp-admin-web"
        DEPLOY_MERCHANT_SERVICE = "dzdp-merchant-web"
        DEPLOY_SMOKE_URLS = "https://api.example.test/actuator/health,https://www.example.test/health"
        DEPLOY_RUNTIME_ENV_FILE = "/etc/dazhongdianping/$Environment.env"
        DEPLOY_DB_DEFAULTS_FILE = "/etc/dazhongdianping/mysql-release.cnf"
        DEPLOY_DB_MIGRATION_MODE = "apply"
        DEPLOY_RELEASE_RETENTION_COUNT = "5"
        VITE_API_BASE_URL = "https://api.example.test"
        VITE_WS_BASE_URL = "wss://api.example.test"
        VITE_STRIPE_PUBLISHABLE_KEY = if ($Environment -eq "prod") { "pk_live_fixture" } else { "pk_test_fixture" }
        PUBLIC_SITE_URL = "https://www.example.test"
        PRERENDER_API_BASE_URL = "https://api.example.test"
    }
}

function New-ReadyConfig {
    param(
        [string]$Environment = "pre",
        [string]$Region = "EU"
    )

    return [ordered]@{
        schemaVersion = 1
        environment = $Environment
        region = $Region
        variables = New-ReadyVariables -Environment $Environment
        secretFiles = [ordered]@{
            DEPLOY_SSH_PRIVATE_KEY = $privateKeyPath
            DEPLOY_KNOWN_HOSTS = $knownHostsPath
        }
        protection = [ordered]@{
            reviewers = @("release-approver")
            preventSelfReview = $true
            canAdminsBypass = $false
            waitTimer = 0
            deploymentPolicies = @(
                [ordered]@{ type = "branch"; name = "main" },
                [ordered]@{ type = "tag"; name = "eu-pre-rc-*" }
            )
        }
    }
}

function Write-Config {
    param([object]$Config)

    $Config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding utf8
}

try {
    Assert-True (Test-Path -LiteralPath $bootstrapPath) "GitHub Environment bootstrap script must exist"
    Assert-True (Test-Path -LiteralPath $examplePath) "GitHub Environment bootstrap example must exist"
    New-Item -ItemType Directory -Path $privateRoot, $binRoot -Force | Out-Null
    Set-Content -LiteralPath $privateKeyPath -Value "PRIVATE-KEY-MATERIAL-MUST-NOT-PRINT" -Encoding utf8 -NoNewline
    Set-Content -LiteralPath $knownHostsPath -Value "example.test ssh-ed25519 AAAAFIXTURE" -Encoding utf8 -NoNewline
    if ([Environment]::OSVersion.Platform -ne "Win32NT") {
        [IO.File]::SetUnixFileMode($privateKeyPath, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)
    }

    $readyConfig = New-ReadyConfig
    Write-Config -Config $readyConfig
    $planRaw = (& $bootstrapPath `
        -Environment pre `
        -ConfigPath $configPath `
        -Repository owner/repo `
        -Json) -join "`n"
    $plan = $planRaw | ConvertFrom-Json
    Assert-True ($plan.Mode -eq "Plan") "default bootstrap mode must be Plan"
    Assert-True (-not $plan.Applied) "Plan must not claim to apply GitHub state"
    Assert-True $plan.ConfigurationReady "ready config must pass the offline preflight"
    Assert-True ($plan.VariableNames.Count -eq 18) "plan must include every configured variable name"
    Assert-True ($plan.SecretNames.Count -eq 2) "plan must include both environment secret names"
    Assert-True ($plan.ReviewerCount -eq 1) "plan must report the reviewer count"
    Assert-True ("branch:main" -in $plan.DeploymentPolicies) "plan must include the main branch policy"
    Assert-True ("tag:eu-pre-rc-*" -in $plan.DeploymentPolicies) "plan must include the release tag policy"
    Assert-True ($plan.ManualActions.Count -eq 1) "plan must disclose the administrator-bypass manual check"
    foreach ($forbidden in @(
        "api.example.test",
        "PRIVATE-KEY-MATERIAL",
        $privateKeyPath,
        "release-approver"
    )) {
        Assert-True ($planRaw -notmatch [regex]::Escape($forbidden)) "plan JSON must not expose configured values, paths, or reviewer identities"
    }

    $planText = (& $bootstrapPath `
        -Environment pre `
        -ConfigPath $configPath `
        -Repository owner/repo) -join "`n"
    Assert-True ($planText -match '\[plan only\] No GitHub state was changed') "text plan must state that it made no changes"
    Assert-True ($planText -match '\[plan\] upsert secret DEPLOY_SSH_PRIVATE_KEY from a local private file') "text plan must identify secret names without paths"
    Assert-True ($planText -notmatch 'api[.]example[.]test') "text plan must not expose variable values"

    $placeholderConfig = New-ReadyConfig
    $placeholderConfig.variables.DEPLOY_SSH_HOST = "CHANGE_ME"
    Write-Config -Config $placeholderConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
    } "non-placeholder string" "placeholder variables must be rejected"

    $unsupportedVariableConfig = New-ReadyConfig
    $unsupportedVariableConfig.variables["APP_AUTH_JWT_SECRET"] = "must-not-be-stored-as-a-variable"
    Write-Config -Config $unsupportedVariableConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
    } "unsupported property 'APP_AUTH_JWT_SECRET'" "unknown or secret-like variable names must be rejected"

    $inlineSecretConfig = New-ReadyConfig
    $inlineSecretConfig["secrets"] = @{ DEPLOY_SSH_PRIVATE_KEY = "must-not-be-inline" }
    Write-Config -Config $inlineSecretConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
    } "unsupported property 'secrets'" "inline secret bodies must be rejected by the config schema"

    $testRegionConfig = New-ReadyConfig -Environment test -Region CN
    $testRegionConfig.protection.reviewers = @()
    Write-Config -Config $testRegionConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment test -ConfigPath $configPath -Repository owner/repo
    } "fixed to region EU" "test bootstrap must reject non-EU regions"

    $placeholderReviewerConfig = New-ReadyConfig
    $placeholderReviewerConfig.protection.reviewers = @("CHANGE_ME_APPROVER")
    Write-Config -Config $placeholderReviewerConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
    } "must not contain placeholder values" "placeholder reviewers must be rejected"

    $stringBooleanConfig = New-ReadyConfig
    $stringBooleanConfig.protection.preventSelfReview = "true"
    Write-Config -Config $stringBooleanConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
    } "must be a boolean" "string booleans must not be silently coerced"

    $testBypassConfig = New-ReadyConfig -Environment test
    $testBypassConfig.protection.reviewers = @()
    $testBypassConfig.protection.preventSelfReview = $false
    $testBypassConfig.protection.canAdminsBypass = $true
    Write-Config -Config $testBypassConfig
    $testBypassPlan = & $bootstrapPath `
        -Environment test `
        -ConfigPath $configPath `
        -Repository owner/repo `
        -Json | ConvertFrom-Json
    Assert-True ($testBypassPlan.ManualActions.Count -eq 0) "test may explicitly allow administrator bypass without a contradictory manual action"
    Assert-True ("manual:verify-admin-bypass-disabled" -notin $testBypassPlan.Actions) "the action list must reflect the administrator-bypass intent"

    if ([Environment]::OSVersion.Platform -ne "Win32NT") {
        [IO.File]::SetUnixFileMode($privateKeyPath,
            [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::GroupRead)
        Write-Config -Config (New-ReadyConfig)
        Assert-ThrowsLike {
            & $bootstrapPath -Environment pre -ConfigPath $configPath -Repository owner/repo
        } "must not grant group or other permissions" "private key permissions must be restricted"
        [IO.File]::SetUnixFileMode($privateKeyPath, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)
    }

    $prodConfig = New-ReadyConfig -Environment prod
    Write-Config -Config $prodConfig
    Assert-ThrowsLike {
        & $bootstrapPath -Environment prod -ConfigPath $configPath -Repository owner/repo -Apply
    } "requires -AllowProduction" "production apply must require an explicit production guard"

    Write-Config -Config (New-ReadyConfig)
    $variablesSnapshotPath = Join-Path $fixtureRoot "variables.json"
    $secretsSnapshotPath = Join-Path $fixtureRoot "secrets.json"
    $protectionSnapshotPath = Join-Path $fixtureRoot "protection.json"
    $livePoliciesPath = Join-Path $fixtureRoot "policies.json"
    $ghLogPath = Join-Path $fixtureRoot "gh.log"
    $policyMarkerPath = Join-Path $fixtureRoot "policy-created"
    $environmentPayloadPath = Join-Path $fixtureRoot "environment-payload.json"
    $policyPayloadsPath = Join-Path $fixtureRoot "policy-payloads.txt"

    @((New-ReadyVariables).GetEnumerator() | ForEach-Object {
        [pscustomobject]@{ name = $_.Key; value = $_.Value }
    }) | ConvertTo-Json -Compress | Set-Content -LiteralPath $variablesSnapshotPath -Encoding utf8
    @(
        [pscustomobject]@{ name = "DEPLOY_KNOWN_HOSTS" },
        [pscustomobject]@{ name = "DEPLOY_SSH_PRIVATE_KEY" }
    ) | ConvertTo-Json -Compress | Set-Content -LiteralPath $secretsSnapshotPath -Encoding utf8
    @{
        protection_rules = @(
            @{
                type = "required_reviewers"
                prevent_self_review = $true
                reviewers = @(@{ type = "User"; reviewer = @{ login = "release-approver" } })
            }
        )
        can_admins_bypass = $false
        deployment_branch_policy = @{ protected_branches = $false; custom_branch_policies = $true }
    } | ConvertTo-Json -Depth 7 -Compress | Set-Content -LiteralPath $protectionSnapshotPath -Encoding utf8
    @{
        total_count = 2
        branch_policies = @(
            @{ id = 1; name = "main"; type = "branch" },
            @{ id = 2; name = "eu-pre-rc-*"; type = "tag" }
        )
    } | ConvertTo-Json -Depth 5 -Compress | Set-Content -LiteralPath $livePoliciesPath -Encoding utf8

    if ([Environment]::OSVersion.Platform -eq "Win32NT") {
        Write-Output "GitHub Environment bootstrap Apply contract skipped on Windows"
        Write-Output "GitHub Environment bootstrap contract passed"
        return
    }
    $fakeGhPath = Join-Path $binRoot "gh"
    $fakeGh = @'
#!/bin/sh
set -eu
printf '%s\n' "$*" >> "$DZDP_GH_LOG"

if [ "$1" = "api" ] && [ "${2:-}" = "users/release-approver" ]; then
  printf '42\n'
  exit 0
fi

if [ "$1" = "api" ] && [ "${2:-}" = "--method" ] && [ "${3:-}" = "PUT" ]; then
  payload="$(cat)"
  printf '%s' "$payload" > "$DZDP_GH_ENVIRONMENT_PAYLOAD"
  exit 0
fi

if [ "$1" = "api" ] && [ "${2:-}" = "--method" ] && [ "${3:-}" = "POST" ]; then
  payload="$(cat)"
  printf '%s\n' "$payload" >> "$DZDP_GH_POLICY_PAYLOADS"
  : > "$DZDP_GH_POLICY_CREATED"
  exit 0
fi

if [ "$1" = "api" ] && printf '%s' "${2:-}" | grep -q '/deployment-branch-policies'; then
  if [ -f "$DZDP_GH_POLICY_CREATED" ]; then
    cat "$DZDP_GH_LIVE_POLICIES_JSON"
  else
    printf '{"total_count":0,"branch_policies":[]}'
  fi
  exit 0
fi

if [ "$1" = "api" ] && printf '%s' "${2:-}" | grep -q '/environments/pre$'; then
  cat "$DZDP_GH_PROTECTION_JSON"
  exit 0
fi

if [ "$1" = "variable" ] && [ "$2" = "list" ]; then
  cat "$DZDP_GH_VARIABLES_JSON"
  exit 0
fi

if [ "$1" = "secret" ] && [ "$2" = "list" ]; then
  cat "$DZDP_GH_SECRETS_JSON"
  exit 0
fi

if [ "$1" = "variable" ] && [ "$2" = "set" ]; then
  payload="$(cat)"
  bytes="$(printf '%s' "$payload" | wc -c | tr -d ' ')"
  printf 'variable-set %s stdin-bytes=%s\n' "$3" "$bytes" >> "$DZDP_GH_LOG"
  exit 0
fi

if [ "$1" = "secret" ] && [ "$2" = "set" ]; then
  payload="$(cat)"
  bytes="$(printf '%s' "$payload" | wc -c | tr -d ' ')"
  printf 'secret-set %s stdin-bytes=%s\n' "$3" "$bytes" >> "$DZDP_GH_LOG"
  exit 0
fi

exit 91
'@
    Set-Content -LiteralPath $fakeGhPath -Value $fakeGh -Encoding utf8 -NoNewline
    [IO.File]::SetUnixFileMode($fakeGhPath,
        [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)

    foreach ($name in $testEnvironmentNames) {
        $existing = Get-Item "Env:\$name" -ErrorAction SilentlyContinue
        $previousEnvironment[$name] = if ($null -eq $existing) { $null } else { $existing.Value }
    }
    $env:DZDP_GH_LOG = $ghLogPath
    $env:DZDP_GH_VARIABLES_JSON = $variablesSnapshotPath
    $env:DZDP_GH_SECRETS_JSON = $secretsSnapshotPath
    $env:DZDP_GH_PROTECTION_JSON = $protectionSnapshotPath
    $env:DZDP_GH_POLICY_CREATED = $policyMarkerPath
    $env:DZDP_GH_LIVE_POLICIES_JSON = $livePoliciesPath
    $env:DZDP_GH_ENVIRONMENT_PAYLOAD = $environmentPayloadPath
    $env:DZDP_GH_POLICY_PAYLOADS = $policyPayloadsPath
    $env:PATH = "$binRoot$([IO.Path]::PathSeparator)$originalPath"

    $applyRaw = (& $bootstrapPath `
        -Environment pre `
        -ConfigPath $configPath `
        -Repository owner/repo `
        -Apply `
        -Json) -join "`n"
    $applyReport = $applyRaw | ConvertFrom-Json
    Assert-True ($applyReport.Mode -eq "Apply") "apply report must record Apply mode"
    Assert-True $applyReport.Applied "apply report must record applied state"
    Assert-True $applyReport.PostApplyReady "apply must run and pass the live post-apply audit"
    foreach ($forbidden in @(
        "PRIVATE-KEY-MATERIAL",
        "api.example.test",
        $privateKeyPath,
        "release-approver"
    )) {
        Assert-True ($applyRaw -notmatch [regex]::Escape($forbidden)) "apply output must not expose values, paths, or reviewer identities"
    }

    $ghLog = Get-Content -LiteralPath $ghLogPath -Raw
    Assert-True ($ghLog -match 'api --method PUT repos/owner/repo/environments/pre --input -') "apply must create or update the target environment"
    Assert-True ($ghLog -match 'variable-set DEPLOY_SSH_HOST') "apply must set environment variables through stdin"
    Assert-True ($ghLog -match 'secret-set DEPLOY_SSH_PRIVATE_KEY') "apply must set environment secrets through stdin"
    Assert-True ($ghLog -notmatch 'PRIVATE-KEY-MATERIAL') "fake gh arguments/logs must not contain secret bodies"
    Assert-True ($ghLog -notmatch 'api[.]example[.]test') "fake gh arguments/logs must not contain variable values"

    $environmentPayload = Get-Content -LiteralPath $environmentPayloadPath -Raw | ConvertFrom-Json
    Assert-True ($environmentPayload.reviewers[0].id -eq 42) "environment payload must resolve the reviewer to a numeric ID"
    Assert-True $environmentPayload.prevent_self_review "environment payload must prevent self-review"
    Assert-True ($null -eq $environmentPayload.PSObject.Properties["can_admins_bypass"]) "environment payload must not send unsupported API properties"
    Assert-True $environmentPayload.deployment_branch_policy.custom_branch_policies "environment payload must enable custom deployment policies"
    $policyPayloads = Get-Content -LiteralPath $policyPayloadsPath -Raw
    Assert-True ($policyPayloads -match '"name":"main"') "apply must create the main branch policy"
    Assert-True ($policyPayloads -match '"name":"eu-pre-rc-[*]"') "apply must create the release tag policy"

    $createdPolicyCount = @(Get-Content -LiteralPath $policyPayloadsPath).Count
    @{
        protection_rules = @(
            @{
                type = "required_reviewers"
                prevent_self_review = $true
                reviewers = @(@{ type = "User"; reviewer = @{ login = "release-approver" } })
            }
        )
        can_admins_bypass = $true
        deployment_branch_policy = @{ protected_branches = $false; custom_branch_policies = $true }
    } | ConvertTo-Json -Depth 7 -Compress | Set-Content -LiteralPath $protectionSnapshotPath -Encoding utf8

    $bypassApplyReport = & $bootstrapPath `
        -Environment pre `
        -ConfigPath $configPath `
        -Repository owner/repo `
        -Apply `
        -Json | ConvertFrom-Json
    Assert-True (-not $bypassApplyReport.PostApplyReady) "apply must not claim full readiness while administrators can still bypass approval"
    Assert-True ($bypassApplyReport.ManualActions.Count -eq 1) "apply must retain the administrator-bypass manual action until the live setting is disabled"
    Assert-True (@(Get-Content -LiteralPath $policyPayloadsPath).Count -eq $createdPolicyCount) "apply must not recreate deployment policies that already exist"

    Write-Output "GitHub Environment bootstrap contract passed"
}
finally {
    $env:PATH = $originalPath
    foreach ($name in $testEnvironmentNames) {
        if (-not $previousEnvironment.ContainsKey($name) -or $null -eq $previousEnvironment[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item "Env:\$name" $previousEnvironment[$name]
        }
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
