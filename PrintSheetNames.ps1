$folder = "C:\Users\admin\Desktop\ex"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false

# 再帰にするときは-Recurse
$files = Get-ChildItem $folder -File |
         Where-Object { $_.Extension -in ".xlsx", ".xlsm", ".xls" }

$files | ForEach-Object {

    $wb = $excel.Workbooks.Open($_.FullName)

    foreach ($sh in $wb.Worksheets) {
        Write-Host "$($_.Name) : $($sh.Name)"
    }

    $wb.Close($false)
}

$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
