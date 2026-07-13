#################################################################################
# 処理名　｜DiffTextfile
# 機能　　｜テキスト形式のファイルを比較(Shift-JISとUTF-8のBOMつきが読める、UTF-8を読み込むときGet-Contentで -Encoding UTF8を指定する)
#--------------------------------------------------------------------------------
# 戻り値　｜-
# 引数　　｜fromfile：比較元ファイル、tofile：比較先ファイル
# 　　　　　(任意)full：-Full指定で全ての差異表示
#################################################################################
function DiffTextfile {
    param (
        [System.String]$fromfile,
        [System.String]$tofile,
        [Switch]$full
    )
    [System.Int32]$maxrow = 27
    [System.Int32]$rowcount = 0
  
    # ウィンドウサイズの変更
 #   If (-Not $c_debug) {
 #       [System.Management.Automation.Host.PSHostRawUserInterface]$userinterface = $host.UI.RawUI
 #       [System.ValueType]$windowsize = $userinterface.WindowSize
 #       $userinterface.WindowSize = New-Object System.Management.Automation.Host.Size(120,30)
 #   }
  
    # エンコーディングを決定
    $encoding = if ([System.IO.Path]::GetExtension($fromfile).ToLower() -eq ".xml") {
        "UTF8"
    } else {
        "Default"    # Shift_JIS（Windowsの既定コードページ）
    }
  
    # 比較処理
    # Compare-Objectでは行の並びは保存されない
    [System.String]$line = ""
    [System.String]$forecolor = ""
    Compare-Object (Get-Content $fromfile -Encoding $encoding) (Get-Content $tofile -Encoding $encoding) -IncludeEqual:$full  |
        ForEach-Object {
        if ($_.SideIndicator -eq "=>")
        {
            # 修正後に存在する行（追加または変更された行）
            $line = "[ + ] " + $_.InputObject
            $forecolor = "Red"
        } elseif ($_.SideIndicator -eq "<=") {
            # 修正後に存在しない行（削除または変更された行）
            $line = "[ - ] " + $_.InputObject
            $forecolor = "DarkGray"
        } elseif ($full) {
            # 変更がない行
            $line = "[ = ] " + $_.InputObject
            $forecolor = "White"
        }
        Write-Host $line -ForegroundColor $forecolor
        $rowcount++
        # 最大行数まで達した場合、画面を一時停止
        if ($rowcount -ge $maxrow) {
            $rowcount = 0
            Write-Host ''
            Read-Host ' --- 次のページへ [ Enter ] / 中断 [ Ctrl + C ] --- '
        }
    }
    # ウィンドウサイズの戻し
#    Write-Host ''
#    Write-Host '--- 比較終了 [ Enter ] ---'
#    Read-Host | Out-Null
#    if (-Not $c_debug) {
#        $userinterface.WindowSize = $windowsize
#    }
}


$fromRoot = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file1\tes"
$toRoot   = "C:\Users\miyuj\Desktop\比較2"

Get-ChildItem $fromRoot -File | ForEach-Object {

    $fromFile = $_.FullName
    $toFile   = Join-Path $toRoot $_.Name

    if (-not (Test-Path $toFile)) {
        Write-Host "存在しません: $toFile" -ForegroundColor Yellow
        return
    }
    Write-Host ""
    Write-Host "===== $($_.Name) =====" -ForegroundColor Cyan

    DiffTextfile -fromfile $fromFile -tofile $toFile
}


