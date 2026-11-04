@echo off
echo ========================================================
echo  English AI - Wav2Vec2 phoneme assessment (CPU)
echo ========================================================
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Run powershell -File backend\pronunciation\setup_backend.ps1 first.
  exit /b 1
)
if not defined HOST set "HOST=127.0.0.1"
if not defined PORT set "PORT=8080"
".venv\Scripts\python.exe" -m uvicorn server:app --app-dir backend/pronunciation --host "%HOST%" --port "%PORT%"
pause

