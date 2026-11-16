$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ansibleRoot = Join-Path $repoRoot "deploy\ansible"
$playbookPath = Join-Path $ansibleRoot "provision-target-host.yml"
$inventoryPath = Join-Path $ansibleRoot "inventory.example.yml"
$varsPath = Join-Path $ansibleRoot "vars\test.example.yml"
$readmePath = Join-Path $ansibleRoot "README.md"
$backendTemplatePath = Join-Path $ansibleRoot "templates\dzdp-backend.service.j2"
$nginxTemplatePath = Join-Path $ansibleRoot "templates\dazhongdianping.conf.j2"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

foreach ($path in @($playbookPath, $inventoryPath, $varsPath, $readmePath, $backendTemplatePath, $nginxTemplatePath)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "missing Ansible provisioning file: $path"
}

$playbook = Get-Content -LiteralPath $playbookPath -Raw
foreach ($token in @(
    'hosts: dzdp_targets',
    'Require Ubuntu 24.04 LTS',
    'openjdk-17-jre-headless',
    'default-mysql-client',
    'Install private runtime environment',
    'Install private MySQL defaults',
    'no_log: true',
    'validate: /usr/sbin/visudo -cf %s',
    'Validate and restart nginx',
    'Enable backend service without starting it'
)) {
    Assert-True ($playbook.Contains($token)) "Ansible provisioning must contain: $token"
}
Assert-True ($playbook -notmatch '(?i)amazon[.]aws|azure[.]azcollection|google[.]cloud|community[.]digitalocean') "host provisioning must remain cloud-provider neutral"
Assert-True (([regex]::Matches($playbook, 'no_log: true')).Count -eq 2) "both private file transfers must suppress task output"
$privateCopyBlocks = [regex]::Matches($playbook, '(?s)- name: Install private (?:runtime environment|MySQL defaults).*?(?=\n    - name:)')
Assert-True ($privateCopyBlocks.Count -eq 2) "both private file transfer tasks must remain identifiable"
foreach ($block in $privateCopyBlocks) {
    Assert-True ($block.Value -notmatch 'backup: true') "private credential rotation must not retain stale backup copies"
}
Assert-True ($playbook -match "dzdp_tls_certificate_path is match") "TLS paths must be constrained before rendering nginx"
Assert-True ($playbook -match "'//'.*not in dzdp_release_root") "release root must reject ambiguous path separators"

$inventory = Get-Content -LiteralPath $inventoryPath -Raw
Assert-True ($inventory -match 'CHANGE_ME_TEST_HOST') "example inventory must retain a target-host placeholder"
Assert-True ($inventory -match 'ansible_user: deploy') "example inventory must use the deployment account"

$vars = Get-Content -LiteralPath $varsPath -Raw
Assert-True ($vars -match 'dzdp_environment: test') "test vars must identify the test runtime"
Assert-True ($vars -match 'dzdp_runtime_env_target: /etc/dazhongdianping/eu-test[.]env') "test vars must install the isolated runtime env"
Assert-True ($vars -match 'dzdp_release_root: /opt/dazhongdianping') "test vars must match the release workflow root"
Assert-True ($vars -notmatch '(?i)(BEGIN (RSA |OPENSSH )?PRIVATE KEY|sk_(live|test)_[A-Za-z0-9]{16,}|whsec_[A-Za-z0-9]{16,})') "example vars must not contain credentials"

$canonicalBackend = Get-Content -LiteralPath (Join-Path $repoRoot "deploy\target-host\systemd\dzdp-backend.service.example") -Raw
$expectedBackend = $canonicalBackend.Replace('User=dzdp', 'User={{ dzdp_runtime_user }}').Replace('Group=dzdp', 'Group={{ dzdp_runtime_group }}').Replace('EnvironmentFile=/etc/dazhongdianping/eu-test.env', 'EnvironmentFile={{ dzdp_runtime_env_target }}').Replace('Environment=DZDP_RELEASE_ROOT=/opt/dazhongdianping', 'Environment=DZDP_RELEASE_ROOT={{ dzdp_release_root }}').Replace('WorkingDirectory=/var/lib/dazhongdianping', 'WorkingDirectory={{ dzdp_runtime_home }}').Replace('ReadWritePaths=/var/lib/dazhongdianping', 'ReadWritePaths={{ dzdp_runtime_home }}')
$backendTemplate = Get-Content -LiteralPath $backendTemplatePath -Raw
Assert-True ($backendTemplate.Replace("`r`n", "`n").Trim() -ceq $expectedBackend.Replace("`r`n", "`n").Trim()) "Ansible backend unit must stay aligned with the manual target-host template"

$canonicalNginx = Get-Content -LiteralPath (Join-Path $repoRoot "deploy\target-host\nginx\dazhongdianping.conf.example") -Raw
$expectedNginx = $canonicalNginx.Replace('CHANGE_ME_WEB_HOST', '{{ dzdp_web_host }}').Replace('CHANGE_ME_ADMIN_HOST', '{{ dzdp_admin_host }}').Replace('CHANGE_ME_MERCHANT_HOST', '{{ dzdp_merchant_host }}').Replace('CHANGE_ME_API_HOST', '{{ dzdp_api_host }}').Replace('CHANGE_ME_CERTIFICATE_FULLCHAIN', '{{ dzdp_tls_certificate_path }}').Replace('CHANGE_ME_CERTIFICATE_KEY', '{{ dzdp_tls_certificate_key_path }}').Replace('/opt/dazhongdianping', '{{ dzdp_release_root }}')
$nginxTemplate = Get-Content -LiteralPath $nginxTemplatePath -Raw
Assert-True ($nginxTemplate.Replace("`r`n", "`n").Trim() -ceq $expectedNginx.Replace("`r`n", "`n").Trim()) "Ansible nginx config must stay aligned with the manual target-host template"

$gitignore = Get-Content -LiteralPath (Join-Path $repoRoot ".gitignore") -Raw
Assert-True ($gitignore -match 'deploy/ansible/inventory[.]yml') "real Ansible inventory must be ignored"
Assert-True ($gitignore -match 'deploy/ansible/vars/[*][.]yml') "real Ansible vars must be ignored"

$ruby = Get-Command ruby -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $ruby) {
    & $ruby.Source -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' $playbookPath $inventoryPath $varsPath
    if ($LASTEXITCODE -ne 0) { throw "Ansible YAML examples must be parseable" }
}

Write-Output "target-host Ansible contract passed"
