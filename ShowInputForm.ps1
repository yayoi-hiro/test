Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-InputForm {
    param (
        [string]$JsonFile,
        [string]$Key
    )

    # JSONが存在しなければ空のJSONを作成
    if (Test-Path $JsonFile) {
        $jsonText = Get-Content $JsonFile -Raw
        if ([string]::IsNullOrWhiteSpace($jsonText)) {
            $history = @{}
        }
        else {
            $history = $jsonText | ConvertFrom-Json
        }
    }
    else {
        $history = @{}
    }

    # 指定されたキーが存在しなければ作成
    if ($null -eq $history.PSObject.Properties[$Key]) {
        $history | Add-Member -MemberType NoteProperty -Name $Key -Value @()
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Key
    $form.Size = New-Object System.Drawing.Size(400, 170)
    $form.StartPosition = "CenterScreen"
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "選択してください"
    $label.Location = New-Object System.Drawing.Point(20, 10)
    $label.Size = New-Object System.Drawing.Size(340, 20)
    $form.Controls.Add($label)

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(20, 35)
    $comboBox.Size = New-Object System.Drawing.Size(340, 25)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
    $form.Controls.Add($comboBox)

    # JSONから履歴を読み込む
    foreach ($item in @($history.$Key)) {
        [void]$comboBox.Items.Add($item)
    }
    
    # 一番上の値をデフォルト値にする
    if ($comboBox.Items.Count -gt 0) {
        $comboBox.SelectedIndex = 0
    }

    $button = New-Object System.Windows.Forms.Button
    $button.Text = "OK"
    $button.Location = New-Object System.Drawing.Point(150, 70)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($button)

    $button.Add_Click({
        $value = $comboBox.Text
        # 両端の"は削除しておく
        $value = $value.Trim('"')
        if ([string]::IsNullOrWhiteSpace($value)) {
            return
        }

        # 現在の履歴を取得
        $items = @($history.$Key)

        # 同じ値があれば削除
        $items = @($items | Where-Object { $_ -ne $value })

        # 最新値を先頭に追加
        $items = @($value) + $items

        # 最大5個に制限
        if ($items.Count -gt 5) {
            $items = @($items | Select-Object -First 5)
        }

        # JSONの値を更新
        $history.$Key = $items

        # JSON保存
        $history | ConvertTo-Json -Depth 10 | Set-Content $JsonFile -Encoding UTF8

        # 戻り値
        $form.Tag = $value

        $form.Close()
    })

    $form.ShowDialog() | Out-Null

    return $form.Tag
}

# 使用例
# $path = Join-Path $PSScriptRoot "config.json"
# $result = Show-InputForm $path "Test1"
# Write-Host "選択された値: $result"