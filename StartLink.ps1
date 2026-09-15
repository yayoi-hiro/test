Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# TXTファイル
$TxtFile = Join-Path $PSScriptRoot "link.txt"

# TXTファイルが存在しない場合
if (-not (Test-Path -LiteralPath $TxtFile -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show("TXTファイルが見つかりません。`r`n$TxtFile", "エラー")
    exit
}

# TXTファイル名を表示名にする
$Title = [System.IO.Path]::GetFileNameWithoutExtension($TxtFile)

# ファイルパスを読み込む
$Paths = Get-Content -LiteralPath $TxtFile -Encoding UTF8

# フォーム作成
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.StartPosition = "CenterScreen"
$form.Size = New-Object -TypeName System.Drawing.Size -ArgumentList 250, 400
$form.AutoScroll = $true

$y = 15

foreach ($Path in $Paths) {

    $Path = $Path.Trim()

    # 空行は無視
    if ([string]::IsNullOrWhiteSpace($Path)) {
        continue
    }

    # Cドライブ以外は無視
    if ($Path -notmatch '^C:\\') {
        continue
    }

    # ファイル名を表示
    $FileName = [System.IO.Path]::GetFileName($Path)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $FileName
    $label.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 15, ($y + 4)
    $label.Size = New-Object -TypeName System.Drawing.Size -ArgumentList 170, 25

    # 開くボタン
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "開く"
    $button.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 200, $y
    $button.Size = New-Object -TypeName System.Drawing.Size -ArgumentList 80, 28
    $button.Tag = $Path

    # ファイルが存在しない場合はボタンを無効化
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $button.Enabled = $false
        $label.Text = $FileName + "（存在しません）"
    }

    $button.Add_Click({
        $TargetPath = $this.Tag
        Start-Process -FilePath $TargetPath
    })

    $form.Controls.Add($label)
    $form.Controls.Add($button)

    $y += 35
}

# ファイル数に応じてフォームの高さを調整
$height = $y + 50

if ($height -gt 800) {
    $height = 800
}

$form.ClientSize = New-Object -TypeName System.Drawing.Size -ArgumentList 300, $height

# 表示
[void]$form.ShowDialog()
