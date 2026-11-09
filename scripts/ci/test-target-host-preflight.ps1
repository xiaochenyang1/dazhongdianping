$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$preflightPath = Join-Path $repoRoot "scripts\ci\target-host-preflight.ps1"
$remoteScriptPath = Join-Path $repoRoot "scripts\ci\target-host-preflight.sh"
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-target-host-preflight-" + [Guid]::NewGuid().ToString("N"))
$binRoot = Join-Path $fixtureRoot "bin"
$remoteRoot = Join-Path $fixtureRoot "remote-root"
$privateRoot = Join-Path $fixtureRoot "private"
$runtimeEnvPath = Join-Path $privateRoot "runtime.env"
$databaseDefaultsPath = Join-Path $privateRoot "mysql.cnf"
$sshLogPath = Join-Path $fixtureRoot "ssh.log"
$sudoLogPath = Join-Path $fixtureRoot "sudo.log"
$originalPath = $env:PATH
$previousSshLog = $env:DZDP_TARGET_SSH_LOG
$previousSudoLog = $env:DZDP_TARGET_SUDO_LOG

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

function Write-Executable {
    param([string]$Name, [string]$Content)

    $path = Join-Path $binRoot $Name
    Set-Content -LiteralPath $path -Value $Content -Encoding utf8 -NoNewline
    [IO.File]::SetUnixFileMode($path,
        [IO.UnixFileMode]::UserRead -bor
        [IO.UnixFileMode]::UserWrite -bor
        [IO.UnixFileMode]::UserExecute)
}

function Write-ReadyRuntimeEnv {
    param([switch]$PlaceholderPassword)

    $databasePassword = if ($PlaceholderPassword) { "CHANGE_ME_DATABASE_PASSWORD" } else { "database-password-fixture" }
    $content = @"
APP_RUNTIME_MODE=pre
APP_LAUNCH_DEFERRED_FEATURES_ENABLED=false
APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED=false
APP_LAUNCH_EU_SECKILL_ENABLED=false
APP_LAUNCH_EU_GROUP_BUY_ENABLED=false
APP_TRUSTED_PROXY_REGEX='^(?:10[.]0[.]0[.]1)$'
APP_DB_HOST=mysql.internal.test
APP_DB_PORT=3306
APP_DB_NAME=dzdp_pre
APP_DB_USERNAME=dzdp
APP_DB_PASSWORD=$databasePassword
APP_REDIS_HOST=redis.internal.test
APP_REDIS_PORT=6379
APP_REDIS_PASSWORD=redis-password-fixture
APP_REDIS_DATABASE=0
APP_REDIS_HEALTH_ENABLED=true
APP_STATE_STORE_PROVIDER=redis
APP_STATE_STORE_KEY_PREFIX=dzdp:eu:pre
APP_AD_CLICK_DEDUPE_SECONDS=1800
APP_AUTH_JWT_SECRET=jwt-secret-fixture-with-at-least-32-characters
APP_PAYMENT_NOTIFY_SECRET=notify-secret-fixture-with-at-least-32-characters
APP_AUTH_VERIFICATION_MOCK_ENABLED=false
APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE=false
APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED=false
APP_AUTH_VERIFICATION_MAIL_ENABLED=true
APP_MAIL_HOST=smtp.example.test
APP_MAIL_PORT=587
APP_MAIL_USERNAME=mailer
APP_MAIL_PASSWORD=mail-password-fixture
APP_MAIL_SMTP_AUTH=true
APP_MAIL_STARTTLS_ENABLED=true
APP_MAIL_HEALTH_ENABLED=true
APP_AUTH_VERIFICATION_MAIL_FROM=no-reply@example.test
APP_AUTH_VERIFICATION_MAIL_SUBJECT="Your verification code"
APP_AUTH_VERIFICATION_BRAND_NAME=Dazhongdianping
APP_AUTH_VERIFICATION_TWILIO_ENABLED=true
APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID=ACfixture
APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN=twilio-token-fixture
APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID=MGfixture
APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL=https://api.twilio.com
APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES=*
APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES=+86
APP_PAYMENT_STRIPE_ENABLED=true
APP_PAYMENT_STRIPE_SECRET_KEY=sk_test_fixture
APP_PAYMENT_STRIPE_ENDPOINT_SECRET=whsec_fixture
APP_PAYMENT_MOCK_ENABLED=false
APP_SEARCH_PROVIDER=elasticsearch
APP_SEARCH_BASE_URL=http://elasticsearch.internal.test:9200
APP_SEARCH_INDEX_NAME=dzdp_shop_eu_v1
APP_SEARCH_FALLBACK_ON_ERROR=false
APP_FILE_STORAGE_PROVIDER=s3
APP_S3_BUCKET=dzdp-pre
APP_S3_REGION=eu-west-1
APP_S3_ENDPOINT=https://s3.example.test
APP_S3_PUBLIC_BASE_URL=https://cdn.example.test
APP_S3_ACCESS_KEY=s3-access-fixture
APP_S3_SECRET_KEY=s3-secret-fixture
APP_S3_PATH_STYLE_ACCESS_ENABLED=false
APP_PUSH_ENABLED=false
APP_CORS_ALLOWED_ORIGIN_PATTERNS=https://www.example.test
PUBLIC_SITE_URL=https://www.example.test
PRERENDER_API_BASE_URL=https://api.example.test
PRERENDER_REGION=EU
VITE_DEFAULT_REGION=EU
VITE_API_BASE_URL=https://api.example.test
VITE_WS_BASE_URL=wss://api.example.test
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_fixture
"@
    Set-Content -LiteralPath $runtimeEnvPath -Value $content -Encoding utf8 -NoNewline
}

