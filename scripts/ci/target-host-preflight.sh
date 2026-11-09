#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: target-host-preflight.sh [options]

Runs a read-only deployment-target audit and emits a tab-separated protocol.
The report contains check names and status messages, never configuration values.

Required options:
  --environment <test|pre|prod>
  --region <CN|EU>
  --remote-root <absolute path>
  --runtime-env-file <absolute path>
  --database-defaults-file <absolute path>
  --service <systemd unit>          Repeat for every deployment service.

Optional:
  --minimum-free-kb <integer>       Defaults to 2097152 (2 GiB).
  --help
EOF
}

environment=""
region=""
remote_root=""
runtime_env_file=""
database_defaults_file=""
minimum_free_kb=2097152
services=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment) environment="${2-}"; shift 2 ;;
    --region) region="${2-}"; shift 2 ;;
    --remote-root) remote_root="${2-}"; shift 2 ;;
    --runtime-env-file) runtime_env_file="${2-}"; shift 2 ;;
    --database-defaults-file) database_defaults_file="${2-}"; shift 2 ;;
    --minimum-free-kb) minimum_free_kb="${2-}"; shift 2 ;;
    --service) services+=("${2-}"); shift 2 ;;
    --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

passed=0
failed=0
warnings=0

emit() {
  local status="$1"
  local name="$2"
  local message="$3"
  message="${message//$'\t'/ }"
  message="${message//$'\r'/ }"
  message="${message//$'\n'/ }"
  printf 'CHECK\t%s\t%s\t%s\n' "$status" "$name" "$message"
  case "$status" in
    PASS) passed=$((passed + 1)) ;;
    FAIL) failed=$((failed + 1)) ;;
    WARN) warnings=$((warnings + 1)) ;;
  esac
}

finish() {
  printf 'SUMMARY\t%d\t%d\t%d\n' "$passed" "$failed" "$warnings"
  if ((failed > 0)); then
    exit 1
  fi
  exit 0
}

is_safe_absolute_path() {
  local value="$1"
  [[ "$value" =~ ^/[A-Za-z0-9._/-]+$ ]] &&
    [[ "$value" != "/" ]] &&
    [[ "$value" != *"//"* ]] &&
    [[ ! "$value" =~ (^|/)\.{1,2}(/|$) ]]
}

if [[ "$environment" != "test" && "$environment" != "pre" && "$environment" != "prod" ]]; then
  emit FAIL input "environment is invalid"
fi
if [[ "$region" != "CN" && "$region" != "EU" ]]; then
  emit FAIL input "region is invalid"
fi
if [[ "$environment" == "test" && "$region" != "EU" ]]; then
  emit FAIL input "test is fixed to region EU"
fi
if ! is_safe_absolute_path "$remote_root"; then
  emit FAIL input "remote root is invalid"
fi
if ! is_safe_absolute_path "$runtime_env_file"; then
  emit FAIL input "runtime env file path is invalid"
fi
if ! is_safe_absolute_path "$database_defaults_file"; then
  emit FAIL input "database defaults file path is invalid"
fi
if [[ ! "$minimum_free_kb" =~ ^[0-9]+$ ]] || ((minimum_free_kb < 1)); then
  emit FAIL input "minimum free space is invalid"
