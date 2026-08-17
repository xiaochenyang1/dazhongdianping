#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
runner="$repo_root/scripts/ci/mysql-migrate.sh"
source_dir="$repo_root/sql/mysql"
manifest="$source_dir/migrations.sha256"
container_name="dzdp-migration-$RANDOM-$$"
container_image="${MYSQL_MIGRATION_TEST_IMAGE:-mysql:8.4}"
run_dir="$(mktemp -d "${TMPDIR:-/tmp}/dzdp-migration-integration.XXXXXX")"
db_password="migration-test-$RANDOM-$RANDOM"
holder_pid=""

fail() {
  printf '[mysql-migration-integration] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  exit_status=$?
  trap - EXIT
  set +e
  if [[ -n "$holder_pid" ]]; then
    wait "$holder_pid" 2>/dev/null
  fi
  docker rm -f "$container_name" >/dev/null 2>&1
  rm -rf "$run_dir"
  exit "$exit_status"
}
trap cleanup EXIT

command -v docker >/dev/null 2>&1 || fail "docker is required"
command -v mysql >/dev/null 2>&1 || fail "mysql client is required"
docker info >/dev/null 2>&1 || fail "Docker daemon is not available"

docker run --detach --rm \
  --name "$container_name" \
  --env "MYSQL_ROOT_PASSWORD=$db_password" \
  --publish 127.0.0.1::3306 \
  "$container_image" >/dev/null

port_mapping="$(docker port "$container_name" 3306/tcp | head -n 1)"
db_port="${port_mapping##*:}"
[[ "$db_port" =~ ^[0-9]+$ ]] || fail "unable to resolve the mapped MySQL port"

server_defaults="$run_dir/server.cnf"
database_defaults="$run_dir/database.cnf"
{
  printf '[client]\n'
  printf 'protocol=tcp\n'
  printf 'host=127.0.0.1\n'
  printf 'port=%s\n' "$db_port"
  printf 'user=root\n'
  printf 'password=%s\n' "$db_password"
} > "$server_defaults"
cp "$server_defaults" "$database_defaults"
printf 'database=dzdp_migration_test\n' >> "$database_defaults"
chmod 600 "$server_defaults" "$database_defaults"

host_ready=false
host_error=""
for _attempt in $(seq 1 90); do
  if host_error="$(mysqladmin --defaults-extra-file="$server_defaults" ping --silent 2>&1)"; then
    host_ready=true
    break
  fi
  sleep 1
done
$host_ready || fail "MySQL mapped port did not become ready: $host_error"

mysql --defaults-extra-file="$server_defaults" \
  -e 'CREATE DATABASE dzdp_migration_test DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

mysql --defaults-extra-file="$database_defaults" <<'SQL'
CREATE TABLE app_user (id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE shop (id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE admin_region_scope (
  admin_id BIGINT NOT NULL,
  region VARCHAR(8) NOT NULL,
  PRIMARY KEY (admin_id, region)
);
CREATE TABLE import_batch (
  id BIGINT NOT NULL PRIMARY KEY,
  region VARCHAR(8) NOT NULL,
  admin_id BIGINT NOT NULL,
  status TINYINT NOT NULL DEFAULT 0
);
CREATE TABLE review_comment (
  id BIGINT NOT NULL PRIMARY KEY,
  status TINYINT NOT NULL DEFAULT 0
);
CREATE TABLE post_comment (
  id BIGINT NOT NULL PRIMARY KEY,
  status TINYINT NOT NULL DEFAULT 0
);
CREATE TABLE payment (
  id BIGINT NOT NULL PRIMARY KEY,
  channel_txn VARCHAR(64) NOT NULL DEFAULT ''
);
CREATE TABLE refund (
  id BIGINT NOT NULL PRIMARY KEY,
  audit_reason VARCHAR(255) NOT NULL DEFAULT '',
  status TINYINT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE admin_permission (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) NOT NULL,
  name VARCHAR(64) NOT NULL,
  category VARCHAR(32) NOT NULL,
  permission_type TINYINT NOT NULL,
  status TINYINT NOT NULL,
  UNIQUE KEY uk_admin_permission_code (code)
);
CREATE TABLE admin_role (
  id BIGINT NOT NULL PRIMARY KEY,
  code VARCHAR(64) NOT NULL,
  UNIQUE KEY uk_admin_role_code (code)
);
CREATE TABLE admin_role_permission (
  role_id BIGINT NOT NULL,
  permission_id BIGINT NOT NULL,
  PRIMARY KEY (role_id, permission_id)
);
INSERT INTO admin_role (id, code) VALUES
  (1, 'super_admin'),
  (2, 'data_operator');
SQL

if "$runner" \
    --defaults-extra-file "$database_defaults" \
    --release-version integration-no-baseline \
    --lock-file "$run_dir/no-baseline.lock" >"$run_dir/no-baseline.log" 2>&1; then
  fail "first takeover without an explicit baseline unexpectedly succeeded"
fi
grep -q 'explicit --baseline-version' "$run_dir/no-baseline.log" ||
  fail "missing-baseline failure was not explicit"

"$runner" \
  --defaults-extra-file "$database_defaults" \
  --baseline-version 2 \
  --release-version integration-first \
  --lock-file "$run_dir/apply.lock"

history_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e 'SELECT COUNT(*) FROM dzdp_schema_migration;')"
[[ "$history_count" == "12" ]] || fail "expected 12 migration history rows, found $history_count"
non_applied_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e "SELECT COUNT(*) FROM dzdp_schema_migration WHERE state <> 'APPLIED';")"
[[ "$non_applied_count" == "0" ]] || fail "old-baseline upgrade did not finish every migration"

