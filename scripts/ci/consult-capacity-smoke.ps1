param(
    [Parameter(Mandatory)][string]$BaseUrl,
    [Parameter(Mandatory)][string]$CustomerToken,
    [Parameter(Mandatory)][string]$MerchantToken,
    [Parameter(Mandatory)][long]$SessionId,
    [Parameter(Mandatory)][long]$NewestId,
    [Parameter(Mandatory)][long]$BeforeId,
    [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = "Stop"
# Controlled CI baseline only: 10 simultaneous requests over a 10,000-message fixture.
# This is not a production load estimate or a target-environment acceptance result.
$clients = @()
$durations = [System.Collections.Generic.List[double]]::new()
try {
    foreach ($token in @($CustomerToken, $MerchantToken)) {
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [TimeSpan]::FromSeconds(10)
        $client.DefaultRequestHeaders.Add("Authorization", "Bearer $token")
        $client.DefaultRequestHeaders.Add("X-Region", "EU")
        $clients += $client
    }
    # Warm both authenticated paths before measuring.
    for ($side = 0; $side -lt 2; $side++) {
        $prefix = if ($side -eq 0) { "c" } else { "b" }
        $response = $clients[$side].GetAsync("$BaseUrl/api/$prefix/v1/consult/sessions/$SessionId/messages").GetAwaiter().GetResult()
        try { $response.EnsureSuccessStatusCode() | Out-Null } finally { $response.Dispose() }
    }
    for ($wave = 0; $wave -lt 20; $wave++) {
        $requests = @()
        for ($slot = 0; $slot -lt 10; $slot++) {
            $side = $slot % 2
            $prefix = if ($side -eq 0) { "c" } else { "b" }
            $query = switch ($slot % 3) {
                0 { "?pageSize=50" }
                1 { "?beforeId=$BeforeId&pageSize=50" }
                2 { "?afterId=$NewestId&pageSize=50" }
            }
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $requests += @{ Timer = $timer; Empty = ($slot % 3 -eq 2); Task = $clients[$side].GetAsync("$BaseUrl/api/$prefix/v1/consult/sessions/$SessionId/messages$query") }
        }
        foreach ($request in $requests) {
            $response = $request.Task.GetAwaiter().GetResult()
            try {
                $request.Timer.Stop()
                $durations.Add($request.Timer.Elapsed.TotalMilliseconds)
                $response.EnsureSuccessStatusCode() | Out-Null
                $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
                if ($body.code -ne 0 -or $body.data.messages.Count -gt 50) { throw "Consultation page exceeded its bound or failed" }
                if ($request.Empty -and ($body.data.messages.Count -ne 0 -or $body.data.nextAfterId -ne $NewestId)) {
                    throw "Idle incremental consultation poll returned history or lost its cursor"
                }
                if (-not $request.Empty -and $body.data.messages.Count -ne 50) { throw "Expected a full fixture history page" }
            } finally { $response.Dispose() }
        }
    }
    $ordered = @($durations | Sort-Object)
    $p95 = $ordered[[int][Math]::Ceiling($ordered.Count * 0.95) - 1]
    $result = @{
        fixtureMessages = 10001; concurrentRequests = 10; requests = $ordered.Count
        errors = 0; pageSize = 50; idlePollMessages = 0
        p95Ms = [Math]::Round($p95, 2); maxMs = [Math]::Round($ordered[-1], 2)
        p95ThresholdMs = 1500; passed = ($p95 -lt 1500)
        scope = "Isolated MySQL CI fixture; not production or target-environment acceptance"
    }
    $result | ConvertTo-Json | Set-Content -LiteralPath $OutputPath -Encoding utf8
    if (-not $result.passed) { throw "Consultation fixture p95 exceeded 1500 ms: $($result.p95Ms) ms" }
    Write-Output "[consult-capacity] 10001 messages, 10 concurrent requests, 200 reads, 0 errors, p95 $($result.p95Ms) ms"
} finally {
    foreach ($client in $clients) { $client.Dispose() }
}
