param(
    [string]$DbHost,
    [int]$DbPort = 0,
    [string]$DbName,
    [string]$DbUsername,
    [string]$DbPassword,
    [int]$BackendPort = 0,
    [switch]$SkipImport,
    [switch]$KeepBackend,
    [switch]$DropDatabaseAfter,
    [switch]$AllowDestructiveImport,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$dbNameWasExplicitlySupplied = $PSBoundParameters.ContainsKey("DbName") -and -not [string]::IsNullOrWhiteSpace([string]$PSBoundParameters["DbName"])
$backendPortWasExplicitlySupplied = $PSBoundParameters.ContainsKey("BackendPort") -or -not [string]::IsNullOrWhiteSpace([string]$env:APP_BACKEND_SMOKE_PORT)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })
$schemaSql = Join-Path $repoRoot "sql\mysql\01_schema.sql"
$seedSql = Join-Path $repoRoot "sql\mysql\02_seed_data.sql"
$runDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-mysql-smoke-" + [System.Guid]::NewGuid().ToString("N"))

if (-not $DbHost) { $DbHost = if ($env:APP_DB_HOST) { $env:APP_DB_HOST } else { "127.0.0.1" } }
if ($DbPort -eq 0) { $DbPort = if ($env:APP_DB_PORT) { [int]$env:APP_DB_PORT } else { 3306 } }
if (-not $DbName) { $DbName = if ($env:APP_DB_NAME) { $env:APP_DB_NAME } else { "dazhongdianping" } }
if (-not $DbUsername) { $DbUsername = if ($env:APP_DB_USERNAME) { $env:APP_DB_USERNAME } else { "root" } }
if ($null -eq $DbPassword) { $DbPassword = if ($env:APP_DB_PASSWORD) { $env:APP_DB_PASSWORD } else { "" } }
if ($BackendPort -eq 0) { $BackendPort = if ($env:APP_BACKEND_SMOKE_PORT) { [int]$env:APP_BACKEND_SMOKE_PORT } else { 18080 } }

$baseUrl = "http://127.0.0.1:$BackendPort"

function Write-Step {
    param([string]$Message)
    Write-Output "[mysql-smoke] $Message"
}

function Assert-ValidDatabaseName {
    param([string]$Name)

    if ($Name -notmatch '^[A-Za-z][A-Za-z0-9_]{0,63}$') {
        throw "DbName must start with an ASCII letter and contain only ASCII letters, digits, or underscores (maximum 64 characters)"
    }
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory = $repoRoot
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

    return Start-Process @parameters
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

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return $listener.LocalEndpoint.Port
    }
    finally {
        $listener.Stop()
    }
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

