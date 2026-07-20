param(
    [string]$Environment,
    [string]$Region,
    [string]$RemoteHost,
    [int]$RemotePort = 22,
    [string]$RemoteUser,
    [string]$RemoteRoot,
    [string]$TargetVersion,
    [string]$BackendServiceName,
    [string]$WebServiceName,
    [string]$AdminServiceName,
    [string]$SmokeUrls,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $Environment) { $Environment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "CN" } }
if (-not $RemoteHost) { $RemoteHost = if ($env:DEPLOY_SSH_HOST) { $env:DEPLOY_SSH_HOST } else { "" } }
if (-not $RemoteUser) { $RemoteUser = if ($env:DEPLOY_SSH_USER) { $env:DEPLOY_SSH_USER } else { "" } }
if (-not $RemoteRoot) { $RemoteRoot = if ($env:DEPLOY_REMOTE_ROOT) { $env:DEPLOY_REMOTE_ROOT } else { "" } }
if (-not $BackendServiceName) { $BackendServiceName = if ($env:DEPLOY_BACKEND_SERVICE) { $env:DEPLOY_BACKEND_SERVICE } else { "dzdp-backend" } }
if (-not $WebServiceName) { $WebServiceName = if ($env:DEPLOY_WEB_SERVICE) { $env:DEPLOY_WEB_SERVICE } else { "dzdp-web" } }
if (-not $AdminServiceName) { $AdminServiceName = if ($env:DEPLOY_ADMIN_SERVICE) { $env:DEPLOY_ADMIN_SERVICE } else { "dzdp-admin-web" } }
if (-not $SmokeUrls) { $SmokeUrls = if ($env:DEPLOY_SMOKE_URLS) { $env:DEPLOY_SMOKE_URLS } else { "" } }

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath exited with code $LASTEXITCODE"
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Resolve the requested or previous stable release on the remote host."
    Write-Output "2. Point the remote current symlink back to the previous stable release."
    Write-Output "3. Restart the backend, web, and admin-web services."
    Write-Output "4. Run smoke checks after rollback."
    exit 0
}

foreach ($pair in @{
    "Environment" = $Environment
    "RemoteHost" = $RemoteHost
    "RemoteUser" = $RemoteUser
    "RemoteRoot" = $RemoteRoot
}.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($pair.Value)) {
        throw "$($pair.Key) must be supplied directly or through DEPLOY_* environment variables"
    }
}

$sshPath = (Get-Command ssh -ErrorAction Stop).Source
$remoteAddress = "$RemoteUser@$RemoteHost"
$systemdServices = @($BackendServiceName, $WebServiceName, $AdminServiceName) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() }
$restartCommand = if ($systemdServices.Count -gt 0) {
    "sudo systemctl restart " + ($systemdServices -join " ")
}
else {
    ":"
}

$targetClause = if ([string]::IsNullOrWhiteSpace($TargetVersion)) {
    @"
versions=`$(find '$RemoteRoot/releases' -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
target=`$(printf '%s\n' "`$versions" | tail -n 2 | head -n 1)
if [ -z "`$target" ]; then
  echo "No previous stable release found" >&2
  exit 1
fi
"@
}
else {
    "target='$TargetVersion'"
}

$remoteRollbackScript = @"
set -euo pipefail
$targetClause
if [ ! -d '$RemoteRoot/releases/'"`$target" ]; then
  echo "Target release not found: `"${target}" >&2
  exit 1
fi
ln -sfn '$RemoteRoot/releases/'"`$target" '$RemoteRoot/current'
$restartCommand
echo `"${target}"
"@

$rolledBackVersion = Invoke-Native -FilePath $sshPath -Arguments @(
    "-p", "$RemotePort",
    $remoteAddress,
    "bash -lc ""$remoteRollbackScript"""
)

if (-not [string]::IsNullOrWhiteSpace($SmokeUrls)) {
    foreach ($url in ($SmokeUrls -split "[,\r\n]+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $response = Invoke-WebRequest -Uri $url.Trim() -UseBasicParsing -TimeoutSec 15
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 500) {
            throw "Smoke URL returned unexpected status after rollback: $($url.Trim()) => $($response.StatusCode)"
        }
    }
}

Write-Output "rolled back to $($rolledBackVersion -join '') in $Environment/$Region"
