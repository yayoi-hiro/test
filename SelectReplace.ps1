# インポート文
. .\FileTextReplace.ps1

Write-Host "置換一覧"
Write-Host "1 : utf8で置換"
Write-Host "2 : app.logでrole=User"

$num = Read-Host "番号を入力してください"
Write-Host ""

switch ($num) {
    1 { Replace-FileText -File "C:\Users\miyuj\Desktop\logput\input_utf8.txt" -Encoding "Auto" -old "画面" -new "画面2" }
    2 { Replace-FileText -File "C:\Users\miyuj\Desktop\logput\app.log" -Encoding "Default" -old "role=Admin" -new "role=User" }
    default { Write-Host "番号が違います" }
}