schema_probe="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names -e "
SELECT
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='refund' AND column_name='channel_status') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='channel_statement_batch') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='shop_search_sync_task') +
  (SELECT COUNT(*) FROM admin_permission WHERE code='system:health:read');")"
[[ "$schema_probe" == "4" ]] || fail "migrations 03-14 did not produce the expected schema/data"

"$runner" \
  --defaults-extra-file "$database_defaults" \
  --release-version integration-repeat \
  --lock-file "$run_dir/repeat.lock"
repeat_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e 'SELECT COUNT(*) FROM dzdp_schema_migration;')"
[[ "$repeat_count" == "12" ]] || fail "repeat apply changed migration history"

"$runner" \
  --defaults-extra-file "$database_defaults" \
  --mode verify \
  --release-version integration-verify \
  --lock-file "$run_dir/verify.lock"

lock_sql="CONCAT('dzdp-schema-migration:', LEFT(SHA2(DATABASE(), 256), 40))"
{
  printf 'SELECT GET_LOCK(%s, 0);\n' "$lock_sql"
  printf 'DO SLEEP(4);\n'
  printf 'SELECT RELEASE_LOCK(%s);\n' "$lock_sql"
} | mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names --silent \
  > "$run_dir/lock-holder.log" &
holder_pid=$!

lock_held=false
for _attempt in $(seq 1 20); do
  lock_owner="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names --silent \
    -e "SELECT IS_USED_LOCK($lock_sql);")"
  if [[ -n "$lock_owner" && "$lock_owner" != "NULL" ]]; then
    lock_held=true
    break
  fi
  sleep 0.1
done
$lock_held || fail "test session did not acquire the database advisory lock"
if "$runner" \
    --defaults-extra-file "$database_defaults" \
    --mode verify \
    --lock-timeout-seconds 1 \
    --release-version integration-lock \
    --lock-file "$run_dir/cross-host.lock" >"$run_dir/lock-contender.log" 2>&1; then
  fail "runner ignored an advisory lock held by another database session"
fi
grep -q 'database-level migration lock' "$run_dir/lock-contender.log" ||
  fail "database lock contention did not produce the expected failure"
wait "$holder_pid"
holder_pid=""

drift_root="$run_dir/drift"
mkdir -p "$drift_root/migrations"
while read -r _checksum filename; do
  cp "$source_dir/$filename" "$drift_root/migrations/$filename"
done < "$manifest"
cp "$manifest" "$drift_root/migrations.sha256"
printf '\n-- intentional checksum-drift integration fixture\n' >> \
  "$drift_root/migrations/14_admin_system_health_permission_migration.sql"
drift_hash="$(sha256sum "$drift_root/migrations/14_admin_system_health_permission_migration.sql" | awk '{print $1}')"
awk -v replacement="$drift_hash" '
  $2 == "14_admin_system_health_permission_migration.sql" { $1 = replacement }
  { printf "%s  %s\n", $1, $2 }
' "$drift_root/migrations.sha256" > "$drift_root/migrations.sha256.new"
mv "$drift_root/migrations.sha256.new" "$drift_root/migrations.sha256"

if "$runner" \
    --defaults-extra-file "$database_defaults" \
    --migrations-dir "$drift_root/migrations" \
    --manifest "$drift_root/migrations.sha256" \
    --release-version integration-drift \
    --lock-file "$run_dir/drift.lock" >"$run_dir/drift.log" 2>&1; then
  fail "historical checksum drift unexpectedly succeeded"
fi
grep -q 'history checksum mismatch' "$run_dir/drift.log" ||
  fail "checksum drift did not produce the expected history failure"

failure_root="$run_dir/failure"
mkdir -p "$failure_root/migrations"
while read -r _checksum filename; do
  cp "$source_dir/$filename" "$failure_root/migrations/$filename"
done < "$manifest"
cp "$manifest" "$failure_root/migrations.sha256"
printf 'THIS IS INTENTIONALLY INVALID SQL;\n' > \
  "$failure_root/migrations/15_forced_failure_migration.sql"
failure_hash="$(sha256sum "$failure_root/migrations/15_forced_failure_migration.sql" | awk '{print $1}')"
printf '%s  %s\n' "$failure_hash" '15_forced_failure_migration.sql' >> \
  "$failure_root/migrations.sha256"

switch_marker="$run_dir/current-switched"
if "$runner" \
    --defaults-extra-file "$database_defaults" \
    --migrations-dir "$failure_root/migrations" \
    --manifest "$failure_root/migrations.sha256" \
    --release-version integration-failure \
    --lock-file "$run_dir/failure.lock" >"$run_dir/failure.log" 2>&1 &&
    touch "$switch_marker"; then
  fail "invalid migration unexpectedly succeeded"
fi
[[ ! -e "$switch_marker" ]] || fail "post-migration switch marker was created after failure"
failed_state="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e 'SELECT state FROM dzdp_schema_migration WHERE version=15;')"
[[ "$failed_state" == "FAILED" ]] || fail "failed migration was not persisted as FAILED"

if "$runner" \
    --defaults-extra-file "$database_defaults" \
    --migrations-dir "$failure_root/migrations" \
    --manifest "$failure_root/migrations.sha256" \
    --release-version integration-rerun \
    --lock-file "$run_dir/failure-rerun.lock" >"$run_dir/failure-rerun.log" 2>&1; then
  fail "runner silently retried a FAILED migration"
fi
grep -q 'manual repair is required' "$run_dir/failure-rerun.log" ||
  fail "FAILED state did not require explicit manual repair"

printf '[mysql-migration-integration] old baseline, repeat, verify, DB lock, checksum drift, and failure blocking passed.\n'
