@echo off
echo ========================================================
echo  Khoi dong Pronunciation AI Backend Server (Real STT)
echo ========================================================
cd /d "%~dp0"
dart run backend/pronunciation/bin/server.dart
pause
