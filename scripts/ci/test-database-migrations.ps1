$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$mysqlSourceDir = Join-Path $repoRoot "sql\mysql"
$manifestPath = Join-Path $mysqlSourceDir "migrations.sha256"
$runnerPath = Join-Path $repoRoot "scripts\ci\mysql-migrate.sh"
$packagePath = Join-Path $repoRoot "scripts\ci\package-release.ps1"
$deployPath = Join-Path $repoRoot "scripts\ci\deploy-release.ps1"
$releaseWorkflowPath = Join-Path $repoRoot ".github\workflows\release.yml"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $manifestPath) "sql/mysql/migrations.sha256 must exist"
Assert-True (Test-Path -LiteralPath $runnerPath) "scripts/ci/mysql-migrate.sh must exist"
Assert-True (Test-Path -LiteralPath $packagePath) "package-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $deployPath) "deploy-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $releaseWorkflowPath) "release workflow must exist"

$manifestLines = @(Get-Content -LiteralPath $manifestPath)
$expectedVersion = 3
$manifestNames = @()
foreach ($line in $manifestLines) {
    $match = [regex]::Match($line, '^([0-9a-f]{64})  ([0-9]{2,}_[A-Za-z0-9_]+_migration\.sql)$')
    Assert-True $match.Success "migration manifest contains an invalid line"
    $version = [int]($match.Groups[2].Value.Split('_')[0])
    Assert-True ($version -eq $expectedVersion) "migration manifest versions must be contiguous from 03"
    $fileName = $match.Groups[2].Value
    $filePath = Join-Path $mysqlSourceDir $fileName
    Assert-True (Test-Path -LiteralPath $filePath -PathType Leaf) "manifest migration file is missing: $fileName"
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash.ToLowerInvariant()
    Assert-True ($actualHash -eq $match.Groups[1].Value) "manifest checksum mismatch: $fileName"
    $manifestNames += $fileName
    $expectedVersion++
}
Assert-True ($manifestNames.Count -eq 12) "the current release baseline must contain migrations 03 through 14"
Assert-True (-not ($manifestNames -match '^01_|^02_')) "foundational schema/seed files must not be release migrations"

$incrementalNames = @(Get-ChildItem -LiteralPath $mysqlSourceDir -File -Filter "*_migration.sql" | Sort-Object Name | ForEach-Object Name)
Assert-True ($incrementalNames.Count -eq $manifestNames.Count) "manifest must enumerate every incremental SQL file"
for ($index = 0; $index -lt $manifestNames.Count; $index++) {
    Assert-True ($incrementalNames[$index] -eq $manifestNames[$index]) "incremental file is not in the manifest: $($incrementalNames[$index])"
}

$bash = (Get-Command bash -ErrorAction Stop).Source
$sourceDryRun = & $bash $runnerPath --dry-run
if ($LASTEXITCODE -ne 0) {
    throw "source-layout migration runner dry-run failed"
}
Assert-True (($sourceDryRun -join "`n") -match "versions 03-14") "source-layout dry-run must report versions 03-14"

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dzdp-migration-contract-" + [guid]::NewGuid().ToString("N"))
try {
    $stagedDatabase = Join-Path $temporaryRoot "database"
    $stagedMigrations = Join-Path $stagedDatabase "migrations"
    New-Item -ItemType Directory -Path $stagedMigrations -Force | Out-Null
    foreach ($name in $manifestNames) {
        Copy-Item -LiteralPath (Join-Path $mysqlSourceDir $name) -Destination (Join-Path $stagedMigrations $name)
    }
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $stagedDatabase "migrations.sha256")
    Copy-Item -LiteralPath $runnerPath -Destination (Join-Path $stagedDatabase "mysql-migrate.sh")
    $stagedDryRun = & $bash (Join-Path $stagedDatabase "mysql-migrate.sh") --dry-run
    if ($LASTEXITCODE -ne 0) {
        throw "packaged-layout migration runner dry-run failed"
    }
    Assert-True (($stagedDryRun -join "`n") -match "versions 03-14") "packaged-layout dry-run must report versions 03-14"
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$runner = Get-Content -LiteralPath $runnerPath -Raw
$package = Get-Content -LiteralPath $packagePath -Raw
$deploy = Get-Content -LiteralPath $deployPath -Raw
$workflow = Get-Content -LiteralPath $releaseWorkflowPath -Raw

Assert-True ($runner -match "GET_LOCK") "migration runner must acquire a MySQL advisory lock"
Assert-True ($runner -match "RELEASE_LOCK") "migration runner must release the MySQL advisory lock"
Assert-True ($runner -match "PENDING") "migration runner must persist PENDING before executing SQL"
Assert-True ($runner -match "FAILED") "migration runner must persist FAILED after SQL failure"
Assert-True ($runner -match "APPLIED") "migration runner must persist APPLIED only after SQL success"
Assert-True ($runner -match "manual repair") "non-success history states must block subsequent deployments"
Assert-True ($runner -match "defaults-extra-file") "migration runner must use a secret-managed MySQL defaults file"
Assert-True ($runner -match "baseline-version") "migration runner must require an explicit first-takeover baseline"
Assert-True ($runner -match "sha256sum --check") "migration runner must verify the migration manifest"
Assert-True ($package -match "migrations\.sha256") "package script must include the migration manifest"
Assert-True ($package -match "database/mysql-migrate\.sh") "package script must include the migration runner"
Assert-True ($package -match "databaseMigrations") "release manifest must record migration metadata"
Assert-True ($package -match "sql/mysql/03\+") "package dry-run must describe the incremental-only boundary"
Assert-True ($package -notmatch "-DskipTests") "release packaging must run backend tests by default"
Assert-True ($deploy -match "DEPLOY_DB_DEFAULTS_FILE") "deploy script must accept the secret-managed DB defaults path"
Assert-True ($deploy -match "DEPLOY_DB_BASELINE_VERSION") "deploy script must accept the explicit baseline version"
Assert-True ($deploy -match "mysql-migrate\.sh") "deploy script must invoke the migration runner"
$migrationInvocationIndex = $deploy.IndexOf('bash ''$remoteReleaseDir/database/mysql-migrate.sh''')
Assert-True ($migrationInvocationIndex -ge 0) "deploy script must contain the real remote migration invocation"
Assert-True ($migrationInvocationIndex -lt $deploy.LastIndexOf('$remotePreviousPath')) "migration must run before previous is changed"
Assert-True ($migrationInvocationIndex -lt $deploy.LastIndexOf('$remoteCurrentPath')) "migration must run before current is switched"
Assert-True ($migrationInvocationIndex -lt $deploy.LastIndexOf('$restartCommand')) "migration must run before services restart"
Assert-True (([regex]::Matches($workflow, "DEPLOY_DB_DEFAULTS_FILE")).Count -ge 3) "all release environments must map DEPLOY_DB_DEFAULTS_FILE"
Assert-True (([regex]::Matches($workflow, "DEPLOY_DB_MIGRATION_MODE")).Count -ge 3) "all release environments must map DEPLOY_DB_MIGRATION_MODE"
Assert-True (([regex]::Matches($workflow, "DEPLOY_DB_BASELINE_VERSION")).Count -ge 3) "all release environments must map DEPLOY_DB_BASELINE_VERSION"

Write-Output "database migration contract passed"
