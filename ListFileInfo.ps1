param(
    [string]$folder
)

if ([string]::IsNullOrWhiteSpace($folder)) {
    return
}

$arg1 = Read-Host "入力してください"

$arg2 = Get-Date -Format "yyyy.MM.dd"

$text = @"
$arg1
固定文字列その1
固定文字列その2
$arg2
"@

$files = Get-ChildItem -Path $folder -Recurse -File | Sort-Object Name

$i = 1

foreach ($file in $files) {
    $fileName = $file.Name.ToUpper()
    $text += "`r`nFILE$i=$fileName, $($file.DirectoryName), $($file.Length), $($file.LastWriteTime)"
    $i++
}

[System.IO.File]::WriteAllText(
    "output.txt",
    $text,
    [System.Text.Encoding]::GetEncoding(932)
)