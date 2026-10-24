param(
    [string]$ElasticsearchBaseUrl,
    [int]$BackendPort = 0,
    [string]$IndexName,
    [switch]$KeepBackend,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$runningOnWindows = [System.Environment]::OSVersion.Platform -eq "Win32NT"
$mvnw = Join-Path $backendDir $(if ($runningOnWindows) { "mvnw.cmd" } else { "mvnw" })
$runDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dazhongdianping-elasticsearch-smoke-" + [guid]::NewGuid().ToString("N"))

if (-not $ElasticsearchBaseUrl) { $ElasticsearchBaseUrl = if ($env:APP_SEARCH_BASE_URL) { $env:APP_SEARCH_BASE_URL } else { "http://127.0.0.1:9200" } }
if ($BackendPort -eq 0) { $BackendPort = if ($env:APP_ELASTICSEARCH_SMOKE_BACKEND_PORT) { [int]$env:APP_ELASTICSEARCH_SMOKE_BACKEND_PORT } else { 18082 } }
if (-not $IndexName) { $IndexName = "dzdp_shop_smoke_" + [guid]::NewGuid().ToString("N") }
$backendBaseUrl = "http://127.0.0.1:$BackendPort"

function Write-Step([string]$Message) { Write-Output "[elasticsearch-smoke] $Message" }

function Invoke-Native([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) { throw "$FilePath exited with code $LASTEXITCODE" }
    }
    finally { Pop-Location }
}

function Test-TcpPortListening([int]$Port) {
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    return $null -ne ($listeners | Where-Object { $_.Port -eq $Port } | Select-Object -First 1)
}

function Start-Backend([string]$JarPath) {
    $stdoutPath = Join-Path $runDir "backend.stdout.log"
    $stderrPath = Join-Path $runDir "backend.stderr.log"
    $arguments = @(
        "-jar", $JarPath,
        "--spring.profiles.active=local",
        "--server.port=$BackendPort",
        "--spring.datasource.driver-class-name=org.h2.Driver",
        "--spring.datasource.url=jdbc:h2:mem:dzdp-es-smoke;MODE=MYSQL;DATABASE_TO_LOWER=TRUE",
        "--spring.datasource.username=sa",
        "--spring.datasource.password=",
        "--spring.sql.init.mode=always",
        "--management.health.redis.enabled=false",
        "--app.search.provider=elasticsearch",
        "--app.search.base-url=$ElasticsearchBaseUrl",
        "--app.search.index-name=$IndexName",
        "--app.search.sync-fixed-delay-ms=200",
        "--app.search.sync-initial-delay-ms=200",
        "--app.search.fallback-on-error=false"
    )
    $parameters = @{
        FilePath = (Get-Command java -ErrorAction Stop).Source
        ArgumentList = $arguments
        WorkingDirectory = $backendDir
        PassThru = $true
        RedirectStandardOutput = $stdoutPath
        RedirectStandardError = $stderrPath
    }
    if ($runningOnWindows) { $parameters.WindowStyle = "Hidden" }
    return Start-Process @parameters
}

function Get-BackendLogs {
    $parts = @()
    foreach ($path in @((Join-Path $runDir "backend.stdout.log"), (Join-Path $runDir "backend.stderr.log"))) {
        if (Test-Path -LiteralPath $path) { $parts += Get-Content -LiteralPath $path -Tail 50 -ErrorAction SilentlyContinue }
    }
    return $parts -join "`n"
}

function Wait-Http([string]$Uri, [int]$TimeoutSeconds, [System.Diagnostics.Process]$Process = $null) {
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTimeOffset]::UtcNow -lt $deadline) {
        if ($null -ne $Process) {
            $Process.Refresh()
            if ($Process.HasExited) { throw "backend exited before becoming healthy.`n$(Get-BackendLogs)" }
        }
        try {
            Invoke-RestMethod -Method GET -Uri $Uri -TimeoutSec 3 | Out-Null
            return
        }
        catch { Start-Sleep -Milliseconds 500 }
    }
    throw "Timed out waiting for $Uri`n$(Get-BackendLogs)"
}

