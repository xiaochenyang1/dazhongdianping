$ErrorActionPreference = 'Stop'
# The deployment target is POSIX. Linux CI uses real GNU filesystem/locking
# tools; macOS fixtures supply only their GNU compatibility behavior.
if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
    Write-Output 'release execution tests require a POSIX host; run in Linux CI'
    return
}
& python3 (Join-Path $PSScriptRoot 'test-release-execution.py')
if ($LASTEXITCODE -ne 0) { throw 'Release execution integration failed' }
