"""Run the real PowerShell deployment entry points and their Bash scripts.

SSH/SCP are loopback transports, systemd and SQL execution are controlled
fixtures, and HTTP is injected in PowerShell. ZIP verification/extraction,
shell evaluation, symlink transitions, recovery guards and retention are real.
No actual SSH, HTTP, database, sudo or service operation is permitted.
"""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


def shim():
    name = Path(sys.argv[0]).name
    args = sys.argv[1:]
    root = Path(os.environ['DZDP_RELEASE_TEST_ROOT'])
    case = os.environ['DZDP_RELEASE_TEST_CASE']
    current = (root / 'current').resolve().name if (root / 'current').is_symlink() else ''
    with Path(os.environ['DZDP_RELEASE_TEST_EVENTS']).open('a') as log:
        log.write(json.dumps({'tool': name, 'args': args, 'current': current}) + '\n')
    if name == 'ssh':
        while args and args[0].startswith('-'):
            option = args.pop(0)
            if option == '--':
                break
            if option in ('-p', '-o'):
                args.pop(0)
        if not args or args.pop(0) != 'deploy@fixture.invalid':
            raise RuntimeError('Fixture refuses a real SSH destination')
        # OpenSSH sends a command string to the remote shell. This deliberately
        # reproduces its parsing instead of bypassing it with an argv execution.
        return subprocess.call(['/bin/bash', '-c', ' '.join(args)])
    if name == 'scp':
        if args[:2] != ['-P', '22'] or not args[-1].startswith('deploy@fixture.invalid:'):
            raise RuntimeError('Fixture refuses a real SCP destination')
        target = Path(args[-1].split(':', 1)[1])
        if not target.parent.is_dir():
            print('SCP target directory does not exist', file=sys.stderr)
            return 1
        shutil.copyfile(args[-2], target)
        if case == 'corrupt-upload':
            with target.open('ab') as stream:
                stream.write(b'corrupted in transport')
        return 0
    if name == 'sudo':
        if args and args[0] == '-n':
            args.pop(0)
        if not args or args[0] != 'systemctl':
            raise RuntimeError('Fixture refuses a real privileged command')
        return subprocess.call(args)
    if name == 'systemctl':
        action = args[0]
        if action == 'restart' and case in ('restart-failure', 'first-restart-failure', 'recovery-failure'):
            if current == 'rc-new' or case == 'recovery-failure':
                return 17
        if action == 'is-active' and case == 'one-inactive' and current == 'rc-new':
            services = [arg for arg in args[1:] if not arg.startswith('-')]
            # systemctl is-active with multiple units succeeds if ANY is active.
            return 3 if services == ['dzdp-merchant-web'] else 0
        return 0
    if name == 'flock':
        import fcntl
        fcntl.flock(int(args[-1]), fcntl.LOCK_EX)
        return 0
    if name == 'readlink':
        assert args[0] == '-f'
        # GNU readlink -f may return a path for a missing final component.
        print(os.path.realpath(args[-1]))
        return 0
    if name == 'sha256sum':
        assert args == ['--check', '--status']
        digest, filename = sys.stdin.read().strip().split('  ', 1)
        return 0 if hashlib.sha256(Path(filename).read_bytes()).hexdigest() == digest else 1
    if name == 'find':
        assert '-printf' in args and args[args.index('-type') + 1] == 'd'
        for path in Path(args[0]).iterdir():
            if path.is_dir() and not path.is_symlink():
                print(f'{path.stat().st_mtime} {path.name}')
        return 0
    raise RuntimeError(f'Unexpected fixture command: {name}')


