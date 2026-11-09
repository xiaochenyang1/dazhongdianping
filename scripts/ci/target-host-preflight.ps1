[CmdletBinding()]
param(
    [Alias("Environment")]
    [ValidateSet("test", "pre", "prod")]
    [string]$TargetEnvironment,
    [ValidateSet("CN", "EU")]
    [string]$Region,
    [string]$RemoteHost,
    [int]$RemotePort = 22,
    [string]$RemoteUser,
    [string]$RemoteRoot,
    [string]$RuntimeEnvFile,
    [string]$DatabaseDefaultsFile,
    [string]$BackendServiceName,
    [string]$WebServiceName,
    [string]$AdminServiceName,
    [string]$MerchantServiceName,
    [int]$MinimumFreeMegabytes = 2048,
    [switch]$ReportOnly,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$remoteScriptPath = Join-Path $PSScriptRoot "target-host-preflight.sh"
$remotePortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("RemotePort")

if (-not $TargetEnvironment) { $TargetEnvironment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "EU" } }
if (-not $RemoteHost) { $RemoteHost = if ($env:DEPLOY_SSH_HOST) { $env:DEPLOY_SSH_HOST } else { "" } }
if (-not $remotePortWasExplicitlySupplied -and $env:DEPLOY_SSH_PORT) { $RemotePort = [int]$env:DEPLOY_SSH_PORT }
if (-not $RemoteUser) { $RemoteUser = if ($env:DEPLOY_SSH_USER) { $env:DEPLOY_SSH_USER } else { "" } }
if (-not $RemoteRoot) { $RemoteRoot = if ($env:DEPLOY_REMOTE_ROOT) { $env:DEPLOY_REMOTE_ROOT } else { "" } }
if (-not $RuntimeEnvFile) { $RuntimeEnvFile = if ($env:DEPLOY_RUNTIME_ENV_FILE) { $env:DEPLOY_RUNTIME_ENV_FILE } else { "" } }
if (-not $DatabaseDefaultsFile) { $DatabaseDefaultsFile = if ($env:DEPLOY_DB_DEFAULTS_FILE) { $env:DEPLOY_DB_DEFAULTS_FILE } else { "" } }
if (-not $BackendServiceName) { $BackendServiceName = if ($env:DEPLOY_BACKEND_SERVICE) { $env:DEPLOY_BACKEND_SERVICE } else { "dzdp-backend" } }
if (-not $WebServiceName) { $WebServiceName = if ($env:DEPLOY_WEB_SERVICE) { $env:DEPLOY_WEB_SERVICE } else { "dzdp-web" } }
if (-not $AdminServiceName) { $AdminServiceName = if ($env:DEPLOY_ADMIN_SERVICE) { $env:DEPLOY_ADMIN_SERVICE } else { "dzdp-admin-web" } }
if (-not $MerchantServiceName) { $MerchantServiceName = if ($env:DEPLOY_MERCHANT_SERVICE) { $env:DEPLOY_MERCHANT_SERVICE } else { "dzdp-merchant-web" } }

function Assert-SafeAbsolutePath {
    param([string]$Value, [string]$Name)

    if ($Value -eq "/" -or
        $Value -notmatch '^/[A-Za-z0-9._/-]+$' -or
        $Value -match '(^|/)\.{1,2}(/|$)' -or
        $Value.Contains("//")) {
        throw "$Name must be a non-root safe absolute path"
    }
}

if (-not (Test-Path -LiteralPath $remoteScriptPath -PathType Leaf)) {
    throw "Target-host remote preflight script is missing"
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
if ([string]::IsNullOrWhiteSpace($RemoteHost) -or $RemoteHost -match '[\s/@]') {
    throw "RemoteHost must be a host name or IP address without scheme, path, user info, or whitespace"
}
if ($RemotePort -lt 1 -or $RemotePort -gt 65535) {
    throw "RemotePort must be between 1 and 65535"
}
if ($RemoteUser -notmatch '^[A-Za-z_][A-Za-z0-9._-]*[$]?$') {
    throw "RemoteUser contains unsupported characters"
}
Assert-SafeAbsolutePath -Value $RemoteRoot -Name "RemoteRoot"
Assert-SafeAbsolutePath -Value $RuntimeEnvFile -Name "RuntimeEnvFile"
Assert-SafeAbsolutePath -Value $DatabaseDefaultsFile -Name "DatabaseDefaultsFile"
if ($MinimumFreeMegabytes -lt 256 -or $MinimumFreeMegabytes -gt 1048576) {
    throw "MinimumFreeMegabytes must be between 256 and 1048576"
}

$services = @($BackendServiceName, $WebServiceName, $AdminServiceName, $MerchantServiceName) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() }
if ($services.Count -eq 0) {
    throw "At least one deployment service must be configured"
}
if (@($services | Where-Object { $_ -notmatch '^[A-Za-z0-9_.@-]+$' }).Count -gt 0) {
    throw "Deployment service names contain unsupported characters"
}

