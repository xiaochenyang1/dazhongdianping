param(
    [string]$Environment,
    [string]$Region,
    [string]$RemoteHost,
    [int]$RemotePort = 22,
    [string]$RemoteUser,
    [string]$RemoteRoot,
    [string]$TargetVersion,
    [string]$ExpectedCurrentVersion,
    [string]$ExpectedDeploymentId,
    [string]$BackendServiceName,
    [string]$WebServiceName,
    [string]$AdminServiceName,
    [string]$MerchantServiceName,
    [string]$SmokeUrls,
    [int]$ReleaseRetentionCount = 5,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$remotePortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("RemotePort")

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
if (-not $PSBoundParameters.ContainsKey("ReleaseRetentionCount") -and $env:DEPLOY_RELEASE_RETENTION_COUNT) {
    $ReleaseRetentionCount = [int]$env:DEPLOY_RELEASE_RETENTION_COUNT
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$InputScript
    )

    if ($PSBoundParameters.ContainsKey('InputScript')) {
        $InputScript.Replace("`r`n", "`n") | & $FilePath @Arguments
    }
    else {
        & $FilePath @Arguments
    }
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

function Get-ValidatedSmokeUrls {
    param([string]$Value)

    $urls = @($Value -split "[,\r\n]+" |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($urls.Count -eq 0) {
        throw "SmokeUrls must contain at least one HTTPS endpoint"
    }
    foreach ($url in $urls) {
        $uri = $null
        if (-not [System.Uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne "https" -or
            [string]::IsNullOrWhiteSpace($uri.Host) -or
            -not [string]::IsNullOrWhiteSpace($uri.UserInfo)) {
            throw "Smoke URL must be an absolute HTTPS URL without user info: $url"
        }
    }
    return $urls
}

function Invoke-SmokeChecks {
    param([string[]]$Urls)

    foreach ($url in $Urls) {
        $lastFailure = "no response"
        $passed = $false
        for ($attempt = 1; $attempt -le 6; $attempt++) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15
                if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
                    $passed = $true
                    break
                }
                $lastFailure = "HTTP $($response.StatusCode)"
            }
            catch {
                $lastFailure = $_.Exception.Message
            }
            if ($attempt -lt 6) {
                Start-Sleep -Seconds 5
            }
        }
        if (-not $passed) {
            throw "Smoke URL did not return 2xx after 6 attempts: $url ($lastFailure)"
        }
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Resolve only the requested or tracked previous stable release; never select an arbitrary unverified directory."
    Write-Output "2. Preserve the currently active release as the next previous target."
    Write-Output "3. Point the remote current symlink back to the selected release."
    Write-Output "4. Restart the backend, web, admin-web, and merchant-web services."
    Write-Output "5. Run smoke checks after rollback."
    Write-Output "6. After successful smoke checks, retain current, previous, and $ReleaseRetentionCount older releases and remove stale bundles."
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

if ($RemotePort -lt 1 -or $RemotePort -gt 65535) {
    throw "RemotePort must be between 1 and 65535"
}
if ($ReleaseRetentionCount -lt 1 -or $ReleaseRetentionCount -gt 100) {
    throw "ReleaseRetentionCount must be between 1 and 100"
}
Assert-SafeRemoteRoot -Value $RemoteRoot
$RemoteRoot = $RemoteRoot.TrimEnd("/")
if (-not [string]::IsNullOrWhiteSpace($TargetVersion)) {
    Assert-SafeReleaseVersion -Value $TargetVersion
}
if ($ExpectedCurrentVersion) { Assert-SafeReleaseVersion -Value $ExpectedCurrentVersion }
if (($ExpectedCurrentVersion -and $ExpectedDeploymentId -notmatch '^[0-9a-f]{32}$') -or
    ($ExpectedDeploymentId -and -not $ExpectedCurrentVersion)) {
    throw 'Automatic recovery requires both ExpectedCurrentVersion and a 32-character ExpectedDeploymentId'
}
$validatedSmokeUrls = @(Get-ValidatedSmokeUrls -Value $SmokeUrls)

$sshPath = (Get-Command ssh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$remoteAddress = "$RemoteUser@$RemoteHost"
$systemdServices = @($BackendServiceName, $WebServiceName, $AdminServiceName, $MerchantServiceName) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() }
Assert-SafeServiceNames -Names $systemdServices
$restartCommand = if ($systemdServices.Count -gt 0) {
    "sudo -n systemctl restart " + ($systemdServices -join " ") + "`n" +
    "for service in " + ($systemdServices -join " ") + "; do sudo -n systemctl is-active --quiet " + '"$service"' + "; done"
}
else {
    ":"
}

$targetClause = if ([string]::IsNullOrWhiteSpace($TargetVersion)) {
    @"
previous_release=''
if [ -e '$RemoteRoot/previous' ] || [ -L '$RemoteRoot/previous' ]; then
  test -L '$RemoteRoot/previous' || { echo 'Previous release must be a symlink' >&2; exit 1; }
  previous_release=`$(readlink -f '$RemoteRoot/previous')
  test -d "`$previous_release" || { echo 'Previous release is missing' >&2; exit 1; }
  case "`$previous_release" in
    '$RemoteRoot/releases'/*) ;;
    *)
      echo "Previous release points outside the managed releases directory" >&2
      exit 1
      ;;
  esac
fi
target=''
if [ -n "`$previous_release" ] && [ "`$previous_release" != "`$current_release" ]; then
  target=`$(basename "`$previous_release")
fi
if [ -z "`$target" ]; then
  if [ -n '$ExpectedCurrentVersion' ]; then
    sudo -n systemctl stop $($systemdServices -join ' ')
    rm -f '$RemoteRoot/current'
    echo 'Failed first deployment deactivated; no previous stable release is available' >&2
  fi
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
mkdir -p '$RemoteRoot'
exec 9>'$RemoteRoot/.deploy.lock'
flock -w 300 9 || { echo "Another deployment or rollback is active" >&2; exit 1; }
current_release=''
if [ -e '$RemoteRoot/current' ] || [ -L '$RemoteRoot/current' ]; then
  test -L '$RemoteRoot/current' || { echo 'Current release must be a symlink' >&2; exit 1; }
  current_release=`$(readlink -f '$RemoteRoot/current')
  test -d "`$current_release" || { echo 'Current release is missing' >&2; exit 1; }
  case "`$current_release" in
    '$RemoteRoot/releases'/*) ;;
    *) echo 'Current release points outside the managed releases directory' >&2; exit 1 ;;
  esac
fi
if [ -n '$ExpectedCurrentVersion' ] && [ "`$current_release" != '$RemoteRoot/releases/$ExpectedCurrentVersion' ]; then
  echo 'Automatic recovery refused: failed deployment is not current; no release was changed' >&2
  exit 1
fi
if [ -n '$ExpectedDeploymentId' ]; then
  if [ ! -f "`$current_release/.deployment-attempt" ] || [ "`$(cat "`$current_release/.deployment-attempt")" != '$ExpectedDeploymentId' ]; then
    echo 'Automatic recovery refused: deployment attempt does not match; no release was changed' >&2
    exit 1
  fi
fi
$targetClause
if [[ ! "`$target" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]; then
  echo "Resolved rollback version contains unsupported characters" >&2
  exit 1
fi
if [ ! -d '$RemoteRoot/releases/'"`$target" ]; then
  echo "Target release not found: `$target" >&2
  exit 1
fi
target_release='$RemoteRoot/releases/'"`$target"
if [ "`$(readlink -f "`$target_release")" != "`$target_release" ]; then
  echo 'Rollback target must be a managed release directory, not a symlink' >&2
  exit 1
fi
if [ ! -f "`$target_release/release-version.txt" ] || [ "`$(tr -d '\r\n' < "`$target_release/release-version.txt")" != "`$target" ]; then
  echo 'Rollback target version marker is invalid' >&2
  exit 1
fi
if [ -z '$ExpectedCurrentVersion' ] && [ -n "`$current_release" ] && [ "`$current_release" != "`$target_release" ]; then
  ln -sfn "`$current_release" '$RemoteRoot/previous'
fi
if [ -n '$ExpectedDeploymentId' ]; then
  restored_previous=`$(cat "`$current_release/.deployment-previous")
  if [ -n "`$restored_previous" ]; then
    case "`$restored_previous" in
      '$RemoteRoot/releases'/*) ;;
      *) echo 'Saved previous release is outside the managed directory' >&2; exit 1 ;;
    esac
    test -d "`$restored_previous" || { echo 'Saved previous release is missing' >&2; exit 1; }
    ln -sfn "`$restored_previous" '$RemoteRoot/previous'
  else
    rm -f '$RemoteRoot/previous'
  fi
fi
ln -sfn '$RemoteRoot/releases/'"`$target" '$RemoteRoot/current'
$restartCommand
printf '%s\n' "`$target"
"@

$sshArguments = @('-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', '-p', "$RemotePort", '--', $remoteAddress, 'bash', '-s')
$rolledBackVersion = Invoke-Native -FilePath $sshPath -Arguments $sshArguments -InputScript $remoteRollbackScript
$restoredVersion = [string](@($rolledBackVersion)[-1])
Assert-SafeReleaseVersion -Value $restoredVersion

Invoke-SmokeChecks -Urls $validatedSmokeUrls

$remoteReleaseRoot = "$RemoteRoot/releases"
$remoteCurrentPath = "$RemoteRoot/current"
$remotePreviousPath = "$RemoteRoot/previous"
$remoteRetentionScript = @"
set -euo pipefail
exec 9>'$RemoteRoot/.deploy.lock'
flock -w 300 9 || { echo "Another deployment or rollback is active" >&2; exit 1; }
current_release=`$(readlink -f '$remoteCurrentPath')
if [ "`$current_release" != '$remoteReleaseRoot/$restoredVersion' ]; then
  echo 'Skipping retention: a different release is now current' >&2
  exit 0
fi
previous_release=''
if [ -L '$remotePreviousPath' ]; then previous_release=`$(readlink -f '$remotePreviousPath'); fi
for tracked_release in "`$current_release" "`$previous_release"; do
  if [ -n "`$tracked_release" ]; then
    case "`$tracked_release" in
      '$remoteReleaseRoot'/*) ;;
      *) echo "Tracked release points outside the managed releases directory" >&2; exit 1 ;;
    esac
  fi
done
kept=0
while IFS= read -r candidate; do
  [[ "`$candidate" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || continue
  candidate_path='$remoteReleaseRoot/'"`$candidate"
  if [ "`$candidate_path" = "`$current_release" ] || [ "`$candidate_path" = "`$previous_release" ]; then
    continue
  fi
  if (( kept < $ReleaseRetentionCount )); then
    kept=`$((kept + 1))
  else
    rm -rf -- "`$candidate_path"
  fi
done < <(find '$remoteReleaseRoot' -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' | sort -nr | sed 's/^[^ ]* //')
"@
try {
    Invoke-Native -FilePath $sshPath -Arguments $sshArguments -InputScript $remoteRetentionScript
}
catch {
    Write-Warning "Release retention cleanup failed after a successful rollback: $($_.Exception.Message)"
}

Write-Output "rolled back to $restoredVersion in $Environment/$Region"
