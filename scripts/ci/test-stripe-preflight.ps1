$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $repoRoot 'scripts\ci\stripe-preflight.sh'
$envTemplatePath = Join-Path $repoRoot 'deploy\eu-pre.env.example'

if (-not (Test-Path -LiteralPath $scriptPath)) { throw 'stripe preflight script is missing' }
if (-not (Test-Path -LiteralPath $envTemplatePath)) { throw 'EU pre-release environment template is missing' }

$script = Get-Content -Raw -LiteralPath $scriptPath
$template = Get-Content -Raw -LiteralPath $envTemplatePath
$bash = (Get-Command bash -ErrorAction Stop).Source
$previousTemplatePath = $env:DZDP_EU_ENV_TEMPLATE
try {
    $env:DZDP_EU_ENV_TEMPLATE = $envTemplatePath
    & $bash -c 'set -a; source "$DZDP_EU_ENV_TEMPLATE"; set +a' 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'EU environment template must be sourceable by bash' }
}
finally {
    if ($null -eq $previousTemplatePath) {
        Remove-Item -LiteralPath 'Env:DZDP_EU_ENV_TEMPLATE' -ErrorAction SilentlyContinue
    }
    else {
        $env:DZDP_EU_ENV_TEMPLATE = $previousTemplatePath
    }
}
foreach ($name in @(
    'APP_RUNTIME_MODE',
    'APP_AUTH_VERIFICATION_MOCK_ENABLED',
    'APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE',
    'APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED',
    'APP_AUTH_VERIFICATION_MAIL_ENABLED',
    'APP_MAIL_HOST',
    'APP_MAIL_PORT',
    'APP_MAIL_USERNAME',
    'APP_MAIL_PASSWORD',
    'APP_MAIL_SMTP_AUTH',
    'APP_MAIL_STARTTLS_ENABLED',
    'APP_MAIL_HEALTH_ENABLED',
    'APP_AUTH_VERIFICATION_MAIL_FROM',
    'APP_AUTH_VERIFICATION_MAIL_SUBJECT',
    'APP_AUTH_VERIFICATION_BRAND_NAME',
    'APP_AUTH_VERIFICATION_TWILIO_ENABLED',
    'APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID',
    'APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN',
    'APP_AUTH_VERIFICATION_TWILIO_FROM',
    'APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID',
    'APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL',
    'APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES',
    'APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES',
    'APP_AUTH_VERIFICATION_ALIYUN_ENABLED',
    'APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_ID',
    'APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_SECRET',
    'APP_AUTH_VERIFICATION_ALIYUN_SIGN_NAME',
    'APP_AUTH_VERIFICATION_ALIYUN_TEMPLATE_CODE',
    'APP_AUTH_VERIFICATION_ALIYUN_ENDPOINT',
    'APP_AUTH_VERIFICATION_ALIYUN_REGION_ID',
    'APP_AUTH_VERIFICATION_ALIYUN_ROUTE_PREFIXES',
    'APP_PAYMENT_STRIPE_ENABLED',
    'APP_PAYMENT_STRIPE_SECRET_KEY',
    'APP_PAYMENT_STRIPE_ENDPOINT_SECRET',
    'VITE_STRIPE_PUBLISHABLE_KEY',
    'APP_STATE_STORE_PROVIDER',
    'APP_FILE_STORAGE_PROVIDER',
    'APP_SEARCH_PROVIDER',
    'APP_SEARCH_BASE_URL',
    'APP_SEARCH_INDEX_NAME',
    'APP_SEARCH_FALLBACK_ON_ERROR',
    'APP_S3_PUBLIC_BASE_URL',
    'APP_PUSH_ENABLED',
    'VITE_WS_BASE_URL',
    'PRERENDER_REGION'
)) {
    if ($script -notmatch [regex]::Escape($name)) { throw "stripe preflight must check $name" }
    if ($template -notmatch [regex]::Escape($name)) { throw "EU environment template must define $name" }
}
if ($template -notmatch 'PRERENDER_REGION=EU') { throw 'EU environment template must target EU' }
if ($template -notmatch 'APP_RUNTIME_MODE=pre') { throw 'EU environment template must identify itself as pre-release' }
if ($template -notmatch 'APP_PAYMENT_MOCK_ENABLED=false') { throw 'EU template must disable mock payment' }
if ($template -notmatch 'APP_AUTH_VERIFICATION_MOCK_ENABLED=false') { throw 'EU template must disable mock verification codes' }
if ($template -notmatch 'APP_AUTH_VERIFICATION_MAIL_ENABLED=true') { throw 'EU template must enable email verification' }
if ($template -notmatch 'APP_AUTH_VERIFICATION_TWILIO_ENABLED=true') { throw 'EU template must enable international SMS verification' }
if ($template -notmatch 'APP_SEARCH_FALLBACK_ON_ERROR=false') { throw 'EU template must disable search fallback so Elasticsearch failures stay visible' }

