$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $repoRoot 'scripts\ci\stripe-preflight.sh'
$envTemplatePaths = [ordered]@{
    test = Join-Path $repoRoot 'deploy\eu-test.env.example'
    pre = Join-Path $repoRoot 'deploy\eu-pre.env.example'
}

if (-not (Test-Path -LiteralPath $scriptPath)) { throw 'stripe preflight script is missing' }
foreach ($entry in $envTemplatePaths.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) { throw "EU $($entry.Key) environment template is missing" }
}

$script = Get-Content -Raw -LiteralPath $scriptPath
$templates = [ordered]@{}
$bash = (Get-Command bash -ErrorAction Stop).Source
$previousTemplatePath = $env:DZDP_EU_ENV_TEMPLATE
try {
    foreach ($entry in $envTemplatePaths.GetEnumerator()) {
        $templates[$entry.Key] = Get-Content -Raw -LiteralPath $entry.Value
        $env:DZDP_EU_ENV_TEMPLATE = $entry.Value
        & $bash -c 'set -a; source "$DZDP_EU_ENV_TEMPLATE"; set +a' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "EU $($entry.Key) environment template must be sourceable by bash" }
    }
}
finally {
    if ($null -eq $previousTemplatePath) {
        Remove-Item -LiteralPath 'Env:DZDP_EU_ENV_TEMPLATE' -ErrorAction SilentlyContinue
    }
    else {
        $env:DZDP_EU_ENV_TEMPLATE = $previousTemplatePath
    }
}
$templateVariableNames = [ordered]@{}
foreach ($entry in $templates.GetEnumerator()) {
    $templateVariableNames[$entry.Key] = @(
        [regex]::Matches($entry.Value, '(?m)^(?<name>[A-Z][A-Z0-9_]*)=') |
            ForEach-Object { $_.Groups['name'].Value } |
            Sort-Object -Unique
    )
}
$templateVariableDiff = @(Compare-Object $templateVariableNames.test $templateVariableNames.pre)
if ($templateVariableDiff.Count -gt 0) {
    $details = $templateVariableDiff | ForEach-Object { "$($_.InputObject) ($($_.SideIndicator))" }
    throw "EU test/pre environment templates must define the same variables: $($details -join ', ')"
}
foreach ($name in @(
    'APP_RUNTIME_MODE',
    'APP_DB_SSL_MODE',
    'APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL',
    'APP_TRUSTED_PROXY_REGEX',
    'APP_AD_CLICK_DEDUPE_SECONDS',
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
    'APP_REDIS_SSL_ENABLED',
    'APP_FILE_STORAGE_PROVIDER',
    'APP_SEARCH_PROVIDER',
    'APP_SEARCH_BASE_URL',
    'APP_SEARCH_INDEX_NAME',
    'APP_SEARCH_USERNAME',
    'APP_SEARCH_PASSWORD',
    'APP_SEARCH_FALLBACK_ON_ERROR',
    'APP_S3_CREDENTIALS_PROVIDER',
    'APP_S3_PUBLIC_BASE_URL',
    'APP_PUSH_ENABLED',
    'APP_CORS_ALLOWED_ORIGIN_PATTERNS',
    'VITE_WS_BASE_URL',
    'VITE_DEFAULT_REGION',
    'APP_LAUNCH_DEFERRED_FEATURES_ENABLED',
    'APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED',
    'APP_LAUNCH_EU_SECKILL_ENABLED',
    'APP_LAUNCH_EU_GROUP_BUY_ENABLED',
    'PRERENDER_REGION'
)) {
    if ($script -notmatch [regex]::Escape($name)) { throw "stripe preflight must check $name" }
    foreach ($entry in $templates.GetEnumerator()) {
        if ($entry.Value -notmatch [regex]::Escape($name)) { throw "EU $($entry.Key) environment template must define $name" }
    }
}
foreach ($entry in $templates.GetEnumerator()) {
    $environment = $entry.Key
    $template = $entry.Value
    if ($template -notmatch 'PRERENDER_REGION=EU') { throw "EU $environment environment template must target EU" }
    if ($template -notmatch "APP_RUNTIME_MODE=$environment") { throw "EU $environment environment template must identify itself as $environment" }
    if ($template -notmatch 'APP_PAYMENT_MOCK_ENABLED=false') { throw "EU $environment template must disable mock payment" }
    if ($template -notmatch 'APP_AUTH_VERIFICATION_MOCK_ENABLED=false') { throw "EU $environment template must disable mock verification codes" }
    if ($template -notmatch 'APP_AUTH_VERIFICATION_MAIL_ENABLED=true') { throw "EU $environment template must enable email verification" }
    if ($template -notmatch 'APP_AUTH_VERIFICATION_TWILIO_ENABLED=true') { throw "EU $environment template must enable international SMS verification" }
    if ($template -notmatch 'APP_SEARCH_FALLBACK_ON_ERROR=false') { throw "EU $environment template must disable search fallback so Elasticsearch failures stay visible" }
    if ($template -notmatch 'APP_STATE_STORE_PROVIDER=redis') { throw "EU $environment template must use Redis state storage" }
    if ($template -notmatch 'APP_DB_SSL_MODE=(REQUIRED|VERIFY_CA|VERIFY_IDENTITY)') { throw "EU $environment template must require encrypted MySQL transport" }
    if ($template -notmatch 'APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL=false') { throw "EU $environment template must disable MySQL public-key retrieval" }
    if ($template -notmatch 'APP_REDIS_SSL_ENABLED=true') { throw "EU $environment template must require Redis TLS" }
    if ($template -notmatch 'APP_FILE_STORAGE_PROVIDER=s3') { throw "EU $environment template must use S3 storage" }
    if ($template -notmatch 'APP_S3_CREDENTIALS_PROVIDER=default_chain') { throw "EU $environment template must use the AWS default credential chain" }
    if ($template -notmatch 'APP_SEARCH_PROVIDER=elasticsearch') { throw "EU $environment template must use Elasticsearch" }
    if ($template -notmatch 'APP_SEARCH_BASE_URL=https://') { throw "EU $environment template must use HTTPS for search" }
    if ($template -notmatch 'APP_PUSH_ENABLED=false') { throw "EU $environment template must keep push disabled until real-device smoke passes" }
}
if ($templates.test -notmatch 'APP_DB_NAME=dazhongdianping_eu_test') { throw 'EU test template must use the isolated test database name' }
if ($templates.test -notmatch 'APP_STATE_STORE_KEY_PREFIX=dzdp:eu:test') { throw 'EU test template must use the isolated test state prefix' }
if ($templates.test -notmatch 'APP_SEARCH_INDEX_NAME=dzdp_shop_eu_test_v1') { throw 'EU test template must use the isolated test search index' }
if ($templates.pre -notmatch 'APP_DB_NAME=dazhongdianping_eu_pre') { throw 'EU pre template must use the isolated pre database name' }
if ($templates.pre -notmatch 'APP_STATE_STORE_KEY_PREFIX=dzdp:eu:pre') { throw 'EU pre template must use the isolated pre state prefix' }
if ($templates.pre -notmatch 'APP_SEARCH_INDEX_NAME=dzdp_shop_eu_v1') { throw 'EU pre template must use the isolated pre search index' }

