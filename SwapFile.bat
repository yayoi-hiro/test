@echo off
setlocal enabledelayedexpansion

rem --- 設定セクション ---
set "targetPath=C:\Users\miyuj\Desktop\change\filelist2.txt"
set "srcPath[1]=C:\Users\miyuj\Desktop\change\filelist2_off.txt"
set "srcPath[2]=C:\Users\miyuj\Desktop\change\filelist2_org.txt"
set "srcPath[3]=C:\Users\miyuj\Desktop\change\filelist3.txt"
set srcSize=3
rem compMode=(0:ハッシュ比較, 1:更新日時比較)
set compMode=1
rem ---------------------


for %%f in ("%targetPath%") do ( 
    set "targetFolderPath=%%~dpf"
    set "targetFileName=%%~nf"
    set "targetFileExt=%%~xf"
)
set "backupPath=%targetFolderPath%%targetFileName%_bak%targetFileExt%"
set "backupFile=%targetFileName%_bak%targetFileExt%"

if not exist "%targetPath%" (
    echo [ERROR] 対象ファイルが見つかりません: "%targetPath%"
    goto end
)
echo 置き換え対象ファイル: "%targetPath%"

rem すでにあるものと一致するかどうか
set FOUND_TARGET=0
set FOUND_BACKUP=0

if "%compMode%"=="0" (
    rem ハッシュ比較
    call :GetHash "%targetPath%" TARGET_HASH
    if exist "%backupPath%" (
        call :GetHash "%backupPath%" BACKUP_HASH
    )
    for /l %%i in (1, 1, %srcSize%) do (
        set "state="
        rem ファイルが存在しない場合は、エラー表示を取得
        call :GetHash "!srcPath[%%i]!" TO_HASH
        if "!TO_HASH!" equ "!TARGET_HASH!" (
            set FOUND_TARGET=1
            rem set "matchTargetPath=!srcPath[%%i]!"
            set "state=!state! [適用中]"
        )
        if "!TO_HASH!" equ "!BACKUP_HASH!" (
            set FOUND_BACKUP=1
            rem set "matchBackupPath=!srcPath[%%i]!"
            set "state=!state! [バックアップ中]"
        )
        echo %%i: "!srcPath[%%i]!" !state!
    )
    
) else (
    rem 更新日時比較
    for %%f in ("%targetPath%") do set TARGET_UPDATE_TIME=%%~tf
    if exist "%backupPath%" (
        for %%f in ("%backupPath%") do set BACKUP_UPDATE_TIME=%%~tf
    )
    for /l %%i in (1, 1, %srcSize%) do (
        set "state="
        rem ファイルが存在しない場合は、エラー表示を取得
        for %%f in ("!srcPath[%%i]!") do set TO_UPDATE_TIME=%%~tf
        if "!TO_UPDATE_TIME!" equ "!TARGET_UPDATE_TIME!" (
            set FOUND_TARGET=1
            rem set "matchTargetPath=!srcPath[%%i]!"
            set "state=!state! [適用中]"
        )
        if "!TO_UPDATE_TIME!" equ "!BACKUP_UPDATE_TIME!" (
            set FOUND_BACKUP=1
            rem set "matchBackupPath=!srcPath[%%i]!"
            set "state=!state! [バックアップ中]"
        )
        echo %%i: "!srcPath[%%i]!" !state!
    )
)

rem echo %matchTargetPath%
rem echo %matchBackupPath%

if %FOUND_TARGET% neq 1 (
    echo [ERROR]対象ファイルが他のファイルと一致しません。対象が変更されている可能性があります。
    goto end
)

rem 置き換え元を選択
:Loop1
set select=
set /p select="どのファイルで切り替えるか番号で指定してください。(1...%srcSize%): "
if "%select%"=="" goto Loop1
set "new=!srcPath[%select%]!"

if not exist "%new%" (
    echo ERROR: 指定されたファイルが見つかりませんでした。
    goto end
)

rem backupがある場合に一致すれば削除確認
if %FOUND_BACKUP% equ 1 (
    echo 既存のbackupファイルは一部の切り替えファイルと一致しています。
    :Loop2
    set /p ans="既存のbackupを削除しますか。[y/n]: "
    if "!ans!"=="" (
        goto Loop2
    )
    if /i "!ans!"=="y" (
        del "%backupPath%"
    )
)

rem ファイルコピー　bak作成
ren "%targetPath%" "%backupFile%" >nul 2>&1
if errorlevel 1 (
    for /l %%i in (1,1,100) do if not exist "%targetFolderPath%%targetFileName%_bak%%i%targetFileExt%" (
        set n=%%i
        goto break
    )
    :break
    ren "%targetPath%" "%targetFileName%_bak%n%%targetFileExt%" >nul
)
copy "%new%" "%targetPath%" /-y >nul
echo "%targetFileName%"を"%new%"に切り替えました。


:end
popd
pause
endlocal
exit /b


:GetHash
setlocal
set "FILE=%~1"
set "RESULT="
for /f "skip=1 tokens=1,* delims= " %%A in ('certutil -hashfile "%FILE%" SHA256') do (
    if not defined RESULT set "RESULT=%%A%%B"
)
endlocal & set "%~2=%RESULT%"
exit /b
