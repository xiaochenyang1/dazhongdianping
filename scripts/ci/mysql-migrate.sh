#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -d "$script_dir/migrations" && -f "$script_dir/migrations.sha256" ]]; then
  migrations_dir="$script_dir/migrations"
  manifest_path="$script_dir/migrations.sha256"
else
  repository_mysql_dir="$(cd "$script_dir/../.." && pwd -P)/sql/mysql"
  migrations_dir="$repository_mysql_dir"
  manifest_path="$repository_mysql_dir/migrations.sha256"
fi
defaults_file=""
mode="apply"
baseline_version=""
release_version="manual"
lock_file="/tmp/dzdp-schema-migration-${UID}.lock"
lock_timeout_seconds=60
dry_run=false
history_table="dzdp_schema_migration"

usage() {
  cat <<'EOF'
Usage: mysql-migrate.sh [options]

Options:
  --defaults-extra-file PATH  MySQL client option file (required unless --dry-run).
  --mode apply|verify         Apply pending migrations or strictly verify history.
  --baseline-version VERSION  Explicit first-takeover baseline (minimum 2).
  --release-version VERSION   Audited release version stored in migration history.
  --migrations-dir PATH       Migration directory (defaults beside this script).
  --manifest PATH             SHA-256 manifest (defaults beside this script).
  --lock-file PATH            Host deployment lock file.
  --lock-timeout-seconds N    Host/database lock wait time (default 60).
  --dry-run                   Validate the artifact and print the database plan only.
  --help                      Show this help.
EOF
}

fail() {
  printf '[mysql-migrate] ERROR: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --defaults-extra-file)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      defaults_file="$2"
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      mode="$2"
      shift 2
      ;;
    --baseline-version)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      baseline_version="$2"
      shift 2
      ;;
    --release-version)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      release_version="$2"
      shift 2
      ;;
    --migrations-dir)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      migrations_dir="$2"
      shift 2
      ;;
    --manifest)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      manifest_path="$2"
      shift 2
      ;;
    --lock-file)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      lock_file="$2"
      shift 2
      ;;
    --lock-timeout-seconds)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      lock_timeout_seconds="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ "$mode" == "apply" || "$mode" == "verify" ]] || fail "mode must be apply or verify"
