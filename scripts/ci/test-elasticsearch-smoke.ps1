$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\elasticsearch-smoke.ps1"
$verifyAllPath = Join-Path $repoRoot "scripts\ci\verify-all.ps1"
$nightlyPath = Join-Path $repoRoot ".github\workflows\nightly.yml"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/elasticsearch-smoke.ps1 must exist"

$dryRunText = (& $scriptPath -DryRun) -join "`n"
Assert-True ($dryRunText -match "Elasticsearch") "dry-run must mention Elasticsearch"
Assert-True ($dryRunText -match "/api/admin/v1/search/reindex") "dry-run must mention full reindex"
Assert-True ($dryRunText -match "Chinese") "dry-run must mention Chinese keyword coverage"
Assert-True ($dryRunText -match "pinyin") "dry-run must mention pinyin coverage"
Assert-True ($dryRunText -match "fuzzy") "dry-run must mention fuzzy correction coverage"
Assert-True ($dryRunText -match "distance") "dry-run must mention geo distance coverage"

$scriptContent = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($scriptContent -match 'APP_SEARCH_PROVIDER') "smoke must start backend with Elasticsearch provider"
Assert-True ($scriptContent -match 'APP_SEARCH_FALLBACK_ON_ERROR') "smoke must disable MySQL fallback"
Assert-True ($scriptContent -match 'jdbc:h2:mem:') "smoke must use isolated H2 source data"
Assert-True ($scriptContent -match '/api/c/v1/search/shops') "smoke must call the real public search endpoint"

$verifyAllContent = Get-Content -LiteralPath $verifyAllPath -Raw
Assert-True ($verifyAllContent -match 'IncludeElasticsearchSmoke') "verify-all must expose the Elasticsearch smoke switch"
Assert-True ($verifyAllContent -match 'elasticsearch-smoke\.ps1') "verify-all must invoke the Elasticsearch smoke"

$nightlyContent = Get-Content -LiteralPath $nightlyPath -Raw
Assert-True ($nightlyContent -match 'elasticsearch:8') "nightly must provision Elasticsearch 8"
Assert-True ($nightlyContent -match 'IncludeElasticsearchSmoke') "nightly must execute the Elasticsearch smoke"

Write-Host "elasticsearch-smoke script contract passed"