try {
    Assert-True (Test-Path -LiteralPath $preflightPath -PathType Leaf) "target-host PowerShell preflight must exist"
    Assert-True (Test-Path -LiteralPath $remoteScriptPath -PathType Leaf) "target-host Bash preflight must exist"

    $dryRunRaw = (& $preflightPath `
        -Environment pre `
        -Region EU `
        -RemoteHost host.example.test `
        -RemoteUser deploy `
        -RemoteRoot /opt/dazhongdianping `
        -RuntimeEnvFile /etc/dazhongdianping/eu-pre.env `
        -DatabaseDefaultsFile /etc/dazhongdianping/mysql-release.cnf `
        -DryRun `
        -Json) -join "`n"
    $dryRun = $dryRunRaw | ConvertFrom-Json
    Assert-True ($dryRun.Mode -eq "DryRun") "dry run must identify its mode"
    Assert-True (-not $dryRun.MutatesTarget) "dry run must state that the target is not mutated"
    Assert-True ("runtime-config" -in $dryRun.CheckGroups) "dry run must disclose runtime configuration checks"
    Assert-True ($dryRunRaw -notmatch 'host[.]example[.]test') "dry-run JSON must not expose the target host"

    Assert-ThrowsLike {
        & $preflightPath `
            -Environment test `
            -Region CN `
            -RemoteHost host.example.test `
            -RemoteUser deploy `
            -RemoteRoot /opt/dazhongdianping `
            -RuntimeEnvFile /etc/dazhongdianping/test.env `
            -DatabaseDefaultsFile /etc/dazhongdianping/mysql-release.cnf `
            -DryRun
    } "fixed to region EU" "test preflight must reject non-EU regions"
    Assert-ThrowsLike {
        & $preflightPath `
            -Environment pre `
            -Region EU `
            -RemoteHost host.example.test `
            -RemoteUser deploy `
            -RemoteRoot '/opt/../unsafe' `
            -RuntimeEnvFile /etc/dazhongdianping/eu-pre.env `
            -DatabaseDefaultsFile /etc/dazhongdianping/mysql-release.cnf `
            -DryRun
    } "safe absolute path" "unsafe target paths must be rejected before SSH"

    if ([Environment]::OSVersion.Platform -eq "Win32NT") {
        Write-Output "target-host preflight integration contract skipped on Windows"
        Write-Output "target-host preflight contract passed"
        return
    }

    New-Item -ItemType Directory -Path $binRoot, $remoteRoot, $privateRoot -Force | Out-Null
    Write-ReadyRuntimeEnv
    Set-Content -LiteralPath $databaseDefaultsPath -Value "PRIVATE-DATABASE-CREDENTIAL-FIXTURE" -Encoding utf8 -NoNewline
    [IO.File]::SetUnixFileMode($runtimeEnvPath, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)
    [IO.File]::SetUnixFileMode($databaseDefaultsPath, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)

    Write-Executable -Name "ssh" -Content @'
#!/bin/sh
set -eu
printf '%s\n' "$*" > "$DZDP_TARGET_SSH_LOG"
while [ "$#" -gt 0 ] && [ "$1" != "bash" ]; do shift; done
[ "${1:-}" = "bash" ] || exit 90
shift
exec /bin/bash "$@"
'@
    Write-Executable -Name "uname" -Content "#!/bin/sh`nprintf 'Linux\n'"
    Write-Executable -Name "stat" -Content "#!/bin/sh`nprintf '600\n'"
    Write-Executable -Name "df" -Content @'
#!/bin/sh
printf 'Filesystem 1024-blocks Used Available Capacity Mounted-on\n'
printf '/dev/fake 10000000 1000 9999000 1%% /fixture\n'
'@
    Write-Executable -Name "mysql" -Content "#!/bin/sh`nprintf '1\n'"
    Write-Executable -Name "java" -Content @'
#!/bin/sh
printf 'openjdk version "17.0.1"\n' >&2
'@
    Write-Executable -Name "systemctl" -Content @'
#!/bin/sh
if [ "${1:-}" = "show" ]; then printf 'loaded\n'; fi
exit 0
'@
    Write-Executable -Name "sudo" -Content @'
#!/bin/sh
printf '%s\n' "$*" >> "$DZDP_TARGET_SUDO_LOG"
exit 0
'@
    Write-Executable -Name "curl" -Content "#!/bin/sh`nprintf '401'"
    foreach ($name in @("timeout", "flock", "sha256sum")) {
        Write-Executable -Name $name -Content "#!/bin/sh`nexit 0"
    }

    $env:DZDP_TARGET_SSH_LOG = $sshLogPath
    $env:DZDP_TARGET_SUDO_LOG = $sudoLogPath
    $env:PATH = "$binRoot$([IO.Path]::PathSeparator)$originalPath"
    $fixtureMode = & (Join-Path $binRoot "stat") -c "%a" $runtimeEnvPath
    Assert-True ($fixtureMode -eq "600") "permission fixture must expose mode 600"
    $fixtureJava = (& (Join-Path $binRoot "java") -version 2>&1) -join "`n"
    Assert-True ($fixtureJava -match '17[.]0[.]1') "Java fixture must expose version 17"

    $readyRaw = (& $preflightPath `
        -Environment pre `
        -Region EU `
        -RemoteHost host.example.test `
        -RemoteUser deploy `
        -RemoteRoot $remoteRoot `
        -RuntimeEnvFile $runtimeEnvPath `
        -DatabaseDefaultsFile $databaseDefaultsPath `
        -MinimumFreeMegabytes 256 `
        -ReportOnly `
        -Json) -join "`n"
    $ready = $readyRaw | ConvertFrom-Json
    Assert-True $ready.Ready "complete target fixture must pass"
    Assert-True (-not $ready.MutatedTarget) "the report must state that the target was not mutated"
    Assert-True ($ready.Failed -eq 0) "complete target fixture must not report failures"
    foreach ($name in @(
        "runtime-config", "mysql-connectivity", "systemd-services", "sudo-policy",
        "redis-connectivity", "elasticsearch-connectivity", "s3-connectivity",
        "smtp-connectivity", "twilio-connectivity", "stripe-connectivity"
    )) {
        Assert-True ($name -in @($ready.Checks.Name)) "ready report must include $name"
    }
    foreach ($forbidden in @(
        "database-password-fixture",
        "PRIVATE-DATABASE-CREDENTIAL-FIXTURE",
        "host.example.test",
        $runtimeEnvPath,
        $databaseDefaultsPath
    )) {
        Assert-True ($readyRaw -notmatch [regex]::Escape($forbidden)) "JSON report must not expose target values, paths, or credentials"
    }
    $sshLog = Get-Content -LiteralPath $sshLogPath -Raw
    Assert-True ($sshLog -match 'BatchMode=yes') "target preflight must use non-interactive SSH"
    Assert-True ($sshLog -match 'StrictHostKeyChecking=yes') "target preflight must require a prepared known_hosts entry"
    Assert-True ($sshLog -match 'bash -s -- --environment pre') "target preflight must send the remote audit over stdin"
    $sudoLog = Get-Content -LiteralPath $sudoLogPath -Raw
    Assert-True ($sudoLog -match '^-n -l -- systemctl restart' -or $sudoLog -match '(?m)^-n -l -- systemctl restart') "preflight must query restart authorization without restarting services"

    Write-ReadyRuntimeEnv -PlaceholderPassword
    $placeholderRaw = (& $preflightPath `
        -Environment pre `
        -Region EU `
        -RemoteHost host.example.test `
        -RemoteUser deploy `
        -RemoteRoot $remoteRoot `
        -RuntimeEnvFile $runtimeEnvPath `
        -DatabaseDefaultsFile $databaseDefaultsPath `
        -MinimumFreeMegabytes 256 `
        -ReportOnly `
        -Json) -join "`n"
    $placeholderReport = $placeholderRaw | ConvertFrom-Json
    $placeholderFailures = @($placeholderReport.Checks | Where-Object Status -eq "FAIL" | ForEach-Object Name)
    Assert-True (-not $placeholderReport.Ready) "placeholder values must block readiness"
    Assert-True ("runtime-config" -in $placeholderFailures) "placeholder configuration must be reported by name"
    Assert-True ("runtime-env-permissions" -notin $placeholderFailures) "safe runtime-env permissions must remain valid"
    Assert-True ($placeholderRaw -notmatch 'CHANGE_ME_DATABASE_PASSWORD') "blocked report must not expose placeholder values"
    Assert-ThrowsLike {
        & $preflightPath `
            -Environment pre `
            -Region EU `
            -RemoteHost host.example.test `
            -RemoteUser deploy `
            -RemoteRoot $remoteRoot `
            -RuntimeEnvFile $runtimeEnvPath `
            -DatabaseDefaultsFile $databaseDefaultsPath `
            -MinimumFreeMegabytes 256 `
            -Json
    } "not ready for deployment" "strict mode must fail a blocked target"

    Write-ReadyRuntimeEnv
    Write-Executable -Name "stat" -Content "#!/bin/sh`nprintf '644\n'"
    $permissionRaw = (& $preflightPath `
        -Environment pre `
        -Region EU `
        -RemoteHost host.example.test `
        -RemoteUser deploy `
        -RemoteRoot $remoteRoot `
        -RuntimeEnvFile $runtimeEnvPath `
        -DatabaseDefaultsFile $databaseDefaultsPath `
        -MinimumFreeMegabytes 256 `
        -ReportOnly `
        -Json) -join "`n"
    $permissionReport = $permissionRaw | ConvertFrom-Json
    $permissionFailures = @($permissionReport.Checks | Where-Object Status -eq "FAIL" | ForEach-Object Name)
    Assert-True (-not $permissionReport.Ready) "unsafe private-file permissions must block readiness"
    Assert-True ("runtime-env-permissions" -in $permissionFailures) "unsafe runtime-env permissions must be reported"
    Assert-True ("database-defaults-permissions" -in $permissionFailures) "unsafe database file permissions must be reported"
    Assert-True ($permissionRaw -notmatch 'database-password-fixture') "permission failure report must not expose configuration values"

    Write-Output "target-host preflight contract passed"
}
finally {
    $env:PATH = $originalPath
    if ($null -eq $previousSshLog) { Remove-Item Env:DZDP_TARGET_SSH_LOG -ErrorAction SilentlyContinue } else { $env:DZDP_TARGET_SSH_LOG = $previousSshLog }
    if ($null -eq $previousSudoLog) { Remove-Item Env:DZDP_TARGET_SUDO_LOG -ErrorAction SilentlyContinue } else { $env:DZDP_TARGET_SUDO_LOG = $previousSudoLog }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
