$folder = "C:\Users\admin\Desktop\ex"
$outFile = "C:\Users\admin\Desktop\ex\Result.xlsx"

# 出力先が開かれている場合は中断したい
# 出力ファイルが存在する場合
if (Test-Path $outFile) {

    try {
        # 排他オープンできるか試す
        $stream = [System.IO.File]::Open(
            $outFile,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        $stream.Close()
    }
    catch {
        Write-Host "エラー: $outFile は現在開かれています。閉じてから再実行してください。"
        exit
    }
}



$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$outBook  = $excel.Workbooks.Add()
$outSheet = $outBook.Sheets(1)

# 対象Excel取得
$files = Get-ChildItem $folder -File |
         Where-Object Extension -in ".xlsx", ".xlsm", ".xls"

$colOut = 1   # 書き込み先の列

foreach ($file in $files) {

    $wb = $excel.Workbooks.Open($file.FullName)

    foreach ($sh in $wb.Sheets) {

        # --- B列の最終行 ---
        $lastRow = $sh.Cells($sh.Rows.Count,2).End(-4162).Row
        Write-Host "$($file.BaseName)_$($sh.Name):$lastRow"

        # --- List作成 ---
        $list = New-Object System.Collections.Generic.List[object]

        # 1行目：シート名
        $list.Add("$($file.BaseName)_$($sh.Name)")

        if ($lastRow -ge 1) {
            $values = $sh.Range("B1:B$lastRow").Value2

            foreach ($v in $values) {
                if ($null -ne $v -and $v -ne "") {
                    $list.Add($v)
                }
            }
        }

        # --- List → 2次元配列 ---
        $rowCount = ($list.Count)
        $data = [System.Object[,]]::new($rowCount,1)

        for ($i=0; $i -lt $rowCount; $i++) {
            $data[$i,0] = $list[$i]
        }

        # --- 一括貼り付け ---
        if ($rowCount -gt 0) {
            $outSheet.Cells(1,$colOut).Resize($rowCount,1).Value2 = $data
        }

        $colOut++
    }

    $wb.Close($false)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}

$outBook.SaveAs($outFile)
$outBook.Close()
$excel.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($outSheet) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($outBook) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Host "完了: $outFile"