$contractEnvironment = [ordered]@{
    APP_RUNTIME_MODE = 'pre'
    APP_TRUSTED_PROXY_REGEX = '^(?:10[.]42[.]0[.]12|10[.]42[.]0[.]13)$'
    APP_AD_CLICK_DEDUPE_SECONDS = '1800'
    APP_DB_HOST = 'db.internal'
    APP_DB_NAME = 'dzdp_eu_contract'
    APP_DB_USERNAME = 'dzdp_contract'
    APP_DB_PASSWORD = 'contract-password'
    APP_DB_SSL_MODE = 'REQUIRED'
    APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL = 'false'
    APP_REDIS_HOST = 'redis.internal'
    APP_REDIS_PASSWORD = 'contract-password'
    APP_REDIS_SSL_ENABLED = 'true'
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
    APP_S3_REGION = 'eu-west-3'
    APP_S3_ENDPOINT = 'https://s3.internal.example'
    APP_S3_PUBLIC_BASE_URL = 'https://cdn.example.com'
    APP_S3_CREDENTIALS_PROVIDER = 'default_chain'
    APP_S3_ACCESS_KEY = ''
    APP_S3_SECRET_KEY = ''
    APP_SEARCH_PROVIDER = 'elasticsearch'
    APP_SEARCH_BASE_URL = 'https://search.internal'
    APP_SEARCH_INDEX_NAME = 'dzdp_shop_eu_contract'
    APP_SEARCH_USERNAME = 'search-contract-user'
    APP_SEARCH_PASSWORD = 'search-contract-password'
    APP_SEARCH_FALLBACK_ON_ERROR = 'false'
    APP_PUSH_ENABLED = 'false'
    APP_CORS_ALLOWED_ORIGIN_PATTERNS = 'https://eu.example.com,https://admin.eu.example.com,https://merchant.eu.example.com'
    PUBLIC_SITE_URL = 'https://eu.example.com'
    PRERENDER_API_BASE_URL = 'https://api.eu.example.com'
    PRERENDER_REGION = 'EU'
    VITE_DEFAULT_REGION = 'EU'
    APP_LAUNCH_DEFERRED_FEATURES_ENABLED = 'false'
    APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED = 'false'
    APP_LAUNCH_EU_SECKILL_ENABLED = 'false'
    APP_LAUNCH_EU_GROUP_BUY_ENABLED = 'false'
    VITE_API_BASE_URL = 'https://api.eu.example.com'
    VITE_WS_BASE_URL = 'wss://api.eu.example.com'
    VITE_STRIPE_PUBLISHABLE_KEY = 'pk_' + 'test_contract'
}
$previousEnvironment = @{}
function Invoke-PreflightContract {
    param([string[]]$Arguments = @())

    & $bash $scriptPath @Arguments 2>&1 | Out-Null
    return $LASTEXITCODE
}

