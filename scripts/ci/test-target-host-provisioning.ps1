$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$targetRoot = Join-Path $repoRoot "deploy\target-host"
$runnerPath = Join-Path $targetRoot "run-backend.sh"
$nginxPath = Join-Path $targetRoot "nginx\dazhongdianping.conf.example"
$sudoersPath = Join-Path $targetRoot "dazhongdianping-deploy.sudoers.example"
$readmePath = Join-Path $targetRoot "README.md"
$preflightPath = Join-Path $repoRoot "scripts\ci\target-host-preflight.sh"
$testEnvTemplatePath = Join-Path $repoRoot "deploy\eu-test.env.example"
$preEnvTemplatePath = Join-Path $repoRoot "deploy\eu-pre.env.example"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

foreach ($path in @($runnerPath, $nginxPath, $sudoersPath, $readmePath, $testEnvTemplatePath, $preEnvTemplatePath)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "missing target-host reference file: $path"
}

$readme = Get-Content -LiteralPath $readmePath -Raw
Assert-True ($readme -match 'eu-test[.]env[.]example') "target-host instructions must identify the test runtime template"
Assert-True ($readme -match 'eu-pre[.]env[.]example') "target-host instructions must identify the pre runtime template"
Assert-True ($readme -match 'usermod -aG dzdp www-data') "target-host instructions must grant nginx access to private release paths"
Assert-True ($readme -match 'install -d -o deploy -g dzdp -m 2750 /opt/dazhongdianping') "release root must preserve the dzdp group on extracted directories"
Assert-True ($readme -match 'systemctl restart nginx') "target-host instructions must restart nginx after changing worker group membership"

$runner = Get-Content -LiteralPath $runnerPath -Raw
Assert-True ($runner -match 'readlink -f') "backend runner must resolve the current release symlink"
Assert-True ($runner -match 'release_dir.*/releases') "backend runner must constrain the managed release directory"
Assert-True ($runner -match "-name '[*][.]jar'") "backend runner must discover the packaged backend JAR"
Assert-True ($runner -match 'exactly one backend JAR') "backend runner must reject ambiguous JAR layouts"

foreach ($name in @("dzdp-backend", "dzdp-web", "dzdp-admin-web", "dzdp-merchant-web")) {
    $unitPath = Join-Path $targetRoot "systemd\$name.service.example"
    Assert-True (Test-Path -LiteralPath $unitPath -PathType Leaf) "missing systemd reference unit: $name"
    $unit = Get-Content -LiteralPath $unitPath -Raw
    if ($name -eq "dzdp-backend") {
        Assert-True ($unit -match 'EnvironmentFile=/etc/dazhongdianping/eu-test[.]env') "backend unit must load the private runtime env"
        Assert-True ($unit -match 'Environment=SERVER_ADDRESS=127[.]0[.]0[.]1') "backend unit must bind to loopback behind the reference nginx"
        Assert-True ($unit -match 'Environment=SERVER_PORT=8080') "backend unit and nginx must agree on the loopback port"
        Assert-True ($unit -match 'ExecStart=/usr/local/libexec/dazhongdianping/run-backend[.]sh') "backend unit must use the safe release runner"
        Assert-True ($unit -match 'ProtectSystem=strict') "backend unit must enable systemd filesystem hardening"
    }
    else {
        Assert-True ($unit -match 'Requires=nginx[.]service') "$name must depend on nginx"
        Assert-True ($unit -match 'nginx -t') "$name must validate nginx before reload"
        Assert-True ($unit -match 'systemctl reload nginx[.]service') "$name must reload nginx after release switching"
        Assert-True ($unit -match 'RemainAfterExit=true') "$name must remain active for deployment checks"
    }
}

$nginx = Get-Content -LiteralPath $nginxPath -Raw
foreach ($hostPlaceholder in @("CHANGE_ME_WEB_HOST", "CHANGE_ME_ADMIN_HOST", "CHANGE_ME_MERCHANT_HOST", "CHANGE_ME_API_HOST")) {
    Assert-True ($nginx -match $hostPlaceholder) "nginx template must expose $hostPlaceholder"
}
foreach ($root in @("current/web/dist", "current/admin-web/dist", "current/merchant-web/dist")) {
    Assert-True ($nginx -match [regex]::Escape($root)) "nginx template must serve $root"
}
Assert-True ($nginx -match 'proxy_pass http://127[.]0[.]0[.]1:8080') "nginx template must proxy the backend over loopback"
Assert-True ($nginx -match 'proxy_set_header Upgrade') "nginx template must preserve WebSocket upgrades"
Assert-True ($nginx -match 'proxy_set_header X-Forwarded-For [$]remote_addr') "nginx template must overwrite client-supplied forwarding chains"
Assert-True ($nginx -notmatch '[$]proxy_add_x_forwarded_for') "single-hop nginx must not append an untrusted client forwarding chain"
Assert-True ($nginx -match 'client_max_body_size 8m') "nginx template must allow the documented image upload size with multipart overhead"

$sudoers = Get-Content -LiteralPath $sudoersPath -Raw
Assert-True ($sudoers -match 'systemctl restart dzdp-backend dzdp-web dzdp-admin-web dzdp-merchant-web') "sudoers must permit the exact release restart"
Assert-True ($sudoers -match 'systemctl stop dzdp-backend dzdp-web dzdp-admin-web dzdp-merchant-web') "sudoers must permit first-deploy recovery stop"
foreach ($name in @("dzdp-backend", "dzdp-web", "dzdp-admin-web", "dzdp-merchant-web")) {
    Assert-True ($sudoers -match "systemctl is-active --quiet $name") "sudoers must permit status checks for $name"
}

$preflight = Get-Content -LiteralPath $preflightPath -Raw
Assert-True ($preflight -match 'sudo -n -l -- systemctl stop') "target-host preflight must verify recovery stop authorization"

$deployScript = Get-Content -LiteralPath (Join-Path $repoRoot "scripts\ci\deploy-release.ps1") -Raw
Assert-True ($deployScript -match "chmod -R g[+]rX '[`$]remoteReleaseDir'") "deployment must make extracted releases readable by the shared runtime group"

Write-Output "target-host provisioning contract passed"
