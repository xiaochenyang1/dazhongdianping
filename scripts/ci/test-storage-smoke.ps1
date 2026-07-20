$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\storage-smoke.ps1"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/storage-smoke.ps1 must exist"

$dryRunOutput = & $scriptPath -DryRun
$dryRunText = $dryRunOutput -join "`n"
$scriptContent = Get-Content -LiteralPath $scriptPath -Raw

Assert-True ($dryRunText -match "H2 backend") "dry-run output must mention the H2 backend"
Assert-True ($dryRunText -match "S3-compatible endpoint") "dry-run output must mention the S3-compatible endpoint"
Assert-True ($dryRunText -match "login/password") "dry-run output must mention password login"
Assert-True ($dryRunText -match "/api/c/v1/files/upload") "dry-run output must mention the upload endpoint"
Assert-True ($dryRunText -match "stop the backend") "dry-run output must mention backend shutdown"

Assert-True ($scriptContent -match "spring\.profiles\.active=h2") "storage smoke must run the backend with the h2 profile"
Assert-True ($scriptContent -match "APP_FILE_STORAGE_PROVIDER") "storage smoke must set APP_FILE_STORAGE_PROVIDER"
Assert-True ($scriptContent -match "APP_S3_ENDPOINT") "storage smoke must read the S3 endpoint from environment or parameters"
Assert-True ($scriptContent -match "MultipartFormDataContent") "storage smoke must build a real multipart upload request"
Assert-True ($scriptContent -match "Assert-PortAvailable") "storage smoke must fail fast when the backend port is already occupied"
Assert-True ($scriptContent -match "Wait-PortReleased") "storage smoke must verify the backend port is released during cleanup"

Write-Output "storage-smoke script contract passed"
