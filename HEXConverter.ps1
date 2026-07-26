# ===== 設定 =====
$inputFile  = "A.txt"
$outputFile = "B.txt"

$headLength = 16  # HEX開始位置
$hex1Length = 12
$spacePos   = 28   # 0始まり（29文字目）

$debug = $true    # デバッグ表示 ON/OFF
# ===============

$enc = [Text.Encoding]::GetEncoding("shift_jis")

function Convert-HexSjis($hex) {

    if ($hex.Length -eq 0) {
        return ""
    }

    # HEXが奇数なら最後を残す
    if (($hex.Length % 2) -ne 0) {
        $hex = $hex.Substring(0, $hex.Length - 1)
    }

    $bytes = for($i=0; $i -lt $hex.Length; $i+=2) {
        [Convert]::ToByte($hex.Substring($i,2),16)
    }

    $enc.GetString($bytes)
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

        $result = $head + (Convert-HexSjis $hex1) + $space + (Convert-HexSjis $hex2)

        # デバッグ表示
        if ($debug -and ($hex1 -ne "" -or $hex2 -ne "")) {
            Write-Host "$result"
        }

        $result
    }
    else {
        $line
    }

} | Set-Content $outputFile