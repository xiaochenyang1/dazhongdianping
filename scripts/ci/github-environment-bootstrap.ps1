[CmdletBinding()]
param(
    [Alias("Environment")]
    [ValidateSet("test", "pre", "prod")]
    [string]$TargetEnvironment = "pre",
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,
    [string]$Repository,
    [switch]$Apply,
    [switch]$AllowProduction,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$preflightPath = Join-Path $PSScriptRoot "github-environment-preflight.ps1"

function Assert-OnlyProperties {
    param(
        [AllowNull()][object]$Value,
        [string[]]$Allowed,
        [string]$Context
    )

    if ($null -eq $Value) {
        throw "$Context must be supplied"
    }
    foreach ($name in @($Value.PSObject.Properties.Name)) {
        if ($name -notin $Allowed) {
            throw "$Context contains unsupported property '$name'"
        }
    }
}

function Assert-RequiredProperties {
    param(
        [object]$Value,
        [string[]]$Required,
        [string]$Context
    )

    foreach ($name in $Required) {
        if ($null -eq $Value.PSObject.Properties[$name]) {
            throw "$Context is missing required property '$name'"
        }
    }
}

function Test-ConfiguredValue {
    param([AllowNull()][string]$Value)

    return -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notmatch 'CHANGE_ME' -and
        $Value -notmatch 'xxxxx'
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
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($origin)) {
        throw "Repository must be supplied when the current Git origin cannot be resolved"
    }
    if ($origin -match 'github[.]com[:/](?<repository>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+?)(?:[.]git)?$') {
        return $Matches.repository
    }
    throw "Repository must be supplied when origin is not a GitHub repository"
}

function Test-PathInsideRepository {
    param([string]$Path)

    $relative = [IO.Path]::GetRelativePath($repoRoot, [IO.Path]::GetFullPath($Path))
    return -not [IO.Path]::IsPathRooted($relative) -and
        $relative -ne ".." -and
        -not $relative.StartsWith("..$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::Ordinal)
}

function Test-GitTrackedPath {
    param([string]$Path)

    if (-not (Test-PathInsideRepository -Path $Path)) {
        return $false
    }
    $relative = [IO.Path]::GetRelativePath($repoRoot, [IO.Path]::GetFullPath($Path)).Replace('\', '/')
    & git -C $repoRoot ls-files --error-unmatch -- $relative *> $null
    return $LASTEXITCODE -eq 0
}

function Assert-PrivateKeyPermissions {
    param([string]$Path)

    if ([Environment]::OSVersion.Platform -eq "Win32NT") {
        return
    }
    $mode = [IO.File]::GetUnixFileMode($Path)
    $unsafe = [IO.UnixFileMode]::GroupRead -bor
        [IO.UnixFileMode]::GroupWrite -bor
        [IO.UnixFileMode]::GroupExecute -bor
        [IO.UnixFileMode]::OtherRead -bor
        [IO.UnixFileMode]::OtherWrite -bor
        [IO.UnixFileMode]::OtherExecute
    if (($mode -band $unsafe) -ne 0) {
        throw "Secret file for DEPLOY_SSH_PRIVATE_KEY must not grant group or other permissions"
    }
}

function Invoke-GhProcess {
    param(
        [string]$GhPath,
        [string[]]$Arguments,
        [AllowNull()][string]$StandardInput,
        [string]$Operation
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $GhPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $null -ne $StandardInput
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Unable to start GitHub CLI operation '$Operation'"
        }
        if ($null -ne $StandardInput) {
            $process.StandardInput.Write($StandardInput)
            $process.StandardInput.Close()
        }
        $standardOutput = $process.StandardOutput.ReadToEnd()
        $null = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "GitHub CLI operation '$Operation' failed with exit code $($process.ExitCode)"
        }
        return $standardOutput.Trim()
    }
    finally {
        $process.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $preflightPath -PathType Leaf)) {
    throw "GitHub Environment preflight script is missing"
}
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "ConfigPath must point to an existing file"
}

$resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
try {
    $config = Get-Content -LiteralPath $resolvedConfigPath -Raw | ConvertFrom-Json -Depth 20
}
catch {
    throw "GitHub Environment bootstrap config is invalid JSON"
}
Assert-OnlyProperties -Value $config -Allowed @(
    "schemaVersion", "environment", "region", "variables", "secretFiles", "protection"
) -Context "Config"
Assert-RequiredProperties -Value $config -Required @(
    "schemaVersion", "environment", "region", "variables", "secretFiles", "protection"
) -Context "Config"

if ($config.schemaVersion -isnot [long] -or [long]$config.schemaVersion -ne 1) {
    throw "Config schemaVersion must be 1"
}
if ($config.environment -isnot [string] -or [string]$config.environment -cne $TargetEnvironment) {
    throw "Config environment must exactly match TargetEnvironment"
}
if ($config.region -isnot [string]) {
    throw "Config region must be CN or EU"
}
$region = ([string]$config.region).Trim().ToUpperInvariant()
if ($region -notin @("CN", "EU")) {
    throw "Config region must be CN or EU"
}
if ($TargetEnvironment -eq "test" -and $region -ne "EU") {
    throw "The test environment is fixed to region EU"
}

$allowedVariableNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($name in @(
    "DEPLOY_SSH_HOST",
    "DEPLOY_SSH_PORT",
    "DEPLOY_SSH_USER",
    "DEPLOY_REMOTE_ROOT",
    "DEPLOY_BACKEND_SERVICE",
    "DEPLOY_WEB_SERVICE",
    "DEPLOY_ADMIN_SERVICE",
    "DEPLOY_MERCHANT_SERVICE",
    "DEPLOY_SMOKE_URLS",
    "DEPLOY_RUNTIME_ENV_FILE",
    "DEPLOY_DB_DEFAULTS_FILE",
    "DEPLOY_DB_MIGRATION_MODE",
    "DEPLOY_DB_BASELINE_VERSION",
    "DEPLOY_RELEASE_RETENTION_COUNT",
    "VITE_API_BASE_URL",
    "VITE_WS_BASE_URL",
    "VITE_STRIPE_PUBLISHABLE_KEY",
    "PUBLIC_SITE_URL",
    "PRERENDER_API_BASE_URL",
    "PRERENDER_REGIONS",
    "PUBLIC_SITE_URL_CN",
    "PRERENDER_API_BASE_URL_CN",
    "PUBLIC_SITE_URL_EU",
    "PRERENDER_API_BASE_URL_EU"
)) {
    $null = $allowedVariableNames.Add($name)
}

$sensitiveVariableNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($name in @(
    "DEPLOY_SSH_HOST",
    "DEPLOY_SSH_USER",
    "DEPLOY_REMOTE_ROOT",
    "DEPLOY_RUNTIME_ENV_FILE",
    "DEPLOY_DB_DEFAULTS_FILE"
)) {
    $null = $sensitiveVariableNames.Add($name)
}

Assert-OnlyProperties -Value $config.variables -Allowed @($allowedVariableNames) -Context "Config.variables"
$variables = [ordered]@{}
foreach ($property in @($config.variables.PSObject.Properties | Sort-Object Name)) {
    if (-not $allowedVariableNames.Contains($property.Name)) {
        throw "Config.variables contains unsupported variable '$($property.Name)'"
    }
    if ($property.Value -isnot [string] -or -not (Test-ConfiguredValue -Value ([string]$property.Value))) {
        throw "Config variable '$($property.Name)' must contain a non-placeholder string value"
    }
    $variables[$property.Name] = [string]$property.Value
}
$publicVariables = [ordered]@{}
$sensitiveValues = [ordered]@{}
foreach ($entry in $variables.GetEnumerator()) {
    if ($sensitiveVariableNames.Contains($entry.Key)) {
        $sensitiveValues[$entry.Key] = $entry.Value
    }
    else {
        $publicVariables[$entry.Key] = $entry.Value
    }
}

