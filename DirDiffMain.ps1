param(
    [string]$A,
    [string]$B
)

function Get-FileInfo($Root) {
    Get-ChildItem $Root -File -Recurse | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName.Substring($Root.TrimEnd('\').Length).TrimStart('\')
            Size = $_.Length
            LastWriteTime = $_.LastWriteTime
        }
    }
}

$filesA = Get-FileInfo $A
$filesB = Get-FileInfo $B

$diff = Compare-Object $filesA $filesB -Property Path, Size, LastWriteTime

Write-Host "===== $A ====="

$diff | Where-Object SideIndicator -eq '<=' | ForEach-Object {
    Write-Host "$($_.Path)`t$($_.Size)`t$($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))"
}

Write-Host ""
Write-Host "===== $B ====="

$diff | Where-Object SideIndicator -eq '=>' | ForEach-Object {
   # Write-Host "$($_.Path)`t$($_.Size)`t$($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))"
    Write-Host "$(Split-Path $_.Path -Leaf)`t$($_.Size)`t$($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))"
}