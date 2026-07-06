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


foreach ($f in $files) {
    
    $wb = $excel.Workbooks.Open($f.FullName)

    foreach ($sh in $wb.Sheets) {
        $sh.Copy([Type]::Missing, $dest.Sheets.Item($dest.Sheets.Count))


        $name = ($f.BaseName + "_" + $sh.Name) `
                -replace '[:\\\/\?\*\[\]]', '_'

        if ($name.Length -gt 31) {
            $name = $name.Substring(0,31)
        }

        $dest.Sheets.Item($dest.Sheets.Count).Name = $name
    }

    $wb.Close($false)
}

# 新規作成時のsheet1を削除する
if ($dest.Sheets.Count -gt 1)
{
    $dest.Sheets(1).Delete()
}

$dest.SaveAs($outputPath)
$excel.Quit()

Write-Host "完了しました"
