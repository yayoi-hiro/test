Add-Type -AssemblyName System.Windows.Forms


try 
{
    # フォルダ選択
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "フォルダを選択してください"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK)
    {
        exit
    }

    $folderPath = $dialog.SelectedPath

    $dest = Join-Path $folderPath "html_output.xlsx"

    if (Test-Path $dest)
    {
        Write-Host "すでに出力ファイルが存在します"
        Write-Host "何かキーを押してください..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $wbTo = $excel.Workbooks.Add()
    $wbTo.SaveAs($dest, 51)
    $wbTo.Close($false)
    $excel.Quit()

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $wbTo = $excel.Workbooks.Open($dest)

    Get-ChildItem $folderPath -Filter *.html | ForEach-Object {

        $htmlFile = $_.FullName

        Write-Host $htmlFile

        $wbFrom = $excel.Workbooks.Open($htmlFile)

        # シートコピー
        $wbFrom.Sheets(1).Copy(
            [System.Type]::Missing,
            $wbTo.Sheets($wbTo.Sheets.Count)
        )

        # シート名設定
        $sheetName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)

        if ($sheetName.Length -gt 31)
        {
            $sheetName = $sheetName.Substring(0, 31)
        }

        $wbTo.Sheets($wbTo.Sheets.Count).Name = $sheetName

        $wbFrom.Close($false)

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wbFrom) | Out-Null
    }

    # 新規作成時のsheet1を削除する
    if ($wbTo.Sheets.Count -gt 1)
    {
        $wbTo.Sheets(1).Delete()
    }
    
    $wbTo.Save()

        Write-Host ""
        Write-Host "完了:"
        Write-Host $dest
}
finally
{
    if ($wbTo -ne $null)
    {
        $wbTo.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wbTo) | Out-Null
    }

    if ($excel -ne $null)
    {
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}