DRIVER = r'''
$ErrorActionPreference = 'Stop'
function Invoke-WebRequest {
    param($Uri, [switch]$UseBasicParsing, $MaximumRedirection, $TimeoutSec)
    $current = (Get-Item -LiteralPath "$env:DZDP_RELEASE_TEST_ROOT/current" -ErrorAction SilentlyContinue).Target
    Add-Content -LiteralPath "$env:DZDP_RELEASE_TEST_HTTP" -Value "$current $Uri"
    if ($env:DZDP_RELEASE_TEST_CASE -eq 'newer-release' -and $current -like '*/rc-new') {
        Remove-Item -LiteralPath "$env:DZDP_RELEASE_TEST_ROOT/current"
        New-Item -ItemType SymbolicLink -Path "$env:DZDP_RELEASE_TEST_ROOT/current" -Target "$env:DZDP_RELEASE_TEST_ROOT/releases/other" | Out-Null
    }
    if ($env:DZDP_RELEASE_TEST_CASE -eq 'newer-release' -or
        ($env:DZDP_RELEASE_TEST_CASE -in @('smoke-failure', 'first-smoke-failure') -and $current -like '*/rc-new')) {
        return @{ StatusCode = 503 }
    }
    return @{ StatusCode = 200 }
}
function Start-Sleep { param($Seconds) }
$parameters = @{
    Environment = 'pre'; Region = 'EU'; RemoteHost = 'fixture.invalid'; RemoteUser = 'deploy'
    RemoteRoot = $env:DZDP_RELEASE_TEST_ROOT; SmokeUrls = 'https://fixture.invalid/health,https://fixture.invalid/merchant'
    ReleaseRetentionCount = [int]$env:DZDP_RELEASE_TEST_RETENTION
}
try {
    if ($env:DZDP_RELEASE_TEST_ROLLBACK -eq 'true') {
        if ($env:DZDP_RELEASE_TEST_TARGET) { $parameters.TargetVersion = $env:DZDP_RELEASE_TEST_TARGET }
        & "$env:DZDP_RELEASE_TEST_SCRIPTS/rollback-release.ps1" @parameters
    } else {
        $parameters.ReleaseBundle = $env:DZDP_RELEASE_TEST_BUNDLE
        $parameters.ExpectedCommitSha = 'a' * 40
        $parameters.DatabaseDefaultsFile = $env:DZDP_RELEASE_TEST_DATABASE
        $parameters.DatabaseMigrationMode = 'verify'
        & "$env:DZDP_RELEASE_TEST_SCRIPTS/deploy-release.ps1" @parameters
    }
} catch { Write-Output $_.Exception.Message; exit 1 }
'''


class ReleaseExecutionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dzdp-release-execution-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.base / 'remote'
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.events = self.base / 'events.jsonl'
        self.http = self.base / 'http.log'
        self.database = self.base / 'private.cnf'
        self.database.write_text('[client]\n# no database connection in this fixture\n')
        self.database.chmod(0o600)
        self.driver = self.base / 'driver.ps1'
        self.driver.write_text(DRIVER)
        tools = ['ssh', 'scp', 'sudo', 'systemctl']
        if sys.platform == 'darwin':
            tools += ['flock', 'readlink', 'find', 'sha256sum']
        for name in tools:
            executable = self.bin / name
            executable.write_text(f'#!{sys.executable}\n' + Path(__file__).read_text())
            executable.chmod(0o700)
        self.scripts = Path(os.environ.get('DZDP_RELEASE_SOURCE_DIR', str(Path(__file__).parent))).resolve()
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        DZDP_RELEASE_TEST_ROOT=str(self.root), DZDP_RELEASE_TEST_EVENTS=str(self.events),
                        DZDP_RELEASE_TEST_HTTP=str(self.http), DZDP_RELEASE_TEST_SCRIPTS=str(self.scripts),
                        DZDP_RELEASE_TEST_DATABASE=str(self.database), DZDP_RELEASE_TEST_CASE='success',
                        DZDP_RELEASE_TEST_ROLLBACK='false', DZDP_RELEASE_TEST_TARGET='',
                        DZDP_RELEASE_TEST_RETENTION='1',
                        active_release='/must-not-expand', current_release='/must-not-expand', target='must-not-expand')
        self.bundle = self.base / 'dazhongdianping-release-rc-new.zip'
        self.env['DZDP_RELEASE_TEST_BUNDLE'] = str(self.bundle)
        self.make_bundle()

    def make_bundle(self):
        sql = b'SELECT 1;'
        manifest = {
            'version': 'rc-new', 'bundleName': self.bundle.name, 'commitSha': 'a' * 40, 'buildEnvironment': 'pre',
            'backendJar': 'fixture.jar', 'frontends': ['web', 'admin-web', 'merchant-web'],
            'databaseMigrations': {'runner': 'database/mysql-migrate.sh', 'manifest': 'database/migrations.sha256',
                                   'directory': 'database/migrations', 'startVersion': 3, 'endVersion': 3, 'count': 1},
            'webRuntime': {'defaultRegion': 'EU', 'apiBaseUrl': 'https://api.fixture.invalid',
                           'webSocketBaseUrl': 'wss://api.fixture.invalid/ws', 'stripeConfigured': True, 'stripeMode': 'test'},
            'seoSnapshot': {'enabled': True},
            'seoSnapshots': [{'region': 'EU', 'directory': 'web/seo-snapshots/EU',
                              'siteUrl': 'https://fixture.invalid', 'apiBaseUrl': 'https://api.fixture.invalid'}],
        }
        with zipfile.ZipFile(self.bundle, 'w') as archive:
            archive.writestr('release-manifest.json', json.dumps(manifest))
            archive.writestr('release-version.txt', 'rc-new\r\n')
            archive.writestr('backend/fixture.jar', 'fixture')
            archive.writestr('database/migrations/03_fixture_migration.sql', sql)
            archive.writestr('database/migrations.sha256', hashlib.sha256(sql).hexdigest() + '  03_fixture_migration.sql\n')
            archive.writestr('database/mysql-migrate.sh', '''#!/usr/bin/env bash
set -euo pipefail
printf 'migration\n' >> "$DZDP_RELEASE_TEST_ROOT/migration.log"
if [ "$DZDP_RELEASE_TEST_CASE" = migration-failure ]; then exit 23; fi
''')
            archive.writestr('web/seo-snapshots/EU/index.html', '<html>EU</html>')
            for frontend in manifest['frontends']:
                archive.writestr(f'{frontend}/dist/index.html', '<html>fixture</html>')
                archive.writestr(f'{frontend}/dist/assets/app.js', 'fixture();')
        self.bundle.with_suffix('.zip.sha256').write_text(hashlib.sha256(self.bundle.read_bytes()).hexdigest() + f'  {self.bundle.name}\n')

    def release(self, name):
        directory = self.root / 'releases' / name
        directory.mkdir(parents=True)
        (directory / 'release-version.txt').write_text(name + '\n')
        return directory

    def history(self):
        (self.root / 'current').symlink_to(self.release('old'))
        (self.root / 'previous').symlink_to(self.release('older'))

    def invoke(self, case='success', rollback=False, target=''):
        self.events.unlink(missing_ok=True)
        self.http.unlink(missing_ok=True)
        self.env.update(DZDP_RELEASE_TEST_CASE=case, DZDP_RELEASE_TEST_ROLLBACK=str(rollback).lower(), DZDP_RELEASE_TEST_TARGET=target)
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(self.driver)], env=self.env,
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=40)
        self.output = result.stdout
        self.records = [json.loads(line) for line in self.events.read_text().splitlines()] if self.events.exists() else []
        return result.returncode

    def assert_current(self, name):
        self.assertTrue((self.root / 'current').is_symlink(), self.output)
        self.assertEqual((self.root / 'current').resolve().name, name, self.output)

    def test_first_deploy_prepares_directory_and_preserves_remote_variables(self):
        self.assertFalse(self.root.exists())
        self.assertEqual(self.invoke(), 0, self.output)
        self.assert_current('rc-new')
        self.assertFalse((self.root / 'previous').exists())
        tools = [record['tool'] for record in self.records]
        self.assertLess(tools.index('ssh'), tools.index('scp'))
        checks = [r['args'][-1] for r in self.records if r['tool'] == 'systemctl' and r['args'][0] == 'is-active']
        self.assertEqual(checks, ['dzdp-backend', 'dzdp-web', 'dzdp-admin-web', 'dzdp-merchant-web'])
        self.assertEqual(len(self.http.read_text().splitlines()), 2)
        self.assertNotIn('WARNING', self.output)

    def test_upgrade_and_manual_rollback_keep_explicit_history(self):
        self.history()
        self.assertEqual(self.invoke(), 0, self.output)
        self.assert_current('rc-new')
        self.assertEqual((self.root / 'previous').resolve().name, 'old')
        self.assertEqual(self.invoke(rollback=True), 0, self.output)
        self.assert_current('old')
        self.assertEqual((self.root / 'previous').resolve().name, 'rc-new')
        self.assertIn('rolled back to old', self.output)

    def test_failures_after_switch_restore_original_current_and_previous(self):
        for case in ('restart-failure', 'one-inactive', 'smoke-failure'):
            with self.subTest(case=case):
                if self.root.exists():
                    shutil.rmtree(self.root)
                self.history()
                self.assertNotEqual(self.invoke(case), 0)
                self.assert_current('old')
                self.assertEqual((self.root / 'previous').resolve().name, 'older', self.output)
                self.assertIn('previous release was automatically restored', self.output)
                self.assertIn('/releases/old https://fixture.invalid/merchant', self.http.read_text())
                self.assertFalse(any(r['tool'] == 'systemctl' and r['args'][0] == 'stop' for r in self.records))

    def test_failures_before_switch_do_not_restart_or_rollback_old_release(self):
        for case in ('migration-failure', 'corrupt-upload'):
            with self.subTest(case=case):
                if self.root.exists():
                    shutil.rmtree(self.root)
                self.history()
                self.events.unlink(missing_ok=True)
                self.assertNotEqual(self.invoke(case), 0)
                self.assert_current('old')
                self.assertEqual((self.root / 'previous').resolve().name, 'older')
                self.assertFalse(any(r['tool'] == 'systemctl' for r in self.records), self.output)
                self.assertEqual((self.root / 'migration.log').exists(), case == 'migration-failure', self.output)

    def test_automatic_recovery_preserves_configured_release_retention(self):
        self.history()
        for index in range(8):
            directory = self.release(f'history-{index}')
            os.utime(directory, (index + 1, index + 1))
        self.env['DZDP_RELEASE_TEST_RETENTION'] = '7'
        self.assertNotEqual(self.invoke('smoke-failure'), 0)
        self.assert_current('old')
        self.assertEqual((self.root / 'previous').resolve().name, 'older')
        remaining = {path.name for path in (self.root / 'releases').iterdir() if path.is_dir()}
        self.assertEqual(remaining, {'old', 'older', 'rc-new', *(f'history-{i}' for i in range(2, 8))}, self.output)

    def test_first_deploy_failure_deactivates_instead_of_selecting_unverified_directory(self):
        for case in ('first-restart-failure', 'first-smoke-failure'):
            with self.subTest(case=case):
                if self.root.exists():
                    shutil.rmtree(self.root)
                self.release('unverified')
                self.assertNotEqual(self.invoke(case), 0)
                self.assertFalse((self.root / 'current').is_symlink(), self.output)
                self.assertIn('Failed first deployment deactivated', self.output)
                self.assertTrue(any(r['tool'] == 'systemctl' and r['args'][0] == 'stop' for r in self.records))

    def test_missing_private_database_file_fails_before_upload(self):
        self.database.unlink()
        self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(any(r['tool'] == 'scp' for r in self.records))
        self.assertIn('Database defaults file is not readable', self.output)

    def test_recovery_failure_keeps_deployment_failed(self):
        self.history()
        self.assertNotEqual(self.invoke('recovery-failure'), 0)
        self.assert_current('old')
        self.assertIn('Automatic rollback also failed', self.output)
        self.assertNotIn('previous release was automatically restored', self.output)
        restarts = [r['current'] for r in self.records if r['tool'] == 'systemctl' and r['args'][0] == 'restart']
        self.assertEqual(restarts, ['rc-new', 'old'], self.output)

    def test_delayed_recovery_cannot_overwrite_newer_release(self):
        self.history()
        self.release('other')
        self.assertNotEqual(self.invoke('newer-release'), 0)
        self.assert_current('other')
        self.assertIn('failed deployment is not current', self.output)
        self.assertFalse(any(r['tool'] == 'systemctl' and r['current'] == 'other' for r in self.records))

    def test_redeploying_same_active_version_does_not_roll_it_back(self):
        self.history()
        self.release('rc-new')
        (self.root / 'current').unlink()
        (self.root / 'current').symlink_to(self.root / 'releases/rc-new')
        (self.root / 'releases/rc-new/.deployment-attempt').write_text('b' * 32)
        self.assertNotEqual(self.invoke(), 0)
        self.assert_current('rc-new')
        self.assertIn('deployment attempt does not match', self.output)
        self.assertFalse(any(r['tool'] == 'systemctl' for r in self.records))

    def test_rollback_without_history_never_guesses_a_target(self):
        (self.root / 'current').symlink_to(self.release('old'))
        self.release('unverified')
        self.assertNotEqual(self.invoke(rollback=True), 0)
        self.assert_current('old')
        self.assertIn('No previous stable release found', self.output)

    def test_rollback_rejects_symlink_target_outside_managed_releases(self):
        self.history()
        outside = self.base / 'outside'
        outside.mkdir()
        (outside / 'release-version.txt').write_text('escape')
        (self.root / 'releases/escape').symlink_to(outside)
        self.assertNotEqual(self.invoke(rollback=True, target='escape'), 0)
        self.assert_current('old')
        self.assertIn('not a symlink', self.output)


if __name__ == '__main__':
    if Path(sys.argv[0]).name in ('ssh', 'scp', 'sudo', 'systemctl', 'flock', 'readlink', 'find', 'sha256sum'):
        sys.exit(shim())
    unittest.main(verbosity=2)
