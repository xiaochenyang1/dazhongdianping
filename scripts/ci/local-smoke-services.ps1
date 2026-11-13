[CmdletBinding()]
param(
    [ValidateSet("Up", "Down", "Status", "VerifyCandidate")]
    [string]$Action = "Status",
    [string]$CandidateVersion,
    [string]$OutputDirectory = "artifacts/candidate-verification",
    [int]$MysqlPort = 33060,
    [int]$RedisPort = 36379,
    [int]$MinioPort = 39000,
    [int]$ElasticsearchPort = 39200,
    [switch]$AllowDirtySource,
    [switch]$KeepServices,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$composePath = Join-Path $repoRoot "deploy\smoke-services.compose.yml"
$candidateVerifyPath = Join-Path $PSScriptRoot "candidate-verify.ps1"
$projectName = "dzdp-smoke"
$fixtureMysqlPassword = "dzdp-smoke-root"
$fixtureMinioAccessKey = "dzdpsmoke"
$fixtureMinioSecretKey = "dzdp-smoke-secret"

function Assert-Port {
    param([string]$Name, [int]$Port)

    if ($Port -lt 1024 -or $Port -gt 65535) {
        throw "$Name must be between 1024 and 65535"
    }
}

function Set-ProcessEnvironment {
    param([string]$Name, [AllowNull()][string]$Value)

    [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
}

function Invoke-DockerCompose {
    param([string[]]$Arguments, [switch]$PassThru)

    $allArguments = @("compose", "--project-name", $projectName, "--file", $composePath) + $Arguments
    if ($PassThru) {
        & $script:dockerPath @allArguments
    }
    else {
        & $script:dockerPath @allArguments | ForEach-Object { Write-Host $_ }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed during $($Arguments[0])"
    }
}

foreach ($entry in @{
    MysqlPort = $MysqlPort
    RedisPort = $RedisPort
    MinioPort = $MinioPort
    ElasticsearchPort = $ElasticsearchPort
}.GetEnumerator()) {
    Assert-Port -Name $entry.Key -Port $entry.Value
}
$ports = @($MysqlPort, $RedisPort, $MinioPort, $ElasticsearchPort)
if (@($ports | Select-Object -Unique).Count -ne $ports.Count) {
    throw "Local smoke service ports must be unique"
}
if (-not (Test-Path -LiteralPath $composePath -PathType Leaf)) {
    throw "Local smoke compose file is missing"
}
if ($Action -eq "VerifyCandidate" -and -not (Test-Path -LiteralPath $candidateVerifyPath -PathType Leaf)) {
    throw "candidate-verify.ps1 is missing"
}

$plan = [ordered]@{
    schemaVersion = 1
    mode = if ($DryRun) { "DryRun" } else { "Execute" }
    action = $Action
    composeProject = $projectName
    services = @("mysql", "redis", "minio", "elasticsearch")
    waitsForHealth = $Action -in @("Up", "VerifyCandidate")
    runsCandidateVerification = $Action -eq "VerifyCandidate"
    removesVolumesAfter = $Action -eq "Down" -or ($Action -eq "VerifyCandidate" -and -not $KeepServices)
    mutatesLocalDocker = -not $DryRun -and $Action -ne "Status"
}
if ($DryRun) {
    if ($Json) { $plan | ConvertTo-Json -Depth 5 }
    else {
        Write-Output "Plan: $Action local MySQL, Redis, MinIO, and Elasticsearch services with Docker Compose."
        if ($Action -eq "VerifyCandidate") {
            Write-Output "After health checks, run candidate-verify.ps1 and $(if ($KeepServices) { 'keep services for debugging' } else { 'remove containers and volumes' })."
        }
    }
    exit 0
}

$dockerCommand = Get-Command docker -CommandType Application -ErrorAction Stop | Select-Object -First 1
$dockerPath = $dockerCommand.Source
& $dockerPath compose version *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker Compose v2 is required" }

$composeEnvironmentNames = @(
    "DZDP_SMOKE_MYSQL_PORT",
    "DZDP_SMOKE_REDIS_PORT",
    "DZDP_SMOKE_MINIO_PORT",
    "DZDP_SMOKE_ELASTICSEARCH_PORT"
)
$applicationEnvironmentNames = @(
    "APP_DB_HOST",
    "APP_DB_PORT",
    "APP_DB_USERNAME",
    "APP_DB_PASSWORD",
    "APP_REDIS_HOST",
    "APP_REDIS_PORT",
    "APP_STATE_STORE_PROVIDER",
    "APP_S3_ENDPOINT",
    "APP_S3_BUCKET",
    "APP_S3_REGION",
    "APP_S3_PUBLIC_BASE_URL",
    "APP_S3_ACCESS_KEY",
    "APP_S3_SECRET_KEY",
    "APP_S3_PATH_STYLE_ACCESS_ENABLED",
    "APP_SEARCH_BASE_URL"
)
$environmentNamesToRestore = @($composeEnvironmentNames + $applicationEnvironmentNames | Select-Object -Unique)
$originalEnvironment = @{}
foreach ($name in $environmentNamesToRestore) {
    $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

Set-ProcessEnvironment -Name "DZDP_SMOKE_MYSQL_PORT" -Value "$MysqlPort"
Set-ProcessEnvironment -Name "DZDP_SMOKE_REDIS_PORT" -Value "$RedisPort"
Set-ProcessEnvironment -Name "DZDP_SMOKE_MINIO_PORT" -Value "$MinioPort"
Set-ProcessEnvironment -Name "DZDP_SMOKE_ELASTICSEARCH_PORT" -Value "$ElasticsearchPort"

try {
    Invoke-DockerCompose -Arguments @("config", "--quiet")
    switch ($Action) {
        "Up" {
            Invoke-DockerCompose -Arguments @("up", "--detach", "--wait", "--wait-timeout", "240")
        }
        "Down" {
            Invoke-DockerCompose -Arguments @("down", "--volumes", "--remove-orphans", "--timeout", "20")
        }
        "Status" {
            Invoke-DockerCompose -Arguments @("ps") -PassThru
        }
        "VerifyCandidate" {
            Invoke-DockerCompose -Arguments @("up", "--detach", "--wait", "--wait-timeout", "240")

            Set-ProcessEnvironment -Name "APP_DB_HOST" -Value "127.0.0.1"
            Set-ProcessEnvironment -Name "APP_DB_PORT" -Value "$MysqlPort"
            Set-ProcessEnvironment -Name "APP_DB_USERNAME" -Value "root"
            Set-ProcessEnvironment -Name "APP_DB_PASSWORD" -Value $fixtureMysqlPassword
            Set-ProcessEnvironment -Name "APP_REDIS_HOST" -Value "127.0.0.1"
            Set-ProcessEnvironment -Name "APP_REDIS_PORT" -Value "$RedisPort"
            Set-ProcessEnvironment -Name "APP_STATE_STORE_PROVIDER" -Value "redis"
            Set-ProcessEnvironment -Name "APP_S3_ENDPOINT" -Value "http://127.0.0.1:$MinioPort"
            Set-ProcessEnvironment -Name "APP_S3_BUCKET" -Value "dzdp-smoke"
            Set-ProcessEnvironment -Name "APP_S3_REGION" -Value "us-east-1"
            Set-ProcessEnvironment -Name "APP_S3_PUBLIC_BASE_URL" -Value "http://127.0.0.1:$MinioPort/dzdp-smoke"
            Set-ProcessEnvironment -Name "APP_S3_ACCESS_KEY" -Value $fixtureMinioAccessKey
            Set-ProcessEnvironment -Name "APP_S3_SECRET_KEY" -Value $fixtureMinioSecretKey
            Set-ProcessEnvironment -Name "APP_S3_PATH_STYLE_ACCESS_ENABLED" -Value "true"
            Set-ProcessEnvironment -Name "APP_SEARCH_BASE_URL" -Value "http://127.0.0.1:$ElasticsearchPort"

            $candidateParameters = @{
                OutputDirectory = $OutputDirectory
                AllowDirtySource = $AllowDirtySource
                Json = $Json
            }
            if (-not [string]::IsNullOrWhiteSpace($CandidateVersion)) {
                $candidateParameters.CandidateVersion = $CandidateVersion
            }
            & $candidateVerifyPath @candidateParameters
        }
    }
}
finally {
    if ($Action -eq "VerifyCandidate" -and -not $KeepServices) {
        try {
            Invoke-DockerCompose -Arguments @("down", "--volumes", "--remove-orphans", "--timeout", "20")
        }
        catch {
            Write-Warning "Local smoke service cleanup failed"
        }
    }
    foreach ($name in $environmentNamesToRestore) {
        Set-ProcessEnvironment -Name $name -Value $originalEnvironment[$name]
    }
}
