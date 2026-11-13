$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\candidate-verify.ps1"
$verifyAllPath = Join-Path $repoRoot "scripts\ci\verify-all.ps1"

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) { throw $Message }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)

    try {
        & $Action | Out-Null
    }
    catch {
        if ($_.Exception.Message -match $Pattern) { return }
        throw "$Message. Unexpected error: $($_.Exception.Message)"
    }
    throw $Message
}

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "candidate verification script must exist"
Assert-True (Test-Path -LiteralPath $verifyAllPath -PathType Leaf) "verify-all script must exist"

$dryRunRaw = (& $scriptPath -CandidateVersion fixture-candidate -DryRun -Json) -join "`n"
$dryRun = $dryRunRaw | ConvertFrom-Json
Assert-True ($dryRun.mode -eq "DryRun") "candidate verification dry run must identify its mode"
Assert-True $dryRun.requiresCleanSource "candidate verification must require a clean source by default"
Assert-True $dryRun.usesUniqueMysqlDatabase "candidate verification must generate an isolated MySQL database by default"
Assert-True $dryRun.dropsMysqlDatabaseAfter "candidate verification must clean up its MySQL database by default"
Assert-True $dryRun.requiresRedis "candidate verification must exercise Redis"
Assert-True $dryRun.requiresS3 "candidate verification must exercise S3"
Assert-True $dryRun.requiresElasticsearch "candidate verification must exercise Elasticsearch"
Assert-True ($dryRun.checks.Count -eq 11) "candidate verification must declare every candidate gate"
Assert-True $dryRun.writesEvidence "candidate verification must generate evidence"
Assert-True (-not $dryRun.mutatesTestServices) "dry run must not mutate test services"

$developmentRaw = (& $scriptPath `
    -CandidateVersion fixture-candidate `
    -MysqlDatabaseName fixture_candidate_db `
    -AllowDirtySource `
    -KeepMysqlDatabase `
    -DryRun `
    -Json) -join "`n"
$development = $developmentRaw | ConvertFrom-Json
Assert-True (-not $development.requiresCleanSource) "development mode may explicitly allow dirty source"
Assert-True (-not $development.usesUniqueMysqlDatabase) "an explicit database name must be reported"
Assert-True (-not $development.dropsMysqlDatabaseAfter) "debug mode may explicitly keep its database"

$candidateScript = Get-Content -LiteralPath $scriptPath -Raw
$verifyAllScript = Get-Content -LiteralPath $verifyAllPath -Raw
foreach ($flag in @(
    "IncludeMysqlSmoke",
    "IncludeStorageSmoke",
    "IncludeBrowserSmoke",
    "IncludeBrowserE2E",
    "IncludeElasticsearchSmoke",
    "IncludeFlutter"
)) {
    Assert-True ($candidateScript -match [regex]::Escape($flag)) "candidate verification must request $flag"
}
Assert-True ($candidateScript -match "MysqlSmokeDbName") "candidate verification must pass its isolated database name"
Assert-True ($candidateScript -match "DropMysqlSmokeDatabaseAfter") "candidate verification must request database cleanup"
Assert-True ($verifyAllScript -match '\[string\]\$MysqlSmokeDbName') "verify-all must accept an isolated MySQL database name"
Assert-True ($verifyAllScript -match '\[switch\]\$DropMysqlSmokeDatabaseAfter') "verify-all must accept database cleanup"
Assert-True ($verifyAllScript -match 'DbName = \$MysqlSmokeDbName') "verify-all must forward the database name"
Assert-True ($verifyAllScript -match 'DropDatabaseAfter = \$true') "verify-all must forward database cleanup"

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("dzdp-candidate-verification-" + [Guid]::NewGuid().ToString("N"))
$s3EnvironmentNames = @("APP_S3_ENDPOINT", "APP_S3_BUCKET", "APP_S3_ACCESS_KEY", "APP_S3_SECRET_KEY")
$originalS3Environment = @{}
try {
    foreach ($name in $s3EnvironmentNames) {
        $originalS3Environment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
    }
    Assert-ThrowsLike {
        & $scriptPath `
            -CandidateVersion fixture-blocked `
            -AllowDirtySource `
            -OutputDirectory $fixtureRoot `
            -Json
    } "requires environment values" "missing service configuration must block candidate verification"

    $blockedJsonPath = Get-ChildItem -LiteralPath $fixtureRoot -Filter "*.json" | Select-Object -First 1 -ExpandProperty FullName
    $blockedMarkdownPath = Get-ChildItem -LiteralPath $fixtureRoot -Filter "*.md" | Select-Object -First 1 -ExpandProperty FullName
    Assert-True (-not [string]::IsNullOrWhiteSpace($blockedJsonPath)) "blocked verification must write JSON evidence"
    Assert-True (-not [string]::IsNullOrWhiteSpace($blockedMarkdownPath)) "blocked verification must write Markdown evidence"
    $blocked = Get-Content -LiteralPath $blockedJsonPath -Raw | ConvertFrom-Json
    Assert-True (-not $blocked.ready) "preflight failure must not be ready"
    Assert-True ($blocked.failedStage -eq "preflight") "preflight failure must identify its stage"
    Assert-True ($blocked.commitSha -match '^[0-9a-f]{40}$') "blocked evidence must retain source provenance"
    Assert-True ((Get-Content -LiteralPath $blockedMarkdownPath -Raw) -match 'Result: \*\*blocked\*\*') "blocked Markdown must state its result"
}
finally {
    foreach ($name in $s3EnvironmentNames) {
        [Environment]::SetEnvironmentVariable($name, $originalS3Environment[$name], "Process")
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Output "candidate verification contract passed"
