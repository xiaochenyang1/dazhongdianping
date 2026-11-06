param(
    [Parameter(Mandatory)][string]$BaseUrl,
    [Parameter(Mandatory)][string]$CustomerToken,
    [Parameter(Mandatory)][string]$MerchantToken,
    [Parameter(Mandatory)][int]$ExpectedCustomerCount,
    [Parameter(Mandatory)][int]$ExpectedMerchantCount,
    [Parameter(Mandatory)][string]$OutputPath
)
$ErrorActionPreference = "Stop"
$clients = @()
$durations = [System.Collections.Generic.List[double]]::new()
$historyQueries = @()
function Read-Page($client, [string]$url) {
    $response = $client.GetAsync($url).GetAwaiter().GetResult()
    try {
        $response.EnsureSuccessStatusCode() | Out-Null
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        if ($body.code -ne 0) { throw "Session list API failed" }
        return $body.data
    } finally { $response.Dispose() }
}
function Cursor-Query($page) {
    if ($null -eq $page.nextBeforeId -or $null -eq $page.nextBeforeUpdatedAt) { throw "Nonterminal page has no cursor" }
    $time = $page.nextBeforeUpdatedAt
    if ($time -is [datetime]) { $time = $time.ToString("yyyy-MM-ddTHH:mm:ss.fffffff", [Globalization.CultureInfo]::InvariantCulture) }
    return "beforeId=$($page.nextBeforeId)&beforeUpdatedAt=$([Uri]::EscapeDataString([string]$time))"
}
try {
    foreach ($token in @($CustomerToken, $MerchantToken)) {
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [TimeSpan]::FromSeconds(10)
        $client.DefaultRequestHeaders.Add("Authorization", "Bearer $token")
        $client.DefaultRequestHeaders.Add("X-Region", "EU")
        $clients += $client
    }
    for ($side = 0; $side -lt 2; $side++) {
        $prefix = if ($side -eq 0) { "c" } else { "b" }
        $url = "$BaseUrl/api/$prefix/v1/consult/sessions"
        $first = Read-Page $clients[$side] $url
        if ($first.list.Count -ne 20 -or -not $first.hasMore) { throw "Default session page is not bounded to 20" }
        $historyQueries += (Cursor-Query $first)
        # Walk all static fixture rows. Equal activity timestamps must not repeat or skip IDs.
        $seen = [System.Collections.Generic.HashSet[long]]::new()
        $query = "pageSize=100"
        $previous = $null
        do {
            $page = Read-Page $clients[$side] "${url}?$query"
            if ($page.list.Count -gt 100 -or ($page.hasMore -and $page.list.Count -ne 100)) { throw "Session page exceeded 100" }
            foreach ($row in $page.list) {
                if (-not $seen.Add([long]$row.id)) { throw "Repeated session across cursor pages" }
                if ($null -ne $previous) {
                    $time = [datetime]$row.updatedAt; $oldTime = [datetime]$previous.updatedAt
                    if ($time -gt $oldTime -or ($time -eq $oldTime -and [long]$row.id -ge [long]$previous.id)) { throw "Session ordering changed" }
                }
                $previous = $row
            }
            if ($page.hasMore) { $query = "pageSize=100&$(Cursor-Query $page)" }
        } while ($page.hasMore)
        $expected = if ($side -eq 0) { $ExpectedCustomerCount } else { $ExpectedMerchantCount }
        if ($seen.Count -ne $expected) { throw "Session cursor walk missed rows: $($seen.Count), expected $expected" }
        if ($null -ne $page.nextBeforeId -or $null -ne $page.nextBeforeUpdatedAt) { throw "Terminal page has a cursor" }
    }
    for ($wave = 0; $wave -lt 20; $wave++) {
        $calls = @()
        for ($slot = 0; $slot -lt 10; $slot++) {
            $side = $slot % 2
            $prefix = if ($side -eq 0) { "c" } else { "b" }
            $unread = ($slot % 3 -eq 2)
            $query = if ($unread) { "unreadOnly=true" } elseif ($slot % 3 -eq 1) { $historyQueries[$side] } else { "pageSize=20" }
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $calls += @{ Timer = $timer; Unread = $unread; Task = $clients[$side].GetAsync("$BaseUrl/api/$prefix/v1/consult/sessions?$query") }
        }
        foreach ($call in $calls) {
            $response = $call.Task.GetAwaiter().GetResult()
            try {
                $call.Timer.Stop(); $durations.Add($call.Timer.Elapsed.TotalMilliseconds)
                $response.EnsureSuccessStatusCode() | Out-Null
                $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
                if ($body.code -ne 0 -or $body.data.list.Count -gt 20 -or $body.data.list.Count -eq 0) { throw "Invalid bounded session response" }
                if ($call.Unread -and @($body.data.list | Where-Object { $_.unread -le 0 }).Count -gt 0) { throw "Unread filter returned a read session" }
            } finally { $response.Dispose() }
        }
    }
    $ordered = @($durations | Sort-Object)
    $p95 = $ordered[[int][Math]::Ceiling($ordered.Count * 0.95) - 1]
    $result = @{ customerSessions = $ExpectedCustomerCount; merchantSessions = $ExpectedMerchantCount; fullWalkPassed = $true
        concurrentRequests = 10; measuredRequests = 200; errors = 0; p95Ms = [Math]::Round($p95, 2); p95ThresholdMs = 1500
        scope = "Isolated MySQL fixture; not target-environment acceptance" }
    $result | ConvertTo-Json | Set-Content -LiteralPath $OutputPath -Encoding utf8
    if ($p95 -ge 1500) { throw "Session list p95 exceeded 1500 ms: $p95" }
    Write-Output "[consult-session-capacity] $ExpectedCustomerCount customer / $ExpectedMerchantCount merchant sessions, full walks passed; 10 concurrent requests, 200 reads, 0 errors, p95 $($result.p95Ms) ms"
} finally { foreach ($client in $clients) { $client.Dispose() } }
