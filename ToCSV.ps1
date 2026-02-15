# ===== 設定 =====
$inputFile  = "C:\Users\admin\Desktop\ex\Result.xlsx"
$outputDir  = "C:\Users\admin\Desktop\ex"

# 出力フォルダが無ければ作成
if (-not (Test-Path $outputDir)) {
    Write-Host "出力フォルダがありません"
    exit
}

# Excel起動
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false   # 上書き確認を出さない

# Excel COMのCSVは Shift-JIS で作成する

try {

    # ブックを開く
    $wb = $excel.Workbooks.Open($inputFile)

    # 全シート処理
    foreach ($sh in $wb.Sheets) {

        # シートをアクティブに
        $sh.Activate()

        # ファイル名に使えない文字を置換
        $safeName = $sh.Name -replace '[\\/:*?"<>|]', '_'

        # 出力CSVパス
        $csvPath = Join-Path $outputDir ($safeName + ".csv")

        # CSV保存 (6 = xlCSV)
        $wb.SaveAs($csvPath, 6)

        Write-Host "出力: $csvPath"
    }

    # ブックを閉じる
    $wb.Close($false)
}
finally {
    # Excel終了
    $excel.Quit()

    # COM解放
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Host "=== 完了 ==="
