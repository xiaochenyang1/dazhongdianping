#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: source <eu-pre.env> && scripts/ci/stripe-preflight.sh [options]

Checks the EU pre-release runtime, verification, infrastructure, and Stripe
configuration without printing secret values.
Options:
  --check-cli             Require the Stripe CLI to be installed.
  --check-health <url>    GET a health endpoint after configuration checks.
  --help                  Show this help.
EOF
}

failures=0
check() {
  local name="$1"
  local value="${2-}"
  if [[ -z "${value//[[:space:]]/}" || "$value" == *CHANGE_ME* || "$value" == *xxxxx* ]]; then
    printf '[missing] %s\n' "$name" >&2
    failures=$((failures + 1))
  else
    printf '[ok]      %s\n' "$name"
  fi
}

is_present() {
  local value="${1-}"
  [[ -n "${value//[[:space:]]/}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* ]]
}

prefix_check() {
  local name="$1"
  local value="${2-}"
  local prefix="$3"
  check "$name" "$value"
  if [[ -n "${value-}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* && "$value" != "$prefix"* ]]; then
    printf '[invalid] %s must start with %s\n' "$name" "$prefix" >&2
    failures=$((failures + 1))
  fi
}

url_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if [[ -n "${value-}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* && ! "$value" =~ ^https://[^[:space:]]+$ ]]; then
    printf '[invalid] %s must be an https URL\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

endpoint_url_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if [[ -n "${value-}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* && ! "$value" =~ ^https?://[^[:space:]]+$ ]]; then
    printf '[invalid] %s must be an http(s) URL\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

wss_url_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if [[ -n "${value-}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* && ! "$value" =~ ^wss://[^[:space:]]+$ ]]; then
    printf '[invalid] %s must be a wss URL\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

port_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if is_present "$value"; then
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
      printf '[invalid] %s must be an integer port\n' "$name" >&2
      failures=$((failures + 1))
    else
      local port_number=$((10#$value))
      if ((port_number < 1 || port_number > 65535)); then
        printf '[invalid] %s must be between 1 and 65535\n' "$name" >&2
        failures=$((failures + 1))
      fi
    fi
  fi
}

email_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if is_present "$value" && [[ ! "$value" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
    printf '[invalid] %s must be an email address\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

secret_length_check() {
  local name="$1"
  local value="${2-}"
  check "$name" "$value"
  if is_present "$value" && [[ "${#value}" -lt 32 ]]; then
    printf '[invalid] %s must contain at least 32 characters\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

cors_origins_check() {
  local value="${1-}"
  check APP_CORS_ALLOWED_ORIGIN_PATTERNS "$value"
  is_present "$value" || return

  local compact="${value//[[:space:]]/}"
  if [[ "$compact" == ,* || "$compact" == *, || "$compact" == *,,* ]]; then
    printf '[invalid] APP_CORS_ALLOWED_ORIGIN_PATTERNS must be a comma-separated list of origins\n' >&2
    failures=$((failures + 1))
    return
  fi

  local item authority host port
  local items=()
  IFS=',' read -r -a items <<< "$value"
  for item in "${items[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    if [[ "$item" == *'*'* || ! "$item" =~ ^https://[^/?#@:[:space:]]+(:[0-9]+)?$ ]]; then
      printf '[invalid] APP_CORS_ALLOWED_ORIGIN_PATTERNS entries must be explicit HTTPS origins without paths or userinfo\n' >&2
      failures=$((failures + 1))
      continue
    fi

    authority="${item#https://}"
    host="${authority%%:*}"
    if [[ "$host" =~ ^[Ll][Oo][Cc][Aa][Ll][Hh][Oo][Ss][Tt]$ || "$host" == "127.0.0.1" ]]; then
      printf '[invalid] APP_CORS_ALLOWED_ORIGIN_PATTERNS cannot target localhost\n' >&2
      failures=$((failures + 1))
    fi
    if [[ "$authority" == *:* ]]; then
      port="${authority##*:}"
      if ((10#$port < 1 || 10#$port > 65535)); then
        printf '[invalid] APP_CORS_ALLOWED_ORIGIN_PATTERNS ports must be between 1 and 65535\n' >&2
        failures=$((failures + 1))
      fi
    fi
  done
}

csv_contains() {
  local csv="${1-}"
  local expected="$2"
  local item
  local items=()
  IFS=',' read -r -a items <<< "$csv"
  for item in "${items[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    if [[ "$item" == "$expected" ]]; then
      return 0
    fi
  done
  return 1
}

twilio_sender_check() {
  local from="${APP_AUTH_VERIFICATION_TWILIO_FROM-}"
  local messaging_service_sid="${APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID-}"
  local configured=false

  if is_present "$from"; then
    configured=true
    if [[ ! "$from" =~ ^\+[1-9][0-9]{6,14}$ ]]; then
      printf '[invalid] APP_AUTH_VERIFICATION_TWILIO_FROM must be an E.164 number\n' >&2
      failures=$((failures + 1))
    else
      printf '[ok]      APP_AUTH_VERIFICATION_TWILIO_FROM\n'
    fi
  fi
  if is_present "$messaging_service_sid"; then
    configured=true
    if [[ "$messaging_service_sid" != MG* ]]; then
      printf '[invalid] APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID must start with MG\n' >&2
      failures=$((failures + 1))
    else
      printf '[ok]      APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID\n'
    fi
  fi
  if ! $configured; then
    printf '[missing] APP_AUTH_VERIFICATION_TWILIO_FROM or APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID\n' >&2
    failures=$((failures + 1))
  fi
}

elasticsearch_index_check() {
  local value="${1-}"
  check APP_SEARCH_INDEX_NAME "$value"
  if [[ -n "${value-}" && "$value" != *CHANGE_ME* && "$value" != *xxxxx* && ! "$value" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
    printf '[invalid] APP_SEARCH_INDEX_NAME must be a lowercase Elasticsearch index name\n' >&2
    failures=$((failures + 1))
  fi
}

health_url=""
check_cli=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-cli) check_cli=true; shift ;;
    --check-health)
      [[ $# -ge 2 ]] || { printf '%s\n' '--check-health requires a URL' >&2; exit 2; }
      health_url="$2"
      shift 2
      ;;
    --help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "${APP_RUNTIME_MODE-}" == "pre" ]] || { printf '[invalid] APP_RUNTIME_MODE must be pre\n' >&2; failures=$((failures + 1)); }
[[ "${APP_PAYMENT_STRIPE_ENABLED-}" == "true" ]] || { printf '[invalid] APP_PAYMENT_STRIPE_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_PAYMENT_MOCK_ENABLED-}" == "false" ]] || { printf '[invalid] APP_PAYMENT_MOCK_ENABLED must be false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_MOCK_ENABLED-}" == "false" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_MOCK_ENABLED must be false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE-}" == "false" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE must be false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED-}" == "false" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED must be false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_MAIL_ENABLED-}" == "true" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_MAIL_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_MAIL_SMTP_AUTH-}" == "true" ]] || { printf '[invalid] APP_MAIL_SMTP_AUTH must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_MAIL_STARTTLS_ENABLED-}" == "true" ]] || { printf '[invalid] APP_MAIL_STARTTLS_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_MAIL_HEALTH_ENABLED-}" == "true" ]] || { printf '[invalid] APP_MAIL_HEALTH_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_TWILIO_ENABLED-}" == "true" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_TWILIO_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES-}" == "*" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES must be * for EU launch coverage\n' >&2; failures=$((failures + 1)); }
if ! csv_contains "${APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES-}" "+86"; then
  printf '[invalid] APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES must include +86\n' >&2
  failures=$((failures + 1))
fi
[[ "${APP_AUTH_VERIFICATION_ALIYUN_ENABLED-}" == "false" || "${APP_AUTH_VERIFICATION_ALIYUN_ENABLED-}" == "true" ]] || { printf '[invalid] APP_AUTH_VERIFICATION_ALIYUN_ENABLED must be true or false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_STATE_STORE_PROVIDER-}" == "redis" ]] || { printf '[invalid] APP_STATE_STORE_PROVIDER must be redis\n' >&2; failures=$((failures + 1)); }
[[ "${APP_FILE_STORAGE_PROVIDER-}" == "s3" ]] || { printf '[invalid] APP_FILE_STORAGE_PROVIDER must be s3\n' >&2; failures=$((failures + 1)); }
[[ "${APP_SEARCH_PROVIDER-}" == "elasticsearch" ]] || { printf '[invalid] APP_SEARCH_PROVIDER must be elasticsearch\n' >&2; failures=$((failures + 1)); }
[[ "${APP_SEARCH_FALLBACK_ON_ERROR-}" == "false" ]] || { printf '[invalid] APP_SEARCH_FALLBACK_ON_ERROR must be false\n' >&2; failures=$((failures + 1)); }
[[ "${PRERENDER_REGION-}" == "EU" ]] || { printf '[invalid] PRERENDER_REGION must be EU\n' >&2; failures=$((failures + 1)); }
[[ "${APP_PUSH_ENABLED-}" == "false" ]] || { printf '[invalid] APP_PUSH_ENABLED must be false until credentialed device smoke passes\n' >&2; failures=$((failures + 1)); }

check APP_DB_HOST "${APP_DB_HOST-}"
check APP_DB_NAME "${APP_DB_NAME-}"
check APP_DB_USERNAME "${APP_DB_USERNAME-}"
check APP_DB_PASSWORD "${APP_DB_PASSWORD-}"
check APP_REDIS_HOST "${APP_REDIS_HOST-}"
check APP_REDIS_PASSWORD "${APP_REDIS_PASSWORD-}"
secret_length_check APP_AUTH_JWT_SECRET "${APP_AUTH_JWT_SECRET-}"
secret_length_check APP_PAYMENT_NOTIFY_SECRET "${APP_PAYMENT_NOTIFY_SECRET-}"
cors_origins_check "${APP_CORS_ALLOWED_ORIGIN_PATTERNS-}"
check APP_MAIL_HOST "${APP_MAIL_HOST-}"
port_check APP_MAIL_PORT "${APP_MAIL_PORT-}"
check APP_MAIL_USERNAME "${APP_MAIL_USERNAME-}"
check APP_MAIL_PASSWORD "${APP_MAIL_PASSWORD-}"
email_check APP_AUTH_VERIFICATION_MAIL_FROM "${APP_AUTH_VERIFICATION_MAIL_FROM-}"
check APP_AUTH_VERIFICATION_MAIL_SUBJECT "${APP_AUTH_VERIFICATION_MAIL_SUBJECT-}"
check APP_AUTH_VERIFICATION_BRAND_NAME "${APP_AUTH_VERIFICATION_BRAND_NAME-}"
prefix_check APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID "${APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID-}" AC
check APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN "${APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN-}"
url_check APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL "${APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL-}"
twilio_sender_check
prefix_check APP_PAYMENT_STRIPE_SECRET_KEY "${APP_PAYMENT_STRIPE_SECRET_KEY-}" sk_test_
prefix_check APP_PAYMENT_STRIPE_ENDPOINT_SECRET "${APP_PAYMENT_STRIPE_ENDPOINT_SECRET-}" whsec_
prefix_check VITE_STRIPE_PUBLISHABLE_KEY "${VITE_STRIPE_PUBLISHABLE_KEY-}" pk_test_
check APP_S3_BUCKET "${APP_S3_BUCKET-}"
check APP_S3_REGION "${APP_S3_REGION-}"
url_check APP_S3_ENDPOINT "${APP_S3_ENDPOINT-}"
url_check APP_S3_PUBLIC_BASE_URL "${APP_S3_PUBLIC_BASE_URL-}"
check APP_S3_ACCESS_KEY "${APP_S3_ACCESS_KEY-}"
check APP_S3_SECRET_KEY "${APP_S3_SECRET_KEY-}"
endpoint_url_check APP_SEARCH_BASE_URL "${APP_SEARCH_BASE_URL-}"
elasticsearch_index_check "${APP_SEARCH_INDEX_NAME-}"
url_check PUBLIC_SITE_URL "${PUBLIC_SITE_URL-}"
url_check PRERENDER_API_BASE_URL "${PRERENDER_API_BASE_URL-}"
url_check VITE_API_BASE_URL "${VITE_API_BASE_URL-}"
wss_url_check VITE_WS_BASE_URL "${VITE_WS_BASE_URL-}"

if [[ "${APP_AUTH_VERIFICATION_ALIYUN_ENABLED-}" == "true" ]]; then
  prefix_check APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_ID "${APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_ID-}" LTAI
  check APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_SECRET "${APP_AUTH_VERIFICATION_ALIYUN_ACCESS_KEY_SECRET-}"
  check APP_AUTH_VERIFICATION_ALIYUN_SIGN_NAME "${APP_AUTH_VERIFICATION_ALIYUN_SIGN_NAME-}"
  prefix_check APP_AUTH_VERIFICATION_ALIYUN_TEMPLATE_CODE "${APP_AUTH_VERIFICATION_ALIYUN_TEMPLATE_CODE-}" SMS_
  url_check APP_AUTH_VERIFICATION_ALIYUN_ENDPOINT "${APP_AUTH_VERIFICATION_ALIYUN_ENDPOINT-}"
  check APP_AUTH_VERIFICATION_ALIYUN_REGION_ID "${APP_AUTH_VERIFICATION_ALIYUN_REGION_ID-}"
  if ! csv_contains "${APP_AUTH_VERIFICATION_ALIYUN_ROUTE_PREFIXES-}" "+86"; then
    printf '[invalid] APP_AUTH_VERIFICATION_ALIYUN_ROUTE_PREFIXES must include +86\n' >&2
    failures=$((failures + 1))
  fi
fi

if $check_cli; then
  if command -v stripe >/dev/null 2>&1; then
    printf '[ok]      stripe CLI (%s)\n' "$(stripe --version 2>/dev/null | head -1)"
  else
    printf '[missing] stripe CLI\n' >&2
    failures=$((failures + 1))
  fi
fi

if [[ -n "$health_url" ]]; then
  if curl --fail --silent --show-error --max-time 15 "$health_url" >/dev/null; then
    printf '[ok]      health %s\n' "$health_url"
  else
    printf '[invalid] health %s\n' "$health_url" >&2
    failures=$((failures + 1))
  fi
fi

if [[ "$failures" -gt 0 ]]; then
  printf '\nEU pre-release configuration failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi
printf '\nEU pre-release configuration is ready for credentialed verification and Stripe E2E.\n'