if ($DryRun) {
    $dryRunReport = [pscustomobject]@{
        SchemaVersion = 1
        Mode = "DryRun"
        Environment = $TargetEnvironment
        Region = $Region
        MutatesTarget = $false
        CheckGroups = @(
            "operating-system", "deployment-tools", "release-layout", "disk-space",
            "private-file-permissions", "runtime-config", "mysql-connectivity",
            "systemd-services", "sudo-policy", "dependency-connectivity"
        )
    }
    if ($Json) {
        $dryRunReport | ConvertTo-Json -Depth 5
    }
    else {
        Write-Output "Target-host preflight DryRun: $TargetEnvironment/$Region"
        Write-Output "[plan only] One SSH session will run read-only checks; no target state will be changed."
        foreach ($group in $dryRunReport.CheckGroups) { Write-Output "[plan] $group" }
    }
    exit 0
}

$sshPath = (Get-Command ssh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$arguments = [Collections.Generic.List[string]]::new()
foreach ($argument in @(
    "-T", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=15", "-p", "$RemotePort", "--",
    "$RemoteUser@$RemoteHost", "bash", "-s", "--",
    "--environment", $TargetEnvironment,
    "--region", $Region,
    "--remote-root", $RemoteRoot,
    "--runtime-env-file", $RuntimeEnvFile,
    "--database-defaults-file", $DatabaseDefaultsFile,
    "--minimum-free-kb", "$($MinimumFreeMegabytes * 1024)"
)) {
    $arguments.Add($argument)
}
foreach ($service in $services) {
    $arguments.Add("--service")
    $arguments.Add($service)
}

$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $sshPath
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardInput = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
foreach ($argument in $arguments) { $startInfo.ArgumentList.Add($argument) }

$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) {
        throw "Unable to start target-host SSH preflight"
    }
    $remoteScript = Get-Content -LiteralPath $remoteScriptPath -Raw
    $process.StandardInput.Write($remoteScript.Replace("`r`n", "`n"))
    $process.StandardInput.Close()
    $standardOutput = $process.StandardOutput.ReadToEnd()
    $null = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $exitCode = $process.ExitCode
}
finally {
    $process.Dispose()
}

$checks = [Collections.Generic.List[object]]::new()
$summary = $null
foreach ($line in @($standardOutput -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
    $parts = @($line -split "`t", 4)
    if ($parts[0] -eq "CHECK" -and $parts.Count -eq 4 -and $parts[1] -in @("PASS", "FAIL", "WARN")) {
        $checks.Add([pscustomobject]@{
            Name = $parts[2]
            Status = $parts[1]
            Message = $parts[3]
        })
    }
    elseif ($parts[0] -eq "SUMMARY" -and $parts.Count -eq 4) {
        $summary = [pscustomobject]@{
            Passed = [int]$parts[1]
            Failed = [int]$parts[2]
            Warnings = [int]$parts[3]
        }
    }
    else {
        throw "Target-host preflight returned an invalid report protocol"
    }
}
if ($null -eq $summary -or $checks.Count -eq 0) {
    throw "Target-host preflight did not return a complete report"
}
if ($exitCode -notin @(0, 1)) {
    throw "Target-host SSH preflight failed with exit code $exitCode"
}
if (($summary.Passed + $summary.Failed + $summary.Warnings) -ne $checks.Count) {
    throw "Target-host preflight summary does not match its checks"
}

$ready = $summary.Failed -eq 0 -and $exitCode -eq 0
$report = [pscustomobject]@{
    SchemaVersion = 1
    Environment = $TargetEnvironment
    Region = $Region
    Ready = $ready
    MutatedTarget = $false
    Passed = $summary.Passed
    Failed = $summary.Failed
    Warnings = $summary.Warnings
    Checks = @($checks)
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
}
else {
    Write-Output "Target-host preflight: $TargetEnvironment/$Region"
    foreach ($check in $checks) {
        Write-Output "[$($check.Status.ToLowerInvariant())] $($check.Name): $($check.Message)"
    }
    if ($ready) {
        Write-Output "[ready] Target host satisfies the read-only deployment preflight."
    }
    else {
        Write-Output "[blocked] Passed: $($summary.Passed); failed: $($summary.Failed); warnings: $($summary.Warnings)."
    }
}

if (-not $ready -and -not $ReportOnly) {
    throw "Target host '$TargetEnvironment/$Region' is not ready for deployment"
}
