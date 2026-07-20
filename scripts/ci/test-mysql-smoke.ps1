$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\mysql-smoke.ps1"
$allInOnePath = Join-Path $repoRoot "sql\mysql\00_all_in_one.sql"
$readmePath = Join-Path $repoRoot "README.md"
$currentStatusPath = Join-Path $repoRoot "docs\当前已完成功能与SQL导入说明.md"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/mysql-smoke.ps1 must exist"
Assert-True (Test-Path -LiteralPath $allInOnePath) "sql/mysql/00_all_in_one.sql must exist"
Assert-True (Test-Path -LiteralPath $readmePath) "README.md must exist"
Assert-True (Test-Path -LiteralPath $currentStatusPath) "current implementation status document must exist"

$smokeDbName = "dazhongdianping_smoke_contract"
$dryRunOutput = & $scriptPath -DryRun -DbName $smokeDbName
$dryRunText = $dryRunOutput -join "`n"

Assert-True ($dryRunText -match [regex]::Escape($smokeDbName)) "dry-run output must mention the selected smoke database"
Assert-True ($dryRunText -match "sql/mysql/01_schema.sql") "dry-run output must mention the schema SQL"
Assert-True ($dryRunText -match "sql/mysql/02_seed_data.sql") "dry-run output must mention the seed SQL"
Assert-True ($dryRunText -notmatch "sql/mysql/00_all_in_one.sql") "dry-run output must not use the hard-coded all-in-one SQL"
Assert-True ($dryRunText -match "refuse") "default import plan must say an existing database is refused"
Assert-True ($dryRunText -match "backend") "dry-run output must mention backend startup"
Assert-True ($dryRunText -match "package") "dry-run output must mention backend packaging"
Assert-True ($dryRunText -match "/actuator/health") "dry-run output must mention health polling"
Assert-True ($dryRunText -match "/api/c/v1/categories") "dry-run output must mention public browse smoke"
Assert-True ($dryRunText -match "/api/admin/v1/auth/login") "dry-run output must mention admin login smoke"
Assert-True ($dryRunText -match "/api/b/v1/health") "dry-run output must mention B endpoint smoke"

$cleanupDryRunOutput = & $scriptPath -DryRun -DbName $smokeDbName -DropDatabaseAfter
$cleanupDryRunText = $cleanupDryRunOutput -join "`n"
Assert-True ($cleanupDryRunText -match "finally") "cleanup dry-run output must say cleanup runs in finally"
Assert-True ($cleanupDryRunText -match "created") "cleanup dry-run output must say only a database created by this run is dropped"

$destructiveDryRunOutput = & $scriptPath -DryRun -DbName $smokeDbName -AllowDestructiveImport
$destructiveDryRunText = $destructiveDryRunOutput -join "`n"
Assert-True ($destructiveDryRunText -match "destructive") "destructive import dry-run must clearly warn that an existing database may be reset"

$skipImportDryRunOutput = & $scriptPath -DryRun -DbName $smokeDbName -SkipImport
$skipImportDryRunText = $skipImportDryRunOutput -join "`n"
Assert-True ($skipImportDryRunText -match "Skip database import") "SkipImport dry-run output must explicitly say database import is skipped"
Assert-True ($skipImportDryRunText -notmatch "sql/mysql/01_schema.sql") "SkipImport dry-run output must not claim the schema SQL will be imported"
Assert-True ($skipImportDryRunText -notmatch "sql/mysql/02_seed_data.sql") "SkipImport dry-run output must not claim the seed SQL will be imported"

$invalidNameRejected = $false
try {
    & $scriptPath -DryRun -DbName "smoke-db;DROP_DATABASE" 2>$null | Out-Null
}
catch {
    $invalidNameRejected = $_.Exception.Message -match "DbName"
}
Assert-True $invalidNameRejected "mysql-smoke must reject unsafe database identifiers before running MySQL"

$implicitCleanupRejected = $false
try {
    & $scriptPath -DryRun -DropDatabaseAfter 2>$null | Out-Null
}
catch {
    $implicitCleanupRejected = $_.Exception.Message -match "DbName"
}
Assert-True $implicitCleanupRejected "DropDatabaseAfter must require an explicitly supplied DbName"

$implicitDestructiveImportRejected = $false
try {
    & $scriptPath -DryRun -AllowDestructiveImport 2>$null | Out-Null
}
catch {
    $implicitDestructiveImportRejected = $_.Exception.Message -match "DbName"
}
Assert-True $implicitDestructiveImportRejected "AllowDestructiveImport must require an explicitly supplied DbName"

