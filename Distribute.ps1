param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Targets
)

$dict = @{
"file.txt" = ""
}

function MoveFile($path) {
    $fileName = Split-Path $path -Leaf
    if($dict.ContainsKey($fileName)){
        Copy-Item $path $dict[$fileName]
        Write-Host "$($fileName): ok"
    }
    else {
        Write-Host "$($fileName): ng" -ForegroundColor Red
    }
}

foreach ($target in $Targets) {

    if (Test-Path $target) {
        # ファイルの場合
        if ((Get-Item $target).PSIsContainer -eq $false) {
            MoveFile $target
        }
        else {
            # ディレクトリの場合（再帰）
            Get-ChildItem $target -Recurse -File |
                ForEach-Object {
                    MoveFile $_.FullName
                }
        }

    }
    else {
        Write-Output "存在しません: $target"
    }
}
