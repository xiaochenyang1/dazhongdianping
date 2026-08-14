$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $repoRoot 'scripts\ci\stripe-preflight.sh'
$envTemplatePath = Join-Path $repoRoot 'deploy\eu-pre.env.example'

if (-not (Test-Path -LiteralPath $scriptPath)) { throw 'stripe preflight script is missing' }
if (-not (Test-Path -LiteralPath $envTemplatePath)) { throw 'EU pre-release environment template is missing' }

$script = Get-Content -Raw -LiteralPath $scriptPath
$template = Get-Content -Raw -LiteralPath $envTemplatePath
foreach ($name in @(
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
    'VITE_WS_BASE_URL',
    'PRERENDER_REGION'
)) {
    if ($script -notmatch [regex]::Escape($name)) { throw "stripe preflight must check $name" }
    if ($template -notmatch [regex]::Escape($name)) { throw "EU environment template must define $name" }
}
if ($template -notmatch 'PRERENDER_REGION=EU') { throw 'EU environment template must target EU' }
if ($template -notmatch 'APP_PAYMENT_MOCK_ENABLED=false') { throw 'EU template must disable mock payment' }
if ($template -notmatch 'APP_SEARCH_FALLBACK_ON_ERROR=false') { throw 'EU template must disable search fallback so Elasticsearch failures stay visible' }

$contractEnvironment = [ordered]@{
    APP_RUNTIME_MODE = 'prod'
    APP_DB_HOST = 'db.internal'
    APP_DB_NAME = 'dzdp_eu_contract'
    APP_DB_USERNAME = 'dzdp_contract'
    APP_DB_PASSWORD = 'contract-password'
    APP_REDIS_HOST = 'redis.internal'
    APP_REDIS_PASSWORD = 'contract-password'
    APP_AUTH_JWT_SECRET = 'contract-jwt-secret-at-least-32-characters'
    APP_PAYMENT_NOTIFY_SECRET = 'contract-notify-secret'
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
    PUBLIC_SITE_URL = 'https://eu.example.com'
    PRERENDER_API_BASE_URL = 'https://api.eu.example.com'
    PRERENDER_REGION = 'EU'
    VITE_API_BASE_URL = 'https://api.eu.example.com'
    VITE_WS_BASE_URL = 'wss://api.eu.example.com/ws'
    VITE_STRIPE_PUBLISHABLE_KEY = 'pk_' + 'test_contract'
}
$previousEnvironment = @{}
$bash = (Get-Command bash -ErrorAction Stop).Source

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
