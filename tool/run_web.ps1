param(
    [ValidateRange(1024, 65535)][int]$WebPort = 7357,
    [switch]$CheckBackendOnly
)

$ErrorActionPreference = 'Stop'
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pythonPath = Join-Path $projectDirectory '.venv/Scripts/python.exe'
$runtimeDirectory = Join-Path $projectDirectory 'backend/pronunciation/.runtime'
$healthUrl = 'http://127.0.0.1:8080/health'
$backendProcess = $null

function Get-BackendHealth {
    try {
        return Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2 -ErrorAction Stop
    } catch { return $null }
}

Push-Location $projectDirectory
try {
    if (-not $CheckBackendOnly -and -not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter is not on PATH. Install Flutter and reopen the terminal.'
    }
    $health = Get-BackendHealth
    if ($health -and $health.provider -ne 'wav2vec2-phoneme-edit-similarity') {
        throw 'Port 8080 belongs to another service. Check it before starting English AI.'
    }
    if (-not $health) {
        if (-not (Test-Path -LiteralPath $pythonPath)) {
            throw 'Run powershell -File backend/pronunciation/setup_backend.ps1 first.'
        }
        New-Item -ItemType Directory -Path $runtimeDirectory -Force | Out-Null
        $backendProcess = Start-Process -FilePath $pythonPath -ArgumentList @(
            '-m', 'uvicorn', 'server:app', '--app-dir', 'backend/pronunciation',
            '--host', '127.0.0.1', '--port', '8080'
        ) -WorkingDirectory $projectDirectory -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $runtimeDirectory 'backend.stdout.log') `
            -RedirectStandardError (Join-Path $runtimeDirectory 'backend.stderr.log')
        $backendProcess.Id | Set-Content -LiteralPath (Join-Path $runtimeDirectory 'backend.pid')
        Write-Output 'Starting AI backend. Waiting for the cached models to load...'
    }

    $deadline = [DateTime]::UtcNow.AddMinutes(3)
    while (-not $health -or $health.assessmentReady -ne $true) {
        if ($backendProcess -and $backendProcess.HasExited) {
            throw 'Backend stopped. Check backend/pronunciation/.runtime/backend.stderr.log.'
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw 'Backend did not become ready in 3 minutes. Check the backend log and model setup.'
        }
        Start-Sleep -Seconds 1
        $health = Get-BackendHealth
    }
    Write-Output 'AI backend ready at http://127.0.0.1:8080. Keep it running while practicing.'
    if ($CheckBackendOnly) { return }

    Write-Output ('Opening English AI at http://localhost:' + $WebPort)
    & flutter run -d chrome --web-port $WebPort --dart-define=PRONUNCIATION_API_URL=http://127.0.0.1:8080/api/pronounce/analyze
    if ($LASTEXITCODE -ne 0) { throw 'Flutter could not start. Check the output above.' }
} finally {
    # Do not stop the backend: an already-open browser may still need to assess audio.
    Pop-Location
}
