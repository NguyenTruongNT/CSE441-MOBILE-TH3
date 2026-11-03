$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$pythonEnvironment = Join-Path $projectRoot '.venv/Scripts/python.exe'
Push-Location $projectRoot
try {
    if (-not (Test-Path -LiteralPath $pythonEnvironment)) {
        python -m venv .venv
        if ($LASTEXITCODE -ne 0) { throw 'Could not create Python environment.' }
    }
    $lockedTorch = Get-Content backend/pronunciation/requirements.lock.txt | Where-Object { $_ -match '^torch==' } | Select-Object -First 1
    if (-not $lockedTorch) { throw 'Missing pinned PyTorch version.' }
    & $pythonEnvironment -m pip install $lockedTorch --index-url https://download.pytorch.org/whl/cpu
    if ($LASTEXITCODE -ne 0) { throw 'PyTorch installation failed.' }
    & $pythonEnvironment -m pip install -r backend/pronunciation/requirements.lock.txt
    if ($LASTEXITCODE -ne 0) { throw 'Backend dependency installation failed.' }
    & $pythonEnvironment backend/pronunciation/engine.py
    if ($LASTEXITCODE -ne 0) { throw 'Model download or load failed. Check network and free memory.' }
    Write-Output 'Backend ready. Run .\run_backend.bat from the project root.'
} finally {
    Pop-Location
}
