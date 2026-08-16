Add-Type -AssemblyName System.Windows.Forms

# フォルダ選択
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "ファイルを集めるフォルダを選択してください"
$dialog.ShowNewFolderButton = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    exit
}

$root = $dialog.SelectedPath

# すべてのファイルを取得
$files = @(Get-ChildItem -Path $root -File -Recurse)

# ファイル名の重複を確認
$duplicates = @($files | Group-Object Name | Where-Object Count -gt 1)

# 移動先の情報を作成
$moveList = foreach ($file in $files) {

    # ルート直下のファイルは移動しない
    if ($file.Directory.FullName -eq $root) {
        continue
    }

    $isDuplicate = $duplicates.Name -contains $file.Name

    if ($isDuplicate) {
        # 相対パスを取得
        $relative = $file.FullName.Substring($root.Length).TrimStart('\')

        # \ を _ に変換
        $newName = $relative -replace '\\', '_'
    }
    else {
        $newName = $file.Name
    }

    [PSCustomObject]@{
        File        = $file
        Relative    = $file.FullName.Substring($root.Length).TrimStart('\')
        Destination = Join-Path $root $newName
        NewName     = $newName
    }
}

# 移動先ファイル名の重複を確認
$destinationDuplicates = @(
    $moveList |
    Group-Object NewName |
    Where-Object Count -gt 1
)

# 既存ファイルとの衝突を確認
$existingConflicts = @(
    $moveList |
    Where-Object { Test-Path -LiteralPath $_.Destination }
)

# 衝突がある場合
if ($destinationDuplicates.Count -gt 0 -or $existingConflicts.Count -gt 0) {

    $message = "移動先でファイル名の衝突が発生します。`r`n`r`n"

    if ($destinationDuplicates.Count -gt 0) {
        $message += "【リネーム後の名前が重複】`r`n"

        foreach ($group in $destinationDuplicates) {
            $message += "  $($group.Name)`r`n"

            foreach ($item in $group.Group) {
                $message += "    $($item.Relative)`r`n"
            }

            $message += "`r`n"
        }
    }

    if ($existingConflicts.Count -gt 0) {
        $message += "【移動先に既に存在するファイル】`r`n"

        foreach ($item in $existingConflicts) {
            $message += "  $($item.Relative) → $($item.NewName)`r`n"
        }

        $message += "`r`n"
    }

    $message += "ファイルを移動せずに処理を中止します。"

    [System.Windows.Forms.MessageBox]::Show(
        $message,
        "FlattenFolder - ファイル名衝突",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    exit
}

# 同名ファイルがあった場合の確認
if ($duplicates.Count -gt 0) {

    $message = "同名ファイルが見つかりました。`r`n`r`n"
    $message += "以下の名前にリネームして移動します。`r`n`r`n"

    foreach ($group in $duplicates) {
        $message += "【$($group.Name)】`r`n"

        foreach ($file in $group.Group) {

            if ($file.Directory.FullName -eq $root) {
                continue
            }

            $relative = $file.FullName.Substring($root.Length).TrimStart('\')
            $newName = $relative -replace '\\', '_'

            $message += "  $relative → $newName`r`n"
        }

        $message += "`r`n"
    }

    $message += "実行しますか？"

    $result = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "FlattenFolder - 確認",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit
    }
}

# ファイルを移動
foreach ($item in $moveList) {
    Move-Item -LiteralPath $item.File.FullName -Destination $item.Destination
}

[System.Windows.Forms.MessageBox]::Show(
    "$($moveList.Count) 個のファイルを移動しました。",
    "FlattenFolder",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)