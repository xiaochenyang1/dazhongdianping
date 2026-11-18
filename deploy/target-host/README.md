# Target host reference setup

These files prepare the Linux host expected by `target-host-preflight.ps1`,
`deploy-release.ps1`, and `rollback-release.ps1`. They are reference templates:
replace every `CHANGE_ME` value and review the paths, users, ports, certificates,
firewall rules, and package names for the selected provider before installation.
For an existing Ubuntu 24.04 host, [`deploy/ansible/`](../ansible/README.md)
automates these same files and permissions without creating cloud resources.

## Required host software

- Linux with systemd, Bash, Java 17+, nginx, MySQL client, curl, OpenSSL,
  unzip, sudo, `chmod`, `flock`, `sha256sum`, `readlink`, and GNU `stat`.
- A non-interactive SSH account named `deploy` (or update the sudoers template
  and GitHub Environment consistently).
- DNS and trusted HTTPS certificates for the user, admin, merchant, and API
  hosts. Only the ingress/load-balancer peers may reach the backend port.

## Filesystem and accounts

The commands below are examples for `/opt/dazhongdianping`. Run them through an
approved privileged provisioning channel, not through the application release
workflow.

```bash
sudo useradd --system --home /var/lib/dazhongdianping --shell /usr/sbin/nologin dzdp
sudo usermod -aG dzdp deploy
# Debian/Ubuntu use www-data by default. Substitute the worker account declared
# by the nginx `user` directive on distributions that use another account.
sudo usermod -aG dzdp www-data
# The setgid bit keeps uploaded and extracted release directories in the dzdp
# group so both the backend runtime and nginx workers can read the active build.
sudo install -d -o deploy -g dzdp -m 2750 /opt/dazhongdianping
sudo install -d -o dzdp -g dzdp -m 0750 /var/lib/dazhongdianping
sudo install -d -o root -g root -m 0755 /usr/local/libexec/dazhongdianping
sudo install -o root -g root -m 0755 deploy/target-host/run-backend.sh \
  /usr/local/libexec/dazhongdianping/run-backend.sh
```

Install the real runtime env and MySQL defaults outside the release root. Both
must be readable by the SSH deployment account and must have mode `0400` or
`0600`, because the target-host audit parses them and performs a read-only
database query. Start the test file from
[`deploy/eu-test.env.example`](../eu-test.env.example). On the separate pre
host, use [`deploy/eu-pre.env.example`](../eu-pre.env.example) and update the
backend unit's `EnvironmentFile` path accordingly. Do not commit either real
file.

```bash
sudo install -d -o deploy -g deploy -m 0700 /etc/dazhongdianping
sudo install -o deploy -g deploy -m 0600 /secure/source/eu-test.env \
  /etc/dazhongdianping/eu-test.env
sudo install -o deploy -g deploy -m 0600 /secure/source/mysql-release.cnf \
  /etc/dazhongdianping/mysql-release.cnf
```

## systemd, nginx, and sudo

1. Copy the four files under `systemd/` to `/etc/systemd/system/`, removing the
   `.example` suffix. Update the backend unit if the runtime env, release root,
   runtime user, or working directory differs. The reference unit binds Spring
   Boot to `127.0.0.1:8080`; do not remove that boundary unless an approved
   external ingress connects directly to the backend and the firewall plus
   trusted-proxy allowlist are updated together.
2. Copy the nginx example to the host site configuration, replace all
   `CHANGE_ME` values, enable the site, and verify it with `nginx -t`. The three
   static service units validate and reload the shared nginx configuration when
   a release switches the `current` symlink.
3. Copy the sudoers example to `/etc/sudoers.d/dazhongdianping-deploy`, update
   the SSH user or service names if necessary, set mode `0440`, and validate it
   with `visudo -cf`. The `stop` command is required for safe recovery when the
   first deployment activates no previous release.
4. Run `systemctl daemon-reload`, enable nginx and the three static reload
   units. The backend unit can remain stopped until the first release creates a
   valid `current` symlink.

```bash
sudo nginx -t
sudo visudo -cf /etc/sudoers.d/dazhongdianping-deploy
sudo systemctl daemon-reload
sudo systemctl enable --now nginx dzdp-web dzdp-admin-web dzdp-merchant-web
# Restart nginx after changing worker group membership; a reload is insufficient
# on platforms that keep the old supplementary group set in existing workers.
sudo systemctl restart nginx
sudo systemctl enable dzdp-backend
```

For this same-host nginx topology, keep port `8080` loopback-only and set
`APP_TRUSTED_PROXY_REGEX='^127[.]0[.]0[.]1$'`; nginx overwrites the incoming
`X-Forwarded-For` header with its observed client address. If a CDN or external
load balancer is inserted before nginx, configure nginx real-IP handling only
for that provider's exact peers before relying on `$remote_addr`. Prepare the
GitHub Environment values and run the read-only target audit before packaging:

```powershell
./scripts/ci/target-host-preflight.ps1 -Environment test -Region EU -ReportOnly -Json
```
