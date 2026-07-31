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
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$remotePortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("RemotePort")

if (-not $Environment) { $Environment = if ($env:DEPLOY_ENVIRONMENT) { $env:DEPLOY_ENVIRONMENT } else { "" } }
if (-not $Region) { $Region = if ($env:DEPLOY_REGION) { $env:DEPLOY_REGION } else { "CN" } }
if (-not $RemoteHost) { $RemoteHost = if ($env:DEPLOY_SSH_HOST) { $env:DEPLOY_SSH_HOST } else { "" } }
if (-not $remotePortWasExplicitlySupplied -and $env:DEPLOY_SSH_PORT) { $RemotePort = [int]$env:DEPLOY_SSH_PORT }
if (-not $RemoteUser) { $RemoteUser = if ($env:DEPLOY_SSH_USER) { $env:DEPLOY_SSH_USER } else { "" } }
if (-not $RemoteRoot) { $RemoteRoot = if ($env:DEPLOY_REMOTE_ROOT) { $env:DEPLOY_REMOTE_ROOT } else { "" } }
if (-not $BackendServiceName) { $BackendServiceName = if ($env:DEPLOY_BACKEND_SERVICE) { $env:DEPLOY_BACKEND_SERVICE } else { "dzdp-backend" } }
if (-not $WebServiceName) { $WebServiceName = if ($env:DEPLOY_WEB_SERVICE) { $env:DEPLOY_WEB_SERVICE } else { "dzdp-web" } }
if (-not $AdminServiceName) { $AdminServiceName = if ($env:DEPLOY_ADMIN_SERVICE) { $env:DEPLOY_ADMIN_SERVICE } else { "dzdp-admin-web" } }
if (-not $MerchantServiceName) { $MerchantServiceName = if ($env:DEPLOY_MERCHANT_SERVICE) { $env:DEPLOY_MERCHANT_SERVICE } else { "dzdp-merchant-web" } }
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

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Resolve the requested or tracked previous stable release on the remote host, falling back to the newest non-current release."
    Write-Output "2. Preserve the currently active release as the next previous target."
    Write-Output "3. Point the remote current symlink back to the selected release."
    Write-Output "4. Restart the backend, web, admin-web, and merchant-web services."
    Write-Output "5. Run smoke checks after rollback."
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
Assert-SafeRemoteRoot -Value $RemoteRoot
$RemoteRoot = $RemoteRoot.TrimEnd("/")
if (-not [string]::IsNullOrWhiteSpace($TargetVersion)) {
    Assert-SafeReleaseVersion -Value $TargetVersion
}

$sshPath = (Get-Command ssh -ErrorAction Stop).Source
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

if (-not [string]::IsNullOrWhiteSpace($SmokeUrls)) {
    foreach ($url in ($SmokeUrls -split "[,\r\n]+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $response = Invoke-WebRequest -Uri $url.Trim() -UseBasicParsing -TimeoutSec 15
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 500) {
            throw "Smoke URL returned unexpected status after rollback: $($url.Trim()) => $($response.StatusCode)"
        }
    }
}

Write-Output "rolled back to $($rolledBackVersion -join '') in $Environment/$Region"
