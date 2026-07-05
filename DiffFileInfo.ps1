#変更前
$leftPath  = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file1"
#変更後
$rightPath = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file2"

$leftFiles  = Get-ChildItem $leftPath -Recurse -File
$rightFiles = Get-ChildItem $rightPath -Recurse -File

$leftName  = Split-Path $leftPath -Leaf
$rightName = Split-Path $rightPath -Leaf

$leftDict = @{}
foreach ($f in $leftFiles) {
    $rel = $f.FullName.Substring($leftPath.Length).TrimStart('\')
    $leftDict[$rel] = $f
}

$rightDict = @{}
foreach ($f in $rightFiles) {
    $rel = $f.FullName.Substring($rightPath.Length).TrimStart('\')
    $rightDict[$rel] = $f
}

$added   = @()
# $deleted = @()
$changed = @()

foreach ($rel in $leftDict.Keys)
{
    if (-not $rightDict.ContainsKey($rel))
    {
    $added +=  $leftDict[$rel]
    continue
    }

    $left  = $leftDict[$rel]
    $right = $rightDict[$rel]
    # 更新日時で比較
    if ($left.LastWriteTime -ne $right.LastWriteTime)
    {
     $changed += $left 
    }
}

# foreach ($rel in $rightDict.Keys)
# {
#     if (-not $leftDict.ContainsKey($rel))
#     {
#     $deleted += [PSCustomObject]@{
#         RelativePath = $rel
#         Path         = $rightDict[$rel].FullName
#         Time         = $rightDict[$rel].LastWriteTime
#         }
#     }
# }

# 比較結果の表示
Write-Host "[右側のみ]"
$added |
    ForEach-Object {
         "{0},{1:yyyy/MM/dd},{2:HH:mm:ss},{3}" -f $_.Name, $_.LastWriteTime, $_.LastWriteTime, $_.Length
    }

# Write-Host ""
# Write-Host "[左側のみ]"
# $deleted |
#     Sort-Object RelativePath |
#     ForEach-Object {
#         "{0}\{1} : {2:yyyy/MM/dd HH:mm:ss} : ----/--/-- --:--:--" -f $leftName, $_.RelativePath, $_.Time
#     }

Write-Host ""
Write-Host "[変更]"
$changed |
    ForEach-Object {
         "{0},{1:yyyy/MM/dd},{2:HH:mm:ss},{3}" -f $_.Name, $_.LastWriteTime, $_.LastWriteTime, $_.Length
    }
