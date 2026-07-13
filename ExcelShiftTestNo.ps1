$shiftNumber = 1

$cellAddresses = @("B1", "C3", "D5")

# =IF(B3="", "", LET(t, TRIM(B3), p, FIND(".", t), LEFT(B3, LEN(B3)-LEN(t)) & (LEFT(t, p-1)+1) & MID(t, p, 9999)))
function Shift-SequenceNumber {
    param(
        [string]$Text,
        [int]$Index,
        [int]$Offset
    )

    $result = [regex]::Replace($Text, '(\d{3})-(\d{3}|XXX)-(\d{3}|XXX)', {
        param($m)

        $numbers = @(
            $m.Groups[1].Value,
            $m.Groups[2].Value,
            $m.Groups[3].Value
        )

        if ($numbers[$Index] -notmatch '^\d{3}$') {
            return $m.Value
        }

        $numbers[$Index] = "{0:D3}" -f ([int]$numbers[$Index] + $Offset)

        "{0}-{1}-{2}" -f $numbers[0], $numbers[1], $numbers[2]
    })

    return $result
}


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

foreach ($f in $files) {

    $wb = $excel.Workbooks.Open($f.FullName)
    $sheets = $wb.Sheets

    # foreachを使うとexcelプロセスが残る場合あり
    for ($i = 1; $i -le $sheets.Count; $i++) {
        $sh = $sheets.Item($i)
        Write-Host "$($f.BaseName) : $($sh.Name)"
        
        # シート名から検索
        $sheetName = $sh.Name
        $shiftedSheetName = Shift-SequenceNumber $sheetName 1 $shiftNumber
        if($sheetName -ne $shiftedSheetName){
            Write-Host "  シート: $sheetName → $shiftedSheetName"
        }
        
        # 全セルから検索
        foreach ($address in $cellAddresses) {
            $cellValue = $sh.Range($address).Value2
            if( ![string]::IsNullOrEmpty($cellValue)) {
                $shiftedCellValue = Shift-SequenceNumber $cellValue 1 $shiftNumber
                if($cellValue -ne $shiftedCellValue) {
                    Write-Host "  セル $address : $cellValue → $shiftedCellValue"
                }
            }
        }
        
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    }
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
            $sheetName = $sh.Name
            $shiftedSheetName = Shift-SequenceNumber $sheetName 1 $shiftNumber
             if($sheetName -ne $shiftedSheetName){
                 $sh.Name = $shiftedSheetName
            }

            # セル
            foreach ($address in $cellAddresses) {
                $cellValue = $sh.Range($address).Value2
                if( ![string]::IsNullOrEmpty($cellValue)) {
                    $shiftedCellValue = Shift-SequenceNumber $cellValue 1 $shiftNumber
                    if($cellValue -ne $shiftedCellValue) {
                        $sh.Range($address).Value2 = $shiftedCellValue
                    }
                }
            }

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


