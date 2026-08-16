
function IsUTF8([byte[]]$bytes) {
    $encoding = New-Object System.Text.UTF8Encoding($false, $true)  # BOMなし, エラー時に例外

    try {
        $null = $encoding.GetString($bytes)
        return $true
    }
    catch {
        return $false
    }
}


function GetEncoding {
    param (
        [string]$path
    )

    $bytes = [System.IO.File]::ReadAllBytes($path)

    if (($bytes | Where-Object { $_ -gt 0x7F }).Count -eq 0) {
        return "Default"
    }
    elseif ($bytes.Length -ge 3 -and
            $bytes[0] -eq 0xEF -and
            $bytes[1] -eq 0xBB -and
            $bytes[2] -eq 0xBF) {
        return "UTF8WithBom"
    }
    elseif (IsUTF8 $bytes) {
        return "UTF8"
    }
    else {
        return "Default"
    }
}


function Replace-FileText {
    param($File, $Encoding, $old, $new)

if(-not (Test-Path $File)){
    Write-Host "[ERROR] ファイルが見つかりません: $File"
    exit
}
else { "Yes" }

# 一時ファイル名を自動生成
$Temp = ".\$(Split-Path $File -Leaf).after"
$Bak = "$File.bak"

if ($Encoding -eq "Auto") {
    $Encoding = GetEncoding $File
}

$WithBom = $false
if($Encoding -eq "UTF8WithBom"){
    $Encoding = "UTF8"
    $WithBom = $true
}

# 置換結果を一時ファイルへ出力
if($Encoding -eq "UTF8" -and (-not $WithBom)) {
    $text = (gc $File -Encoding UTF8) -join "`r`n"
    $text = $text.Replace($old, $new)

    [System.IO.File]::WriteAllText($Temp, $text, (New-Object System.Text.UTF8Encoding($false)))
} else {
    (gc $File -Encoding $Encoding) |
        ForEach-Object { $_.Replace($old, $new) } |
        sc $Temp -Encoding $Encoding
}

# 差分表示
if ($Encoding -eq "UTF8") {
    $Diff = Compare-Object (gc $File -Encoding UTF8) (gc $Temp -Encoding UTF8)
    Write-Host "(=>) $Temp"
    Write-Host "(<=) $File"
    $Diff | Out-Host
    $Result = if ($Diff.Count -eq 0) { 0 } else { 1 }
}
else {
    fc.exe $File $Temp
    $Result = $LASTEXITCODE
}

# 確認
switch ($Result) {
    0 {
        Write-Host "変更はありません。"
        Remove-Item $Temp
    }
    1 {
        if ((Read-Host "置き換えますか？ (Y/N)") -match '^[Yy]$') {
            if(-not (Test-Path $Bak)){
                Copy-Item $File $Bak
            }
            Move-Item $Temp $File -Force
            Write-Host "置き換えました。"
        }
        else {
            Remove-Item $Temp
            Write-Host "キャンセルしました。"
        }
    }
    default {
        Write-Host "比較中にエラーが発生しました。"
        Remove-Item $Temp
    }
}
}


#Replace-FileText `
#    -File "C:\Users\miyuj\Desktop\logput\input_utf8.txt" `
#    -Encoding "Auto" `
#    -old "画面" `
#    -new "画面2"

