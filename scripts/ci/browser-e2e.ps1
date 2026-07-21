param(
    [int]$WebPort = 16173,
    [int]$AdminPort = 16174,
    [int]$BackendPort = 18080,
    [string]$BrowserChannel = "chromium",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$webDir = Join-Path $repoRoot "web"
$adminDir = Join-Path $repoRoot "admin-web"
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })
$managedProcesses = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
$runDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-e2e-" + [System.Guid]::NewGuid().ToString("N"))
$succeeded = $false
$backendProcess = $null
$backendJar = $null

function Write-Step {
    param([string]$Message)
    Write-Output "[browser-e2e] $Message"
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

function Test-PortAvailable {
    param([int]$Port)

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    try {
        $listener.Start()
        return $true
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $listener) {
            $listener.Stop()
        }
    }
}

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    }
    finally {
        $listener.Stop()
    }
}

function Resolve-ManagedPort {
    param(
        [string]$Name,
        [int]$Port,
        [bool]$ExplicitlyAssigned
    )

    if (Test-PortAvailable -Port $Port) {
        return $Port
    }

    if ($ExplicitlyAssigned) {
        throw "$Name port $Port is already in use. Stop the conflicting process or pass a different port."
    }

    $fallbackPort = Get-FreeTcpPort
    [void](Write-Step "$Name port $Port is already occupied; falling back to $fallbackPort")
    return $fallbackPort
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
                Start-Sleep -Milliseconds 300
                $Process.Refresh()
                if ($Process.HasExited) {
                    $logs = Get-ProcessLogTail -Name $Name
                    throw "$Name exited after the readiness probe responded on $Url (exit code $($Process.ExitCode)).`n$logs"
                }
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
    for ($index = $managedProcesses.Count - 1; $index -ge 0; $index--) {
        $process = $managedProcesses[$index]
        try {
            $process.Refresh()
            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction Stop
                [void]$process.WaitForExit(10000)
            }
        }
        catch {
            Write-Warning "Failed to stop managed process $($process.Id): $($_.Exception.Message)"
        }
    }
}