try {
    foreach ($entry in $contractEnvironment.GetEnumerator()) {
        $existing = Get-Item -LiteralPath "Env:$($entry.Key)" -ErrorAction SilentlyContinue
        $previousEnvironment[$entry.Key] = if ($null -eq $existing) { $null } else { $existing.Value }
        Set-Item -LiteralPath "Env:$($entry.Key)" -Value $entry.Value
    }

    if ((Invoke-PreflightContract) -ne 0) { throw 'complete EU contract configuration must pass preflight' }

    $env:APP_RUNTIME_MODE = 'test'
    if ((Invoke-PreflightContract -Arguments @('--environment', 'test')) -ne 0) { throw 'complete EU test contract configuration must pass the explicit test preflight' }
    if ((Invoke-PreflightContract) -eq 0) { throw 'EU test runtime must not pass the default pre environment gate' }
    $env:APP_RUNTIME_MODE = $contractEnvironment.APP_RUNTIME_MODE

    $env:VITE_DEFAULT_REGION = 'CN'
    if ((Invoke-PreflightContract) -eq 0) { throw 'a CN default for new Web visitors must fail the Paris launch gate' }
    $env:VITE_DEFAULT_REGION = $contractEnvironment.VITE_DEFAULT_REGION

    foreach ($feature in @('APP_LAUNCH_DEFERRED_FEATURES_ENABLED', 'APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED', 'APP_LAUNCH_EU_SECKILL_ENABLED', 'APP_LAUNCH_EU_GROUP_BUY_ENABLED')) {
        Set-Item -LiteralPath "Env:$feature" -Value 'true'
        if ((Invoke-PreflightContract) -eq 0) { throw "enabled deferred feature $feature must fail the Paris launch gate" }
        Remove-Item -LiteralPath "Env:$feature"
        if ((Invoke-PreflightContract) -eq 0) { throw "unspecified deferred feature $feature must fail the Paris launch gate" }
        Set-Item -LiteralPath "Env:$feature" -Value 'false'
    }

    $env:APP_TRUSTED_PROXY_REGEX = '^10[.]42[.]0[.].+$'
    if ((Invoke-PreflightContract) -eq 0) { throw 'broad trusted-proxy regex must fail preflight' }
    $env:APP_TRUSTED_PROXY_REGEX = $contractEnvironment.APP_TRUSTED_PROXY_REGEX

    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = ''
    $env:PUBLIC_SITE_URL = ''
    $aggregateOutput = @(& $bash $scriptPath 2>&1)
    $aggregateExitCode = $LASTEXITCODE
    if ($aggregateExitCode -eq 0) { throw 'missing CORS origins must fail preflight' }
    if (-not ($aggregateOutput -match '\[missing\] PUBLIC_SITE_URL')) {
        throw 'preflight must continue reporting missing configuration after a missing CORS origin'
    }
    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = $contractEnvironment.APP_CORS_ALLOWED_ORIGIN_PATTERNS
    $env:PUBLIC_SITE_URL = $contractEnvironment.PUBLIC_SITE_URL

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

    foreach ($missingExclusion in @('', ' , , ', $null)) {
        if ($null -eq $missingExclusion) {
            Remove-Item Env:APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES -ErrorAction SilentlyContinue
        }
        else {
            $env:APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES = $missingExclusion
        }
        $env:PUBLIC_SITE_URL = ''
        $aggregateOutput = @(& $bash $scriptPath 2>&1)
        if ($LASTEXITCODE -eq 0) { throw 'missing +86 Twilio exclusion must fail preflight' }
        if (-not ($aggregateOutput -match 'EXCLUDED_ROUTE_PREFIXES must include \+86')) {
            throw 'missing Twilio exclusion must produce a configuration diagnostic'
        }
        if (-not ($aggregateOutput -match '\[missing\] PUBLIC_SITE_URL') -or
            -not ($aggregateOutput -match 'configuration failed with') -or
            ($aggregateOutput -match 'unbound variable')) {
            throw 'empty Twilio routing must not abort the remaining preflight checks on Bash 3.2'
        }
    }
    $env:APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES = $contractEnvironment.APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES
    $env:PUBLIC_SITE_URL = $contractEnvironment.PUBLIC_SITE_URL

    $env:APP_PAYMENT_NOTIFY_SECRET = 'too-short'
    if ((Invoke-PreflightContract) -eq 0) { throw 'short payment notification secret must fail preflight' }
    $env:APP_PAYMENT_NOTIFY_SECRET = $contractEnvironment.APP_PAYMENT_NOTIFY_SECRET

    $env:APP_DB_SSL_MODE = 'DISABLED'
    if ((Invoke-PreflightContract) -eq 0) { throw 'disabled MySQL transport encryption must fail preflight' }
    $env:APP_DB_SSL_MODE = $contractEnvironment.APP_DB_SSL_MODE

    $env:APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL = 'true'
    if ((Invoke-PreflightContract) -eq 0) { throw 'enabled MySQL public-key retrieval must fail preflight' }
    $env:APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL = $contractEnvironment.APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL

    $env:APP_REDIS_SSL_ENABLED = 'false'
    if ((Invoke-PreflightContract) -eq 0) { throw 'disabled Redis TLS must fail preflight' }
    $env:APP_REDIS_SSL_ENABLED = $contractEnvironment.APP_REDIS_SSL_ENABLED

    $env:APP_SEARCH_BASE_URL = ''
    if ((Invoke-PreflightContract) -eq 0) { throw 'missing APP_SEARCH_BASE_URL must fail preflight' }
    $env:APP_SEARCH_BASE_URL = $contractEnvironment.APP_SEARCH_BASE_URL

    $env:APP_SEARCH_BASE_URL = 'http://search.internal:9200'
    if ((Invoke-PreflightContract) -eq 0) { throw 'non-HTTPS APP_SEARCH_BASE_URL must fail preflight' }
    $env:APP_SEARCH_BASE_URL = $contractEnvironment.APP_SEARCH_BASE_URL

    $env:APP_SEARCH_PASSWORD = ''
    if ((Invoke-PreflightContract) -eq 0) { throw 'missing APP_SEARCH_PASSWORD must fail preflight' }
    $env:APP_SEARCH_PASSWORD = $contractEnvironment.APP_SEARCH_PASSWORD

    $env:APP_SEARCH_INDEX_NAME = 'Invalid Index'
    if ((Invoke-PreflightContract) -eq 0) { throw 'invalid APP_SEARCH_INDEX_NAME must fail preflight' }
    $env:APP_SEARCH_INDEX_NAME = $contractEnvironment.APP_SEARCH_INDEX_NAME

    $env:APP_SEARCH_FALLBACK_ON_ERROR = 'true'
    if ((Invoke-PreflightContract) -eq 0) { throw 'enabled APP_SEARCH_FALLBACK_ON_ERROR must fail preflight' }
    $env:APP_SEARCH_FALLBACK_ON_ERROR = $contractEnvironment.APP_SEARCH_FALLBACK_ON_ERROR

    $env:APP_S3_PUBLIC_BASE_URL = 'http://cdn.example.com'
    if ((Invoke-PreflightContract) -eq 0) { throw 'non-HTTPS APP_S3_PUBLIC_BASE_URL must fail preflight' }
    $env:APP_S3_PUBLIC_BASE_URL = $contractEnvironment.APP_S3_PUBLIC_BASE_URL

    $env:APP_S3_CREDENTIALS_PROVIDER = 'static'
    if ((Invoke-PreflightContract) -eq 0) { throw 'static S3 mode without keys must fail preflight' }
    $env:APP_S3_ACCESS_KEY = 'contract-access'
    $env:APP_S3_SECRET_KEY = 'contract-secret'
    if ((Invoke-PreflightContract) -ne 0) { throw 'static S3 mode with both keys must pass preflight' }
    $env:APP_S3_CREDENTIALS_PROVIDER = 'default_chain'
    if ((Invoke-PreflightContract) -eq 0) { throw 'default-chain S3 mode with static keys must fail preflight' }
    $env:APP_S3_ACCESS_KEY = ''
    $env:APP_S3_SECRET_KEY = ''
    if ((Invoke-PreflightContract) -ne 0) { throw 'default-chain S3 mode without static keys must pass preflight' }

    $env:VITE_WS_BASE_URL = 'ws://api.eu.example.com'
    if ((Invoke-PreflightContract) -eq 0) { throw 'non-WSS VITE_WS_BASE_URL must fail preflight' }
    $env:VITE_WS_BASE_URL = $contractEnvironment.VITE_WS_BASE_URL

    $env:VITE_WS_BASE_URL = 'wss://api.eu.example.com/ws'
    if ((Invoke-PreflightContract) -eq 0) { throw 'VITE_WS_BASE_URL with a path must fail preflight' }
    $env:VITE_WS_BASE_URL = $contractEnvironment.VITE_WS_BASE_URL

    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = 'http://localhost:5173'
    if ((Invoke-PreflightContract) -eq 0) { throw 'local CORS origin must fail the EU pre-release gate' }
    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = $contractEnvironment.APP_CORS_ALLOWED_ORIGIN_PATTERNS

    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = 'https://eu.example.com/api'
    if ((Invoke-PreflightContract) -eq 0) { throw 'CORS origin with a path must fail preflight' }
    $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = $contractEnvironment.APP_CORS_ALLOWED_ORIGIN_PATTERNS

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