$allowedSecretNames = @("DEPLOY_KNOWN_HOSTS", "DEPLOY_SSH_PRIVATE_KEY")
Assert-OnlyProperties -Value $config.secretFiles -Allowed $allowedSecretNames -Context "Config.secretFiles"
$secretFiles = [ordered]@{}
$configDirectory = Split-Path -Parent $resolvedConfigPath
foreach ($property in @($config.secretFiles.PSObject.Properties | Sort-Object Name)) {
    if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        throw "Secret file for $($property.Name) must be a non-empty path"
    }
    $candidatePath = if ([IO.Path]::IsPathRooted([string]$property.Value)) {
        [string]$property.Value
    }
    else {
        Join-Path $configDirectory ([string]$property.Value)
    }
    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        throw "Secret file for $($property.Name) does not exist"
    }
    $resolvedSecretPath = (Resolve-Path -LiteralPath $candidatePath).Path
    if ([string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $resolvedSecretPath -Raw))) {
        throw "Secret file for $($property.Name) must not be empty"
    }
    if ($property.Name -eq "DEPLOY_SSH_PRIVATE_KEY") {
        Assert-PrivateKeyPermissions -Path $resolvedSecretPath
    }
    $secretFiles[$property.Name] = $resolvedSecretPath
}

Assert-OnlyProperties -Value $config.protection -Allowed @(
    "reviewers", "preventSelfReview", "canAdminsBypass", "waitTimer", "deploymentPolicies"
) -Context "Config.protection"
Assert-RequiredProperties -Value $config.protection -Required @(
    "reviewers", "preventSelfReview", "canAdminsBypass", "waitTimer", "deploymentPolicies"
) -Context "Config.protection"

if ($config.protection.reviewers -isnot [array]) {
    throw "Config.protection.reviewers must be an array"
}
if ($config.protection.preventSelfReview -isnot [bool]) {
    throw "Config.protection.preventSelfReview must be a boolean"
}
if ($config.protection.canAdminsBypass -isnot [bool]) {
    throw "Config.protection.canAdminsBypass must be a boolean"
}
if ($config.protection.waitTimer -isnot [long]) {
    throw "Config.protection.waitTimer must be an integer"
}
if ($config.protection.deploymentPolicies -isnot [array]) {
    throw "Config.protection.deploymentPolicies must be an array"
}

