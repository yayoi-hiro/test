
$cellAddresses = @("B1", "C3", "D5")



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



Write-Host "=== セル内容 ==="


$count = $files.Count

for ($i = 0; $i -lt $count; $i++) {

    $f = $files[$i]

    $wb = $excel.Workbooks.Open($f.FullName)
    # 1シート目固定
    $sh = $wb.Sheets.Item(1)

    Write-Host "$($f.Name) ブック, $($sh.Name) シート"

    foreach ($address in $cellAddresses) {
        $value = $sh.Range($address).Value2
        Write-Host "    $address : $value"
    }

    $wb.Close($false)

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}



$excel.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()