function Wait-BackendHealthy {
    param(
        [string]$Name,
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutSeconds
    )

    $deadline = [System.DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([System.DateTimeOffset]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            $logs = Get-ProcessLogTail -Name $Name
            throw "$Name exited before becoming healthy (exit code $($Process.ExitCode)).`n$logs"
        }

        try {
            $health = Invoke-RestMethod -Method "GET" -Uri "$baseUrl/actuator/health" -TimeoutSec 2
            if ($health.status -eq "UP") {
                return
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    $logs = Get-ProcessLogTail -Name $Name
    throw "$Name did not become healthy within $TimeoutSeconds seconds.`n$logs"
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

function Invoke-Json {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )

    $uri = "$baseUrl$Path"
    $request = @{
        Method = $Method
        Uri = $uri
        Headers = $Headers
        TimeoutSec = 10
    }

    if ($null -ne $Body) {
        $request.ContentType = "application/json"
        $request.Body = ($Body | ConvertTo-Json -Depth 8)
    }

    return Invoke-RestMethod @request
}

Assert-ValidDatabaseName -Name $DbName

if ($DropDatabaseAfter -and -not $dbNameWasExplicitlySupplied) {
    throw "-DropDatabaseAfter requires an explicitly supplied -DbName"
}

if ($AllowDestructiveImport -and -not $dbNameWasExplicitlySupplied) {
    throw "-AllowDestructiveImport requires an explicitly supplied -DbName"
}

if ($DryRun) {
    Write-Output "Plan:"
    if ($SkipImport) {
        Write-Output "- Skip database import and use the existing $DbName database."
    }
    else {
        if ($AllowDestructiveImport) {
            Write-Output "- Create $DbName when absent; when it already exists, allow a destructive schema reset."
    }
    else {
        Write-Output "- Create $DbName when absent; refuse to import when that database already exists."
        }
        Write-Output "- Source sql/mysql/01_schema.sql into $DbName."
        Write-Output "- Source sql/mysql/02_seed_data.sql into $DbName."
    }
    Write-Output "- Package backend with backend/mvnw.cmd -DskipTests package."
    Write-Output "- Start the packaged backend jar with APP_DB_* environment variables on port $BackendPort."
    Write-Output "- Poll /actuator/health until Spring Boot and the MySQL datasource are healthy."
    Write-Output "- Smoke GET /api/c/v1/categories with X-Region=CN."
    Write-Output "- Smoke GET /api/c/v1/shops with X-Region=EU."
    Write-Output "- Smoke POST /api/admin/v1/auth/login and GET /api/b/v1/health."
    Write-Output "- When APP_STATE_STORE_PROVIDER=redis, smoke send-code rate limiting and Idempotency-Key replay through Redis."
    if ($DropDatabaseAfter) {
        Write-Output "- In finally, drop $DbName only if this run created it; never drop a pre-existing database."
    }
    else {
        Write-Output "- Leave $DbName intact after the smoke run."
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $mvnw)) {
    throw "backend Maven wrapper not found"
}

if (-not (Test-Path -LiteralPath $schemaSql)) {
    throw "sql/mysql/01_schema.sql not found"
}

if (-not (Test-Path -LiteralPath $seedSql)) {
    throw "sql/mysql/02_seed_data.sql not found"
}

$mysqlCommand = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlCommand) {
    throw "mysql client not found in PATH"
}

$javaCommand = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCommand) {
    throw "java runtime not found in PATH"
}

if (-not $backendPortWasExplicitlySupplied -and (Test-TcpPortListening -Port $BackendPort)) {
    $fallbackBackendPort = Get-FreeTcpPort
    Write-Warning "backend port $BackendPort is already in use; falling back to port $fallbackBackendPort because no explicit -BackendPort or APP_BACKEND_SMOKE_PORT was supplied"
    $BackendPort = $fallbackBackendPort
    $baseUrl = "http://127.0.0.1:$BackendPort"
}

New-Item -ItemType Directory -Path $runDir -Force | Out-Null
Assert-PortAvailable -Port $BackendPort

$env:APP_DB_HOST = $DbHost
$env:APP_DB_PORT = "$DbPort"
$env:APP_DB_NAME = $DbName
$env:APP_DB_USERNAME = $DbUsername
$env:APP_DB_PASSWORD = $DbPassword

$mysqlConnectionArgs = @(
    "--protocol=tcp",
    "-h", $DbHost,
    "-P", "$DbPort",
    "-u", $DbUsername
)
if ($DbPassword.Length -gt 0) {
    $mysqlConnectionArgs += "--password=$DbPassword"
}

$databaseCreatedByThisRun = $false
$databaseOwnershipToken = [guid]::NewGuid().ToString("N")
$backendStartedByThisRun = $false
$backendProcess = $null
$succeeded = $false

try {
    Write-Step "packaging backend"
    Invoke-Native -FilePath $mvnw -Arguments @(
        "-q",
        "-DskipTests",
        "package"
    ) -WorkingDirectory $backendDir

    $backendJar = Get-ChildItem -File -LiteralPath (Join-Path $backendDir "target") -Filter "*.jar" |
        Where-Object { $_.Name -notmatch "-(sources|javadoc)\.jar$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $backendJar) {
        throw "Packaged backend jar was not found under backend/target"
    }

    if (-not $SkipImport) {
        $databaseLookupSql = "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DbName';"
        $databaseLookupResult = @(
            Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
                "--batch",
                "--skip-column-names",
                "-e", $databaseLookupSql
            )) -WorkingDirectory $repoRoot
        )
        $databaseAlreadyExists = @($databaseLookupResult | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0

        if ($databaseAlreadyExists -and -not $AllowDestructiveImport) {
            throw "Database $DbName already exists. Refusing destructive import; choose a fresh -DbName, use -SkipImport for a prepared database, or explicitly pass -AllowDestructiveImport."
        }

        if (-not $databaseAlreadyExists) {
            Write-Step "creating database $DbName"
            $createDatabaseSql = "CREATE DATABASE ``$DbName`` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"
            Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
                "-e", $createDatabaseSql
            )) -WorkingDirectory $repoRoot
            $databaseCreatedByThisRun = $true

            $createOwnershipMarkerSql = @"
CREATE TABLE ``$DbName``.``__dzdp_smoke_owner`` (
    owner_token CHAR(32) NOT NULL PRIMARY KEY
);
INSERT INTO ``$DbName``.``__dzdp_smoke_owner`` (owner_token)
VALUES ('$databaseOwnershipToken');
"@
            Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
                "-e", $createOwnershipMarkerSql
            )) -WorkingDirectory $repoRoot
        }
        else {
            Write-Warning "database $DbName already exists and will be destructively reset by sql/mysql/01_schema.sql"
        }

        Write-Step "importing sql/mysql/01_schema.sql into $DbName"
        Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
            "--database=$DbName",
            "-e", "source sql/mysql/01_schema.sql"
        )) -WorkingDirectory $repoRoot

        Write-Step "importing sql/mysql/02_seed_data.sql into $DbName"
        Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
            "--database=$DbName",
            "-e", "source sql/mysql/02_seed_data.sql"
        )) -WorkingDirectory $repoRoot
    }

    Write-Step "starting backend on $baseUrl"
    $backendProcess = Start-ManagedProcess -Name "backend" -FilePath $javaCommand.Source -Arguments @(
        "-jar",
        $backendJar.FullName,
        "--server.port=$BackendPort",
        "--management.health.redis.enabled=false"
    ) -WorkingDirectory $backendDir
    $backendStartedByThisRun = $true

    Write-Step "polling /actuator/health"
    Wait-BackendHealthy -Name "backend" -Process $backendProcess -TimeoutSeconds 120

    Write-Step "smoking public browse endpoints"
    $categories = Invoke-Json -Method "GET" -Path "/api/c/v1/categories" -Headers @{ "X-Region" = "CN" }
    if (-not $categories.data -or $categories.data.Count -lt 1) {
        throw "GET /api/c/v1/categories returned no data"
    }

    $shops = Invoke-Json -Method "GET" -Path "/api/c/v1/shops" -Headers @{ "X-Region" = "EU" }
    if (-not $shops.data -or -not $shops.data.list -or $shops.data.list.Count -lt 1) {
        throw "GET /api/c/v1/shops returned no EU data"
    }

    Write-Step "smoking admin login"
    $idempotencyKey = "ci-admin-login-" + [guid]::NewGuid().ToString("N")
    $adminHeaders = @{ "Idempotency-Key" = $idempotencyKey }
    $adminLogin = Invoke-Json -Method "POST" -Path "/api/admin/v1/auth/login" -Headers $adminHeaders -Body @{
        account = "admin"
        password = "admin123456"
    }
    if (-not $adminLogin.data -or -not $adminLogin.data.accessToken) {
        throw "POST /api/admin/v1/auth/login did not return an admin token"
    }

    $adminLoginReplay = Invoke-Json -Method "POST" -Path "/api/admin/v1/auth/login" -Headers $adminHeaders -Body @{
        account = "admin"
        password = "admin123456"
    }
    if ($adminLoginReplay.data.accessToken -ne $adminLogin.data.accessToken) {
        throw "Idempotency-Key replay did not reuse the first admin login response"
    }

    Write-Step "smoking B endpoint"
    $merchantHealth = Invoke-Json -Method "GET" -Path "/api/b/v1/health"
    if (-not $merchantHealth.data -or $merchantHealth.data.status -ne "ok") {
        throw "GET /api/b/v1/health did not return ok"
    }

    if ($env:APP_STATE_STORE_PROVIDER -eq "redis") {
        Write-Step "smoking Redis-backed send-code rate limiting"
        $account = "ci-smoke-" + [guid]::NewGuid().ToString("N") + "@example.com"
        $sendCodeBody = @{
            scene = "login"
            type = "email"
            account = $account
            deviceId = "ci-smoke-device"
        }
        $sendCode = Invoke-Json -Method "POST" -Path "/api/c/v1/auth/send-code" -Headers @{ "X-Forwarded-For" = "203.0.113.10" } -Body $sendCodeBody
        if (-not $sendCode.data -or $sendCode.data.sent -ne $true) {
            throw "first send-code smoke did not succeed"
        }

        try {
            Invoke-Json -Method "POST" -Path "/api/c/v1/auth/send-code" -Headers @{ "X-Forwarded-For" = "203.0.113.10" } -Body $sendCodeBody | Out-Null
            throw "second send-code smoke should have been rate limited"
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            if ($statusCode -ne 429) {
                throw
            }
        }
    }

    $succeeded = $true
    Write-Step "MySQL import and backend smoke passed"
}
finally {
    $cleanupFailures = [System.Collections.Generic.List[string]]::new()

    if (-not $KeepBackend -and $backendStartedByThisRun -and $null -ne $backendProcess) {
        Write-Step "stopping backend"
        try {
            Stop-ManagedProcessTree -ProcessId $backendProcess.Id
            Wait-ManagedProcessExit -ProcessId $backendProcess.Id -TimeoutSeconds 15
        }
        catch {
            $cleanupFailures.Add("backend stop failed: $($_.Exception.Message)")
        }

        try {
            Wait-PortReleased -Port $BackendPort -TimeoutSeconds 15
        }
        catch {
            $cleanupFailures.Add($_.Exception.Message)
        }
        finally {
            try {
                $backendProcess.Close()
            }
            catch {
            }
        }
    }

    if ($DropDatabaseAfter -and $databaseCreatedByThisRun) {
        try {
            $ownershipLookupSql = "SELECT owner_token FROM ``$DbName``.``__dzdp_smoke_owner`` LIMIT 1;"
            $ownershipLookupResult = @(
                Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
                    "--batch",
                    "--skip-column-names",
                    "-e", $ownershipLookupSql
                )) -WorkingDirectory $repoRoot
            )
            $actualOwnershipToken = @(
                $ownershipLookupResult | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
            ) | Select-Object -First 1

            if ($actualOwnershipToken -eq $databaseOwnershipToken) {
                Write-Step "dropping database $DbName created by this run"
                $dropDatabaseSql = "DROP DATABASE ``$DbName``;"
                Invoke-Native -FilePath $mysqlCommand.Source -Arguments ($mysqlConnectionArgs + @(
                    "-e", $dropDatabaseSql
                )) -WorkingDirectory $repoRoot
            }
            else {
                Write-Warning "database $DbName ownership changed; refusing DropDatabaseAfter cleanup"
            }
        }
        catch {
            Write-Warning "database ownership verification failed; refusing DropDatabaseAfter cleanup: $($_.Exception.Message)"
        }
    }

    if ($succeeded -and $cleanupFailures.Count -eq 0 -and -not $KeepBackend) {
        Remove-RunDirectory -Path $runDir
    }
    elseif (Test-Path -LiteralPath $runDir) {
        Write-Warning "MySQL smoke logs were preserved at $runDir"
    }

    if ($cleanupFailures.Count -gt 0) {
        throw ($cleanupFailures -join "`n")
    }
}
