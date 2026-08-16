# ===== 設定 =====
$inputFile  = "t.txt"
$outputFile = "B.txt"

# "UTF8" or "Default"
$fileEncoding = "UTF8"

# 00000000  E38182E381 84E381
# 00000010  86E38188E3 818A

$headLength = 10
$hex1Length = 10
$spacePos   = 20   # 0始まり

$debug = $true    # デバッグ表示 ON/OFF
# ===============

if($fileEncoding -eq "UTF8"){
    $enc = [Text.Encoding]::GetEncoding("utf-8")
} else {
    $enc = [Text.Encoding]::GetEncoding("shift_jis")
}

$decoder = $enc.GetDecoder()

function Convert-Hex($hex)
{
    if ($hex.Length -eq 0) {
        return ""
    }

    if (($hex.Length % 2) -ne 0) {
        $hex = $hex.Substring(0, $hex.Length - 1)
    }

    $bytes = for ($i=0; $i -lt $hex.Length; $i+=2) {
        [Convert]::ToByte($hex.Substring($i,2),16)
    }

    $chars = New-Object char[] ($enc.GetMaxCharCount($bytes.Length))

    $byteUsed = 0
    $charUsed = 0
    $completed = $false

    $decoder.Convert(
        $bytes,
        0,
        $bytes.Length,
        $chars,
        0,
        $chars.Length,
        $false,
        [ref]$byteUsed,
        [ref]$charUsed,
        [ref]$completed
    )

    -join $chars[0..($charUsed-1)]
}


Get-Content $inputFile | ForEach-Object {

    $line = $_

    # HEAD以上の長さがあるかつ、HEADの最後がスペースであるとき、対象とする
    if ($line.Length -gt $headLength -and $line[$headLength - 1] -eq " ") {

        $head = $line.Substring(0,$headLength)

        # 17～28文字目
        $hex1 = ""
        $len = [Math]::Min($hex1Length, $line.Length - $headLength)
        $hex1 = $line.Substring($headLength,$len)

        # 29文字目がスペースの場合
        $hex2 = ""
        $space = ""

        if ($line.Length -gt $spacePos -and $line[$spacePos] -eq " ") {

            $space = " "

            if ($line.Length -gt ($spacePos + 1)) {
                $hex2 = $line.Substring($spacePos + 1)
            }
        }

        $result = $head + (Convert-Hex $hex1) + $space + (Convert-Hex $hex2)

        # デバッグ表示
        if ($debug -and ($hex1 -ne "" -or $hex2 -ne "")) {
            Write-Host "$result"
        }

        $result
    }
    else {
        $line
    }

} | Set-Content $outputFile -Encoding $fileEncoding