fi
if ((${#services[@]} == 0)); then
  emit FAIL input "at least one systemd service is required"
fi
for service in "${services[@]}"; do
  if [[ ! "$service" =~ ^[A-Za-z0-9_.@-]+$ ]]; then
    emit FAIL input "a systemd service name is invalid"
  fi
done
if ((failed > 0)); then
  finish
fi

if [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]]; then
  emit PASS operating-system "Linux target detected"
else
  emit FAIL operating-system "target must run Linux"
fi

required_tools=(
  bash awk chmod curl df find flock grep head java ln mkdir mysql readlink rm sed
  sha256sum sort stat sudo systemctl timeout tr unzip
)
missing_tools=()
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing_tools+=("$tool")
  fi
done
if ((${#missing_tools[@]} == 0)); then
  emit PASS deployment-tools "all deployment and connectivity tools are installed"
else
  emit FAIL deployment-tools "missing tools: $(IFS=,; printf '%s' "${missing_tools[*]}")"
fi

java_version_line="$(java -version 2>&1 | head -1 || true)"
java_major="$(printf '%s' "$java_version_line" | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p')"
if [[ "$java_major" =~ ^[0-9]+$ ]] && ((java_major >= 17)); then
  emit PASS java-runtime "Java runtime is version 17 or newer"
else
  emit FAIL java-runtime "Java runtime must be version 17 or newer"
fi

if [[ -d "$remote_root" && ! -L "$remote_root" && -w "$remote_root" ]]; then
  emit PASS release-root "release root exists, is writable, and is not a symlink"
else
  emit FAIL release-root "release root must exist, be writable, and not be a symlink"
fi

release_root="$remote_root/releases"
layout_ok=true
if [[ -e "$release_root" || -L "$release_root" ]]; then
  if [[ ! -d "$release_root" || -L "$release_root" ]]; then
    layout_ok=false
  fi
fi
for link_name in current previous; do
  link_path="$remote_root/$link_name"
  if [[ -e "$link_path" || -L "$link_path" ]]; then
    if [[ ! -L "$link_path" ]]; then
      layout_ok=false
      continue
    fi
    resolved_link="$(readlink -f "$link_path" 2>/dev/null || true)"
    if [[ -z "$resolved_link" || ! -d "$resolved_link" || "$resolved_link" != "$release_root/"* ]]; then
      layout_ok=false
    fi
  fi
done
if $layout_ok; then
  emit PASS release-layout "managed release directories and symlinks are safe"
else
  emit FAIL release-layout "release layout contains an unsafe directory or symlink"
fi

available_kb="$(df -Pk "$remote_root" 2>/dev/null | awk 'NR == 2 { print $4 }' || true)"
if [[ "$available_kb" =~ ^[0-9]+$ ]] && ((available_kb >= minimum_free_kb)); then
  emit PASS disk-space "minimum free-space threshold is satisfied"
else
  emit FAIL disk-space "free space is below the configured threshold or could not be measured"
fi

check_private_file() {
  local check_prefix="$1"
  local path="$2"
  if [[ ! -f "$path" || -L "$path" || ! -r "$path" ]]; then
    emit FAIL "$check_prefix-file" "file must exist, be readable, regular, and not be a symlink"
    return 1
  fi
  emit PASS "$check_prefix-file" "private file exists and is readable"

  local mode
  mode="$(stat -c '%a' "$path" 2>/dev/null || true)"
  mode="${mode: -3}"
  if [[ "$mode" == "400" || "$mode" == "600" ]]; then
    emit PASS "$check_prefix-permissions" "private file denies group and other permissions"
  else
    emit FAIL "$check_prefix-permissions" "private file must deny group and other permissions"
    return 1
  fi
  return 0
}

runtime_file_ready=false
if check_private_file runtime-env "$runtime_env_file"; then
  runtime_file_ready=true
fi
database_file_ready=false
if check_private_file database-defaults "$database_defaults_file"; then
  database_file_ready=true
fi

config_keys=()
config_values=()
set_config_value() {
  local requested_key="$1"
  local requested_value="$2"
  local index
  for ((index = 0; index < ${#config_keys[@]}; index++)); do
    if [[ "${config_keys[$index]}" == "$requested_key" ]]; then
      return 1
    fi
  done
  config_keys+=("$requested_key")
  config_values+=("$requested_value")
}
get_config_value() {
  local requested_key="$1"
  local index
  for ((index = 0; index < ${#config_keys[@]}; index++)); do
    if [[ "${config_keys[$index]}" == "$requested_key" ]]; then
      printf '%s' "${config_values[$index]}"
      return 0
    fi
  done
  return 1
}
runtime_syntax_valid=true
if $runtime_file_ready; then
  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    raw_line="${raw_line%$'\r'}"
    trimmed_line="${raw_line#"${raw_line%%[![:space:]]*}"}"
    if [[ -z "$trimmed_line" || "$trimmed_line" == \#* ]]; then
      continue
    fi
    if [[ "$raw_line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      value="${value#"${value%%[![:space:]]*}"}"
      value="${value%"${value##*[![:space:]]}"}"
      if [[ ${#value} -ge 2 && "$value" == \"*\" ]]; then
        value="${value:1:${#value}-2}"
      elif [[ ${#value} -ge 2 && "$value" == \'*\' ]]; then
        value="${value:1:${#value}-2}"
      fi
      if ! set_config_value "$key" "$value"; then
        runtime_syntax_valid=false
      fi
    else
      runtime_syntax_valid=false
    fi
  done < "$runtime_env_file"
fi

invalid_runtime_names=()
mark_runtime_invalid() {
  local requested_name="$1"
  local existing_name
  if ((${#invalid_runtime_names[@]} > 0)); then
    for existing_name in "${invalid_runtime_names[@]}"; do
      if [[ "$existing_name" == "$requested_name" ]]; then
        return
      fi
    done
  fi
  invalid_runtime_names+=("$requested_name")
}
runtime_value_present() {
  local value="${1-}"
  [[ -n "${value//[[:space:]]/}" ]] && ! printf '%s' "$value" | grep -Eqi 'CHANGE_ME|xxxxx'
}
require_runtime_value() {
  local name="$1"
  local value
  value="$(get_config_value "$name" || true)"
  if ! runtime_value_present "$value"; then
    mark_runtime_invalid "$name"
  fi
}
require_runtime_equals() {
  local name="$1"
  local expected="$2"
  local value
  value="$(get_config_value "$name" || true)"
  if [[ "$value" != "$expected" ]]; then
    mark_runtime_invalid "$name"
  fi
}
require_runtime_port() {
  local name="$1"
  local value
  value="$(get_config_value "$name" || true)"
  if [[ ! "$value" =~ ^[0-9]+$ ]] || ((10#$value < 1 || 10#$value > 65535)); then
    mark_runtime_invalid "$name"
  fi
}
require_runtime_url() {
  local name="$1"
  local schemes="$2"
  local value
  value="$(get_config_value "$name" || true)"
  if ! runtime_value_present "$value" || [[ ! "$value" =~ ^($schemes)://[^[:space:]/@]+(:[0-9]+)?(/[^[:space:]]*)?$ ]]; then
    mark_runtime_invalid "$name"
  fi
}
require_runtime_prefix() {
  local name="$1"
  local prefix="$2"
  local value
  value="$(get_config_value "$name" || true)"
  if ! runtime_value_present "$value" || [[ "$value" != "$prefix"* ]]; then
    mark_runtime_invalid "$name"
  fi
}
require_runtime_secret_length() {
  local name="$1"
  local value
  value="$(get_config_value "$name" || true)"
  if ! runtime_value_present "$value" || ((${#value} < 32)); then
    mark_runtime_invalid "$name"
  fi
}

if $runtime_file_ready; then
  if ! $runtime_syntax_valid; then
    mark_runtime_invalid file-syntax
  fi
  required_runtime_values=(
    APP_DB_HOST APP_DB_NAME APP_DB_USERNAME APP_DB_PASSWORD
    APP_TRUSTED_PROXY_REGEX APP_REDIS_HOST APP_REDIS_PASSWORD APP_STATE_STORE_KEY_PREFIX
    APP_AUTH_VERIFICATION_MAIL_FROM APP_AUTH_VERIFICATION_MAIL_SUBJECT
    APP_AUTH_VERIFICATION_BRAND_NAME APP_MAIL_HOST APP_MAIL_USERNAME APP_MAIL_PASSWORD
    APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN
    APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES
    APP_PAYMENT_STRIPE_SECRET_KEY APP_PAYMENT_STRIPE_ENDPOINT_SECRET
    APP_SEARCH_BASE_URL APP_SEARCH_INDEX_NAME APP_S3_BUCKET APP_S3_REGION
    APP_S3_ENDPOINT APP_S3_PUBLIC_BASE_URL APP_S3_ACCESS_KEY APP_S3_SECRET_KEY
    APP_CORS_ALLOWED_ORIGIN_PATTERNS PUBLIC_SITE_URL PRERENDER_API_BASE_URL
    VITE_API_BASE_URL VITE_WS_BASE_URL VITE_STRIPE_PUBLISHABLE_KEY
  )
  for name in "${required_runtime_values[@]}"; do
    require_runtime_value "$name"
  done
  require_runtime_equals APP_RUNTIME_MODE "$environment"
  require_runtime_equals APP_STATE_STORE_PROVIDER redis
  require_runtime_equals APP_REDIS_HEALTH_ENABLED true
  require_runtime_equals APP_AD_CLICK_DEDUPE_SECONDS 1800
  require_runtime_equals APP_FILE_STORAGE_PROVIDER s3
  require_runtime_equals APP_SEARCH_PROVIDER elasticsearch
  require_runtime_equals APP_SEARCH_FALLBACK_ON_ERROR false
  require_runtime_equals APP_PAYMENT_STRIPE_ENABLED true
  require_runtime_equals APP_PAYMENT_MOCK_ENABLED false
  require_runtime_equals APP_AUTH_VERIFICATION_MOCK_ENABLED false
  require_runtime_equals APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE false
  require_runtime_equals APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED false
  require_runtime_equals APP_AUTH_VERIFICATION_MAIL_ENABLED true
  require_runtime_equals APP_MAIL_SMTP_AUTH true
  require_runtime_equals APP_MAIL_STARTTLS_ENABLED true
  require_runtime_equals APP_MAIL_HEALTH_ENABLED true
  require_runtime_equals APP_AUTH_VERIFICATION_TWILIO_ENABLED true
  require_runtime_equals APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES '*'
  require_runtime_equals APP_LAUNCH_DEFERRED_FEATURES_ENABLED false
  require_runtime_equals APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED false
  require_runtime_equals APP_LAUNCH_EU_SECKILL_ENABLED false
  require_runtime_equals APP_LAUNCH_EU_GROUP_BUY_ENABLED false
  require_runtime_equals APP_PUSH_ENABLED false
  require_runtime_equals VITE_DEFAULT_REGION "$region"
  require_runtime_equals PRERENDER_REGION "$region"
  require_runtime_port APP_DB_PORT
  require_runtime_port APP_REDIS_PORT
  require_runtime_port APP_MAIL_PORT
  redis_database="$(get_config_value APP_REDIS_DATABASE || true)"
  if [[ ! "$redis_database" =~ ^[0-9]+$ ]]; then
    mark_runtime_invalid APP_REDIS_DATABASE
  fi
  s3_path_style="$(get_config_value APP_S3_PATH_STYLE_ACCESS_ENABLED || true)"
  if [[ "$s3_path_style" != "true" && "$s3_path_style" != "false" ]]; then
    mark_runtime_invalid APP_S3_PATH_STYLE_ACCESS_ENABLED
  fi
  require_runtime_url APP_S3_ENDPOINT https
  require_runtime_url APP_S3_PUBLIC_BASE_URL https
  require_runtime_url APP_SEARCH_BASE_URL 'https?'
  require_runtime_url APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL https
  require_runtime_url PUBLIC_SITE_URL https
  require_runtime_url PRERENDER_API_BASE_URL https
  require_runtime_url VITE_API_BASE_URL https
  require_runtime_url VITE_WS_BASE_URL wss
  require_runtime_secret_length APP_AUTH_JWT_SECRET
  require_runtime_secret_length APP_PAYMENT_NOTIFY_SECRET
  require_runtime_prefix APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID AC
  require_runtime_prefix APP_PAYMENT_STRIPE_ENDPOINT_SECRET whsec_
  if [[ "$environment" == "prod" ]]; then
    require_runtime_prefix APP_PAYMENT_STRIPE_SECRET_KEY sk_live_
    require_runtime_prefix VITE_STRIPE_PUBLISHABLE_KEY pk_live_
  else
    require_runtime_prefix APP_PAYMENT_STRIPE_SECRET_KEY sk_test_
    require_runtime_prefix VITE_STRIPE_PUBLISHABLE_KEY pk_test_
  fi
  twilio_from="$(get_config_value APP_AUTH_VERIFICATION_TWILIO_FROM || true)"
  twilio_messaging_service="$(get_config_value APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID || true)"
  twilio_excluded_routes="$(get_config_value APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES || true)"
  if ! runtime_value_present "$twilio_from" && ! runtime_value_present "$twilio_messaging_service"; then
    mark_runtime_invalid APP_AUTH_VERIFICATION_TWILIO_FROM_OR_MESSAGING_SERVICE_SID
  fi
  if [[ "$twilio_excluded_routes" != *+86* ]]; then
    mark_runtime_invalid APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES
  fi

  invalid_names=()
  if ((${#invalid_runtime_names[@]} > 0)); then
    while IFS= read -r name; do
      invalid_names+=("$name")
    done < <(printf '%s\n' "${invalid_runtime_names[@]}" | sort)
  fi
  if ((${#invalid_names[@]} == 0)); then
    emit PASS runtime-config "required runtime settings are present and valid"
  else
    emit FAIL runtime-config "missing or invalid names: $(IFS=,; printf '%s' "${invalid_names[*]}")"
  fi
else
  emit FAIL runtime-config "runtime configuration could not be inspected"
fi

if $database_file_ready; then
  mysql_result="$(mysql --defaults-extra-file="$database_defaults_file" --batch --skip-column-names -e 'SELECT 1' 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ "$mysql_result" == "1" ]]; then
    emit PASS mysql-connectivity "credentialed read-only query succeeded"
  else
    emit FAIL mysql-connectivity "credentialed read-only query failed"
  fi
else
  emit FAIL mysql-connectivity "database defaults file is unavailable"
fi

service_units_ready=true
for service in "${services[@]}"; do
  load_state="$(systemctl show "$service" --property=LoadState --value 2>/dev/null || true)"
  if [[ "$load_state" != "loaded" ]]; then
    service_units_ready=false
  fi
done
if $service_units_ready; then
  emit PASS systemd-services "all deployment service units are loaded"
else
  emit FAIL systemd-services "one or more deployment service units are not loaded"
fi

sudo_ready=true
if ! sudo -n -l -- systemctl restart "${services[@]}" >/dev/null 2>&1; then
  sudo_ready=false
fi
for service in "${services[@]}"; do
  if ! sudo -n -l -- systemctl is-active --quiet "$service" >/dev/null 2>&1; then
    sudo_ready=false
  fi
done
if $sudo_ready; then
  emit PASS sudo-policy "passwordless policy permits the exact deployment service commands"
else
  emit FAIL sudo-policy "passwordless policy does not permit the exact deployment service commands"
fi

tcp_reachable() {
  local host="$1"
  local port="$2"
  if [[ ! "$host" =~ ^[A-Za-z0-9._:-]+$ || ! "$port" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  timeout 5 bash -c 'exec 3<>"/dev/tcp/$1/$2"' bash "$host" "$port" >/dev/null 2>&1
}
http_reachable() {
  local url="$1"
  local code
  code="$(curl --silent --show-error --output /dev/null --connect-timeout 5 --max-time 15 --write-out '%{http_code}' "$url" 2>/dev/null || true)"
  [[ "$code" =~ ^[1-4][0-9][0-9]$ ]]
}

redis_host="$(get_config_value APP_REDIS_HOST || true)"
redis_port="$(get_config_value APP_REDIS_PORT || true)"
search_base_url="$(get_config_value APP_SEARCH_BASE_URL || true)"
s3_endpoint="$(get_config_value APP_S3_ENDPOINT || true)"
mail_host="$(get_config_value APP_MAIL_HOST || true)"
mail_port="$(get_config_value APP_MAIL_PORT || true)"
twilio_api_base_url="$(get_config_value APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL || true)"

if runtime_value_present "$redis_host" && tcp_reachable "$redis_host" "$redis_port"; then
  emit PASS redis-connectivity "Redis TCP endpoint is reachable; authenticated smoke remains required"
else
  emit FAIL redis-connectivity "Redis TCP endpoint is not reachable"
fi
if runtime_value_present "$search_base_url" && http_reachable "$search_base_url"; then
  emit PASS elasticsearch-connectivity "Elasticsearch endpoint is reachable; index smoke remains required"
else
  emit FAIL elasticsearch-connectivity "Elasticsearch endpoint is not reachable"
fi
if runtime_value_present "$s3_endpoint" && http_reachable "$s3_endpoint"; then
  emit PASS s3-connectivity "S3 endpoint is reachable; credentialed object smoke remains required"
else
  emit FAIL s3-connectivity "S3 endpoint is not reachable"
fi
if runtime_value_present "$mail_host" && tcp_reachable "$mail_host" "$mail_port"; then
  emit PASS smtp-connectivity "SMTP TCP endpoint is reachable; authenticated delivery smoke remains required"
else
  emit FAIL smtp-connectivity "SMTP TCP endpoint is not reachable"
fi
if runtime_value_present "$twilio_api_base_url" && http_reachable "$twilio_api_base_url"; then
  emit PASS twilio-connectivity "Twilio API is reachable; credentialed delivery smoke remains required"
else
  emit FAIL twilio-connectivity "Twilio API is not reachable"
fi
if http_reachable "https://api.stripe.com/v1/payment_intents"; then
  emit PASS stripe-connectivity "Stripe API is reachable; credentialed payment and webhook smoke remain required"
else
  emit FAIL stripe-connectivity "Stripe API is not reachable"
fi

finish
