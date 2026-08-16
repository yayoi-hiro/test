@echo off
rem ps1ファイルを実行

set "ARG_FULL_PATH=%~1"

for %%f in ("%ARG_FULL_PATH%") do set "ext=%%~xf"
for %%f in ("%ARG_FULL_PATH%") do set "dirpath=%%~dpf"
if not "%ext%" == ".ps1" (
  exit 1
)

cd "%dirpath%"
echo powershell "%ARG_FULL_PATH%"
cmd /k powershell "%ARG_FULL_PATH%"

@echo on

