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
    [string]$MerchantServiceName,
    [string]$SmokeUrls,
    [string]$DatabaseDefaultsFile,
    [string]$DatabaseMigrationMode,
    [string]$DatabaseBaselineVersion,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$remotePortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("RemotePort")
$rollbackScriptPath = Join-Path $PSScriptRoot "rollback-release.ps1"

if (-not $ReleaseBundle) { $ReleaseBundle = if ($env:APP_RELEASE_BUNDLE) { $env:APP_RELEASE_BUNDLE } else { "" } }
if (-not $Environment) { $Environment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "EU" } }
if (-not $RemoteHost) { $RemoteHost = if ($env:DEPLOY_SSH_HOST) { $env:DEPLOY_SSH_HOST } else { "" } }
if (-not $remotePortWasExplicitlySupplied -and $env:DEPLOY_SSH_PORT) { $RemotePort = [int]$env:DEPLOY_SSH_PORT }
if (-not $RemoteUser) { $RemoteUser = if ($env:DEPLOY_SSH_USER) { $env:DEPLOY_SSH_USER } else { "" } }
if (-not $RemoteRoot) { $RemoteRoot = if ($env:DEPLOY_REMOTE_ROOT) { $env:DEPLOY_REMOTE_ROOT } else { "" } }
if (-not $BackendServiceName) { $BackendServiceName = if ($env:DEPLOY_BACKEND_SERVICE) { $env:DEPLOY_BACKEND_SERVICE } else { "dzdp-backend" } }
if (-not $WebServiceName) { $WebServiceName = if ($env:DEPLOY_WEB_SERVICE) { $env:DEPLOY_WEB_SERVICE } else { "dzdp-web" } }
if (-not $AdminServiceName) { $AdminServiceName = if ($env:DEPLOY_ADMIN_SERVICE) { $env:DEPLOY_ADMIN_SERVICE } else { "dzdp-admin-web" } }
if (-not $MerchantServiceName) { $MerchantServiceName = if ($env:DEPLOY_MERCHANT_SERVICE) { $env:DEPLOY_MERCHANT_SERVICE } else { "dzdp-merchant-web" } }
if (-not $SmokeUrls) { $SmokeUrls = if ($env:DEPLOY_SMOKE_URLS) { $env:DEPLOY_SMOKE_URLS } else { "" } }
if (-not $DatabaseDefaultsFile) { $DatabaseDefaultsFile = if ($env:DEPLOY_DB_DEFAULTS_FILE) { $env:DEPLOY_DB_DEFAULTS_FILE } else { "" } }
if (-not $DatabaseMigrationMode) { $DatabaseMigrationMode = if ($env:DEPLOY_DB_MIGRATION_MODE) { $env:DEPLOY_DB_MIGRATION_MODE } else { "apply" } }
if (-not $DatabaseBaselineVersion) { $DatabaseBaselineVersion = if ($env:DEPLOY_DB_BASELINE_VERSION) { $env:DEPLOY_DB_BASELINE_VERSION } else { "" } }

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

function Assert-SafeRemoteRoot {
    param([string]$Value)

    if ($Value -eq "/" -or
        $Value -notmatch '^/[A-Za-z0-9._/-]+$' -or
        $Value -match '(^|/)\.{1,2}(/|$)' -or
        $Value.Contains("//")) {
        throw "RemoteRoot must be a non-root absolute path containing only safe path segments"
    }
}

function Assert-SafeRemoteFilePath {
    param([string]$Value)

    if ($Value -notmatch '^/[A-Za-z0-9._/-]+$' -or
        $Value -match '(^|/)\.{1,2}(/|$)' -or
        $Value.Contains("//")) {
        throw "DatabaseDefaultsFile must be a safe absolute path without traversal"
    }
}

function Assert-SafeReleaseVersion {
    param([string]$Value)

    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw "Release version contains unsupported characters: $Value"
    }
}

