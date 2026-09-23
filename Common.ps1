Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DpiHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@

[DpiHelper]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()

function Open-Folder {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        [System.Windows.Forms.MessageBox]::Show(
            "フォルダが存在しません。`n$Path",
            "エラー"
        )
        return
    }

    Start-Process explorer.exe -ArgumentList "`"$Path`""
}

function Open-Excel {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        [System.Windows.Forms.MessageBox]::Show(
            "ファイルが存在しません。`n$Path",
            "エラー"
        )
        return
    }

    Start-Process excel.exe -ArgumentList "`"$Path`""
}

function Create-Mail {
    param(
        [string]$Subject,
        [string]$Body
    )

    $outlook = New-Object -ComObject Outlook.Application
    $mail = $outlook.CreateItem(0)

    $mail.Subject = $Subject
    $mail.Body = $Body
    $mail.Display()
}

function Show-Flow {
    param(
        [string]$Title,
        [array]$Steps
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Width = 500
    #$form.Height = 430
    $minFormHeight = 250
    $maxFormHeight = 700
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Meiryo UI", 10)
    $form.BackColor = [System.Drawing.Color]::White

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Font = New-Object System.Drawing.Font(
        "Meiryo UI",
        14,
        [System.Drawing.FontStyle]::Bold
    )
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.AutoSize = $true
    $form.Controls.Add($titleLabel)

    # ステップ表示領域
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowPanel.Location = New-Object System.Drawing.Point(10, 55)
    $flowPanel.Size = New-Object System.Drawing.Size(465, 290)
    $flowPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor `
                        [System.Windows.Forms.AnchorStyles]::Bottom -bor `
                        [System.Windows.Forms.AnchorStyles]::Left -bor `
                        [System.Windows.Forms.AnchorStyles]::Right
    $flowPanel.AutoScroll = $true
    $flowPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $flowPanel.WrapContents = $false
    $flowPanel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($flowPanel)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "未完了：$($Steps.Count) 項目"
    $statusLabel.Location = New-Object System.Drawing.Point(20, 355)
    $statusLabel.AutoSize = $true
    $statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor `
                          [System.Windows.Forms.AnchorStyles]::Left
    $form.Controls.Add($statusLabel)

    $flowPanel.Location = New-Object System.Drawing.Point(10, 55)
    $flowPanel.Size = New-Object System.Drawing.Size(465, 290)
    $flowPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor `
                        [System.Windows.Forms.AnchorStyles]::Bottom -bor `
                        [System.Windows.Forms.AnchorStyles]::Left -bor `
                        [System.Windows.Forms.AnchorStyles]::Right
    $flowPanel.AutoScroll = $true


    # 配列ではなく、同じオブジェクトを変更する
    $checkBoxes = New-Object System.Collections.ArrayList

    $number = 1

    foreach ($step in $Steps) {

        # 1ステップ分のパネル
        $stepPanel = New-Object System.Windows.Forms.Panel
        $stepPanel.Width = 440
        $stepPanel.AutoSize = $true
        $stepPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
        $stepPanel.Margin = New-Object System.Windows.Forms.Padding(5, 5, 5, 5)
        $stepPanel.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 5)

        # チェックボックス
        $checkBox = New-Object System.Windows.Forms.CheckBox
        $checkBox.Text = "$number. $($step.Text)"
        $checkBox.Location = New-Object System.Drawing.Point(5, 5)
        $checkBox.AutoSize = $true

        $stepPanel.Controls.Add($checkBox)

        [void]$checkBoxes.Add($checkBox)

        # 実行ボタン
        if ($null -ne $step.Action) {

            $button = New-Object System.Windows.Forms.Button
            $button.Text = "実行"
            $button.Width = 80
            $button.Height = 28
            $button.Location = New-Object System.Drawing.Point(350, 0)

            $action = $step.Action

            $button.Add_Click({
                & $action
            }.GetNewClosure())

            $stepPanel.Controls.Add($button)
        }

        # 説明文
        if ($null -ne $step.Description -and $step.Description -ne "") {

            $descriptionLabel = New-Object System.Windows.Forms.Label
            $descriptionLabel.Text = $step.Description
            $descriptionLabel.Location = New-Object System.Drawing.Point(25, 32)
            $descriptionLabel.AutoSize = $true

            # 横幅を超えたら自動的に折り返す
            $descriptionLabel.MaximumSize = New-Object System.Drawing.Size(390, 0)

            $stepPanel.Controls.Add($descriptionLabel)
        }

        # チェック状態変更時に未完了数を更新
        $checkBox.Add_CheckedChanged({
            $count = 0

            foreach ($item in $checkBoxes) {
                if (-not $item.Checked) {
                    $count++
                }
            }

            $statusLabel.Text = "未完了：$count 項目"
        }.GetNewClosure())

        $flowPanel.Controls.Add($stepPanel)

        $number++
    }
    

    # 終了表示
    $endLabel = New-Object System.Windows.Forms.Label
    $endLabel.Text = "------------ 終了 ------------"
    $endLabel.AutoSize = $true
    $endLabel.Margin = New-Object System.Windows.Forms.Padding(10, 10, 10, 10)
    $flowPanel.Controls.Add($endLabel)

    # 必要な高さを計算
    $flowPanel.PerformLayout()

    $requiredPanelHeight = $flowPanel.PreferredSize.Height
    $requiredFormHeight = $requiredPanelHeight + 140

    if ($requiredFormHeight -lt $minFormHeight) {
        $requiredFormHeight = $minFormHeight
    }

    if ($requiredFormHeight -gt $maxFormHeight) {
        $requiredFormHeight = $maxFormHeight
    }

    $form.Height = $requiredFormHeight


    # 完了ボタン
    $buttonClose = New-Object System.Windows.Forms.Button
    $buttonClose.Text = "完了"
    $buttonClose.Location = New-Object System.Drawing.Point(350, 355)
    $buttonClose.Width = 80
    $buttonClose.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor `
                          [System.Windows.Forms.AnchorStyles]::Right

    $buttonClose.Add_Click({
        foreach ($checkBox in $checkBoxes) {
            if (-not $checkBox.Checked) {

                [System.Windows.Forms.MessageBox]::Show(
                    "未完了の項目があります。",
                    "確認",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )

                return
            }
        }

        $form.Close()
    })

    $form.Controls.Add($buttonClose)

    $form.ShowDialog() | Out-Null
}