function Stop-BackendListener {
    param(
        [int]$Port,
        [int]$ExpectedProcessId,
        [string]$ExpectedJarPath
    )

    if (-not $runningOnWindows -or $ExpectedProcessId -le 0 -or [string]::IsNullOrWhiteSpace($ExpectedJarPath)) {
        return
    }

    try {
        $owners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($ownerId in $owners) {
            if ([int]$ownerId -ne $ExpectedProcessId) {
                continue
            }
            $candidate = Get-CimInstance Win32_Process -Filter "ProcessId = $ownerId" -ErrorAction SilentlyContinue
            $commandLine = [string]$candidate.CommandLine
            if ($commandLine.IndexOf($ExpectedJarPath, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                continue
            }
            Stop-Process -Id $ownerId -Force -ErrorAction Stop
            $stopped = Get-Process -Id $ownerId -ErrorAction SilentlyContinue
            if ($null -ne $stopped) {
                [void]$stopped.WaitForExit(10000)
            }
        }
    }
    catch {
        Write-Warning "Failed to clean backend listener on port ${Port}: $($_.Exception.Message)"
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

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "1. Package and start the H2 backend directly with Java on http://127.0.0.1:$BackendPort."
    Write-Output "2. Start web Vite directly with Node on http://127.0.0.1:$WebPort."
    Write-Output "3. Start admin-web Vite directly with Node on http://127.0.0.1:$AdminPort."
    Write-Output "4. Run the Playwright real backend review submission flow with isolated output."
    Write-Output "5. Run admin approval and interaction checks, then stop every managed process."
    exit 0
}

$previousRealBackend = $env:PLAYWRIGHT_REAL_BACKEND
$previousExternalServers = $env:PLAYWRIGHT_EXTERNAL_SERVERS
$previousOutputDir = $env:PLAYWRIGHT_OUTPUT_DIR
$previousWebPort = $env:PLAYWRIGHT_WEB_PORT
$previousAdminPort = $env:PLAYWRIGHT_ADMIN_PORT
$previousBackendPort = $env:PLAYWRIGHT_BACKEND_PORT
$previousChannel = $env:PLAYWRIGHT_CHANNEL
$previousProxyTarget = $env:VITE_PROXY_TARGET

try {
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null

    $webPortExplicitlyAssigned = $PSBoundParameters.ContainsKey('WebPort')
    $adminPortExplicitlyAssigned = $PSBoundParameters.ContainsKey('AdminPort')
    $backendPortExplicitlyAssigned = $PSBoundParameters.ContainsKey('BackendPort')

    $WebPort = Resolve-ManagedPort -Name "web" -Port $WebPort -ExplicitlyAssigned:$webPortExplicitlyAssigned
    $AdminPort = Resolve-ManagedPort -Name "admin-web" -Port $AdminPort -ExplicitlyAssigned:$adminPortExplicitlyAssigned
    $BackendPort = Resolve-ManagedPort -Name "backend" -Port $BackendPort -ExplicitlyAssigned:$backendPortExplicitlyAssigned

    Write-Step "packaging backend"
    Invoke-Native -FilePath $mvnw -Arguments @("-q", "-DskipTests", "package") -WorkingDirectory $backendDir

    $backendJar = Get-ChildItem -File -LiteralPath (Join-Path $backendDir "target") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "-(sources|javadoc)\.jar$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $backendJar) {
        throw "Packaged backend jar was not found under backend/target"
    }

    $javaPath = (Get-Command java -ErrorAction Stop).Source
    $nodePath = (Get-Command node -ErrorAction Stop).Source
    $webVitePath = Join-Path $webDir "node_modules\vite\bin\vite.js"
    $adminVitePath = Join-Path $adminDir "node_modules\vite\bin\vite.js"
    $playwrightCliPath = Join-Path $webDir "node_modules\@playwright\test\cli.js"
    foreach ($requiredPath in @($webVitePath, $adminVitePath, $playwrightCliPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "Required frontend dependency entrypoint is missing: $requiredPath"
        }
    }

    $backendBaseUrl = "http://127.0.0.1:$BackendPort"
    $env:VITE_PROXY_TARGET = $backendBaseUrl
    $env:PLAYWRIGHT_REAL_BACKEND = "1"
    $env:PLAYWRIGHT_EXTERNAL_SERVERS = "1"
    $env:PLAYWRIGHT_OUTPUT_DIR = Join-Path $runDir "test-results"
    $env:PLAYWRIGHT_WEB_PORT = "$WebPort"
    $env:PLAYWRIGHT_ADMIN_PORT = "$AdminPort"
    $env:PLAYWRIGHT_BACKEND_PORT = "$BackendPort"
    $env:PLAYWRIGHT_CHANNEL = $BrowserChannel

    Write-Step "starting H2 backend"
    $backendProcess = Start-ManagedProcess -Name "backend" -FilePath $javaPath -Arguments @(
        "-jar",
        $backendJar.FullName,
        "--spring.profiles.active=h2",
        "--server.port=$BackendPort",
        "--management.health.redis.enabled=false"
    ) -WorkingDirectory $backendDir
    Wait-HttpReady -Name "backend" -Process $backendProcess -Url "$backendBaseUrl/actuator/health" -TimeoutSeconds 120

    Write-Step "starting web"
    $webProcess = Start-ManagedProcess -Name "web" -FilePath $nodePath -Arguments @(
        $webVitePath,
        "--host", "127.0.0.1",
        "--port", "$WebPort",
        "--strictPort"
    ) -WorkingDirectory $webDir
    Wait-HttpReady -Name "web" -Process $webProcess -Url "http://127.0.0.1:$WebPort/" -TimeoutSeconds 60

    Write-Step "starting admin-web"
    $adminProcess = Start-ManagedProcess -Name "admin" -FilePath $nodePath -Arguments @(
        $adminVitePath,
        "--host", "127.0.0.1",
        "--port", "$AdminPort",
        "--strictPort"
    ) -WorkingDirectory $adminDir
    Wait-HttpReady -Name "admin-web" -Process $adminProcess -Url "http://127.0.0.1:$AdminPort/login" -TimeoutSeconds 60

    Write-Step "running Playwright real backend flow"
    Invoke-Native -FilePath $nodePath -Arguments @(
        $playwrightCliPath,
        "test",
        "e2e/real-backend-flow.spec.ts"
    ) -WorkingDirectory $webDir

    $succeeded = $true
    Write-Step "browser E2E passed"
}
finally {
    Stop-ManagedProcesses
    Stop-BackendListener -Port $BackendPort -ExpectedProcessId $(if ($null -eq $backendProcess) { 0 } else { $backendProcess.Id }) -ExpectedJarPath $(if ($null -eq $backendJar) { "" } else { $backendJar.FullName })

    Restore-EnvironmentVariable -Name "PLAYWRIGHT_REAL_BACKEND" -Value $previousRealBackend
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_EXTERNAL_SERVERS" -Value $previousExternalServers
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_OUTPUT_DIR" -Value $previousOutputDir
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_WEB_PORT" -Value $previousWebPort
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_ADMIN_PORT" -Value $previousAdminPort
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_BACKEND_PORT" -Value $previousBackendPort
    Restore-EnvironmentVariable -Name "PLAYWRIGHT_CHANNEL" -Value $previousChannel
    Restore-EnvironmentVariable -Name "VITE_PROXY_TARGET" -Value $previousProxyTarget

    if ($succeeded -and (Test-Path -LiteralPath $runDir)) {
        $resolvedRunDir = (Resolve-Path -LiteralPath $runDir).Path
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if ($resolvedRunDir.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedRunDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    elseif (Test-Path -LiteralPath $runDir) {
        Write-Warning "Browser E2E logs were preserved at $runDir"
    }
}
