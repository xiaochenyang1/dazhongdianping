"""Verify the creator flow in a disposable local MySQL server and browser sessions."""
import json
import os
from pathlib import Path
import secrets
import signal
import socket
import subprocess
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports" / "creator-review-mysql"


def free_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def ready(url, process):
    for _ in range(240):
        if process.poll() is not None:
            raise RuntimeError(f"Server exited while waiting for {url}; see logs")
        try:
            with urllib.request.urlopen(url, timeout=1) as response:
                if response.status == 200:
                    return
        except Exception:
            pass
        time.sleep(0.5)
    raise RuntimeError(f"Timed out waiting for {url}; see logs")


def main():
    REPORT.mkdir(parents=True, exist_ok=True)
    processes, logs = [], []
    outcome = {"mysqlVersion": subprocess.check_output(["mysqld", "--version"], text=True).strip(), "exitCode": None}
    with tempfile.TemporaryDirectory(prefix="dzdp-creator-browser-", dir="/tmp") as scratch:
        run = Path(scratch)
        db_port, backend_port, web_port, admin_port = (free_port() for _ in range(4))
        outcome["ports"] = {"mysql": db_port, "backend": backend_port, "web": web_port, "admin": admin_port}
        env = {key: value for key, value in os.environ.items() if not key.startswith(("APP_", "SPRING_", "VITE_", "PLAYWRIGHT_"))}
        env.update({
            "APP_DB_HOST": "127.0.0.1", "APP_DB_PORT": str(db_port), "APP_DB_NAME": "creator_browser_test",
            "APP_DB_USERNAME": "creator_test", "APP_DB_PASSWORD": secrets.token_hex(20),
            "APP_RUNTIME_MODE": "local", "APP_LAUNCH_DEFERRED_FEATURES_ENABLED": "true",
            "APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED": "true",
            "APP_AUTH_VERIFICATION_MOCK_ENABLED": "true", "APP_FILE_STORAGE_PROVIDER": "local",
            "VITE_PROXY_TARGET": f"http://127.0.0.1:{backend_port}",
            "PLAYWRIGHT_REAL_BACKEND": "1", "PLAYWRIGHT_CREATOR_REVIEW": "1", "PLAYWRIGHT_EXTERNAL_SERVERS": "1",
            "PLAYWRIGHT_BACKEND_PORT": str(backend_port), "PLAYWRIGHT_WEB_PORT": str(web_port), "PLAYWRIGHT_ADMIN_PORT": str(admin_port),
            "PLAYWRIGHT_OUTPUT_DIR": str(REPORT / "browser-results"),
        })

        def start(name, command, cwd=ROOT):
            log = (REPORT / f"{name}.log").open("w")
            logs.append(log)
            process = subprocess.Popen(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            processes.append(process)
            return process

        mysql = ["mysql", "--no-defaults", "--protocol=socket", f"--socket={run}/mysql.sock", "--user=root"]
        try:
            subprocess.run(["mysqld", "--no-defaults", "--initialize-insecure", f"--datadir={run}/data", f"--log-error={run}/mysql.log"], check=True)
            db = start("browser-mysql", ["mysqld", "--no-defaults", f"--datadir={run}/data", f"--socket={run}/mysql.sock", f"--port={db_port}", "--bind-address=127.0.0.1", "--mysqlx=OFF", f"--log-error={run}/mysql.log"])
            for _ in range(100):
                if subprocess.run(mysql + ["-e", "SELECT 1"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                    break
                if db.poll() is not None:
                    raise RuntimeError("Isolated MySQL exited during initialization")
                time.sleep(0.2)
            else:
                raise RuntimeError("Isolated MySQL did not start")
            subprocess.run(mysql, input=(
                "CREATE DATABASE creator_browser_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                f"CREATE USER 'creator_test'@'127.0.0.1' IDENTIFIED BY '{env['APP_DB_PASSWORD']}';"
                "GRANT ALL ON creator_browser_test.* TO 'creator_test'@'127.0.0.1';"
            ), text=True, check=True)
            for name in ("01_schema.sql", "02_seed_data.sql"):
                with (ROOT / "sql/mysql" / name).open("rb") as source:
                    subprocess.run(mysql + ["creator_browser_test"], stdin=source, check=True)
            defaults = run / "database.cnf"
            defaults.write_text(f"[client]\nprotocol=socket\nsocket={run}/mysql.sock\nuser=root\ndatabase=creator_browser_test\n")
            defaults.chmod(0o600)
            with (REPORT / "browser-migrations.log").open("w") as log:
                subprocess.run(["bash", "scripts/ci/mysql-migrate.sh", "--defaults-extra-file", str(defaults), "--baseline-version", "14", "--release-version", "creator-browser-local", "--lock-file", str(run / "migration.lock")], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
            print("Disposable MySQL schema migrated through 28", flush=True)
            backend = start("browser-backend", ["./mvnw", "-q", "-DskipTests", "spring-boot:run", "-Dspring-boot.run.profiles=local", f"-Dspring-boot.run.arguments=--server.address=127.0.0.1 --server.port={backend_port} --management.health.redis.enabled=false --app.file-storage.base-dir={run}/uploads --app.privacy.export.base-dir={run}/privacy"], ROOT / "backend")
            ready(f"http://127.0.0.1:{backend_port}/actuator/health", backend)
            for name, folder, port in [("browser-web", "web", web_port), ("browser-admin", "admin-web", admin_port)]:
                process = start(name, ["node", "node_modules/vite/bin/vite.js", "--host", "127.0.0.1", "--port", str(port), "--strictPort"], ROOT / folder)
                ready(f"http://127.0.0.1:{port}/", process)
            print("Local backend, Web and admin are ready; running browser workflow", flush=True)
            checks = start("browser-creator", ["npm", "exec", "--", "playwright", "test", "e2e/creator-review.spec.ts", "--reporter=list"], ROOT / "web")
            outcome["exitCode"] = checks.wait(timeout=240)
            print(f"Creator browser tests exited {outcome['exitCode']}", flush=True)
        finally:
            for process in reversed(processes):
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=8)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
            for log in logs:
                log.close()
            outcome["temporaryServerRemoved"] = all(process.poll() is not None for process in processes)
            (REPORT / "browser-verification.json").write_text(json.dumps(outcome, indent=2) + "\n")
    return outcome["exitCode"] if outcome["exitCode"] is not None else 1


if __name__ == "__main__":
    raise SystemExit(main())
