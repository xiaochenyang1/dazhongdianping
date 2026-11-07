"""Exercise flash-sale transactions and all three Web clients on disposable MySQL.

Usage: python3 scripts/ci/seckill-order-integration.py --server local
CI uses --server docker (MySQL 8.4). No existing database is used or modified.
"""
import argparse
import json
import os
from pathlib import Path
import secrets
import shutil
import signal
import socket
import subprocess
import tempfile
import time
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def free_ports(count):
    ports = set()
    while len(ports) < count:
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            ports.add(listener.getsockname()[1])
    return list(ports)


def ready(url, process):
    for _ in range(240):
        if process.poll() is not None:
            raise RuntimeError(f"Server exited while waiting for {url}; see report logs")
        try:
            with urllib.request.urlopen(url, timeout=1) as response:
                if response.status == 200:
                    return
        except Exception:
            pass
        time.sleep(0.5)
    raise RuntimeError(f"Timed out waiting for {url}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", choices=("local", "docker"), default="docker")
    parser.add_argument("--report-dir", default="reports/seckill-order-integration")
    args = parser.parse_args()
    report = (ROOT / args.report_dir).resolve()
    report.mkdir(parents=True, exist_ok=True)
    processes, logs = [], []
    outcome = {"server": args.server, "exitCode": 1}
    container = None
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("APP_", "SPRING_", "VITE_", "PLAYWRIGHT_"))}
    with tempfile.TemporaryDirectory(prefix="dzdp-seckill-", dir="/tmp") as scratch:
        run = Path(scratch)
        db_port, backend_port, web_port, admin_port, merchant_port = free_ports(5)

        def start(name, command, cwd=ROOT):
            log = (report / f"{name}.log").open("w")
            logs.append(log)
            process = subprocess.Popen(command, cwd=cwd, env=env, stdout=log,
                                       stderr=subprocess.STDOUT, start_new_session=True)
            processes.append(process)
            return process

        try:
            defaults = run / "mysql.cnf"
            if args.server == "local":
                outcome["mysqlVersion"] = subprocess.check_output(["mysqld", "--version"], text=True).strip()
                subprocess.run(["mysqld", "--no-defaults", "--initialize-insecure", f"--datadir={run}/data",
                                f"--log-error={run}/mysql.log"], check=True, env=env)
                start("mysql", ["mysqld", "--no-defaults", f"--datadir={run}/data", f"--socket={run}/mysql.sock",
                                f"--port={db_port}", "--bind-address=127.0.0.1", "--mysqlx=OFF",
                                f"--log-error={run}/mysql.log"])
                defaults.write_text(f"[client]\nprotocol=socket\nsocket={run}/mysql.sock\nuser=root\n")
            else:
                container = "dzdp-seckill-" + secrets.token_hex(6)
                env["MYSQL_ROOT_PASSWORD"] = secrets.token_hex(24)
                image = os.environ.get("MYSQL_MIGRATION_TEST_IMAGE", "mysql:8.4")
                subprocess.run(["docker", "run", "--detach", "--rm", "--name", container,
                                "--env", "MYSQL_ROOT_PASSWORD", "--publish", "127.0.0.1::3306", image],
                               check=True, env=env, stdout=subprocess.DEVNULL)
                mapping = subprocess.check_output(["docker", "port", container, "3306/tcp"], text=True).strip()
                db_port = int(mapping.rsplit(":", 1)[1])
                defaults.write_text(f"[client]\nprotocol=tcp\nhost=127.0.0.1\nport={db_port}\nuser=root\n"
                                    f"password={env['MYSQL_ROOT_PASSWORD']}\n")
            defaults.chmod(0o600)
            mysql = ["mysql", f"--defaults-extra-file={defaults}"]
            for _ in range(120):
                if subprocess.run(mysql + ["-e", "SELECT 1"], stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL).returncode == 0:
                    break
                time.sleep(0.5)
            else:
                raise RuntimeError("Disposable MySQL did not start")
            outcome["mysqlVersion"] = subprocess.check_output(mysql + ["--batch", "--skip-column-names", "-e", "SELECT VERSION()"], text=True).strip()
            password = secrets.token_hex(20)
            subprocess.run(mysql, input=("CREATE DATABASE seckill_orders CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                           f"CREATE USER 'seckill_test'@'%' IDENTIFIED BY '{password}';"
                           "GRANT ALL ON seckill_orders.* TO 'seckill_test'@'%';"), text=True, check=True)
            for name in ("01_schema.sql", "02_seed_data.sql"):
                with (ROOT / "sql/mysql" / name).open("rb") as source:
                    subprocess.run(mysql + ["seckill_orders"], stdin=source, check=True)
            with defaults.open("a") as config:
                config.write("database=seckill_orders\n")
            migration = start("migrations", ["bash", "scripts/ci/mysql-migrate.sh", "--defaults-extra-file", str(defaults),
                "--baseline-version", "14", "--release-version", "seckill-integration", "--lock-file", str(run / "migration.lock")])
            if migration.wait(timeout=180) != 0:
                raise RuntimeError("MySQL migrations failed")
            env.update({
                "APP_DB_HOST": "127.0.0.1", "APP_DB_PORT": str(db_port), "APP_DB_NAME": "seckill_orders",
                "APP_DB_USERNAME": "seckill_test", "APP_DB_PASSWORD": password,
                "SPRING_DATASOURCE_DRIVER_CLASS_NAME": "com.mysql.cj.jdbc.Driver",
                "SPRING_DATASOURCE_URL": f"jdbc:mysql://127.0.0.1:{db_port}/seckill_orders?useSSL=false&allowPublicKeyRetrieval=true",
                "SPRING_DATASOURCE_USERNAME": "seckill_test", "SPRING_DATASOURCE_PASSWORD": password,
                "SPRING_SQL_INIT_MODE": "never", "APP_RUNTIME_MODE": "test",
                "APP_LAUNCH_DEFERRED_FEATURES_ENABLED": "true", "APP_LAUNCH_EU_SECKILL_ENABLED": "true",
                "APP_AUTH_VERIFICATION_MOCK_ENABLED": "true", "APP_FILE_STORAGE_PROVIDER": "local",
                "APP_STATE_STORE_PROVIDER": "local", "APP_STATE_STORE_KEY_PREFIX": "dzdp:seckill:" + secrets.token_hex(8),
                "PLAYWRIGHT_REAL_BACKEND": "1", "PLAYWRIGHT_SECKILL_ORDERS": "1", "PLAYWRIGHT_EXTERNAL_SERVERS": "1",
                "PLAYWRIGHT_CHANNEL": "chromium", "PLAYWRIGHT_OUTPUT_DIR": str(report / "browser-results"),
                "PLAYWRIGHT_BACKEND_PORT": str(backend_port), "PLAYWRIGHT_WEB_PORT": str(web_port),
                "PLAYWRIGHT_ADMIN_PORT": str(admin_port), "PLAYWRIGHT_MERCHANT_PORT": str(merchant_port),
                "VITE_PROXY_TARGET": f"http://127.0.0.1:{backend_port}",
            })
            outcome["ports"] = {"mysql": db_port, "backend": backend_port, "web": web_port, "admin": admin_port, "merchant": merchant_port}
            print(f"MySQL {outcome['mysqlVersion']} ready; testing committed transactions and concurrency", flush=True)
            checks = start("mysql-transactions", ["./mvnw", "-q", "-Dtest=SeckillOrderIntegrationTest", "package"], ROOT / "backend")
            if checks.wait(timeout=600) != 0:
                raise RuntimeError("MySQL transaction tests failed")
            test_report = ROOT / "backend/target/surefire-reports/TEST-com.tuowei.dazhongdianping.module.marketing.SeckillOrderIntegrationTest.xml"
            result = ET.parse(test_report).getroot()
            outcome["transactions"] = {key: result.attrib[key] for key in ("tests", "failures", "errors", "skipped")}
            # Surefire XML includes system properties. Keep only counts, not ephemeral credentials.
            env["APP_RUNTIME_MODE"] = "local"
            jar = next((ROOT / "backend/target").glob("dazhongdianping-backend-*.jar"))
            backend = start("backend", ["java", "-jar", str(jar), "--spring.profiles.active=local",
                "--server.address=127.0.0.1", f"--server.port={backend_port}", "--management.health.redis.enabled=false",
                f"--app.file-storage.base-dir={run}/uploads", f"--app.privacy.export.base-dir={run}/privacy"])
            ready(f"http://127.0.0.1:{backend_port}/actuator/health", backend)
            for name, folder, port in [("web", "web", web_port), ("admin", "admin-web", admin_port), ("merchant", "merchant-web", merchant_port)]:
                process = start(name, ["node", "node_modules/vite/bin/vite.js", "--host", "127.0.0.1", "--port", str(port), "--strictPort"], ROOT / folder)
                ready(f"http://127.0.0.1:{port}/", process)
            print("Transaction checks passed; running merchant, admin and customer browser journeys", flush=True)
            browser = start("browser", ["npm", "exec", "--", "playwright", "test", "e2e/seckill-orders.spec.ts", "--reporter=list"], ROOT / "web")
            outcome["exitCode"] = browser.wait(timeout=360)
            if outcome["exitCode"] != 0:
                raise RuntimeError("Flash-sale browser journeys failed")
            print("MySQL transactions and CN/EU flash-sale browser journeys passed", flush=True)
        finally:
            for process in reversed(processes):
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=8)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
            if container:
                subprocess.run(["docker", "rm", "-f", container], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if (run / "mysql.log").exists():
                shutil.copy(run / "mysql.log", report / "mysql.log")
            for log in logs:
                log.close()
            outcome["managedProcessesStopped"] = all(process.poll() is not None for process in processes)
            (report / "verification.json").write_text(json.dumps(outcome, indent=2) + "\n")


if __name__ == "__main__":
    main()
