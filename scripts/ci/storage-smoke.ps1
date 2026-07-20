param(
    [string]$S3Endpoint,
    [string]$S3Bucket,
    [string]$S3Region,
    [string]$S3PublicBaseUrl,
    [string]$S3AccessKey,
    [string]$S3SecretKey,
    [bool]$S3PathStyleAccessEnabled = $true,
    [int]$BackendPort = 0,
    [switch]$KeepBackend,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })
$runDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-storage-smoke-" + [System.Guid]::NewGuid().ToString("N"))
$managedProcesses = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
$succeeded = $false
$backendWasStarted = $false

if (-not $S3Endpoint) { $S3Endpoint = if ($env:APP_S3_ENDPOINT) { $env:APP_S3_ENDPOINT } else { "" } }
if (-not $S3Bucket) { $S3Bucket = if ($env:APP_S3_BUCKET) { $env:APP_S3_BUCKET } else { "" } }
if (-not $S3Region) { $S3Region = if ($env:APP_S3_REGION) { $env:APP_S3_REGION } else { "us-east-1" } }
if (-not $S3PublicBaseUrl) { $S3PublicBaseUrl = if ($env:APP_S3_PUBLIC_BASE_URL) { $env:APP_S3_PUBLIC_BASE_URL } else { "" } }
if (-not $S3AccessKey) { $S3AccessKey = if ($env:APP_S3_ACCESS_KEY) { $env:APP_S3_ACCESS_KEY } else { "" } }
if (-not $S3SecretKey) { $S3SecretKey = if ($env:APP_S3_SECRET_KEY) { $env:APP_S3_SECRET_KEY } else { "" } }
if ($BackendPort -eq 0) { $BackendPort = if ($env:APP_STORAGE_SMOKE_PORT) { [int]$env:APP_STORAGE_SMOKE_PORT } else { 19080 } }

$baseUrl = "http://127.0.0.1:$BackendPort"

