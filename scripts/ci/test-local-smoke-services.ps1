$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\local-smoke-services.ps1"
$composePath = Join-Path $repoRoot "deploy\smoke-services.compose.yml"

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) { throw $Message }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)

    try { & $Action | Out-Null }
    catch {
        if ($_.Exception.Message -match $Pattern) { return }
        throw "$Message. Unexpected error: $($_.Exception.Message)"
    }
    throw $Message
}

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "local smoke service script must exist"
Assert-True (Test-Path -LiteralPath $composePath -PathType Leaf) "local smoke compose file must exist"

$dryRunRaw = (& $scriptPath -Action VerifyCandidate -CandidateVersion fixture -DryRun -Json) -join "`n"
$dryRun = $dryRunRaw | ConvertFrom-Json
Assert-True ($dryRun.mode -eq "DryRun") "local smoke dry run must identify its mode"
Assert-True ($dryRun.action -eq "VerifyCandidate") "local smoke dry run must preserve its action"
Assert-True ($dryRun.services.Count -eq 4) "local smoke orchestration must include four infrastructure services"
Assert-True $dryRun.waitsForHealth "candidate verification must wait for healthy services"
Assert-True $dryRun.runsCandidateVerification "candidate verification action must invoke the candidate gate"
Assert-True $dryRun.removesVolumesAfter "candidate verification must remove local volumes by default"
Assert-True (-not $dryRun.mutatesLocalDocker) "dry run must not mutate Docker"
foreach ($forbidden in @("dzdp-smoke-root", "dzdp-smoke-secret")) {
    Assert-True ($dryRunRaw -notmatch [regex]::Escape($forbidden)) "dry run must not expose fixture credentials"
}

$keepRaw = (& $scriptPath -Action VerifyCandidate -CandidateVersion fixture -KeepServices -DryRun -Json) -join "`n"
$keep = $keepRaw | ConvertFrom-Json
Assert-True (-not $keep.removesVolumesAfter) "debug mode may explicitly keep local services"

Assert-ThrowsLike {
    & $scriptPath -Action Up -MysqlPort 33060 -RedisPort 33060 -DryRun
} "ports must be unique" "duplicate local ports must be rejected before Docker is invoked"

$compose = Get-Content -LiteralPath $composePath -Raw
foreach ($required in @(
    "mysql:8.4",
    "redis:7.4-alpine",
    "bitnamilegacy/minio@sha256:451fe6858cb770cc9d0e77ba811ce287420f781c7c1b806a386f6896471a349c",
    "docker.elastic.co/elasticsearch/elasticsearch:8.15.5",
    "DZDP_SMOKE_MYSQL_PORT",
    "DZDP_SMOKE_REDIS_PORT",
    "DZDP_SMOKE_MINIO_PORT",
    "DZDP_SMOKE_ELASTICSEARCH_PORT",
    "healthcheck:",
    "127.0.0.1:"
)) {
    Assert-True ($compose.Contains($required)) "local smoke compose must contain $required"
}

$script = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($script -match 'up", "--detach", "--wait"') "local smoke services must wait for health"
Assert-True ($script -match 'down", "--volumes", "--remove-orphans"') "local smoke cleanup must remove volumes and orphans"
Assert-True ($script -match 'candidate-verify[.]ps1') "local smoke orchestration must invoke candidate verification"

Write-Output "local smoke services contract passed"