$reviewers = @($config.protection.reviewers | ForEach-Object { ([string]$_).Trim() })
if ($reviewers.Count -gt 6) {
    throw "Config.protection.reviewers supports at most 6 users"
}
if (@($reviewers | Where-Object { -not (Test-ConfiguredValue -Value $_) }).Count -gt 0) {
    throw "Config.protection.reviewers must not contain placeholder values"
}
if (@($reviewers | Where-Object { $_ -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$' }).Count -gt 0) {
    throw "Config.protection.reviewers contains an invalid GitHub login"
}
if (@($reviewers | Select-Object -Unique).Count -ne $reviewers.Count) {
    throw "Config.protection.reviewers must not contain duplicates"
}

$preventSelfReview = [bool]$config.protection.preventSelfReview
$canAdminsBypass = [bool]$config.protection.canAdminsBypass
$waitTimer = [long]$config.protection.waitTimer
if ($waitTimer -lt 0 -or $waitTimer -gt 43200) {
    throw "Config.protection.waitTimer must be between 0 and 43200 minutes"
}
if ($TargetEnvironment -in @("pre", "prod")) {
    if ($reviewers.Count -eq 0) {
        throw "$TargetEnvironment requires at least one deployment reviewer"
    }
    if (-not $preventSelfReview) {
        throw "$TargetEnvironment requires preventSelfReview=true"
    }
    if ($canAdminsBypass) {
        throw "$TargetEnvironment requires canAdminsBypass=false"
    }
}

$deploymentPolicies = [Collections.Generic.List[object]]::new()
$policyKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($policy in @($config.protection.deploymentPolicies)) {
    Assert-OnlyProperties -Value $policy -Allowed @("type", "name") -Context "Config.protection.deploymentPolicies entry"
    $policyType = ([string]$policy.type).Trim().ToLowerInvariant()
    $policyName = ([string]$policy.name).Trim()
    if ($policyType -notin @("branch", "tag")) {
        throw "Deployment policy type must be branch or tag"
    }
    if ($policyName -notmatch '^[A-Za-z0-9._/*-]{1,200}$' -or $policyName.Contains("..")) {
        throw "Deployment policy name contains unsupported characters"
    }
    $policyKey = "$policyType`:$policyName"
    if (-not $policyKeys.Add($policyKey)) {
        throw "Deployment policies must not contain duplicates"
    }
    $deploymentPolicies.Add([pscustomobject]@{ Type = $policyType; Name = $policyName })
}
if ($deploymentPolicies.Count -eq 0) {
    throw "At least one custom deployment branch or tag policy is required"
}

$repositoryName = Resolve-RepositoryName -ExplicitRepository $Repository

$reviewerSnapshots = @($reviewers | ForEach-Object {
    [pscustomobject]@{ type = "User"; reviewer = [pscustomobject]@{ login = $_ } }
})
$protectionRules = if ($reviewerSnapshots.Count -gt 0) {
    @([pscustomobject]@{
        type = "required_reviewers"
        prevent_self_review = $preventSelfReview
        reviewers = $reviewerSnapshots
    })
}
else {
    @()
}
$protectionSnapshot = [pscustomobject]@{
    protection_rules = $protectionRules
    can_admins_bypass = $canAdminsBypass
    deployment_branch_policy = [pscustomobject]@{
        protected_branches = $false
        custom_branch_policies = $true
    }
}
$variablesJson = @($variables.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ name = $_.Key; value = $_.Value }
}) | ConvertTo-Json -Compress
$secretNames = @(@($sensitiveValues.Keys) + @($secretFiles.Keys))
$secretsJson = @($secretNames | ForEach-Object {
    [pscustomobject]@{ name = $_ }
}) | ConvertTo-Json -Compress
$protectionJson = $protectionSnapshot | ConvertTo-Json -Depth 8 -Compress
$desiredAudit = & $preflightPath `
    -Environment $TargetEnvironment `
    -Repository $repositoryName `
    -VariablesJson $variablesJson `
    -SecretsJson $secretsJson `
    -ProtectionJson $protectionJson `
    -ReportOnly `
    -Json | ConvertFrom-Json
if (-not $desiredAudit.Ready) {
    $missing = @($desiredAudit.MissingVariables) + @($desiredAudit.MissingSecrets) + @($desiredAudit.MissingProtectionRules)
    $invalid = @($desiredAudit.InvalidVariables.Name) + @($desiredAudit.InvalidProtectionRules.Name)
    throw "Bootstrap configuration is not deployment-ready (missing: $($missing -join ', '); invalid: $($invalid -join ', '))"
}

$actionNames = [Collections.Generic.List[string]]::new()
$actionNames.Add("environment-protection")
foreach ($policy in $deploymentPolicies) { $actionNames.Add("deployment-policy:$($policy.Type):$($policy.Name)") }
foreach ($name in $publicVariables.Keys) { $actionNames.Add("variable:$name") }
foreach ($name in $sensitiveValues.Keys) { $actionNames.Add("secret:$name") }
foreach ($name in $secretFiles.Keys) { $actionNames.Add("secret:$name") }
if (-not $canAdminsBypass) {
    $actionNames.Add("manual:verify-admin-bypass-disabled")
}
$actionNames.Add("post-apply-audit")

$postApplyReady = $null
$remainingManualActions = if ($canAdminsBypass) {
    @()
}
else {
    @("verify can_admins_bypass=false in GitHub Environment settings")
}
if ($Apply) {
    if ($TargetEnvironment -eq "prod" -and -not $AllowProduction) {
        throw "Applying the prod environment requires -AllowProduction"
    }
    if (Test-GitTrackedPath -Path $resolvedConfigPath) {
        throw "Apply refuses a tracked bootstrap config; copy it to an ignored or external private path"
    }
    foreach ($entry in $secretFiles.GetEnumerator()) {
        if (Test-GitTrackedPath -Path $entry.Value) {
            throw "Apply refuses a Git-tracked secret file for $($entry.Key)"
        }
    }

    $ghCommand = Get-Command gh -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $ghPath = $ghCommand.Source
    $reviewerPayloads = [Collections.Generic.List[object]]::new()
    foreach ($login in $reviewers) {
        $reviewerIdText = Invoke-GhProcess -GhPath $ghPath `
            -Arguments @("api", "users/$login", "--jq", ".id") `
            -StandardInput $null `
            -Operation "resolve deployment reviewer"
        $reviewerId = 0L
        if (-not [long]::TryParse($reviewerIdText, [ref]$reviewerId) -or $reviewerId -le 0) {
            throw "GitHub reviewer lookup returned an invalid user ID"
        }
        $reviewerPayloads.Add([pscustomobject]@{ type = "User"; id = $reviewerId })
    }

    $environmentPayload = [ordered]@{
        wait_timer = $waitTimer
        prevent_self_review = $preventSelfReview
        reviewers = @($reviewerPayloads)
        deployment_branch_policy = [ordered]@{
            protected_branches = $false
            custom_branch_policies = $true
        }
    } | ConvertTo-Json -Depth 6 -Compress
    Invoke-GhProcess -GhPath $ghPath `
        -Arguments @("api", "--method", "PUT", "repos/$repositoryName/environments/$TargetEnvironment", "--input", "-") `
        -StandardInput $environmentPayload `
        -Operation "create or update environment protection" | Out-Null

    $policyListText = Invoke-GhProcess -GhPath $ghPath `
        -Arguments @("api", "repos/$repositoryName/environments/$TargetEnvironment/deployment-branch-policies?per_page=100") `
        -StandardInput $null `
        -Operation "list deployment policies"
    $existingPolicies = @()
    if (-not [string]::IsNullOrWhiteSpace($policyListText)) {
        $existingPolicies = @((ConvertFrom-Json -InputObject $policyListText -Depth 8).branch_policies)
    }
    foreach ($policy in $deploymentPolicies) {
        $alreadyExists = @($existingPolicies | Where-Object {
            [string]$_.name -ceq $policy.Name -and
                ([string]::IsNullOrWhiteSpace([string]$_.type) -or [string]$_.type -ceq $policy.Type)
        }).Count -gt 0
        if (-not $alreadyExists) {
            $policyPayload = [ordered]@{ name = $policy.Name; type = $policy.Type } |
                ConvertTo-Json -Compress
            Invoke-GhProcess -GhPath $ghPath `
                -Arguments @("api", "--method", "POST", "repos/$repositoryName/environments/$TargetEnvironment/deployment-branch-policies", "--input", "-") `
                -StandardInput $policyPayload `
                -Operation "create deployment policy" | Out-Null
        }
    }

    foreach ($entry in $publicVariables.GetEnumerator()) {
        Invoke-GhProcess -GhPath $ghPath `
            -Arguments @("variable", "set", $entry.Key, "--repo", $repositoryName, "--env", $TargetEnvironment) `
            -StandardInput $entry.Value `
            -Operation "set environment variable $($entry.Key)" | Out-Null
    }
    foreach ($entry in $sensitiveValues.GetEnumerator()) {
        Invoke-GhProcess -GhPath $ghPath `
            -Arguments @("secret", "set", $entry.Key, "--repo", $repositoryName, "--env", $TargetEnvironment) `
            -StandardInput $entry.Value `
            -Operation "set environment secret $($entry.Key)" | Out-Null
    }
    foreach ($entry in $secretFiles.GetEnumerator()) {
        $secretValue = Get-Content -LiteralPath $entry.Value -Raw
        try {
            Invoke-GhProcess -GhPath $ghPath `
                -Arguments @("secret", "set", $entry.Key, "--repo", $repositoryName, "--env", $TargetEnvironment) `
                -StandardInput $secretValue `
                -Operation "set environment secret $($entry.Key)" | Out-Null
        }
        finally {
            $secretValue = $null
        }
    }

    $liveAudit = & $preflightPath `
        -Environment $TargetEnvironment `
        -Repository $repositoryName `
        -ReportOnly `
        -Json | ConvertFrom-Json
    if (-not [bool]$liveAudit.Ready) {
        throw "Post-apply GitHub Environment audit is not ready"
    }
    if (-not $canAdminsBypass) {
        $liveEnvironmentText = Invoke-GhProcess -GhPath $ghPath `
            -Arguments @("api", "repos/$repositoryName/environments/$TargetEnvironment") `
            -StandardInput $null `
            -Operation "verify administrator bypass setting"
        $liveEnvironment = ConvertFrom-Json -InputObject $liveEnvironmentText -Depth 8
        if ($liveEnvironment.can_admins_bypass -eq $false) {
            $remainingManualActions = @()
        }
    }
    $postApplyReady = $remainingManualActions.Count -eq 0

    $livePolicyListText = Invoke-GhProcess -GhPath $ghPath `
        -Arguments @("api", "repos/$repositoryName/environments/$TargetEnvironment/deployment-branch-policies?per_page=100") `
        -StandardInput $null `
        -Operation "verify deployment policies"
    $livePolicies = @((ConvertFrom-Json -InputObject $livePolicyListText -Depth 8).branch_policies)
    foreach ($policy in $deploymentPolicies) {
        if (@($livePolicies | Where-Object {
            [string]$_.name -ceq $policy.Name -and
                ([string]::IsNullOrWhiteSpace([string]$_.type) -or [string]$_.type -ceq $policy.Type)
        }).Count -eq 0) {
            throw "Post-apply deployment policy verification failed"
        }
    }
}

