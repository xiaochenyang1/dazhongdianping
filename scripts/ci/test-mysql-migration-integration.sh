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
CREATE TABLE privacy_delete_task (id BIGINT NOT NULL PRIMARY KEY,user_id BIGINT NOT NULL,status TINYINT NOT NULL DEFAULT 1);
CREATE TABLE user_device (id BIGINT NOT NULL PRIMARY KEY,device_uid VARCHAR(128) NOT NULL);
CREATE TABLE conversation (id BIGINT NOT NULL PRIMARY KEY,user_a BIGINT NOT NULL,user_b BIGINT NOT NULL,UNIQUE KEY uk_conversation_users(user_a,user_b));
CREATE TABLE post_report (id BIGINT NOT NULL PRIMARY KEY,reporter_user_id BIGINT NOT NULL);
CREATE TABLE review_comment_report (id BIGINT NOT NULL PRIMARY KEY,review_id BIGINT NOT NULL,comment_id BIGINT NOT NULL,reporter_user_id BIGINT NOT NULL,reporter_user_name VARCHAR(64) NOT NULL,reason VARCHAR(200) NOT NULL,status TINYINT NOT NULL DEFAULT 0,created_at DATETIME DEFAULT CURRENT_TIMESTAMP,updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,is_deleted BOOLEAN NOT NULL DEFAULT FALSE,UNIQUE KEY uk_review_comment_report_user(comment_id,reporter_user_id));
CREATE TABLE post_comment_report (id BIGINT NOT NULL PRIMARY KEY,post_id BIGINT NOT NULL,comment_id BIGINT NOT NULL,reporter_user_id BIGINT NOT NULL,reporter_user_name VARCHAR(64) NOT NULL,reason VARCHAR(200) NOT NULL,status TINYINT NOT NULL DEFAULT 0,created_at DATETIME DEFAULT CURRENT_TIMESTAMP,updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,is_deleted BOOLEAN NOT NULL DEFAULT FALSE,UNIQUE KEY uk_post_comment_report_user(comment_id,reporter_user_id));
CREATE TABLE message_report (id BIGINT NOT NULL PRIMARY KEY,reporter_user_id BIGINT NOT NULL);

CREATE TABLE city (
  id BIGINT NOT NULL PRIMARY KEY,
  code VARCHAR(32) NOT NULL,
  region VARCHAR(8) NOT NULL,
  name VARCHAR(64) NOT NULL,
  status TINYINT NOT NULL DEFAULT 1
);
INSERT INTO city(id,code,region,name,status) VALUES
  (101,'PAR','EU','Paris',1), (102,'BER','EU','Berlin',1);
CREATE TABLE shop (id BIGINT NOT NULL PRIMARY KEY, city_id BIGINT NOT NULL, region VARCHAR(8) NOT NULL);
INSERT INTO shop(id,city_id,region) VALUES (20001,101,'EU'), (20002,102,'EU');
CREATE TABLE reservation (id BIGINT NOT NULL PRIMARY KEY, shop_id BIGINT NOT NULL, reserve_time DATETIME NOT NULL);
INSERT INTO reservation(id,shop_id,reserve_time) VALUES (1,20001,'2026-12-01 18:30:00');
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
CREATE TABLE audit_task (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  biz_type TINYINT NOT NULL,
  biz_id BIGINT NOT NULL,
  region VARCHAR(8) NOT NULL,
  machine_result TINYINT NOT NULL DEFAULT 0,
  status TINYINT NOT NULL DEFAULT 0,
  auditor_id BIGINT NOT NULL DEFAULT 0,
  remark VARCHAR(255) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_audit_task_region_status (region, biz_type, status, id),
  KEY idx_audit_task_biz_status (biz_type, biz_id, status, id)
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
CREATE TABLE review (
  id BIGINT NOT NULL PRIMARY KEY,
  comment_count INT NOT NULL DEFAULT 0
);
CREATE TABLE `order` (
  id BIGINT NOT NULL PRIMARY KEY,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0
);
CREATE TABLE merchant_role (
  id BIGINT NOT NULL PRIMARY KEY,
  code VARCHAR(64) NOT NULL,
  permissions VARCHAR(1000) NOT NULL DEFAULT ''
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
[[ "$history_count" == "24" ]] || fail "expected 24 migration history rows, found $history_count"
cleanup_marker_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names -e \
  "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='privacy_delete_task' AND column_name='domain_cleanup_version' AND column_default='0';")"
[[ "$cleanup_marker_count" == "1" ]] || fail "historical deletions must receive a pending cleanup marker"
non_applied_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e "SELECT COUNT(*) FROM dzdp_schema_migration WHERE state <> 'APPLIED';")"
[[ "$non_applied_count" == "0" ]] || fail "old-baseline upgrade did not finish every migration"

