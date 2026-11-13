param(
    [Alias("Environment")]
    [ValidateSet("test", "pre", "prod")]
    [string]$TargetEnvironment = "pre",
    [string]$Repository,
    [string]$VariablesJson,
    [string]$SecretsJson,
    [string]$ProtectionJson,
    [switch]$ReportOnly,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Invoke-GhJson {
    param([string[]]$Arguments)

    $output = @(& gh @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "gh $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return $output -join "`n"
}

function Test-ConfiguredValue {
    param([AllowNull()][string]$Value)

    return -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notmatch 'CHANGE_ME' -and
        $Value -notmatch 'xxxxx'
}

function Test-AbsoluteUrl {
    param(
        [string]$Value,
        [string]$Scheme,
        [switch]$OriginOnly
    )

    $uri = $null
    $valid = [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -and
        $uri.Scheme -ceq $Scheme -and
        -not [string]::IsNullOrWhiteSpace($uri.Host) -and
        [string]::IsNullOrWhiteSpace($uri.UserInfo)
    return $valid -and (-not $OriginOnly -or
        ($uri.AbsolutePath -ceq "/" -and [string]::IsNullOrWhiteSpace($uri.Query) -and [string]::IsNullOrWhiteSpace($uri.Fragment)))
}

function Test-PublicHttpsOrigin {
    param([string]$Value)

    $uri = $null
    if (-not (Test-AbsoluteUrl -Value $Value -Scheme "https" -OriginOnly) -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) {
        return $false
    }
    return -not $uri.IsLoopback -and $uri.Host -notmatch '(?i)(^|[.])localhost$'
}

function Test-SafeAbsolutePath {
    param(
        [string]$Value,
        [switch]$AllowRoot
    )

    if (-not $AllowRoot -and $Value -eq "/") {
        return $false
    }
    return $Value -match '^/[A-Za-z0-9._/-]+$' -and
        $Value -notmatch '(^|/)\.{1,2}(/|$)' -and
        -not $Value.Contains("//")
}

$offlineInputs = @($VariablesJson, $SecretsJson, $ProtectionJson) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($offlineInputs.Count -gt 0 -and $offlineInputs.Count -ne 3) {
    throw "VariablesJson, SecretsJson, and ProtectionJson must be supplied together for an offline audit"
}

$offline = -not [string]::IsNullOrWhiteSpace($VariablesJson)
if (-not $offline) {
    $null = Get-Command gh -CommandType Application -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        $Repository = (Invoke-GhJson -Arguments @("repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner")).Trim()
    }
    $VariablesJson = Invoke-GhJson -Arguments @(
        "variable", "list", "--repo", $Repository, "--env", $TargetEnvironment, "--json", "name,value"
    )
    $SecretsJson = Invoke-GhJson -Arguments @(
        "secret", "list", "--repo", $Repository, "--env", $TargetEnvironment, "--json", "name"
    )
    $ProtectionJson = Invoke-GhJson -Arguments @(
        "api", "repos/$Repository/environments/$TargetEnvironment"
    )
}
elseif ([string]::IsNullOrWhiteSpace($Repository)) {
    $Repository = "offline-snapshot"
}

try {
    $variableEntries = @($VariablesJson | ConvertFrom-Json)
    $secretEntries = @($SecretsJson | ConvertFrom-Json)
    $protection = $ProtectionJson | ConvertFrom-Json
}
catch {
    throw "Environment snapshot JSON is invalid"
}

if (-not $offline -and
    $null -ne $protection.deployment_branch_policy -and
    $protection.deployment_branch_policy.custom_branch_policies -eq $true) {
    try {
        $policyList = Invoke-GhJson -Arguments @(
            "api", "repos/$Repository/environments/$TargetEnvironment/deployment-branch-policies?per_page=100"
        ) | ConvertFrom-Json
        $deploymentPolicies = @($policyList.branch_policies | ForEach-Object {
            [pscustomobject]@{
                name = [string]$_.name
                type = [string]$_.type
            }
        })
        $protection | Add-Member -NotePropertyName "deployment_branch_policies" -NotePropertyValue $deploymentPolicies -Force
    }
    catch {
        throw "Unable to read Environment deployment policies"
    }
}

$variables = @{}
foreach ($entry in $variableEntries) {
    if ([string]::IsNullOrWhiteSpace([string]$entry.name)) {
        throw "Environment variable snapshot contains an entry without a name"
    }
    $variables[[string]$entry.name] = [string]$entry.value
}

$secrets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($entry in $secretEntries) {
    if ([string]::IsNullOrWhiteSpace([string]$entry.name)) {
        throw "Environment secret snapshot contains an entry without a name"
    }
    $null = $secrets.Add([string]$entry.name)
}

$missingVariables = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$missingSecrets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$invalidVariables = [System.Collections.Generic.List[object]]::new()
$missingProtectionRules = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$invalidProtectionRules = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()

function Get-EnvironmentVariableValue {
    param([string]$Name)

    if ($variables.ContainsKey($Name)) {
        return [string]$variables[$Name]
    }
    return $null
}

function Require-EnvironmentVariable {
    param([string]$Name)

    $value = Get-EnvironmentVariableValue -Name $Name
    if (-not (Test-ConfiguredValue -Value $value)) {
        $null = $missingVariables.Add($Name)
    }
}

function Add-InvalidVariable {
    param(
        [string]$Name,
        [string]$Message
    )

    $invalidVariables.Add([pscustomobject]@{
        Name = $Name
        Message = $Message
    })
}

function Add-InvalidProtectionRule {
    param(
        [string]$Name,
        [string]$Message
    )

    $invalidProtectionRules.Add([pscustomobject]@{
        Name = $Name
        Message = $Message
    })
}

function Add-AuditWarning {
    param(
        [string]$Name,
        [string]$Message
    )

    $warnings.Add([pscustomobject]@{
        Name = $Name
        Message = $Message
    })
}

$requiredVariables = @(
    "DEPLOY_SMOKE_URLS",
    "VITE_API_BASE_URL",
    "VITE_WS_BASE_URL",
    "VITE_STRIPE_PUBLISHABLE_KEY"
)
foreach ($name in $requiredVariables) {
    Require-EnvironmentVariable -Name $name
}

if ($TargetEnvironment -eq "test") {
    foreach ($name in @(
        "REMOTE_ACCEPTANCE_WEB_BASE_URL",
        "REMOTE_ACCEPTANCE_ADMIN_BASE_URL",
        "REMOTE_ACCEPTANCE_MERCHANT_BASE_URL",
        "REMOTE_ACCEPTANCE_BACKEND_BASE_URL"
    )) {
        Require-EnvironmentVariable -Name $name
    }
}

foreach ($name in @(
    "DEPLOY_SSH_HOST",
    "DEPLOY_SSH_USER",
    "DEPLOY_REMOTE_ROOT",
    "DEPLOY_RUNTIME_ENV_FILE",
    "DEPLOY_DB_DEFAULTS_FILE",
    "DEPLOY_SSH_PRIVATE_KEY",
    "DEPLOY_KNOWN_HOSTS"
)) {
    if (-not $secrets.Contains($name)) {
        $null = $missingSecrets.Add($name)
    }
}

if ($TargetEnvironment -eq "test") {
    foreach ($name in @(
        "PLAYWRIGHT_E2E_ADMIN_ACCOUNT",
        "PLAYWRIGHT_E2E_ADMIN_PASSWORD",
        "PLAYWRIGHT_E2E_MERCHANT_ACCOUNT",
        "PLAYWRIGHT_E2E_MERCHANT_PASSWORD"
    )) {
        if (-not $secrets.Contains($name)) {
            $null = $missingSecrets.Add($name)
        }
    }
}

$seoRegionsValue = Get-EnvironmentVariableValue -Name "PRERENDER_REGIONS"
$seoUrlVariables = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
if (Test-ConfiguredValue -Value $seoRegionsValue) {
    $seoRegions = @($seoRegionsValue -split '[,\s]+' |
        ForEach-Object { $_.Trim().ToUpperInvariant() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique)
    if ($seoRegions.Count -eq 0) {
        Add-InvalidVariable -Name "PRERENDER_REGIONS" -Message "must contain CN, EU, or both"
    }
    foreach ($region in $seoRegions) {
        if ($region -notin @("CN", "EU")) {
            Add-InvalidVariable -Name "PRERENDER_REGIONS" -Message "contains an unsupported region"
            continue
        }
        foreach ($name in @("PUBLIC_SITE_URL_$region", "PRERENDER_API_BASE_URL_$region")) {
            Require-EnvironmentVariable -Name $name
            $null = $seoUrlVariables.Add($name)
        }
    }
}
else {
    foreach ($name in @("PUBLIC_SITE_URL", "PRERENDER_API_BASE_URL")) {
        Require-EnvironmentVariable -Name $name
        $null = $seoUrlVariables.Add($name)
    }
}

$sshHost = Get-EnvironmentVariableValue -Name "DEPLOY_SSH_HOST"
if ((Test-ConfiguredValue -Value $sshHost) -and $sshHost -match '[\s/@]') {
    Add-InvalidVariable -Name "DEPLOY_SSH_HOST" -Message "must be a host name or IP address without scheme, path, user info, or whitespace"
}

$sshUser = Get-EnvironmentVariableValue -Name "DEPLOY_SSH_USER"
if ((Test-ConfiguredValue -Value $sshUser) -and $sshUser -notmatch '^[A-Za-z_][A-Za-z0-9._-]*[$]?$') {
    Add-InvalidVariable -Name "DEPLOY_SSH_USER" -Message "contains unsupported characters"
}

$sshPort = Get-EnvironmentVariableValue -Name "DEPLOY_SSH_PORT"
if (Test-ConfiguredValue -Value $sshPort) {
    $parsedPort = 0
    if (-not [int]::TryParse($sshPort, [ref]$parsedPort) -or $parsedPort -lt 1 -or $parsedPort -gt 65535) {
        Add-InvalidVariable -Name "DEPLOY_SSH_PORT" -Message "must be an integer between 1 and 65535"
    }
}

$remoteRoot = Get-EnvironmentVariableValue -Name "DEPLOY_REMOTE_ROOT"
if ((Test-ConfiguredValue -Value $remoteRoot) -and -not (Test-SafeAbsolutePath -Value $remoteRoot)) {
    Add-InvalidVariable -Name "DEPLOY_REMOTE_ROOT" -Message "must be a non-root safe absolute path without traversal"
}

$databaseDefaultsFile = Get-EnvironmentVariableValue -Name "DEPLOY_DB_DEFAULTS_FILE"
if ((Test-ConfiguredValue -Value $databaseDefaultsFile) -and -not (Test-SafeAbsolutePath -Value $databaseDefaultsFile -AllowRoot)) {
    Add-InvalidVariable -Name "DEPLOY_DB_DEFAULTS_FILE" -Message "must be a safe absolute path without traversal"
}

$runtimeEnvFile = Get-EnvironmentVariableValue -Name "DEPLOY_RUNTIME_ENV_FILE"
if ((Test-ConfiguredValue -Value $runtimeEnvFile) -and -not (Test-SafeAbsolutePath -Value $runtimeEnvFile -AllowRoot)) {
    Add-InvalidVariable -Name "DEPLOY_RUNTIME_ENV_FILE" -Message "must be a safe absolute path without traversal"
}

$smokeUrls = Get-EnvironmentVariableValue -Name "DEPLOY_SMOKE_URLS"
if (Test-ConfiguredValue -Value $smokeUrls) {
    $resolvedSmokeUrls = @($smokeUrls -split '[,\r\n]+' |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($resolvedSmokeUrls.Count -eq 0) {
        Add-InvalidVariable -Name "DEPLOY_SMOKE_URLS" -Message "must contain at least one HTTPS endpoint"
    }
    elseif (@($resolvedSmokeUrls | Where-Object { -not (Test-AbsoluteUrl -Value $_ -Scheme "https") }).Count -gt 0) {
        Add-InvalidVariable -Name "DEPLOY_SMOKE_URLS" -Message "all entries must be absolute HTTPS URLs without user info"
    }
}

foreach ($name in @("VITE_API_BASE_URL") + @($seoUrlVariables)) {
    $value = Get-EnvironmentVariableValue -Name $name
    if ((Test-ConfiguredValue -Value $value) -and -not (Test-AbsoluteUrl -Value $value -Scheme "https")) {
        Add-InvalidVariable -Name $name -Message "must be an absolute HTTPS URL without user info"
    }
}

if ($TargetEnvironment -eq "test") {
    foreach ($name in @(
        "REMOTE_ACCEPTANCE_WEB_BASE_URL",
        "REMOTE_ACCEPTANCE_ADMIN_BASE_URL",
        "REMOTE_ACCEPTANCE_MERCHANT_BASE_URL",
        "REMOTE_ACCEPTANCE_BACKEND_BASE_URL"
    )) {
        $value = Get-EnvironmentVariableValue -Name $name
        if ((Test-ConfiguredValue -Value $value) -and -not (Test-PublicHttpsOrigin -Value $value)) {
            Add-InvalidVariable -Name $name -Message "must be a non-loopback HTTPS origin without user info, path, query, or fragment"
        }
    }
}

$webSocketUrl = Get-EnvironmentVariableValue -Name "VITE_WS_BASE_URL"
if ((Test-ConfiguredValue -Value $webSocketUrl) -and -not (Test-AbsoluteUrl -Value $webSocketUrl -Scheme "wss" -OriginOnly)) {
    Add-InvalidVariable -Name "VITE_WS_BASE_URL" -Message "must be a WSS origin without user info, path, query, or fragment"
}

$stripePublishableKey = Get-EnvironmentVariableValue -Name "VITE_STRIPE_PUBLISHABLE_KEY"
$expectedStripePrefix = if ($TargetEnvironment -eq "prod") { "pk_live_" } else { "pk_test_" }
if ((Test-ConfiguredValue -Value $stripePublishableKey) -and -not $stripePublishableKey.StartsWith($expectedStripePrefix, [StringComparison]::Ordinal)) {
    Add-InvalidVariable -Name "VITE_STRIPE_PUBLISHABLE_KEY" -Message "must use the $expectedStripePrefix prefix for $TargetEnvironment"
}

foreach ($name in @("DEPLOY_BACKEND_SERVICE", "DEPLOY_WEB_SERVICE", "DEPLOY_ADMIN_SERVICE", "DEPLOY_MERCHANT_SERVICE")) {
    $value = Get-EnvironmentVariableValue -Name $name
    if ((Test-ConfiguredValue -Value $value) -and $value -notmatch '^[A-Za-z0-9_.@-]+$') {
        Add-InvalidVariable -Name $name -Message "contains unsupported systemd service-name characters"
    }
}

$migrationMode = Get-EnvironmentVariableValue -Name "DEPLOY_DB_MIGRATION_MODE"
if ((Test-ConfiguredValue -Value $migrationMode) -and $migrationMode -notin @("apply", "verify")) {
    Add-InvalidVariable -Name "DEPLOY_DB_MIGRATION_MODE" -Message "must be apply or verify"
}

$baselineVersion = Get-EnvironmentVariableValue -Name "DEPLOY_DB_BASELINE_VERSION"
if ((Test-ConfiguredValue -Value $baselineVersion) -and $baselineVersion -notmatch '^[0-9]+$') {
    Add-InvalidVariable -Name "DEPLOY_DB_BASELINE_VERSION" -Message "must contain only digits"
}

$retentionCount = Get-EnvironmentVariableValue -Name "DEPLOY_RELEASE_RETENTION_COUNT"
if (Test-ConfiguredValue -Value $retentionCount) {
    $parsedRetentionCount = 0
    if (-not [int]::TryParse($retentionCount, [ref]$parsedRetentionCount) -or
        $parsedRetentionCount -lt 1 -or $parsedRetentionCount -gt 100) {
        Add-InvalidVariable -Name "DEPLOY_RELEASE_RETENTION_COUNT" -Message "must be an integer between 1 and 100"
    }
}

$protectionRules = @($protection.protection_rules)
if ($TargetEnvironment -in @("pre", "prod")) {
    $requiredReviewerRules = @($protectionRules | Where-Object { $_.type -eq "required_reviewers" })
    if ($requiredReviewerRules.Count -eq 0) {
        $null = $missingProtectionRules.Add("required_reviewers")
    }
    else {
        $reviewerCount = @($requiredReviewerRules | ForEach-Object { @($_.reviewers) }).Count
        if ($reviewerCount -eq 0) {
            Add-InvalidProtectionRule -Name "required_reviewers" -Message "must contain at least one reviewer"
        }
        if (@($requiredReviewerRules | Where-Object { $_.prevent_self_review -eq $true }).Count -eq 0) {
            Add-AuditWarning -Name "prevent_self_review" -Message "release initiators can approve their own deployment"
        }
    }

    if ($protection.can_admins_bypass -eq $true) {
        Add-AuditWarning -Name "can_admins_bypass" -Message "repository administrators can bypass the environment approval gate"
    }
    $deploymentBranchPolicy = $protection.deployment_branch_policy
    if ($null -eq $deploymentBranchPolicy -or
        $deploymentBranchPolicy.protected_branches -ne $false -or
        $deploymentBranchPolicy.custom_branch_policies -ne $true) {
        Add-AuditWarning -Name "deployment_branch_policy" -Message "the environment must use the approved custom branch and tag policies"
    }
    else {
        $expectedPolicyKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $null = $expectedPolicyKeys.Add("branch:main")
        $null = $expectedPolicyKeys.Add("tag:eu-pre-rc-*")
        $observedPolicyKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $deploymentPoliciesProperty = $protection.PSObject.Properties["deployment_branch_policies"]
        $deploymentPolicies = if ($null -eq $deploymentPoliciesProperty) { @() } else { @($deploymentPoliciesProperty.Value) }
        $policyEntriesValid = $deploymentPolicies.Count -eq $expectedPolicyKeys.Count
        foreach ($policy in $deploymentPolicies) {
            $policyType = [string]$policy.type
            $policyName = [string]$policy.name
            if ($policyType -notin @("branch", "tag") -or [string]::IsNullOrWhiteSpace($policyName)) {
                $policyEntriesValid = $false
                continue
            }
            if (-not $observedPolicyKeys.Add("${policyType}:$policyName")) {
                $policyEntriesValid = $false
            }
        }
        foreach ($expectedPolicyKey in $expectedPolicyKeys) {
            if (-not $observedPolicyKeys.Contains($expectedPolicyKey)) {
                $policyEntriesValid = $false
            }
        }
        if (-not $policyEntriesValid) {
            Add-AuditWarning -Name "deployment_branch_policy" -Message "the environment deployment policies must allow only main and eu-pre-rc-*"
        }
    }
}

$missingVariableNames = @($missingVariables | Sort-Object)
$missingSecretNames = @($missingSecrets | Sort-Object)
$invalidVariableReports = @($invalidVariables | Sort-Object Name, Message)
$missingProtectionRuleNames = @($missingProtectionRules | Sort-Object)
$invalidProtectionRuleReports = @($invalidProtectionRules | Sort-Object Name, Message)
$warningReports = @($warnings | Sort-Object Name, Message)
$ready = $missingVariableNames.Count -eq 0 -and
    $missingSecretNames.Count -eq 0 -and
    $invalidVariableReports.Count -eq 0 -and
    $missingProtectionRuleNames.Count -eq 0 -and
    $invalidProtectionRuleReports.Count -eq 0

$report = [pscustomobject]@{
    SchemaVersion = 1
    Repository = $Repository
    Environment = $TargetEnvironment
    Ready = $ready
    VariablesObserved = $variables.Count
    SecretsObserved = $secrets.Count
    ProtectionRulesObserved = $protectionRules.Count
    MissingVariables = $missingVariableNames
    MissingSecrets = $missingSecretNames
    InvalidVariables = $invalidVariableReports
    MissingProtectionRules = $missingProtectionRuleNames
    InvalidProtectionRules = $invalidProtectionRuleReports
    Warnings = $warningReports
}

if ($Json) {
    $report | ConvertTo-Json -Depth 5
}
else {
    Write-Output "GitHub Environment audit: $Repository / $TargetEnvironment"
    foreach ($name in $missingVariableNames) {
        Write-Output "[missing variable] $name"
    }
    foreach ($name in $missingSecretNames) {
        Write-Output "[missing secret]   $name"
    }
    foreach ($item in $invalidVariableReports) {
        Write-Output "[invalid variable] $($item.Name): $($item.Message)"
    }
    foreach ($name in $missingProtectionRuleNames) {
        Write-Output "[missing protection] $name"
    }
    foreach ($item in $invalidProtectionRuleReports) {
        Write-Output "[invalid protection] $($item.Name): $($item.Message)"
    }
    foreach ($item in $warningReports) {
        Write-Output "[warning] $($item.Name): $($item.Message)"
    }
    if ($ready) {
        Write-Output "[ready] GitHub Environment deployment configuration is complete."
    }
    else {
        Write-Output "[blocked] Missing variables: $($missingVariableNames.Count); missing secrets: $($missingSecretNames.Count); invalid variables: $($invalidVariableReports.Count); missing protections: $($missingProtectionRuleNames.Count); invalid protections: $($invalidProtectionRuleReports.Count)."
    }
}

if (-not $ready -and -not $ReportOnly) {
    throw "GitHub Environment '$TargetEnvironment' is not ready for deployment"
}
