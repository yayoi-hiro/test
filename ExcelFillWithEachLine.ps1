
$cellAddress = "B1"
# 貼り付ける値
$pasteText = @"
AAA
BBB
CCC
"@

#結合セルでも使用できるように変更する

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false


# Bookループ
#フォルダ名指定
$folderPath = "C:\Users\miyuj\Desktop\ex"
$files = Get-ChildItem $folderPath -File |
         Where-Object { $_.Extension -in ".xlsx", ".xlsm", ".xls" }

## ファイル名指定
#$files = @(
#Get-Item "C:\Users\miyuj\Desktop\ex\1.xlsx"
#Get-Item "C:\Users\miyuj\Desktop\ex\2.xlsx"
#)



Write-Host "=== 変更内容 ==="

$lines = $pasteText -split "\r\n" | Where-Object { $_ -ne "" }

$count = [Math]::Min($lines.Count, $files.Count)

for ($i = 0; $i -lt $count; $i++) {

    $f = $files[$i]

    $wb = $excel.Workbooks.Open($f.FullName)
    $sh = $wb.Sheets.Item(1)

    $oldValue = $sh.Range($cellAddress).Value2
    $newValue = $lines[$i]

    Write-Host "$($f.Name) ブック, $($sh.Name) シート"
    Write-Host "    $oldValue -> $newValue"

    $wb.Close($false)

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}

$answer = Read-Host "貼り付けますか？ (y/N)"

if ($answer -eq "y") {

    for ($i = 0; $i -lt $count; $i++) {

        $f = $files[$i]

        $wb = $excel.Workbooks.Open($f.FullName)
        $sh = $wb.Sheets.Item(1)

        $sh.Range($cellAddress).Value2 = $lines[$i]

        $wb.Save()
        $wb.Close($false)

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
    }
}
else {
    Write-Host "キャンセルしました。"
}



$excel.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()