$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$dest = $excel.Workbooks.Add()
$folder = "C:\Users\admin\Desktop\ex"

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

$dest.SaveAs("C:\Users\admin\Desktop\Result.xlsx")
$excel.Quit()

Write-Host "完了しました"