$scriptContent = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($scriptContent -match 'source sql/mysql/01_schema\.sql') "mysql-smoke must source the schema SQL directly"
Assert-True ($scriptContent -match 'source sql/mysql/02_seed_data\.sql') "mysql-smoke must source the seed SQL directly"
Assert-True ($scriptContent -notmatch 'source sql/mysql/00_all_in_one\.sql') "mysql-smoke must not source the hard-coded all-in-one SQL"
Assert-True ($scriptContent -match 'CREATE DATABASE') "mysql-smoke must create the requested database"
Assert-True ($scriptContent -match '--database') "mysql-smoke must select the requested database for imports"
Assert-True ($scriptContent -match '\$databaseAlreadyExists -and -not \$AllowDestructiveImport') "mysql-smoke must refuse importing destructive schema into an existing database by default"
Assert-True ($scriptContent -match '\$backendStartedByThisRun') "mysql-smoke must track whether this run started the backend"
Assert-True ($scriptContent -match '-not \$KeepBackend -and \$backendStartedByThisRun') "mysql-smoke must not stop a backend it did not start"
Assert-True ($scriptContent -match 'Assert-PortAvailable -Port \$BackendPort') "mysql-smoke must reject an already occupied backend port before startup"
Assert-True ($scriptContent -match 'Get-FreeTcpPort') "mysql-smoke must be able to fall back to a free backend port when the default port is occupied"
Assert-True ($scriptContent -match '\$backendPortWasExplicitlySupplied') "mysql-smoke must distinguish between explicit ports and the default fallback port"
Assert-True ($scriptContent -match 'Wait-PortReleased -Port \$BackendPort') "mysql-smoke cleanup must verify the backend port is released"
Assert-True ($scriptContent -match 'Start-ManagedProcess -Name "backend"') "mysql-smoke must manage the backend process directly instead of relying on Maven JMX defaults"
Assert-True ($scriptContent -match '__dzdp_smoke_owner') "temporary database cleanup must store an ownership marker"
Assert-True ($scriptContent -match '\$databaseOwnershipToken') "temporary database cleanup must use an unguessable ownership token"
Assert-True ($scriptContent -match '\$actualOwnershipToken -eq \$databaseOwnershipToken') "DropDatabaseAfter must verify ownership again before dropping the database"
$mainFinallyIndex = $scriptContent.LastIndexOf("finally {")
Assert-True ($mainFinallyIndex -ge 0) "mysql-smoke must have a top-level finally block"
$mainFinallyContent = $scriptContent.Substring($mainFinallyIndex)
Assert-True ($mainFinallyContent -match 'DROP DATABASE') "DropDatabaseAfter cleanup must execute from the top-level finally"
Assert-True ($scriptContent -match '\$databaseCreatedByThisRun') "cleanup must track whether this run created the database"
Assert-True ($scriptContent -match '\$shops\.data\.list') "shop smoke must read PageResult.list"
Assert-True ($scriptContent -notmatch '\$shops\.data\.items') "shop smoke must not read the nonexistent PageResult.items"
Assert-True ($scriptContent -match '\$adminLogin\.data\.accessToken') "admin login smoke must read AdminLoginResponse.accessToken"
Assert-True ($scriptContent -notmatch '\$adminLogin\.data\.token') "admin login smoke must not read the nonexistent AdminLoginResponse.token"

$allInOneContent = Get-Content -LiteralPath $allInOnePath -Raw
Assert-True ($allInOneContent -match 'SIGNAL SQLSTATE') "the unsafe fixed-name all-in-one import must fail closed"
Assert-True ($allInOneContent -notmatch 'source sql/mysql/01_schema\.sql') "the retired all-in-one entrypoint must not source the destructive schema"

foreach ($documentationPath in @($readmePath, $currentStatusPath)) {
    $documentationContent = Get-Content -LiteralPath $documentationPath -Raw
    Assert-True ($documentationContent -notmatch 'mysql -u root -p < sql/mysql/00_all_in_one\.sql') "PowerShell documentation must not use unsupported input redirection: $documentationPath"
    Assert-True ($documentationContent -notmatch 'mysql -u root -p -e "source sql/mysql/00_all_in_one\.sql"') "documentation must not recommend the retired destructive all-in-one import: $documentationPath"
    Assert-True ($documentationContent -match 'mysql-smoke\.ps1') "documentation must direct users to the guarded mysql-smoke entrypoint: $documentationPath"
}

Write-Host "mysql-smoke script contract passed"
