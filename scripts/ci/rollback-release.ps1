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
    Write-Output "1. Resolve the requested or tracked previous stable release on the remote host, falling back to the newest non-current release."
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
$validatedSmokeUrls = @(Get-ValidatedSmokeUrls -Value $SmokeUrls)

$sshPath = (Get-Command ssh -ErrorAction Stop).Source
$remoteAddress = "$RemoteUser@$RemoteHost"
$systemdServices = @($BackendServiceName, $WebServiceName, $AdminServiceName, $MerchantServiceName) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() }
Assert-SafeServiceNames -Names $systemdServices
$restartCommand = if ($systemdServices.Count -gt 0) {
    "sudo systemctl restart " + ($systemdServices -join " ") + "`n" +
    "sudo systemctl is-active --quiet " + ($systemdServices -join " ")
}
else {
    ":"
}

$targetClause = if ([string]::IsNullOrWhiteSpace($TargetVersion)) {
    @"
current_release=`$(readlink -f '$RemoteRoot/current' || true)
previous_release=`$(readlink -f '$RemoteRoot/previous' || true)
if [ -n "`$previous_release" ]; then
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
else
  while IFS= read -r candidate; do
    if [[ "`$candidate" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] &&
       [ '$RemoteRoot/releases/'"`$candidate" != "`$current_release" ]; then
      target="`$candidate"
      break
    fi
  done < <(find '$RemoteRoot/releases' -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' | sort -nr | sed 's/^[^ ]* //')
fi
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
mkdir -p '$RemoteRoot'
exec 9>'$RemoteRoot/.deploy.lock'
flock -w 300 9 || { echo "Another deployment or rollback is active" >&2; exit 1; }
$targetClause
if [[ ! "`$target" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]; then
  echo "Resolved rollback version contains unsupported characters" >&2
  exit 1
fi
if [ ! -d '$RemoteRoot/releases/'"`$target" ]; then
  echo "Target release not found: `"${target}" >&2
  exit 1
fi
current_release=`$(readlink -f '$RemoteRoot/current' || true)
if [ -n "`$current_release" ]; then
  case "`$current_release" in
    '$RemoteRoot/releases'/*) ;;
    *)
      echo "Current release points outside the managed releases directory" >&2
      exit 1
      ;;
  esac
fi
target_release='$RemoteRoot/releases/'"`$target"
if [ -n "`$current_release" ] && [ "`$current_release" != "`$target_release" ]; then
  ln -sfn "`$current_release" '$RemoteRoot/previous'
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

Invoke-SmokeChecks -Urls $validatedSmokeUrls

$remoteReleaseRoot = "$RemoteRoot/releases"
$remoteCurrentPath = "$RemoteRoot/current"
$remotePreviousPath = "$RemoteRoot/previous"
$remoteRetentionScript = @"
set -euo pipefail
exec 9>'$RemoteRoot/.deploy.lock'
flock -w 300 9 || { echo "Another deployment or rollback is active" >&2; exit 1; }
current_release=`$(readlink -f '$remoteCurrentPath' || true)
previous_release=`$(readlink -f '$remotePreviousPath' || true)
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
find '$RemoteRoot' -maxdepth 1 -type f -name 'dazhongdianping-release-*.zip' -delete
"@
try {
    Invoke-Native -FilePath $sshPath -Arguments @(
        "-p", "$RemotePort",
        $remoteAddress,
        "bash -lc ""$remoteRetentionScript"""
    )
}
catch {
    Write-Warning "Release retention cleanup failed after a successful rollback: $($_.Exception.Message)"
}

Write-Output "rolled back to $($rolledBackVersion -join '') in $Environment/$Region"
