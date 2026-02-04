@echo off
cd %~dp0
powershell -ExecutionPolicy RemoteSigned -File Distribute.ps1 %*
pause