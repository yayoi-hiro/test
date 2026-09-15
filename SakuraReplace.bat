@echo off

set "targetPath=C:\test"
set "tagetFile=input_utf8bom2.txt"

call :SakuraReplaceNormal "aaaa"    "bbbb"
rem コメント行削除
call :SakuraReplaceRegex "^\s*//.*"    ""
rem 空行削除
call :SakuraReplaceRegex "^\r\n"    ""


exit /b

:SakuraReplaceNormal
"C:\Program Files (x86)\sakura\sakura.exe" -GOPT=U -GREPMODE -GKEY="%~1" -GREPR="%~2" -GFOLDER="%targetPath%" -GFILE="%tagetFile%"
exit /b


:SakuraReplaceRegex
"C:\Program Files (x86)\sakura\sakura.exe" -GOPT=UR -GREPMODE -GKEY="%~1" -GREPR="%~2" -GFOLDER="%targetPath%" -GFILE="%tagetFile%"
exit /b

rem UTF8BOMのときは先頭BOMが認識できない
rem -GOPT=U 標準出力に出力し、Grep画面にデータを表示しない コマンドラインからパイプやリダイレクトを指定することで結果を利用できます。
rem -GOPT=R 正規表現