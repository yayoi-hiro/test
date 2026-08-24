@echo off
setlocal enabledelayedexpansion

if "%~1"=="" exit /b 0
if not "%~3"=="" exit /b 0

set "FOLDER1=%~1"
set "FOLDER2=%~2"


if "%FOLDER2%"=="" (
    rem フォルダ１つ
    if not exist "%FOLDER1%\" goto ERROR
    set "FOLDER1=%FOLDER1:\=\\%"
    
    set "COMMAND=powershell -nop -f .\\DirMain.ps1 ""!FOLDER1!"""
) else (
    rem フォルダ２つ
    if not exist "%FOLDER1%\" goto ERROR
    if not exist "%FOLDER2%\" goto ERROR
    set "FOLDER1=%FOLDER1:\=\\%"
    set "FOLDER2=%FOLDER2:\=\\%"
    
    set "COMMAND=powershell -nop -f .\\DirDiffMain.ps1 ""!FOLDER1!"" ""!FOLDER2!"""
)

rem echo '%COMMAND%'
start "" "C:\Program Files (x86)\sakura\sakura.exe" "-M=Editor.ExecCommand('%COMMAND%' , 3 )" "-MTYPE=js"

exit /b 0

:ERROR
echo エラー: 引数はフォルダパスを1個または2個指定してください。
exit /b 1