function Write-Step {
    param([string]$Message)
    Write-Output "[storage-smoke] $Message"
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

function Start-ManagedProcess {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $stdoutPath = Join-Path $runDir "$Name.stdout.log"
    $stderrPath = Join-Path $runDir "$Name.stderr.log"
    $parameters = @{
        FilePath = $FilePath
        ArgumentList = $Arguments
        WorkingDirectory = $WorkingDirectory
        PassThru = $true
        RedirectStandardOutput = $stdoutPath
        RedirectStandardError = $stderrPath
    }
    if ($runningOnWindows) {
        $parameters.WindowStyle = "Hidden"
    }

    $process = Start-Process @parameters
    $managedProcesses.Add($process)
    return $process
}

function Get-ProcessLogTail {
    param([string]$Name)

    $parts = @()
    foreach ($stream in @("stdout", "stderr")) {
        $path = Join-Path $runDir "$Name.$stream.log"
        if (Test-Path -LiteralPath $path) {
            $content = Get-Content -LiteralPath $path -Tail 40 -ErrorAction SilentlyContinue
            if ($content) {
                $parts += "[$Name $stream]"
                $parts += $content
            }
        }
    }
    return $parts -join "`n"
}

function Test-TcpPortListening {
    param([int]$Port)

    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    return $null -ne ($listeners | Where-Object { $_.Port -eq $Port } | Select-Object -First 1)
}

function Get-ListeningProcessIds {
    param([int]$Port)

    if (-not $runningOnWindows) {
        return @()
    }

    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($null -eq $connections) {
        return @()
    }

    return @($connections | Select-Object -ExpandProperty OwningProcess -Unique)
}

function Assert-PortAvailable {
    param([int]$Port)

    if (Test-TcpPortListening -Port $Port) {
        $listeningProcessIds = @(Get-ListeningProcessIds -Port $Port)
        if ($listeningProcessIds.Count -gt 0) {
            throw "backend port $Port is already in use by PID(s): $($listeningProcessIds -join ', ')"
        }

        throw "backend port $Port is already in use"
    }
}

function Wait-PortReleased {
    param(
        [int]$Port,
        [int]$TimeoutSeconds
    )

    $deadline = [System.DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([System.DateTimeOffset]::UtcNow -lt $deadline) {
        if (-not (Test-TcpPortListening -Port $Port)) {
            return
        }

        Start-Sleep -Milliseconds 500
    }

    $listeningProcessIds = @(Get-ListeningProcessIds -Port $Port)
    if ($listeningProcessIds.Count -gt 0) {
        throw "backend port $Port is still listening after cleanup (PID(s): $($listeningProcessIds -join ', '))"
    }

    throw "backend port $Port is still listening after cleanup"
}

function Test-ProcessAlive {
    param([int]$ProcessId)

    return $null -ne (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)
}

function Stop-ManagedProcessTree {
    param([int]$ProcessId)

    if (-not (Test-ProcessAlive -ProcessId $ProcessId)) {
        return
    }

    if ($runningOnWindows) {
        $taskkillOutput = & taskkill /PID $ProcessId /T /F 2>&1
        $taskkillExitCode = $LASTEXITCODE
        if ($taskkillExitCode -ne 0 -and (Test-ProcessAlive -ProcessId $ProcessId)) {
            $details = ($taskkillOutput | Out-String).Trim()
            if ([string]::IsNullOrWhiteSpace($details)) {
                $details = "taskkill exited with code $taskkillExitCode"
            }

            throw $details
        }

        return
    }

    Stop-Process -Id $ProcessId -Force -ErrorAction Stop
}

function Wait-ManagedProcessExit {
    param(
        [int]$ProcessId,
        [int]$TimeoutSeconds
    )

    $deadline = [System.DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([System.DateTimeOffset]::UtcNow -lt $deadline) {
        if (-not (Test-ProcessAlive -ProcessId $ProcessId)) {
            return
        }

        Start-Sleep -Milliseconds 500
    }

    throw "managed process $ProcessId did not exit within $TimeoutSeconds seconds"
}

function Wait-HttpReady {
    param(
        [string]$Name,
        [System.Diagnostics.Process]$Process,
        [string]$Url,
        [int]$TimeoutSeconds
    )

    $deadline = [System.DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([System.DateTimeOffset]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            $logs = Get-ProcessLogTail -Name $Name
            throw "$Name exited before becoming ready (exit code $($Process.ExitCode)).`n$logs"
        }

        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                Write-Step "$Name ready at $Url"
                return
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    $logs = Get-ProcessLogTail -Name $Name
    throw "$Name did not become ready within $TimeoutSeconds seconds.`n$logs"
}

function Stop-ManagedProcesses {
    $stopFailures = [System.Collections.Generic.List[string]]::new()

    for ($index = $managedProcesses.Count - 1; $index -ge 0; $index--) {
        $process = $managedProcesses[$index]
        $processId = $process.Id
        try {
            if (-not (Test-ProcessAlive -ProcessId $processId)) {
                continue
            }

            Write-Step "stopping managed process PID $processId"
            Stop-ManagedProcessTree -ProcessId $processId
            Wait-ManagedProcessExit -ProcessId $processId -TimeoutSeconds 15
        }
        catch {
            $stopFailures.Add("Failed to stop managed process ${processId}: $($_.Exception.Message)")
        }
        finally {
            try {
                $process.Close()
            }
            catch {
            }
        }
    }

    if ($stopFailures.Count -gt 0) {
        throw ($stopFailures -join "`n")
    }
}

function Remove-RunDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolvedRunDir = (Resolve-Path -LiteralPath $Path).Path
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedRunDir.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedRunDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Restore-StorageSmokeEnvironment {
    param(
        [AllowNull()][string]$FileStorageProvider,
        [AllowNull()][string]$S3Endpoint,
        [AllowNull()][string]$S3Bucket,
        [AllowNull()][string]$S3Region,
        [AllowNull()][string]$S3PublicBaseUrl,
        [AllowNull()][string]$S3AccessKey,
        [AllowNull()][string]$S3SecretKey,
        [AllowNull()][string]$S3PathStyle
    )

    Restore-EnvironmentVariable -Name "APP_FILE_STORAGE_PROVIDER" -Value $FileStorageProvider
    Restore-EnvironmentVariable -Name "APP_S3_ENDPOINT" -Value $S3Endpoint
    Restore-EnvironmentVariable -Name "APP_S3_BUCKET" -Value $S3Bucket
    Restore-EnvironmentVariable -Name "APP_S3_REGION" -Value $S3Region
    Restore-EnvironmentVariable -Name "APP_S3_PUBLIC_BASE_URL" -Value $S3PublicBaseUrl
    Restore-EnvironmentVariable -Name "APP_S3_ACCESS_KEY" -Value $S3AccessKey
    Restore-EnvironmentVariable -Name "APP_S3_SECRET_KEY" -Value $S3SecretKey
    Restore-EnvironmentVariable -Name "APP_S3_PATH_STYLE_ACCESS_ENABLED" -Value $S3PathStyle
}

function Complete-Cleanup {
    param(
        [bool]$Succeeded,
        [bool]$KeepBackendEnabled,
        [bool]$RequirePortRelease,
        [int]$Port,
        [string]$Path,
        [AllowNull()][string]$FileStorageProvider,
        [AllowNull()][string]$S3Endpoint,
        [AllowNull()][string]$S3Bucket,
        [AllowNull()][string]$S3Region,
        [AllowNull()][string]$S3PublicBaseUrl,
        [AllowNull()][string]$S3AccessKey,
        [AllowNull()][string]$S3SecretKey,
        [AllowNull()][string]$S3PathStyle
    )

    $cleanupFailures = [System.Collections.Generic.List[string]]::new()

    try {
        if (-not $KeepBackendEnabled) {
            try {
                Stop-ManagedProcesses
            }
            catch {
                $cleanupFailures.Add($_.Exception.Message)
            }

            if ($RequirePortRelease) {
                try {
                    Wait-PortReleased -Port $Port -TimeoutSeconds 15
                }
                catch {
                    $cleanupFailures.Add($_.Exception.Message)
                }
            }
        }
    }
    finally {
        Restore-StorageSmokeEnvironment `
            -FileStorageProvider $FileStorageProvider `
            -S3Endpoint $S3Endpoint `
            -S3Bucket $S3Bucket `
            -S3Region $S3Region `
            -S3PublicBaseUrl $S3PublicBaseUrl `
            -S3AccessKey $S3AccessKey `
            -S3SecretKey $S3SecretKey `
            -S3PathStyle $S3PathStyle

        if ($Succeeded -and $cleanupFailures.Count -eq 0) {
            Remove-RunDirectory -Path $Path
        }
        elseif (Test-Path -LiteralPath $Path) {
            Write-Warning "Storage smoke logs were preserved at $Path"
        }
    }

    if ($cleanupFailures.Count -gt 0) {
        throw ($cleanupFailures -join "`n")
    }
}

function Restore-EnvironmentVariable {
    param(
        [string]$Name,
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        Remove-Item "Env:\$Name" -ErrorAction SilentlyContinue
    }
    else {
        Set-Item "Env:\$Name" $Value
    }
}

function Invoke-Json {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )

    $request = @{
        Method = $Method
        Uri = "$baseUrl$Path"
        Headers = $Headers
        TimeoutSec = 15
    }

    if ($null -ne $Body) {
        $request.ContentType = "application/json"
        $request.Body = ($Body | ConvertTo-Json -Depth 8)
    }

    return Invoke-RestMethod @request
}

function Invoke-MultipartUpload {
    param(
        [string]$Path,
        [string]$AccessToken,
        [string]$FilePath,
        [string]$ContentType
    )

    $handler = [System.Net.Http.HttpClientHandler]::new()
    $client = [System.Net.Http.HttpClient]::new($handler)
    $content = [System.Net.Http.MultipartFormDataContent]::new()
    try {
        $client.Timeout = [System.TimeSpan]::FromSeconds(30)
        $client.DefaultRequestHeaders.Authorization =
            [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $AccessToken)

        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $fileContent = [System.Net.Http.ByteArrayContent]::new($bytes)
        $fileContent.Headers.ContentType =
            [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($ContentType)
        $content.Add($fileContent, "file", [System.IO.Path]::GetFileName($FilePath))

        $response = $client.PostAsync("$baseUrl$Path", $content).GetAwaiter().GetResult()
        $responseText = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Multipart upload failed with status $([int]$response.StatusCode): $responseText"
        }
        return $responseText | ConvertFrom-Json
    }
    finally {
        $content.Dispose()
        $client.Dispose()
        $handler.Dispose()
    }
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Package and start the H2 backend directly with Java on $baseUrl."
    Write-Output "2. Configure APP_FILE_STORAGE_PROVIDER=s3 against an S3-compatible endpoint."
    Write-Output "3. Sign in with login/password using the H2 demo user demo.cn@example.com."
    Write-Output "4. Upload a PNG through POST /api/c/v1/files/upload."
    Write-Output "5. Assert the response file URL points at the configured S3-compatible endpoint and stop the backend."
    exit 0
}

foreach ($pair in @{
    "S3Endpoint" = $S3Endpoint
    "S3Bucket" = $S3Bucket
    "S3AccessKey" = $S3AccessKey
    "S3SecretKey" = $S3SecretKey
}.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($pair.Value)) {
        throw "$($pair.Key) must be supplied directly or through APP_S3_* environment variables"
    }
}

$previousFileStorageProvider = $env:APP_FILE_STORAGE_PROVIDER
$previousS3Endpoint = $env:APP_S3_ENDPOINT
$previousS3Bucket = $env:APP_S3_BUCKET
$previousS3Region = $env:APP_S3_REGION
$previousS3PublicBaseUrl = $env:APP_S3_PUBLIC_BASE_URL
$previousS3AccessKey = $env:APP_S3_ACCESS_KEY
$previousS3SecretKey = $env:APP_S3_SECRET_KEY
$previousS3PathStyle = $env:APP_S3_PATH_STYLE_ACCESS_ENABLED

try {
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null

    Write-Step "verifying backend port availability"
    Assert-PortAvailable -Port $BackendPort

    Write-Step "packaging backend"
    Invoke-Native -FilePath $mvnw -Arguments @("-q", "-DskipTests", "package") -WorkingDirectory $backendDir

    $backendJar = Get-ChildItem -File -LiteralPath (Join-Path $backendDir "target") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "-(sources|javadoc)\.jar$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $backendJar) {
        throw "Packaged backend jar was not found under backend/target"
    }

    $env:APP_FILE_STORAGE_PROVIDER = "s3"
    $env:APP_S3_ENDPOINT = $S3Endpoint
    $env:APP_S3_BUCKET = $S3Bucket
    $env:APP_S3_REGION = $S3Region
    $env:APP_S3_PUBLIC_BASE_URL = if ($S3PublicBaseUrl) { $S3PublicBaseUrl } else { "s3://$S3Bucket" }
    $env:APP_S3_ACCESS_KEY = $S3AccessKey
    $env:APP_S3_SECRET_KEY = $S3SecretKey
    $env:APP_S3_PATH_STYLE_ACCESS_ENABLED = if ($S3PathStyleAccessEnabled) { "true" } else { "false" }

    $javaPath = (Get-Command java -ErrorAction Stop).Source

    Write-Step "starting H2 backend"
    $backendProcess = Start-ManagedProcess -Name "backend" -FilePath $javaPath -Arguments @(
        "-jar",
        $backendJar.FullName,
        "--spring.profiles.active=h2",
        "--server.port=$BackendPort",
        "--management.health.redis.enabled=false"
    ) -WorkingDirectory $backendDir
    $backendWasStarted = $true
    Wait-HttpReady -Name "backend" -Process $backendProcess -Url "$baseUrl/actuator/health" -TimeoutSeconds 120

    Write-Step "logging in with password"
    $login = Invoke-Json -Method "POST" -Path "/api/c/v1/auth/login/password" -Body @{
        account = "demo.cn@example.com"
        password = "Demo123456"
    }
    $accessToken = $login.data.accessToken
    if ([string]::IsNullOrWhiteSpace($accessToken)) {
        throw "login/password did not return an access token"
    }

    $sampleFilePath = Join-Path $runDir "storage-smoke.png"
    [System.IO.File]::WriteAllBytes(
        $sampleFilePath,
        [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR42mP8z8Dwn4GBgYGJAQoAHxcCAr7afKQAAAAASUVORK5CYII=")
    )

    Write-Step "uploading PNG to the S3-compatible endpoint"
    $upload = Invoke-MultipartUpload -Path "/api/c/v1/files/upload" -AccessToken $accessToken -FilePath $sampleFilePath -ContentType "image/png"

    if ($upload.code -ne 0) {
        throw "upload endpoint returned code $($upload.code)"
    }
    if ([string]::IsNullOrWhiteSpace($upload.data.url)) {
        throw "upload endpoint did not return a file URL"
    }

    $expectedUrlPrefix = if ([string]::IsNullOrWhiteSpace($S3PublicBaseUrl)) {
        "s3://$S3Bucket/"
    }
    else {
        $S3PublicBaseUrl.TrimEnd("/") + "/"
    }

    if (-not $upload.data.url.StartsWith($expectedUrlPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "upload endpoint returned unexpected URL $($upload.data.url)"
    }

    $succeeded = $true
    Write-Step "storage smoke passed"
}
finally {
    Complete-Cleanup `
        -Succeeded $succeeded `
        -KeepBackendEnabled ([bool]$KeepBackend) `
        -RequirePortRelease $backendWasStarted `
        -Port $BackendPort `
        -Path $runDir `
        -FileStorageProvider $previousFileStorageProvider `
        -S3Endpoint $previousS3Endpoint `
        -S3Bucket $previousS3Bucket `
        -S3Region $previousS3Region `
        -S3PublicBaseUrl $previousS3PublicBaseUrl `
        -S3AccessKey $previousS3AccessKey `
        -S3SecretKey $previousS3SecretKey `
        -S3PathStyle $previousS3PathStyle
}
