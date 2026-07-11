# 対象フォルダ
$folder = "C:\Users\miyuj\Desktop\ex"
# 出力先エクセル名
$outputPath = "C:\Users\miyuj\Desktop\output.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$dest = $excel.Workbooks.Add()

$files = Get-ChildItem $folder -File |
         Where-Object { $_.Extension -in ".xlsx", ".xlsm", ".xls" }

# 使用済みシート名を管理
$sheetNameTable = @{}

foreach ($f in $files) {

    $wb = $excel.Workbooks.Open($f.FullName)
    $sheets = $wb.Sheets

    # foreachを使うとexcelプロセスが残る場合あり
    for ($i = 1; $i -le $sheets.Count; $i++) {
        $sh = $sheets.Item($i)
    
        Write-Host "$($f.Name) ブック, $($sh.Name) シート"
    
        $sh.Copy([Type]::Missing, $dest.Sheets.Item($dest.Sheets.Count))

        $baseName = ($f.BaseName + "_" + $sh.Name) `
                    -replace '[:\\\/\?\*\[\]]', '_'

        # Excelシート名は31文字まで
        if ($baseName.Length -gt 31) {
            $baseName = $baseName.Substring(0,31)
        }

        $name = $baseName

        if ($sheetNameTable.ContainsKey($baseName)) {
            $sheetNameTable[$baseName]++

            do {
                $suffix = "_" + $sheetNameTable[$baseName]

                # 31文字以内に収める
                $maxBaseLength = 31 - $suffix.Length
                $trimmedBase = $baseName
                if ($trimmedBase.Length -gt $maxBaseLength) {
                    $trimmedBase = $trimmedBase.Substring(0, $maxBaseLength)
                }

                $name = $trimmedBase + $suffix

            } while ($sheetNameTable.ContainsKey($name))

            $sheetNameTable[$name] = 1
        }
        else {
            $sheetNameTable[$baseName] = 1
        }

        $dest.Sheets.Item($dest.Sheets.Count).Name = $name
         [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    }

    $wb.Close($false)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheets) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
}

# 新規作成時のsheet1を削除する
if ($dest.Sheets.Count -gt 1)
{
    $dest.Sheets(1).Delete()
}

$dest.SaveAs($outputPath)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($dest) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

[GC]::Collect()
[GC]::WaitForPendingFinalizers()


Write-Host "完了しました"