schema_probe="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names -e "
SELECT
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='refund' AND column_name='channel_status') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='channel_statement_batch') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='shop_search_sync_task') +
  (SELECT COUNT(*) FROM admin_permission WHERE code='system:health:read') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='review' AND column_name='helpful_count') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='marketing_coupon_template') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='order' AND column_name='user_coupon_id') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='risk_rule') +
  (SELECT COUNT(*) FROM admin_role_permission rp
     JOIN admin_role r ON r.id=rp.role_id AND r.code='super_admin'
     JOIN admin_permission p ON p.id=rp.permission_id AND p.code='operations:ad:read') +
  (SELECT COUNT(*) FROM admin_role_permission rp
     JOIN admin_role r ON r.id=rp.role_id AND r.code='super_admin'
     JOIN admin_permission p ON p.id=rp.permission_id AND p.code='operations:marketing:read') +
  (SELECT IF(COUNT(*)=0,1,0) FROM ad_click_log WHERE user_id <> 0) +
  (SELECT IF(COUNT(DISTINCT index_name)=1,1,0) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='audit_task' AND index_name='idx_audit_task_region_queue_order') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='admin_audit_sla_alert') +
  (SELECT IF(COUNT(*)=3,1,0) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='audit_task' AND column_name IN ('claimed_by_admin_id','claimed_at','claim_expires_at')) +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='city' AND column_name='time_zone') +
  (SELECT COUNT(*) FROM city WHERE region='EU' AND code='PAR' AND status=1 AND time_zone='Europe/Paris') +
  (SELECT COUNT(*) FROM city WHERE region='EU' AND code='BER' AND status=0 AND time_zone='Europe/Berlin') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='reservation' AND column_name='time_zone') +
  (SELECT COUNT(*) FROM reservation WHERE id=1 AND time_zone='Europe/Paris');")"
[[ "$schema_probe" == "19" ]] || fail "migrations 03-26 schema/data probe expected 19, found $schema_probe"

"$runner" \
  --defaults-extra-file "$database_defaults" \
  --release-version integration-repeat \
  --lock-file "$run_dir/repeat.lock"
repeat_count="$(mysql --defaults-extra-file="$database_defaults" --batch --skip-column-names \
  -e 'SELECT COUNT(*) FROM dzdp_schema_migration;')"
[[ "$repeat_count" == "24" ]] || fail "repeat apply changed migration history"

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
latest_migration="$(awk 'END {print $2}' "$manifest")"
latest_version="${latest_migration%%_*}"
forced_failure_version=$((10#$latest_version + 1))
forced_failure_name="$(printf '%02d_forced_failure_migration.sql' "$forced_failure_version")"
printf 'THIS IS INTENTIONALLY INVALID SQL;\n' > \
  "$failure_root/migrations/$forced_failure_name"
failure_hash="$(sha256sum "$failure_root/migrations/$forced_failure_name" | awk '{print $1}')"
printf '%s  %s\n' "$failure_hash" "$forced_failure_name" >> \
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
  -e "SELECT state FROM dzdp_schema_migration WHERE version=$forced_failure_version;")"
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

fresh_database="dzdp_fresh_install_test"
fresh_defaults="$run_dir/fresh-database.cnf"
cp "$server_defaults" "$fresh_defaults"
printf 'database=%s\n' "$fresh_database" >> "$fresh_defaults"
chmod 600 "$fresh_defaults"
mysql --defaults-extra-file="$server_defaults" -e \
  "CREATE DATABASE $fresh_database DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql --defaults-extra-file="$fresh_defaults" < "$source_dir/01_schema.sql"
mysql --defaults-extra-file="$fresh_defaults" < "$source_dir/02_seed_data.sql"

"$runner" \
  --defaults-extra-file "$fresh_defaults" \
  --baseline-version 14 \
  --release-version integration-fresh-install \
  --lock-file "$run_dir/fresh-install.lock"

fresh_history_counts="$(mysql --defaults-extra-file="$fresh_defaults" --batch --skip-column-names -e \
  "SELECT SUM(state='BASELINED' AND version<=14), SUM(state='APPLIED' AND version>14) FROM dzdp_schema_migration;")"
[[ "$fresh_history_counts" == $'12\t12' ]] ||
  fail "fresh schema must baseline versions 03-14 and apply 15-26; found $fresh_history_counts"

fresh_schema_probe="$(mysql --defaults-extra-file="$fresh_defaults" --batch --skip-column-names -e "
SELECT
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='shop' AND column_name='chinese_service') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='review' AND column_name='helpful_count') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='order' AND column_name='original_amount') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='marketing_coupon_template') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='shop_question') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='shop_question' AND column_name='status') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='shop_answer' AND column_name='status') +
  (SELECT IF(COUNT(DISTINCT index_name)=1,1,0) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='audit_task' AND index_name='idx_audit_task_region_queue_order') +
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='admin_audit_sla_alert') +
  (SELECT COUNT(*) FROM admin_role_permission rp
     JOIN admin_role r ON r.id=rp.role_id AND r.code='super_admin'
     JOIN admin_permission p ON p.id=rp.permission_id AND p.code='audit:automod:read') +
  (SELECT IF(COUNT(*)=3,1,0) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='audit_task' AND column_name IN ('claimed_by_admin_id','claimed_at','claim_expires_at')) +
  (SELECT COUNT(*) FROM city WHERE region='EU' AND code='PAR' AND status=1 AND time_zone='Europe/Paris') +
  (SELECT COUNT(*) FROM city WHERE region='EU' AND code='BER' AND status=0 AND time_zone='Europe/Berlin') +
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='reservation' AND column_name='time_zone');")"
[[ "$fresh_schema_probe" == "14" ]] ||
  fail "fresh schema plus migrations 15-26 probe expected 14, found $fresh_schema_probe"

printf '[mysql-migration-integration] old baseline, fresh baseline 14, repeat, verify, DB lock, checksum drift, and failure blocking passed.\n'