function Invoke-Api([string]$Method, [string]$Path, [hashtable]$Headers = @{}, [object]$Body = $null) {
    $request = @{ Method = $Method; Uri = "$backendBaseUrl$Path"; Headers = $Headers; TimeoutSec = 15 }
    if ($null -ne $Body) {
        $request.ContentType = "application/json"
        $request.Body = $Body | ConvertTo-Json -Depth 8
    }
    return Invoke-RestMethod @request
}

function Assert-FirstShop([object]$Response, [long]$ExpectedId, [string]$Scenario) {
    if (-not $Response.data -or -not $Response.data.list -or $Response.data.list.Count -lt 1) { throw "$Scenario returned no shops" }
    if ([long]$Response.data.list[0].id -ne $ExpectedId) { throw "$Scenario expected shop $ExpectedId but got $($Response.data.list[0].id)" }
}

function Assert-DealSearch([string]$Keyword, [long]$ExpectedId, [string]$Region = "EU") {
    # Wait for the durable outbox, then refresh ES before checking absence as well
    # as presence. A missing event cannot pass a rename/on-shelf assertion.
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        $tasks = Invoke-Api GET "/api/admin/v1/search/sync-tasks?pageSize=50" $euAdminHeaders
        if ([long]$tasks.data.total -eq 0) { break }
        if ([DateTime]::UtcNow -ge $deadline) { throw "deal search sync did not drain for $Keyword" }
        Start-Sleep -Milliseconds 250
    } while ($true)
    Invoke-RestMethod -Method POST -Uri "$ElasticsearchBaseUrl/$IndexName/_refresh" -TimeoutSec 15 | Out-Null
    $encoded = [Uri]::EscapeDataString($Keyword)
    $response = Invoke-Api GET "/api/c/v1/search/shops?keyword=$encoded" @{ "X-Region" = $Region }
    if ($ExpectedId -eq 0) {
        if ([long]$response.data.total -ne 0) { throw "non-public deal title leaked: $Keyword ($Region)" }
    } else {
        Assert-FirstShop $response $ExpectedId "deal title $Keyword ($Region)"
        if ([long]$response.data.total -ne 1) { throw "deal title returned duplicate or unrelated shops: $Keyword" }
    }
}

function Invoke-DealAudit([long]$DealId, [bool]$Pass) {
    $tasks = Invoke-Api GET "/api/admin/v1/audit/tasks?bizType=2&status=0&pageSize=50" $euAdminHeaders
    $task = @($tasks.data.list | Where-Object { [long]$_.bizId -eq $DealId })
    if ($task.Count -ne 1) { throw "expected one pending audit for deal $DealId" }
    $action = if ($Pass) { "pass" } else { "reject" }
    $body = if ($Pass) { @{ remark = "search lifecycle smoke" } } else { @{ reason = "revise the menu" } }
    Invoke-Api POST "/api/admin/v1/audit/tasks/$($task[0].id)/$action" $euAdminHeaders $body | Out-Null
}

if ($DryRun) {
    Write-Output "Plan:"
    Write-Output "- Require a real Elasticsearch 8 service at $ElasticsearchBaseUrl."
    Write-Output "- Package and start the backend with isolated H2 data, APP_SEARCH_PROVIDER=elasticsearch, and APP_SEARCH_FALLBACK_ON_ERROR=false."
    Write-Output "- Login as admin and POST /api/admin/v1/search/reindex."
    Write-Output "- Verify Chinese keyword, pinyin keyword, fuzzy correction, category/region filters, Paris-only EU availability, and geo distance sorting through /api/c/v1/search/shops."
    Write-Output "- Verify Chinese/English deal titles, creation, approval/rejection, renaming, on/off-shelf changes, and region isolation through real ES outbox updates."
    Write-Output "- Delete the temporary Elasticsearch index and stop the managed backend in finally."
    exit 0
}