$report = [pscustomobject]@{
    SchemaVersion = 1
    Mode = if ($Apply) { "Apply" } else { "Plan" }
    Repository = $repositoryName
    Environment = $TargetEnvironment
    Region = $region
    ConfigurationReady = $true
    Applied = [bool]$Apply
    PostApplyReady = $postApplyReady
    VariableNames = @($publicVariables.Keys)
    SecretNames = $secretNames
    ReviewerCount = $reviewers.Count
    DeploymentPolicies = @($deploymentPolicies | ForEach-Object { "$($_.Type):$($_.Name)" })
    Actions = @($actionNames)
    ManualActions = @($remainingManualActions)
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
}
else {
    Write-Output "GitHub Environment bootstrap $($report.Mode): $repositoryName / $TargetEnvironment / $region"
    Write-Output "[plan] create or update environment protection with $($reviewers.Count) reviewer(s)"
    foreach ($policy in $report.DeploymentPolicies) { Write-Output "[plan] ensure deployment policy $policy" }
    foreach ($name in $report.VariableNames) { Write-Output "[plan] upsert variable $name" }
    foreach ($name in $report.SecretNames) { Write-Output "[plan] upsert secret $name" }
    foreach ($manualAction in $report.ManualActions) { Write-Output "[manual] $manualAction" }
    Write-Output "[plan] run the live GitHub Environment preflight after apply"
    if ($Apply) {
        if ($postApplyReady) {
            Write-Output "[applied] GitHub Environment is ready according to the live preflight."
        }
        else {
            Write-Output "[applied] Supported settings were applied; the environment still requires the listed manual hardening action."
        }
    }
    else {
        Write-Output "[plan only] No GitHub state was changed. Re-run with -Apply after reviewing the plan."
    }
}
