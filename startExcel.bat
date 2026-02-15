@echo off

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$path = '%1'; ^
 $excel = New-Object -ComObject Excel.Application; ^
 $excel.Visible = $true; ^
 $excel.Workbooks.Open($path)"