param(
    [switch]$IncludeMysqlSmoke,
    [switch]$IncludeStorageSmoke,
    [switch]$IncludeBrowserSmoke,
    [switch]$IncludeBrowserE2E,
    [switch]$IncludeElasticsearchSmoke,
    [switch]$IncludeFlutter,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $repoRoot $(if ($runningOnWindows) { "backend\mvnw.cmd" } else { "backend/mvnw" })

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "$FilePath exited with code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-CiContractTests {
    param([string]$ScriptsDirectory)

    $contractScripts = Get-ChildItem -LiteralPath $ScriptsDirectory -Filter "test-*.ps1" |
        Sort-Object Name

    foreach ($script in $contractScripts) {
        Write-Output "[verify-all] contract: $($script.Name)"
        & $script.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "$($script.FullName) exited with code $LASTEXITCODE"
        }
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. scripts/ci/test-*.ps1 contract checks"
    Write-Output "2. backend: backend/mvnw.cmd test"
    Write-Output "3. web: npm test"
    Write-Output "4. web: npm run build"
    Write-Output "5. admin-web: npm test"
    Write-Output "6. admin-web: npm run build"
    Write-Output "7. merchant-web: npm test"
    Write-Output "8. merchant-web: npm run build"
    Write-Output "9. optional app: flutter test when -IncludeFlutter is set"
    Write-Output "10. optional app: flutter analyze when -IncludeFlutter is set"
    Write-Output "11. optional app: flutter build web --no-wasm-dry-run when -IncludeFlutter is set"
    Write-Output "12. optional: scripts/ci/mysql-smoke.ps1 when -IncludeMysqlSmoke is set"
    Write-Output "13. optional: scripts/ci/storage-smoke.ps1 when -IncludeStorageSmoke is set"
    Write-Output "14. optional: scripts/ci/browser-smoke.ps1 when -IncludeBrowserSmoke is set"
    Write-Output "15. optional: scripts/ci/browser-e2e.ps1 when -IncludeBrowserE2E is set"
    Write-Output "16. optional: scripts/ci/elasticsearch-smoke.ps1 when -IncludeElasticsearchSmoke is set"
    exit 0
}

Invoke-CiContractTests -ScriptsDirectory (Join-Path $repoRoot "scripts\ci")

Write-Output "[verify-all] backend: mvnw.cmd test"
Invoke-Native -FilePath $mvnw -Arguments @("test") -WorkingDirectory (Join-Path $repoRoot "backend")

Write-Output "[verify-all] web: npm test"
Invoke-Native -FilePath "npm" -Arguments @("test") -WorkingDirectory (Join-Path $repoRoot "web")

Write-Output "[verify-all] web: npm run build"
Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory (Join-Path $repoRoot "web")

Write-Output "[verify-all] admin-web: npm test"
Invoke-Native -FilePath "npm" -Arguments @("test") -WorkingDirectory (Join-Path $repoRoot "admin-web")

Write-Output "[verify-all] admin-web: npm run build"
Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory (Join-Path $repoRoot "admin-web")

Write-Output "[verify-all] merchant-web: npm test"
Invoke-Native -FilePath "npm" -Arguments @("test") -WorkingDirectory (Join-Path $repoRoot "merchant-web")

Write-Output "[verify-all] merchant-web: npm run build"
Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory (Join-Path $repoRoot "merchant-web")

if ($IncludeFlutter) {
    Write-Output "[verify-all] app: flutter pub get"
    Invoke-Native -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory (Join-Path $repoRoot "app")

    Write-Output "[verify-all] app: flutter test"
    Invoke-Native -FilePath "flutter" -Arguments @("test") -WorkingDirectory (Join-Path $repoRoot "app")

    Write-Output "[verify-all] app: flutter analyze"
    Invoke-Native -FilePath "flutter" -Arguments @("analyze") -WorkingDirectory (Join-Path $repoRoot "app")

    Write-Output "[verify-all] app: flutter build web --no-wasm-dry-run"
    Invoke-Native -FilePath "flutter" -Arguments @("build", "web", "--no-wasm-dry-run") -WorkingDirectory (Join-Path $repoRoot "app")
}

if ($IncludeMysqlSmoke) {
    Write-Output "[verify-all] mysql smoke"
    & (Join-Path $repoRoot "scripts\ci\mysql-smoke.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "scripts/ci/mysql-smoke.ps1 exited with code $LASTEXITCODE"
    }
}

if ($IncludeStorageSmoke) {
    Write-Output "[verify-all] storage smoke"
    & (Join-Path $repoRoot "scripts\ci\storage-smoke.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "scripts/ci/storage-smoke.ps1 exited with code $LASTEXITCODE"
    }
}

if ($IncludeBrowserSmoke) {
    Write-Output "[verify-all] browser smoke"
    & (Join-Path $repoRoot "scripts\ci\browser-smoke.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "scripts/ci/browser-smoke.ps1 exited with code $LASTEXITCODE"
    }
}

if ($IncludeBrowserE2E) {
    Write-Output "[verify-all] browser E2E"
    & (Join-Path $repoRoot "scripts\ci\browser-e2e.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "scripts/ci/browser-e2e.ps1 exited with code $LASTEXITCODE"
    }
}

if ($IncludeElasticsearchSmoke) {
    Write-Output "[verify-all] Elasticsearch smoke"
    & (Join-Path $repoRoot "scripts\ci\elasticsearch-smoke.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "scripts/ci/elasticsearch-smoke.ps1 exited with code $LASTEXITCODE"
    }
}

Write-Output "[verify-all] all requested checks passed"
