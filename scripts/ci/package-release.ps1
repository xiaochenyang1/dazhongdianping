param(
    [string]$Version,
    [string]$OutputDir,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$webDir = Join-Path $repoRoot "web"
$adminDir = Join-Path $repoRoot "admin-web"
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })

if (-not $Version) {
    if ($env:APP_RELEASE_VERSION) {
        $Version = $env:APP_RELEASE_VERSION
    }
    elseif ($env:GITHUB_SHA) {
        $Version = $env:GITHUB_SHA.Substring(0, [Math]::Min(12, $env:GITHUB_SHA.Length))
    }
    else {
        $Version = [System.DateTimeOffset]::UtcNow.ToString("yyyyMMddHHmmss")
    }
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $repoRoot "artifacts"
}

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

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Build the backend jar with backend/mvnw.cmd -DskipTests package."
    Write-Output "2. Build web dist with npm run build under web."
    Write-Output "3. Build admin-web dist with npm run build under admin-web."
    Write-Output "4. Assemble backend jar + web dist + admin-web dist into a release bundle under $OutputDir."
    Write-Output "5. Write a release manifest for version $Version."
    exit 0
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-release-" + [System.Guid]::NewGuid().ToString("N"))
$bundlePath = Join-Path (Resolve-Path $OutputDir) "dazhongdianping-release-$Version.zip"

try {
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

    Invoke-Native -FilePath $mvnw -Arguments @("-q", "-DskipTests", "package") -WorkingDirectory $backendDir
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $webDir
    Invoke-Native -FilePath "npm" -Arguments @("run", "build") -WorkingDirectory $adminDir

    $backendJar = Get-ChildItem -File -LiteralPath (Join-Path $backendDir "target") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "-(sources|javadoc)\.jar$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $backendJar) {
        throw "Packaged backend jar was not found under backend/target"
    }

    $backendOutputDir = Join-Path $stagingDir "backend"
    $webOutputDir = Join-Path $stagingDir "web"
    $adminOutputDir = Join-Path $stagingDir "admin-web"
    New-Item -ItemType Directory -Path $backendOutputDir, $webOutputDir, $adminOutputDir -Force | Out-Null

    Copy-Item -LiteralPath $backendJar.FullName -Destination (Join-Path $backendOutputDir $backendJar.Name)
    Copy-Item -LiteralPath (Join-Path $webDir "dist") -Destination $webOutputDir -Recurse
    Copy-Item -LiteralPath (Join-Path $adminDir "dist") -Destination $adminOutputDir -Recurse

    $manifest = [ordered]@{
        version = $Version
        builtAtUtc = [System.DateTimeOffset]::UtcNow.ToString("o")
        commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { "" }
        bundleName = [System.IO.Path]::GetFileName($bundlePath)
        backendJar = $backendJar.Name
    }
    $manifestPath = Join-Path $stagingDir "release-manifest.json"
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8

    if (Test-Path -LiteralPath $bundlePath) {
        Remove-Item -LiteralPath $bundlePath -Force
    }
    Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $bundlePath

    Write-Output $bundlePath
}
finally {
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
