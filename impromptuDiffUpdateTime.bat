@echo off
setlocal enabledelayedexpansion
set "A=C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file1"
set "B=C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file2"

cd %~dp0
del A.txt
del B.txt
for /r "%A%" %%f in (*) do  ( 
set "p=%%~f"
set "p=!p:~47!"
echo !p! %%~tf>>A.txt
)
for /r "%B%" %%f in (*) do  ( 
set "p=%%~f"
set "p=!p:~47!"
echo !p! %%~tf>>B.txt
)

rem fc A.txt B.txt
powershell -nop "diff (gc 'A.txt') (gc 'B.txt') | ? SideIndicator -eq '<=' "


pause