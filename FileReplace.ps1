function Replace-File {
    param($File, $Source, $Encoding = "Default")
# Encodingに指定できる文字列 "Default" Shift-JIS, "UTF8" UTF-8, "BIN" Binary

    if (-not (Test-Path $File)) {
        Write-Host "[ERROR] ファイルが見つかりません: $File"
        return
    }

    if (-not (Test-Path $Source)) {
        Write-Host "[ERROR] 置換元ファイルが見つかりません: $Source"
        return
    }

    $Bak = "$File.bak"

    # 差分表示
    if ($Encoding -eq "UTF8") {
        $Diff = Compare-Object (gc $File -Encoding UTF8) (gc $Source -Encoding UTF8)
        Write-Host "(=>) $Source"
        Write-Host "(<=) $File"
        $Diff | Out-Host
        $Result = if ($Diff.Count -eq 0) { 0 } else { 1 }
    }
    elseif ($Encoding -eq "BIN") {
        fc.exe /B $File $Source | Where-Object { $_ -like 'FC:*' }
        $Result = $LASTEXITCODE
    }
    else {
        fc.exe $File $Source
        $Result = $LASTEXITCODE
    }

    switch ($Result) {
        0 {
            Write-Host "変更はありません。"
        }

        1 {
            if ((Read-Host "置き換えますか？ (Y/N)") -match '^[Yy]$') {

                if (-not (Test-Path $Bak)) {
                    Copy-Item $File $Bak
                }

                Copy-Item $Source $File -Force
                Write-Host "置き換えました。"
            }
            else {
                Write-Host "キャンセルしました。"
            }
        }

        default {
            Write-Host "比較中にエラーが発生しました。"
        }
    }
}


Replace-File `
    -File "C:\Users\miyuj\Desktop\DLLsample_7.dll" `
    -Source "C:\Users\miyuj\Desktop\DLLsample7_2.dll" `
    -Encoding "BIN"
    