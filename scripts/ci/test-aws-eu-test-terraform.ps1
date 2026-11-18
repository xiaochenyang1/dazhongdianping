$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$terraformRoot = Join-Path $repoRoot "deploy\terraform\aws-eu-test"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$requiredFiles = @(
    ".terraform.lock.hcl",
    "README.md",
    "backend.hcl.example",
    "cloud-init.tftpl",
    "compute.tf",
    "data-services.tf",
    "locals.tf",
    "network.tf",
    "outputs.tf",
    "security.tf",
    "storage.tf",
    "terraform.tfvars.example",
    "variables.tf",
    "versions.tf"
)

foreach ($name in $requiredFiles) {
    $path = Join-Path $terraformRoot $name
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "missing AWS EU test Terraform file: $name"
}

$tfFiles = Get-ChildItem -LiteralPath $terraformRoot -Filter "*.tf" -File | Sort-Object Name
$terraformSource = ($tfFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
$versions = Get-Content -LiteralPath (Join-Path $terraformRoot "versions.tf") -Raw
$variables = Get-Content -LiteralPath (Join-Path $terraformRoot "variables.tf") -Raw
$locals = Get-Content -LiteralPath (Join-Path $terraformRoot "locals.tf") -Raw
$network = Get-Content -LiteralPath (Join-Path $terraformRoot "network.tf") -Raw
$security = Get-Content -LiteralPath (Join-Path $terraformRoot "security.tf") -Raw
$compute = Get-Content -LiteralPath (Join-Path $terraformRoot "compute.tf") -Raw
$cloudInit = Get-Content -LiteralPath (Join-Path $terraformRoot "cloud-init.tftpl") -Raw
$services = Get-Content -LiteralPath (Join-Path $terraformRoot "data-services.tf") -Raw
$storage = Get-Content -LiteralPath (Join-Path $terraformRoot "storage.tf") -Raw
$outputs = Get-Content -LiteralPath (Join-Path $terraformRoot "outputs.tf") -Raw
$readme = Get-Content -LiteralPath (Join-Path $terraformRoot "README.md") -Raw
$tfvarsExample = Get-Content -LiteralPath (Join-Path $terraformRoot "terraform.tfvars.example") -Raw

Assert-True ($versions -match 'required_version\s*=\s*">= 1[.]8[.]0, < 2[.]0[.]0"') "Terraform CLI compatibility must be bounded"
Assert-True ($versions -match 'source\s*=\s*"hashicorp/aws"') "the AWS provider must be declared explicitly"
Assert-True ($versions -match 'backend\s+"s3"') "reviewed remote S3 state must be supported"
Assert-True ($variables -match 'var[.]aws_region == "eu-west-3"') "the module must fail closed outside Paris"
Assert-True ($variables -match 'var[.]environment == "test"') "the module must fail closed outside test"
Assert-True ($variables -match 'cidr != "0[.]0[.]0[.]0/0"') "SSH validation must reject the world CIDR"
Assert-True ($locals -match '(?s)merge\(\s*var[.]additional_tags,\s*\{.*DataResidency\s*=\s*"EU"') "mandatory residency tags must override optional tags"

Assert-True (([regex]::Matches($network, 'resource\s+"aws_subnet"\s+"(?:public|private)"')).Count -eq 2) "public and private subnet resources must both exist"
Assert-True (([regex]::Matches($network, '(?m)^\s*count\s*=\s*2\s*$')).Count -eq 4) "two-AZ subnet and route-table associations must stay explicit"
Assert-True ($network -match 'resource\s+"aws_internet_gateway"') "the public target subnet needs an internet gateway"
Assert-True ($network -match 'resource\s+"aws_vpc_endpoint"\s+"s3"') "the VPC must retain an S3 gateway endpoint"

foreach ($port in @(3306, 6379, 443)) {
    Assert-True ($security -match "from_port\s*=\s*$port") "managed-service security rules must retain port $port"
}
Assert-True (([regex]::Matches($security, 'referenced_security_group_id\s*=\s*aws_security_group[.]target[.]id')).Count -eq 3) "MySQL, Redis, and OpenSearch must accept traffic only from the target security group"
Assert-True ($security -notmatch 'from_port\s*=\s*8080') "the Spring Boot loopback port must not be exposed by Terraform"

Assert-True ($compute -match 'owners\s*=\s*\["099720109477"\]') "the Ubuntu image must come from Canonical"
Assert-True ($compute -match 'ubuntu-noble-24[.]04') "the target must use Ubuntu 24.04 LTS"
Assert-True ($compute -match 'http_tokens\s*=\s*"required"') "EC2 must require IMDSv2"
Assert-True ($compute -match 'encrypted\s*=\s*true') "the EC2 root volume must be encrypted"
Assert-True ($compute -match 'secretsmanager:GetSecretValue') "the target role must read approved runtime secrets"
Assert-True ($compute -notmatch 'aws_db_instance[.]mysql[.]master_user_secret') "the target role must not read the RDS bootstrap secret"
Assert-True ($compute -match 's3:PutObject') "the target role must support application asset writes"
Assert-True ($cloudInit -match '(?m)^\s*- name: deploy\s*$') "cloud-init must create the restricted release identity"
Assert-True ($cloudInit -notmatch '(?m)^\s*sudo:') "cloud-init must not grant deploy general sudo access"

Assert-True ($services -match 'name\s*=\s*"require_secure_transport"') "RDS must force MySQL TLS"
Assert-True ($services -match 'manage_master_user_password\s*=\s*true') "RDS must manage its bootstrap password in Secrets Manager"
Assert-True ($services -match 'publicly_accessible\s*=\s*false') "RDS must stay private"
Assert-True ($services -match 'transit_encryption_enabled\s*=\s*true') "Redis transport encryption must remain enabled"
Assert-True ($services -match 'transit_encryption_mode\s*=\s*"required"') "Redis must reject plaintext connections"
Assert-True ($services -match 'at_rest_encryption_enabled\s*=\s*true') "Redis at-rest encryption must remain enabled"
Assert-True ($services -match 'auth_token\s*=\s*random_password[.]redis[.]result') "Redis must retain generated authentication"
Assert-True ($services -match 'enforce_https\s*=\s*true') "OpenSearch must force HTTPS"
Assert-True ($services -match 'node_to_node_encryption') "OpenSearch node-to-node encryption must remain declared"
Assert-True ($services -match 'internal_user_database_enabled\s*=\s*true') "OpenSearch internal-user authentication must remain enabled"
Assert-True ($services -match 'anonymous_auth_enabled\s*=\s*false') "OpenSearch anonymous authentication must remain disabled"
Assert-True ($services -match 'security_group_ids\s*=\s*\[aws_security_group[.]opensearch[.]id\]') "OpenSearch must stay inside the restricted VPC boundary"

foreach ($setting in @('block_public_acls', 'block_public_policy', 'ignore_public_acls', 'restrict_public_buckets')) {
    Assert-True ($storage -match "$setting\s*=\s*true") "S3 public access control must retain $setting"
}
Assert-True ($storage -match 'object_ownership\s*=\s*"BucketOwnerEnforced"') "S3 ACLs must stay disabled"
Assert-True ($storage -match 'sse_algorithm\s*=\s*"AES256"') "S3 default encryption must remain enabled"
Assert-True ($storage -match 'signing_behavior\s*=\s*"always"') "CloudFront must always sign private S3 origin requests"
Assert-True ($storage -match 'origin_access_control_id') "CloudFront must use origin access control"
Assert-True ($storage -match 'minimum_protocol_version\s*=\s*"TLSv1[.]2_2021"') "CloudFront viewers must use the TLS 1.2 baseline"

Assert-True ($outputs -match 'APP_S3_CREDENTIALS_PROVIDER\s*=\s*"default_chain"') "runtime hints must select the EC2 role/default credential chain"
Assert-True ($outputs -match 'runtime_secret_arns') "outputs must expose secret identifiers for controlled retrieval"
Assert-True ($outputs -notmatch 'APP_DB_USERNAME\s*=\s*aws_db_instance[.]mysql[.]username') "runtime hints must not promote the RDS bootstrap administrator to the application identity"
Assert-True ($outputs -notmatch 'random_password[.]|secret_string\s*=|(?m)^\s*password\s*=') "outputs must never expose generated secret values"
Assert-True ($terraformSource -notmatch '(?i)(AKIA[0-9A-Z]{16}|BEGIN (RSA |OPENSSH )?PRIVATE KEY|sk_(live|test)_[A-Za-z0-9]{16,}|whsec_[A-Za-z0-9]{16,})') "Terraform source must not contain credentials"
Assert-True ($tfvarsExample -match 'CHANGE_ME_SSH_PUBLIC_KEY') "tfvars example must retain an explicit public-key placeholder"
Assert-True ($tfvarsExample -notmatch '(?i)PRIVATE KEY-----') "tfvars example must never contain private key material"

Assert-True ($readme -match 'must stop at formatting, validation, and\s+plan review') "documentation must forbid unapproved paid-resource creation"
Assert-True ($readme -match '`ubuntu` account is the privileged provisioning identity') "documentation must retain the provisioning identity boundary"
Assert-True ($readme -match '`deploy` with the reviewed SSH public key but gives it no\s+general sudo permission') "documentation must retain the release identity boundary"
Assert-True ($readme -match 'APP_S3_CREDENTIALS_PROVIDER=default_chain') "documentation must prohibit long-lived target AWS keys"

$gitignore = Get-Content -LiteralPath (Join-Path $repoRoot ".gitignore") -Raw
foreach ($pattern in @(
    'deploy/terraform/**/.terraform/',
    'deploy/terraform/**/terraform.tfvars',
    'deploy/terraform/**/*.tfvars',
    'deploy/terraform/**/*.tfvars.json',
    'deploy/terraform/**/backend.hcl',
    'deploy/terraform/**/*.tfplan',
    'deploy/terraform/**/*.tfstate'
)) {
    Assert-True ($gitignore.Contains($pattern)) "Terraform working artifact must be ignored: $pattern"
}

$terraform = Get-Command terraform -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $terraform) {
    & $terraform.Source "-chdir=$terraformRoot" fmt -check -recursive -no-color
    if ($LASTEXITCODE -ne 0) { throw "AWS EU test Terraform files must pass terraform fmt -check" }

    & $terraform.Source "-chdir=$terraformRoot" init -backend=false -input=false -no-color
    if ($LASTEXITCODE -ne 0) { throw "AWS EU test Terraform provider initialization must pass" }

    & $terraform.Source "-chdir=$terraformRoot" validate -no-color
    if ($LASTEXITCODE -ne 0) { throw "AWS EU test Terraform configuration must pass terraform validate" }
}

Write-Output "AWS EU test Terraform contract passed"
