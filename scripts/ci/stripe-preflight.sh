#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: source <eu-pre.env> && scripts/ci/stripe-preflight.sh [options]

Checks the EU pre-release configuration without printing secret values.
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

[[ "${APP_RUNTIME_MODE-}" == "prod" ]] || { printf '[invalid] APP_RUNTIME_MODE must be prod\n' >&2; failures=$((failures + 1)); }
[[ "${APP_PAYMENT_STRIPE_ENABLED-}" == "true" ]] || { printf '[invalid] APP_PAYMENT_STRIPE_ENABLED must be true\n' >&2; failures=$((failures + 1)); }
[[ "${APP_PAYMENT_MOCK_ENABLED-}" == "false" ]] || { printf '[invalid] APP_PAYMENT_MOCK_ENABLED must be false\n' >&2; failures=$((failures + 1)); }
[[ "${APP_STATE_STORE_PROVIDER-}" == "redis" ]] || { printf '[invalid] APP_STATE_STORE_PROVIDER must be redis\n' >&2; failures=$((failures + 1)); }
[[ "${APP_FILE_STORAGE_PROVIDER-}" == "s3" ]] || { printf '[invalid] APP_FILE_STORAGE_PROVIDER must be s3\n' >&2; failures=$((failures + 1)); }
[[ "${APP_SEARCH_PROVIDER-}" == "elasticsearch" ]] || { printf '[invalid] APP_SEARCH_PROVIDER must be elasticsearch\n' >&2; failures=$((failures + 1)); }
[[ "${APP_SEARCH_FALLBACK_ON_ERROR-}" == "false" ]] || { printf '[invalid] APP_SEARCH_FALLBACK_ON_ERROR must be false\n' >&2; failures=$((failures + 1)); }
[[ "${PRERENDER_REGION-}" == "EU" ]] || { printf '[invalid] PRERENDER_REGION must be EU\n' >&2; failures=$((failures + 1)); }

check APP_DB_HOST "${APP_DB_HOST-}"
check APP_DB_NAME "${APP_DB_NAME-}"
check APP_DB_USERNAME "${APP_DB_USERNAME-}"
check APP_DB_PASSWORD "${APP_DB_PASSWORD-}"
check APP_REDIS_HOST "${APP_REDIS_HOST-}"
check APP_REDIS_PASSWORD "${APP_REDIS_PASSWORD-}"
check APP_AUTH_JWT_SECRET "${APP_AUTH_JWT_SECRET-}"
check APP_PAYMENT_NOTIFY_SECRET "${APP_PAYMENT_NOTIFY_SECRET-}"
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

auth_jwt_secret="${APP_AUTH_JWT_SECRET-}"
if [[ "${#auth_jwt_secret}" -lt 32 ]]; then
  printf '[invalid] APP_AUTH_JWT_SECRET must contain at least 32 characters\n' >&2
  failures=$((failures + 1))
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
printf '\nEU pre-release configuration is ready for credentialed Stripe E2E.\n'