[[ "$release_version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] ||
  fail "release version contains unsupported characters"
if [[ -n "$baseline_version" && ! "$baseline_version" =~ ^[0-9]+$ ]]; then
  fail "baseline version must be an integer"
fi
[[ "$lock_timeout_seconds" =~ ^[0-9]+$ ]] || fail "lock timeout must be an integer"
(( lock_timeout_seconds >= 1 && lock_timeout_seconds <= 300 )) ||
  fail "lock timeout must be between 1 and 300 seconds"

command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
[[ -d "$migrations_dir" ]] || fail "migration directory not found: $migrations_dir"
[[ -f "$manifest_path" ]] || fail "migration manifest not found: $manifest_path"
migrations_dir="$(cd "$migrations_dir" && pwd -P)"
manifest_path="$(cd "$(dirname "$manifest_path")" && pwd -P)/$(basename "$manifest_path")"

manifest_files=()
manifest_checksums=()
manifest_versions=()
expected_version=3
manifest_pattern='^([0-9a-f]{64})  ([0-9]{2,}_[A-Za-z0-9_]+_migration\.sql)$'

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ $manifest_pattern ]] || fail "invalid migration manifest line"
  checksum="${BASH_REMATCH[1]}"
  filename="${BASH_REMATCH[2]}"
  version_text="${filename%%_*}"
  version=$((10#$version_text))
  [[ "$version" -eq "$expected_version" ]] ||
    fail "migration versions must be contiguous from 03; expected $expected_version, found $version"
  manifest_checksums+=("$checksum")
  manifest_files+=("$filename")
  manifest_versions+=("$version")
  expected_version=$((expected_version + 1))
done < "$manifest_path"

[[ ${#manifest_files[@]} -gt 0 ]] || fail "migration manifest is empty"
latest_version="${manifest_versions[${#manifest_versions[@]} - 1]}"

actual_sql_count=0
while IFS= read -r sql_file; do
  actual_sql_count=$((actual_sql_count + 1))
  sql_name="$(basename "$sql_file")"
  declared=false
  for declared_name in "${manifest_files[@]}"; do
    if [[ "$sql_name" == "$declared_name" ]]; then
      declared=true
      break
    fi
  done
  $declared || fail "SQL file is not declared in migration manifest: $sql_name"
done < <(find "$migrations_dir" -maxdepth 1 -type f -name '*_migration.sql' | sort)

[[ "$actual_sql_count" -eq "${#manifest_files[@]}" ]] ||
  fail "migration manifest and SQL file count differ"

if ! (cd "$migrations_dir" && sha256sum --check --strict --quiet "$manifest_path"); then
  fail "migration artifact checksum verification failed"
fi

if [[ -n "$baseline_version" ]]; then
  baseline_number=$((10#$baseline_version))
  [[ "$baseline_number" -ge 2 && "$baseline_number" -le "$latest_version" ]] ||
    fail "baseline version must be between 2 and $latest_version"
fi

if $dry_run; then
  printf '[mysql-migrate] artifact verified: versions 03-%02d (%d files)\n' \
    "$latest_version" "${#manifest_files[@]}"
  printf '[mysql-migrate] mode: %s\n' "$mode"
  if [[ -n "$baseline_version" ]]; then
    printf '[mysql-migrate] first-takeover baseline: %s\n' "$baseline_version"
  else
    printf '[mysql-migrate] first takeover requires --baseline-version; existing history will be verified.\n'
  fi
  printf '[mysql-migrate] dry-run does not connect to or modify MySQL.\n'
  exit 0
fi

command -v mysql >/dev/null 2>&1 || fail "mysql client is required"
[[ -n "$defaults_file" ]] || fail "--defaults-extra-file is required"
[[ -f "$defaults_file" && -r "$defaults_file" ]] ||
  fail "MySQL defaults file must be a readable regular file"

if permissions="$(stat -c '%a' "$defaults_file" 2>/dev/null)"; then
  :
elif permissions="$(stat -f '%Lp' "$defaults_file" 2>/dev/null)"; then
  :
else
  fail "unable to inspect MySQL defaults file permissions"
fi
[[ "$permissions" =~ ^[0-7]{3,4}$ ]] || fail "unable to validate MySQL defaults file permissions"
permission_value=$((8#$permissions))
(( (permission_value & 077) == 0 )) ||
  fail "MySQL defaults file must not be readable, writable, or executable by group/other"

mkdir -p "$(dirname "$lock_file")"
lock_dir=""
db_lock_session_dir=""
db_lock_pid=""
db_lock_open=false

cleanup_locks() {
  exit_status=$?
  trap - EXIT
  set +e
  if $db_lock_open; then
    printf '%s\n' "SELECT RELEASE_LOCK(CONCAT('dzdp-schema-migration:', LEFT(SHA2(DATABASE(), 256), 40)));" >&8
    IFS= read -r _released <&7
    exec 8>&-
    exec 7<&-
    wait "$db_lock_pid" 2>/dev/null
  fi
  if [[ -n "$db_lock_session_dir" ]]; then
    rm -f "$db_lock_session_dir/input" "$db_lock_session_dir/output"
    rmdir "$db_lock_session_dir" 2>/dev/null
  fi
  if [[ -n "$lock_dir" ]]; then
    rmdir "$lock_dir" 2>/dev/null
  fi
  exit "$exit_status"
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"$lock_file"
  flock -w "$lock_timeout_seconds" 9 || fail "timed out waiting for the database migration lock"
else
  lock_dir="${lock_file}.d"
  mkdir "$lock_dir" 2>/dev/null || fail "database migration lock is already held"
fi
trap cleanup_locks EXIT

mysql_client=(
  mysql
  "--defaults-extra-file=$defaults_file"
  --connect-timeout=10
  --batch
  --raw
  --skip-column-names
  --silent
)

query_mysql() {
  "${mysql_client[@]}" -e "$1"
}

database_name="$(query_mysql 'SELECT DATABASE();')"
[[ -n "$database_name" && "$database_name" != "NULL" ]] ||
  fail "MySQL defaults file must select a target database"

db_lock_session_dir="$(mktemp -d "${TMPDIR:-/tmp}/dzdp-mysql-lock.XXXXXX")"
mkfifo "$db_lock_session_dir/input" "$db_lock_session_dir/output"
"${mysql_client[@]}" --unbuffered \
  < "$db_lock_session_dir/input" > "$db_lock_session_dir/output" &
db_lock_pid=$!
exec 8>"$db_lock_session_dir/input"
exec 7<"$db_lock_session_dir/output"
db_lock_open=true
printf '%s\n' "SELECT GET_LOCK(CONCAT('dzdp-schema-migration:', LEFT(SHA2(DATABASE(), 256), 40)), $lock_timeout_seconds);" >&8
if ! IFS= read -r db_lock_acquired <&7; then
  fail "database migration lock session terminated unexpectedly"
fi
[[ "$db_lock_acquired" == "1" ]] || fail "timed out waiting for the database-level migration lock"

history_exists="$(query_mysql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = '$history_table';")"
[[ "$history_exists" == "0" || "$history_exists" == "1" ]] ||
  fail "unable to determine migration history state"

if [[ "$history_exists" == "0" ]]; then
  [[ "$mode" == "apply" ]] ||
    fail "strict verification requires an existing migration history table"
  [[ -n "$baseline_version" ]] ||
    fail "first takeover requires an explicit --baseline-version; refusing to infer schema state"

  anchor_count="$(query_mysql "SELECT COUNT(DISTINCT table_name) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name IN ('app_user','shop','admin_permission','payment','refund');")"
  [[ "$anchor_count" == "5" ]] ||
    fail "target database is not a prepared application schema; provision it outside release deployment"

  bootstrap_sql='CREATE TABLE dzdp_schema_migration (
    version INT UNSIGNED NOT NULL,
    script_name VARCHAR(255) NOT NULL,
    checksum_sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    state VARCHAR(16) NOT NULL,
    release_version VARCHAR(128) NOT NULL,
    installed_by VARCHAR(288) NOT NULL,
    started_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    finished_at TIMESTAMP(6) NULL,
    PRIMARY KEY (version),
    UNIQUE KEY uk_dzdp_schema_migration_script (script_name)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'

  baseline_values=""
  for index in "${!manifest_files[@]}"; do
    version="${manifest_versions[$index]}"
    if [[ "$version" -le "$baseline_number" ]]; then
      value="($version, '${manifest_files[$index]}', '${manifest_checksums[$index]}', 'BASELINED', '$release_version', CURRENT_USER(), CURRENT_TIMESTAMP(6))"
      if [[ -n "$baseline_values" ]]; then
        baseline_values="$baseline_values, $value"
      else
        baseline_values="$value"
      fi
    fi
  done
  if [[ -n "$baseline_values" ]]; then
    bootstrap_sql="$bootstrap_sql INSERT INTO $history_table (version, script_name, checksum_sha256, state, release_version, installed_by, finished_at) VALUES $baseline_values;"
  fi
  query_mysql "$bootstrap_sql" >/dev/null
  printf '[mysql-migrate] initialized history with explicit baseline %s.\n' "$baseline_version"
elif [[ -n "$baseline_version" ]]; then
  fail "--baseline-version is only allowed when migration history does not yet exist"
fi

while IFS=$'\t' read -r stored_version stored_name stored_checksum stored_state; do
  [[ -n "$stored_version" ]] || continue
  matched_index=""
  for index in "${!manifest_versions[@]}"; do
    if [[ "$stored_version" == "${manifest_versions[$index]}" ]]; then
      matched_index="$index"
      break
    fi
  done
  [[ -n "$matched_index" ]] ||
    fail "database history contains version $stored_version that is absent from this release"
  [[ "$stored_name" == "${manifest_files[$matched_index]}" ]] ||
    fail "database history script name mismatch for version $stored_version"
  [[ "$stored_state" == "APPLIED" || "$stored_state" == "BASELINED" ]] ||
    fail "migration version $stored_version is $stored_state; manual repair is required before deployment"
  [[ "$stored_checksum" == "${manifest_checksums[$matched_index]}" ]] ||
    fail "database history checksum mismatch for version $stored_version"
done < <(query_mysql "SELECT version, script_name, checksum_sha256, state FROM $history_table ORDER BY version;")

pending_indexes=()
for index in "${!manifest_versions[@]}"; do
  version="${manifest_versions[$index]}"
  history_row="$(query_mysql "SELECT CONCAT(script_name, CHAR(9), checksum_sha256) FROM $history_table WHERE version = $version;")"
  if [[ -z "$history_row" ]]; then
    pending_indexes+=("$index")
  fi
done

if [[ "$mode" == "verify" && ${#pending_indexes[@]} -gt 0 ]]; then
  first_pending="${manifest_files[${pending_indexes[0]}]}"
  fail "strict verification found pending migration: $first_pending"
fi

if [[ "$mode" == "apply" ]]; then
  if [[ ${#pending_indexes[@]} -gt 0 ]]; then
    for index in "${pending_indexes[@]}"; do
      version="${manifest_versions[$index]}"
      filename="${manifest_files[$index]}"
      checksum="${manifest_checksums[$index]}"
      printf '[mysql-migrate] applying %s\n' "$filename"
      query_mysql "INSERT INTO $history_table (version, script_name, checksum_sha256, state, release_version, installed_by) VALUES ($version, '$filename', '$checksum', 'PENDING', '$release_version', CURRENT_USER());" >/dev/null
      if ! "${mysql_client[@]}" < "$migrations_dir/$filename"; then
        query_mysql "UPDATE $history_table SET state = 'FAILED', finished_at = CURRENT_TIMESTAMP(6) WHERE version = $version AND state = 'PENDING';" >/dev/null || true
        fail "migration failed and may be partially applied: $filename; history is FAILED and requires manual repair"
      fi
      if ! query_mysql "UPDATE $history_table SET state = 'APPLIED', finished_at = CURRENT_TIMESTAMP(6) WHERE version = $version AND state = 'PENDING';" >/dev/null; then
        fail "migration SQL completed but history remains PENDING: $filename; manual verification is required"
      fi
    done
  fi
fi

for index in "${!manifest_versions[@]}"; do
  version="${manifest_versions[$index]}"
  expected_name="${manifest_files[$index]}"
  expected_checksum="${manifest_checksums[$index]}"
  history_row="$(query_mysql "SELECT CONCAT(script_name, CHAR(9), checksum_sha256, CHAR(9), state) FROM $history_table WHERE version = $version;")"
  [[ "$history_row" == "$expected_name"$'\t'"$expected_checksum"$'\t'"APPLIED" ||
     "$history_row" == "$expected_name"$'\t'"$expected_checksum"$'\t'"BASELINED" ]] ||
    fail "post-migration verification failed for version $version"
done

printf '[mysql-migrate] database %s verified through version %02d in %s mode.\n' \
  "$database_name" "$latest_version" "$mode"
