@echo off

rem 管理者権限チェック
net session >nul 2>&1
if %errorlevel% == 0 (
    echo 管理者権限で実行されています。
) else (
    echo 管理者権限ではありません。UAC を表示して再実行します...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

cd "%~dp0"
powershell -Command ".\http.sysToHttps.ps1"



pause