param(
    [string]$ReleaseBundle,
    [string]$Environment,
    [string]$Region,
    [string]$RemoteHost,
    [int]$RemotePort = 22,
    [string]$RemoteUser,
    [string]$RemoteRoot,
    [string]$BackendServiceName,
    [string]$WebServiceName,
    [string]$AdminServiceName,
    [string]$SmokeUrls,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $ReleaseBundle) { $ReleaseBundle = if ($env:APP_RELEASE_BUNDLE) { $env:APP_RELEASE_BUNDLE } else { "" } }
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
    Write-Output "1. Upload the release bundle over SSH/SCP."
    Write-Output "2. Extract the bundle under a versioned releases directory below the remote root."
    Write-Output "3. Switch the remote current symlink to the new release."
    Write-Output "4. Restart the backend, web, and admin-web services."
    Write-Output "5. Run smoke checks against the deployed environment."
    exit 0
}

foreach ($pair in @{
    "ReleaseBundle" = $ReleaseBundle
    "Environment" = $Environment
    "RemoteHost" = $RemoteHost
    "RemoteUser" = $RemoteUser
    "RemoteRoot" = $RemoteRoot
}.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($pair.Value)) {
        throw "$($pair.Key) must be supplied directly or through DEPLOY_* environment variables"
    }
}

if (-not (Test-Path -LiteralPath $ReleaseBundle)) {
    throw "Release bundle not found: $ReleaseBundle"
}

$sshPath = (Get-Command ssh -ErrorAction Stop).Source
$scpPath = (Get-Command scp -ErrorAction Stop).Source
$resolvedBundle = (Resolve-Path -LiteralPath $ReleaseBundle).Path
$bundleName = [System.IO.Path]::GetFileName($resolvedBundle)
$version = [System.IO.Path]::GetFileNameWithoutExtension($bundleName).Replace("dazhongdianping-release-", "")
$remoteReleaseRoot = "$RemoteRoot/releases"
$remoteReleaseDir = "$remoteReleaseRoot/$version"
$remoteBundlePath = "$RemoteRoot/$bundleName"
$remoteCurrentPath = "$RemoteRoot/current"
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

Invoke-Native -FilePath $scpPath -Arguments @(
    "-P", "$RemotePort",
    $resolvedBundle,
    "${remoteAddress}:$remoteBundlePath"
)

$remoteDeployScript = @"
set -euo pipefail
mkdir -p '$remoteReleaseRoot'
rm -rf '$remoteReleaseDir'
mkdir -p '$remoteReleaseDir'
unzip -oq '$remoteBundlePath' -d '$remoteReleaseDir'
ln -sfn '$remoteReleaseDir' '$remoteCurrentPath'
$restartCommand
"@

Invoke-Native -FilePath $sshPath -Arguments @(
    "-p", "$RemotePort",
    $remoteAddress,
    "bash -lc ""$remoteDeployScript"""
)

if (-not [string]::IsNullOrWhiteSpace($SmokeUrls)) {
    foreach ($url in ($SmokeUrls -split "[,\r\n]+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $response = Invoke-WebRequest -Uri $url.Trim() -UseBasicParsing -TimeoutSec 15
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 500) {
            throw "Smoke URL returned unexpected status: $($url.Trim()) => $($response.StatusCode)"
        }
    }
}

Write-Output "deployed $version to $Environment/$Region"
