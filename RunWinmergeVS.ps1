. .\ShowInputForm.ps1

# powershell.exe "RunWinmergeVS.ps1" $(ProjectDir) として実行

if ($args.Count -eq 0) {
    exit
}
$projectPath = $args[0]

$path = Join-Path $PSScriptRoot "config.json"
$TargetPath = Show-InputForm $path $projectPath

if ($null -eq $TargetPath) {
    exit
}

& "C:\Program Files\WinMerge\WinMergeU.exe" $projectPath $TargetPath /r /x -wr -cfg Settings/DirViewExpandSubdirs=1