$searchText = "xy"
$replaceText = "201-"

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

$num = 0
foreach ($f in $files) {

    $wb = $excel.Workbooks.Open($f.FullName)
    $sheets = $wb.Sheets

    # foreachを使うとexcelプロセスが残る場合あり
    for ($i = 1; $i -le $sheets.Count; $i++) {
        $sh = $sheets.Item($i)
        Write-Host "$($f.BaseName) : $($sh.Name)"
        
        if ($sh.Name.Contains($searchText)) {
            Write-Host "  シート: $($sh.Name)"
        }
        
        $range = $sh.UsedRange
        $cell = $range.Find($searchText)
        
        if ($cell) {
            $firstAddress = $cell.Address()
            
            do {
                Write-Host "   セル $($cell.Address()): $($cell.Value2)"
                $cell = $range.FindNext($cell)
            } while ($cell -and $cell.Address() -ne $firstAddress)
        }
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    }
    #$wb.Save()
    $wb.Close($false)

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheets) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}

# 置換処理
$answer = Read-Host "置換しますか？ (y/N)"

if ($answer -eq "y") {

    foreach ($f in $files) {

        $wb = $excel.Workbooks.Open($f.FullName)
        $sheets = $wb.Sheets

        for ($i = 1; $i -le $sheets.Count; $i++) {
            $sh = $sheets.Item($i)

            # シート名
            if ($sh.Name.Contains($searchText)) {
                $sh.Name = $sh.Name.Replace($searchText, $replaceText)
            }

            # セル
            $range = $sh.UsedRange
            $range.Replace($searchText, $replaceText) | Out-Null

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
        }

        $wb.Save()
        $wb.Close($false)

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheets) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
    }
}

$excel.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()