$contractEnvironment = [ordered]@{
    APP_RUNTIME_MODE = 'pre'
    APP_DB_HOST = 'db.internal'
    APP_DB_NAME = 'dzdp_eu_contract'
    APP_DB_USERNAME = 'dzdp_contract'
    APP_DB_PASSWORD = 'contract-password'
    APP_REDIS_HOST = 'redis.internal'
    APP_REDIS_PASSWORD = 'contract-password'
    APP_AUTH_JWT_SECRET = 'contract-jwt-secret-at-least-32-characters'
    APP_PAYMENT_NOTIFY_SECRET = 'contract-notify-secret-at-least-32-characters'
    APP_AUTH_VERIFICATION_MOCK_ENABLED = 'false'
    APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE = 'false'
    APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED = 'false'
    APP_AUTH_VERIFICATION_MAIL_ENABLED = 'true'
    APP_MAIL_HOST = 'smtp.eu.example.com'
    APP_MAIL_PORT = '587'
    APP_MAIL_USERNAME = 'smtp-contract-user'
    APP_MAIL_PASSWORD = 'smtp-contract-password'
    APP_MAIL_SMTP_AUTH = 'true'
    APP_MAIL_STARTTLS_ENABLED = 'true'
    APP_MAIL_HEALTH_ENABLED = 'true'
    APP_AUTH_VERIFICATION_MAIL_FROM = 'no-reply@eu.example.com'
    APP_AUTH_VERIFICATION_MAIL_SUBJECT = 'Your verification code'
    APP_AUTH_VERIFICATION_BRAND_NAME = 'Dazhongdianping EU'
    APP_AUTH_VERIFICATION_TWILIO_ENABLED = 'true'
    APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID = 'AC_contract_account'
    APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN = 'contract-twilio-token'
    APP_AUTH_VERIFICATION_TWILIO_FROM = ''
    APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID = 'MG_contract_service'
    APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL = 'https://api.twilio.com'
    APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES = '*'
    APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES = '+86'
    APP_AUTH_VERIFICATION_ALIYUN_ENABLED = 'false'
    APP_PAYMENT_STRIPE_ENABLED = 'true'
    APP_PAYMENT_STRIPE_SECRET_KEY = 'sk_' + 'test_contract'
    APP_PAYMENT_STRIPE_ENDPOINT_SECRET = 'whsec_' + 'contract'
    APP_PAYMENT_MOCK_ENABLED = 'false'
    APP_STATE_STORE_PROVIDER = 'redis'
    APP_FILE_STORAGE_PROVIDER = 's3'
    APP_S3_BUCKET = 'dzdp-contract'
    APP_S3_REGION = 'eu-west-1'
    APP_S3_ENDPOINT = 'https://s3.internal.example'
    APP_S3_PUBLIC_BASE_URL = 'https://cdn.example.com'
    APP_S3_ACCESS_KEY = 'contract-access'
    APP_S3_SECRET_KEY = 'contract-secret'
    APP_SEARCH_PROVIDER = 'elasticsearch'
    APP_SEARCH_BASE_URL = 'http://search.internal:9200'
    APP_SEARCH_INDEX_NAME = 'dzdp_shop_eu_contract'
    APP_SEARCH_FALLBACK_ON_ERROR = 'false'
    APP_PUSH_ENABLED = 'false'
    PUBLIC_SITE_URL = 'https://eu.example.com'
    PRERENDER_API_BASE_URL = 'https://api.eu.example.com'
    PRERENDER_REGION = 'EU'
    VITE_API_BASE_URL = 'https://api.eu.example.com'
    VITE_WS_BASE_URL = 'wss://api.eu.example.com/ws'
    VITE_STRIPE_PUBLISHABLE_KEY = 'pk_' + 'test_contract'
}
$previousEnvironment = @{}
function Invoke-PreflightContract {
    & $bash $scriptPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

try {
    foreach ($entry in $contractEnvironment.GetEnumerator()) {
        $existing = Get-Item -LiteralPath "Env:$($entry.Key)" -ErrorAction SilentlyContinue
        $previousEnvironment[$entry.Key] = if ($null -eq $existing) { $null } else { $existing.Value }
        Set-Item -LiteralPath "Env:$($entry.Key)" -Value $entry.Value
    }

    if ((Invoke-PreflightContract) -ne 0) { throw 'complete EU contract configuration must pass preflight' }

    $env:APP_RUNTIME_MODE = 'prod'
    if ((Invoke-PreflightContract) -eq 0) { throw 'prod runtime identity must fail the EU pre-release gate' }
    $env:APP_RUNTIME_MODE = $contractEnvironment.APP_RUNTIME_MODE

    $env:APP_AUTH_VERIFICATION_MAIL_ENABLED = 'false'
    if ((Invoke-PreflightContract) -eq 0) { throw 'disabled EU email verification must fail preflight' }
    $env:APP_AUTH_VERIFICATION_MAIL_ENABLED = $contractEnvironment.APP_AUTH_VERIFICATION_MAIL_ENABLED

    $env:APP_MAIL_STARTTLS_ENABLED = 'false'
    if ((Invoke-PreflightContract) -eq 0) { throw 'disabled SMTP STARTTLS must fail preflight' }
    $env:APP_MAIL_STARTTLS_ENABLED = $contractEnvironment.APP_MAIL_STARTTLS_ENABLED

    $env:APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID = ''
    if ((Invoke-PreflightContract) -eq 0) { throw 'missing Twilio sender must fail preflight' }
    $env:APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID = $contractEnvironment.APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID

    $env:APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES = '+33,+49'
    if ((Invoke-PreflightContract) -eq 0) { throw 'partial Twilio routing must fail the EU launch gate' }
    $env:APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES = $contractEnvironment.APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES

    $env:APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES = ''
    if ((Invoke-PreflightContract) -eq 0) { throw 'missing +86 Twilio exclusion must fail preflight' }
    $env:APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES = $contractEnvironment.APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES

    $env:APP_PAYMENT_NOTIFY_SECRET = 'too-short'
    if ((Invoke-PreflightContract) -eq 0) { throw 'short payment notification secret must fail preflight' }
    $env:APP_PAYMENT_NOTIFY_SECRET = $contractEnvironment.APP_PAYMENT_NOTIFY_SECRET

    $env:APP_SEARCH_BASE_URL = ''
    if ((Invoke-PreflightContract) -eq 0) { throw 'missing APP_SEARCH_BASE_URL must fail preflight' }
    $env:APP_SEARCH_BASE_URL = $contractEnvironment.APP_SEARCH_BASE_URL

    $env:APP_SEARCH_INDEX_NAME = 'Invalid Index'
    if ((Invoke-PreflightContract) -eq 0) { throw 'invalid APP_SEARCH_INDEX_NAME must fail preflight' }
    $env:APP_SEARCH_INDEX_NAME = $contractEnvironment.APP_SEARCH_INDEX_NAME

    $env:APP_SEARCH_FALLBACK_ON_ERROR = 'true'
    if ((Invoke-PreflightContract) -eq 0) { throw 'enabled APP_SEARCH_FALLBACK_ON_ERROR must fail preflight' }
    $env:APP_SEARCH_FALLBACK_ON_ERROR = $contractEnvironment.APP_SEARCH_FALLBACK_ON_ERROR

    $env:APP_S3_PUBLIC_BASE_URL = 'http://cdn.example.com'
    if ((Invoke-PreflightContract) -eq 0) { throw 'non-HTTPS APP_S3_PUBLIC_BASE_URL must fail preflight' }
    $env:APP_S3_PUBLIC_BASE_URL = $contractEnvironment.APP_S3_PUBLIC_BASE_URL

    $env:VITE_WS_BASE_URL = 'ws://api.eu.example.com/ws'
    if ((Invoke-PreflightContract) -eq 0) { throw 'non-WSS VITE_WS_BASE_URL must fail preflight' }
    $env:VITE_WS_BASE_URL = $contractEnvironment.VITE_WS_BASE_URL

    $env:APP_PUSH_ENABLED = 'true'
    if ((Invoke-PreflightContract) -eq 0) { throw 'unverified mobile push must fail the EU launch gate' }
}
finally {
    foreach ($entry in $previousEnvironment.GetEnumerator()) {
        if ($null -eq $entry.Value) {
            Remove-Item -LiteralPath "Env:$($entry.Key)" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -LiteralPath "Env:$($entry.Key)" -Value $entry.Value
        }
    }
}

Write-Output 'stripe preflight contract passed'
