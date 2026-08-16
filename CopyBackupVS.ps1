. .\ShowInputForm.ps1

# powershell.exe "CopyBackupVS.ps1" $(ItemPath) として実行

if ($args.Count -eq 0) {
    exit
}
$filePath = $args[0]

$path = Join-Path $PSScriptRoot "CopyBackupVS-config.json"
$targetPath = Show-InputForm $path $filePath

if ($null -eq $targetPath) {
    exit
}

# コピー先に同名ファイルがないか確認
$dstFile = Join-Path $targetPath (Split-Path $filePath -Leaf)
if (Test-Path $dstFile) {
    [System.Windows.Forms.MessageBox]::Show("既にファイルが存在します。`r`n$dstFile", "確認")
}
else {
    Copy-Item $filePath $targetPath
}

