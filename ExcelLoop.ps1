$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

<#
# Bookループ
#フォルダ名指定
$folderPath = "C:\Users\miyuj\Desktop\ex"
$files = Get-ChildItem $folderPath -File |
         Where-Object { $_.Extension -in ".xlsx", ".xlsm", ".xls" }

# ファイル名指定
$files = @(
Get-Item "C:\Users\miyuj\Desktop\ex\1.xlsx"
Get-Item "C:\Users\miyuj\Desktop\ex\12.xlsx"
)

foreach ($f in $files) {

    $wb = $excel.Workbooks.Open($f.FullName)
    $sheets = $wb.Sheets

    # foreachを使うとexcelプロセスが残る場合あり
    for ($i = 1; $i -le $sheets.Count; $i++) {
        $sh = $sheets.Item($i)

        Write-Host "$($f.BaseName) : $($sh.Name)"

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    }

    $wb.Close($false)

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheets) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}

#>

<#
# Sheetループ
$filePath = "C:\Users\miyuj\Desktop\ex\1.xlsx"
$file = Get-Item $filePath
$wb = $excel.Workbooks.Open($file.FullName)
$sheets = $wb.Sheets

for ($i = 1; $i -le $sheets.Count; $i++) {
    $sh = $sheets.Item($i)

    Write-Host "$($file.BaseName) : $($sh.Name)"

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
}

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheets) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
#>

<#
# Rowループ
$filePath = "C:\Users\miyuj\Desktop\ex\1.xlsx"
$sheetName = "表検索"
$column = 1    # A列なら1、B列なら2

$wb = $excel.Workbooks.Open($filePath)
$sh = $wb.Sheets.Item($sheetName)

for ($r = 1; $r -le $sh.UsedRange.Rows.Count; $r++) {
    Write-Host $sh.Cells.Item($r, $column).Value2
}

$wb.Close($false)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
#>



$excel.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()