if (Test-TcpPortListening -Port $BackendPort) { throw "backend port $BackendPort is already in use" }
if (-not (Test-Path -LiteralPath $mvnw)) { throw "backend Maven wrapper not found" }
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$backendProcess = $null
$succeeded = $false
try {
    Write-Step "waiting for Elasticsearch"
    Wait-Http -Uri $ElasticsearchBaseUrl -TimeoutSeconds 60

    Write-Step "packaging backend"
    Invoke-Native -FilePath $mvnw -Arguments @("-q", "-DskipTests", "package") -WorkingDirectory $backendDir
    $jar = Get-ChildItem -LiteralPath (Join-Path $backendDir "target") -File -Filter "*.jar" |
        Where-Object { $_.Name -notmatch '-(sources|javadoc)\.jar$' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $jar) { throw "backend jar not found" }

    Write-Step "starting isolated backend"
    $backendProcess = Start-Backend -JarPath $jar.FullName
    Wait-Http -Uri "$backendBaseUrl/actuator/health" -TimeoutSeconds 120 -Process $backendProcess

    $login = Invoke-Api -Method POST -Path "/api/admin/v1/auth/login" -Body @{ account = "admin"; password = "admin123456" }
    if (-not $login.data.accessToken) { throw "admin login did not return accessToken" }
    $adminHeaders = @{ Authorization = "Bearer $($login.data.accessToken)"; "X-Region" = "CN" }
    $euAdminHeaders = @{ Authorization = "Bearer $($login.data.accessToken)"; "X-Region" = "EU" }

    Write-Step "rebuilding Elasticsearch index"
    $reindex = Invoke-Api -Method POST -Path "/api/admin/v1/search/reindex" -Headers $adminHeaders
    # Paris is the only enabled EU city; the two CN shops remain available.
    if ([int]$reindex.data.indexed -ne 3) { throw "reindex expected 3 active shops but indexed $($reindex.data.indexed)" }
    Start-Sleep -Seconds 1

    Write-Step "verifying Chinese, pinyin and fuzzy queries"
    Assert-FirstShop (Invoke-Api GET "/api/c/v1/search/shops?keyword=%E7%81%AB%E9%94%85" @{ "X-Region" = "CN" }) 10001 "Chinese keyword"
    Assert-FirstShop (Invoke-Api GET "/api/c/v1/search/shops?keyword=yulihuoguo" @{ "X-Region" = "CN" }) 10001 "pinyin keyword"
    Assert-FirstShop (Invoke-Api GET "/api/c/v1/search/shops?keyword=yulihuogoa" @{ "X-Region" = "CN" }) 10001 "fuzzy keyword"

    Write-Step "verifying filters, region isolation and distance"
    Assert-FirstShop (Invoke-Api GET "/api/c/v1/search/shops?categoryId=111" @{ "X-Region" = "CN" }) 10002 "category filter"
    Assert-FirstShop (Invoke-Api GET "/api/c/v1/search/shops?keyword=Sichuan" @{ "X-Region" = "EU" }) 20001 "EU region"
    $euShops = Invoke-Api GET "/api/c/v1/search/shops" @{ "X-Region" = "EU" }
    Assert-FirstShop $euShops 20001 "Paris-only EU launch"
    if ([long]$euShops.data.total -ne 1) { throw "EU search must contain only the active Paris shop" }
    $disabledCity = Invoke-Api GET "/api/c/v1/search/shops?cityId=102" @{ "X-Region" = "EU" }
    if ([long]$disabledCity.data.total -ne 0) { throw "disabled Berlin city leaked into EU search" }
    $crossRegion = Invoke-Api GET "/api/c/v1/search/shops?keyword=Sichuan" @{ "X-Region" = "CN" }
    if ([long]$crossRegion.data.total -ne 0) { throw "region isolation leaked EU results into CN" }
    $distance = Invoke-Api GET "/api/c/v1/search/shops?sort=distance&lat=31.2297&lng=121.4470" @{ "X-Region" = "CN" }
    Assert-FirstShop $distance 10002 "distance sort"
    if ($null -eq $distance.data.list[0].distanceMeters) { throw "distance sort did not return distanceMeters" }

    Write-Step "verifying deal titles in rebuilt documents and incremental lifecycle"
    $cnDocument = Invoke-RestMethod -Uri "$ElasticsearchBaseUrl/$IndexName/_doc/10001" -TimeoutSec 15
    if ($cnDocument._source.dealTitles -notcontains "双人川渝火锅套餐") { throw "Chinese deal title was not preserved in bulk indexing" }
    Assert-DealSearch "双人" 10001 "CN"
    Assert-DealSearch "Dinner for Two" 20001
    $merchant = Invoke-Api POST "/api/b/v1/auth/login" @{ "X-Region" = "EU" } @{
        account = "merchant_eu_sichuan@example.com"; password = "merchant123456"
    }
    $merchantHeaders = @{ Authorization = "Bearer $($merchant.data.accessToken)"; "X-Region" = "EU" }
    $dealBody = @{
        shopId = 20001; type = 1; title = "AuroraTasting"; coverImage = "https://files.example/deals/dinner.jpg"
        price = 49.90; originalPrice = 68.00; currency = "EUR"; stock = 20
        validStart = [DateTime]::UtcNow.AddDays(-1).ToString("yyyy-MM-dd")
        validEnd = [DateTime]::UtcNow.AddMonths(1).ToString("yyyy-MM-dd")
        rules = "Reservation required"; items = @(@{ name = "Main"; quantity = 2; price = 0; sort = 1 })
    }
    $created = Invoke-Api POST "/api/b/v1/deals" $merchantHeaders $dealBody
    $dealId = [long]$created.data.id
    if ($dealId -le 0) { throw "merchant deal creation did not return an id" }
    Assert-DealSearch "AuroraTasting" 0
    Invoke-DealAudit $dealId $true
    Assert-DealSearch "AuroraTasting" 0
    Invoke-Api PUT "/api/b/v1/deals/$dealId/status" $merchantHeaders @{ status = 1 } | Out-Null
    Assert-DealSearch "auroratasting" 20001
    Assert-DealSearch "auroratasting" 0 "CN"

    $dealBody.title = "松露晚宴"
    Invoke-Api PUT "/api/b/v1/deals/$dealId" $merchantHeaders $dealBody | Out-Null
    Assert-DealSearch "AuroraTasting" 0
    Assert-DealSearch "松露晚宴" 0
    Invoke-DealAudit $dealId $true
    Invoke-Api PUT "/api/b/v1/deals/$dealId/status" $merchantHeaders @{ status = 1 } | Out-Null
    Assert-DealSearch "松露晚宴" 20001
    Assert-DealSearch "AuroraTasting" 0
    Invoke-Api PUT "/api/b/v1/deals/$dealId/status" $merchantHeaders @{ status = 0 } | Out-Null
    Assert-DealSearch "松露晚宴" 0

    $dealBody.title = "RejectedMenu"
    Invoke-Api PUT "/api/b/v1/deals/$dealId" $merchantHeaders $dealBody | Out-Null
    Invoke-DealAudit $dealId $false
    Assert-DealSearch "RejectedMenu" 0

    $succeeded = $true
    Write-Step "real Elasticsearch smoke passed"
}
finally {
    try { Invoke-RestMethod -Method DELETE -Uri "$ElasticsearchBaseUrl/$IndexName" -TimeoutSec 10 | Out-Null } catch {}
    if (-not $KeepBackend -and $null -ne $backendProcess) {
        if ($runningOnWindows) { & taskkill /PID $backendProcess.Id /T /F 2>$null | Out-Null }
        else { Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($succeeded -and -not $KeepBackend -and (Test-Path -LiteralPath $runDir)) {
        $resolved = (Resolve-Path -LiteralPath $runDir).Path
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
    elseif (Test-Path -LiteralPath $runDir) { Write-Warning "Elasticsearch smoke logs preserved at $runDir" }
}
