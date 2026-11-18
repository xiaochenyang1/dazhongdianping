# Ubuntu 24.04 target-host provisioning

This playbook applies the repository's target-host contract to an existing
Ubuntu 24.04 LTS server. It does not create a VM, DNS records, TLS certificates,
databases, Redis, object storage, Elasticsearch, Stripe, SMTP, or Twilio
accounts. Those resources must exist before the playbook is applied.

For the AWS EU `test` topology, the reviewed repository-side resource baseline
is under [`deploy/terraform/aws-eu-test/`](../terraform/aws-eu-test/README.md).
Terraform validation or plan review does not authorize creating its paid
resources; apply it only after separate account, cost, network, and lifecycle
approval.

The SSH provisioning account must already exist and have passwordless `become`
access. On the repository's AWS Ubuntu 24.04 baseline this is Canonical's
`ubuntu` account. The separate `deploy` account must already exist but must not
have general sudo access; application releases use only the narrower sudoers
policy installed by this playbook.

## Private inputs

Keep the real inventory, runtime env, MySQL defaults file, SSH key, and
certificate material outside Git. The repository ignores the conventional
`inventory.yml` and `vars/*.yml` working copies, but the runtime env and MySQL
files should preferably live outside the repository entirely.

```bash
cp deploy/ansible/inventory.example.yml deploy/ansible/inventory.yml
cp deploy/ansible/vars/test.example.yml deploy/ansible/vars/test.yml
```

Replace every `CHANGE_ME` value. The two controller-side source paths must point
to private files with reviewed test values. Do not put secret values in the
inventory or vars YAML. Keep `ansible_user: ubuntu` for AWS provisioning and
keep `dzdp_deploy_user: deploy` in the vars file so privileged provisioning and
routine releases remain separate identities.

Before uploading the runtime file, validate its launch modes and provider
configuration from an approved workstation:

```bash
set -a
source /path/to/private/eu-test.env
set +a
./scripts/ci/stripe-preflight.sh --environment test --check-cli
```

## Apply

Install `ansible-core` on the controller, then validate and apply from the
repository root:

```bash
ansible-playbook \
  -i deploy/ansible/inventory.yml \
  deploy/ansible/provision-target-host.yml \
  -e @deploy/ansible/vars/test.yml \
  --syntax-check

ansible-playbook \
  -i deploy/ansible/inventory.yml \
  deploy/ansible/provision-target-host.yml \
  -e @deploy/ansible/vars/test.yml
```

The playbook refuses non-Ubuntu-24 hosts and validates the existing TLS files
before replacing nginx configuration. After it succeeds, run the repository's
read-only target audit:

```powershell
./scripts/ci/target-host-preflight.ps1 -Environment test -Region EU -ReportOnly -Json
```

Do not treat Ansible success as supplier delivery, deployment, browser
acceptance, backup restore, or rollback evidence.