function Assert-SafeServiceNames {
    param([string[]]$Names)

    foreach ($name in $Names) {
        if ($name -notmatch '^[A-Za-z0-9_.@-]+$') {
            throw "Service name contains unsupported characters: $name"
        }
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Upload the release bundle over SSH/SCP."
    Write-Output "2. Verify the remote bundle SHA-256 integrity before extracting it."
    Write-Output "3. Extract the bundle under a versioned releases directory below the remote root."
    Write-Output "4. Run database/mysql-migrate.sh with the secret-managed MySQL defaults file before changing current/previous or restarting services."
    Write-Output "5. Switch the remote current symlink to the new release only after migration apply/strict verification succeeds."
    Write-Output "6. Restart the backend, web, admin-web, and merchant-web services."
    Write-Output "7. Run smoke checks against the deployed environment."
    Write-Output "8. If smoke checks fail, automatically restore the tracked previous release and keep the deployment failed."
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

if ($RemotePort -lt 1 -or $RemotePort -gt 65535) {
    throw "RemotePort must be between 1 and 65535"
}
Assert-SafeRemoteRoot -Value $RemoteRoot
$RemoteRoot = $RemoteRoot.TrimEnd("/")

if ([string]::IsNullOrWhiteSpace($DatabaseDefaultsFile)) {
    throw "DatabaseDefaultsFile must be supplied directly or through DEPLOY_DB_DEFAULTS_FILE"
}
Assert-SafeRemoteFilePath -Value $DatabaseDefaultsFile
if ($DatabaseMigrationMode -notin @("apply", "verify")) {
    throw "DatabaseMigrationMode must be apply or verify"
}
if (-not [string]::IsNullOrWhiteSpace($DatabaseBaselineVersion) -and
    $DatabaseBaselineVersion -notmatch '^[0-9]+$') {
    throw "DatabaseBaselineVersion must contain only digits"
}

if (-not (Test-Path -LiteralPath $ReleaseBundle)) {
    throw "Release bundle not found: $ReleaseBundle"
}

$sshPath = (Get-Command ssh -ErrorAction Stop).Source
$scpPath = (Get-Command scp -ErrorAction Stop).Source
$resolvedBundle = (Resolve-Path -LiteralPath $ReleaseBundle).Path
$bundleName = [System.IO.Path]::GetFileName($resolvedBundle)
$bundleSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedBundle).Hash.ToLowerInvariant()
$bundleMatch = [regex]::Match($bundleName, '^dazhongdianping-release-([A-Za-z0-9][A-Za-z0-9._-]{0,127})\.zip$')
if (-not $bundleMatch.Success) {
    throw "Release bundle name must match dazhongdianping-release-<version>.zip"
}
$version = $bundleMatch.Groups[1].Value
Assert-SafeReleaseVersion -Value $version
$remoteReleaseRoot = "$RemoteRoot/releases"
$remoteReleaseDir = "$remoteReleaseRoot/$version"
$remoteBundlePath = "$RemoteRoot/$bundleName"
$remoteCurrentPath = "$RemoteRoot/current"
$remotePreviousPath = "$RemoteRoot/previous"
$remoteAddress = "$RemoteUser@$RemoteHost"
$systemdServices = @($BackendServiceName, $WebServiceName, $AdminServiceName, $MerchantServiceName) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() }
Assert-SafeServiceNames -Names $systemdServices
$restartCommand = if ($systemdServices.Count -gt 0) {
    "sudo systemctl restart " + ($systemdServices -join " ")
}
else {
    ":"
}

$migrationBaselineClause = if (-not [string]::IsNullOrWhiteSpace($DatabaseBaselineVersion)) {
    " --baseline-version '$DatabaseBaselineVersion'"
}
else {
    ""
}

Invoke-Native -FilePath $scpPath -Arguments @(
    "-P", "$RemotePort",
    $resolvedBundle,
    "${remoteAddress}:$remoteBundlePath"
)

$remoteDeployScript = @"
set -euo pipefail
printf '%s  %s\n' '$bundleSha256' '$remoteBundlePath' | sha256sum --check --status
active_release=`$(readlink -f '$remoteCurrentPath' || true)
if [ -n "`$active_release" ]; then
  case "`$active_release" in
    '$remoteReleaseRoot'/*) ;;
    *)
      echo "Current release points outside the managed releases directory" >&2
      exit 1
      ;;
  esac
fi
mkdir -p '$remoteReleaseRoot'
if [ -n "`$active_release" ] && [ "`$active_release" = '$remoteReleaseDir' ]; then
  echo "Refusing to replace the currently active release directory" >&2
  exit 1
fi
rm -rf '$remoteReleaseDir'
mkdir -p '$remoteReleaseDir'
unzip -oq '$remoteBundlePath' -d '$remoteReleaseDir'
if [ ! -x '$remoteReleaseDir/database/mysql-migrate.sh' ]; then
  chmod 755 '$remoteReleaseDir/database/mysql-migrate.sh'
fi
bash '$remoteReleaseDir/database/mysql-migrate.sh' \
  --defaults-extra-file '$DatabaseDefaultsFile' \
  --mode '$DatabaseMigrationMode' \
  --release-version '$version' \
  --lock-file '$RemoteRoot/.database-migration.lock'$migrationBaselineClause
if [ -n "`$active_release" ] && [ "`$active_release" != '$remoteReleaseDir' ]; then
  ln -sfn "`$active_release" '$remotePreviousPath'
fi
ln -sfn '$remoteReleaseDir' '$remoteCurrentPath'
$restartCommand
"@

Invoke-Native -FilePath $sshPath -Arguments @(
    "-p", "$RemotePort",
    $remoteAddress,
    "bash -lc ""$remoteDeployScript"""
)

try {
    if (-not [string]::IsNullOrWhiteSpace($SmokeUrls)) {
        foreach ($url in ($SmokeUrls -split "[,\r\n]+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            $response = Invoke-WebRequest -Uri $url.Trim() -UseBasicParsing -TimeoutSec 15
            if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 500) {
                throw "Smoke URL returned unexpected status: $($url.Trim()) => $($response.StatusCode)"
            }
        }
    }
}
catch {
    $smokeFailure = $_.Exception.Message
    try {
        & $rollbackScriptPath `
            -Environment $Environment `
            -Region $Region `
            -RemoteHost $RemoteHost `
            -RemotePort $RemotePort `
            -RemoteUser $RemoteUser `
            -RemoteRoot $RemoteRoot `
            -BackendServiceName $BackendServiceName `
            -WebServiceName $WebServiceName `
            -AdminServiceName $AdminServiceName `
            -MerchantServiceName $MerchantServiceName `
            -SmokeUrls " " |
            ForEach-Object { Write-Host $_ }
    }
    catch {
        throw "Deployment smoke checks failed: $smokeFailure. Automatic rollback also failed: $($_.Exception.Message)"
    }
    throw "Deployment smoke checks failed and the previous release was automatically restored: $smokeFailure"
}

Write-Output "deployed $version to $Environment/$Region"
