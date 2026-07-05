$leftPath  = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file1"
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
$deleted = @()
$changed = @()
$changedTimeOnly = @()

foreach ($rel in $leftDict.Keys)
{
    if (-not $rightDict.ContainsKey($rel))
    {
    $added += [PSCustomObject]@{
        RelativePath = $rel
        Source       = Join-Path $leftPath $rel
        Target       = $leftDict[$rel].FullName
        Time         = $leftDict[$rel].LastWriteTime
        }
        continue
    }

    $left  = $leftDict[$rel]
    $right = $rightDict[$rel]
    # 更新日時で比較
    if ($left.LastWriteTime -ne $right.LastWriteTime)
    {
        $leftHash  = (Get-FileHash $left.FullName  -Algorithm SHA256).Hash
        $rightHash = (Get-FileHash $right.FullName -Algorithm SHA256).Hash
        # 内容で比較
        if ($leftHash -ne $rightHash)
        {
            # 内容も変更
            $changed += [PSCustomObject]@{
                RelativePath = $rel
                Source       = $left.FullName
                Target       = $right.FullName
                LeftTime     = $left.LastWriteTime
                RightTime    = $right.LastWriteTime
            }
        }
        else
        {
            # 更新日時だけ変更
            $changedTimeOnly += [PSCustomObject]@{
                RelativePath = $rel
                Source       = $left.FullName
                Target       = $right.FullName
                LeftTime     = $left.LastWriteTime
                RightTime    = $right.LastWriteTime
            }
        }
    }
}

foreach ($rel in $rightDict.Keys)
{
    if (-not $leftDict.ContainsKey($rel))
    {
    $deleted += [PSCustomObject]@{
        RelativePath = $rel
        Path         = $rightDict[$rel].FullName
        Time         = $rightDict[$rel].LastWriteTime
        }
    }
}

# 比較結果の表示
Write-Host "[右側のみ]"
$added |
    Sort-Object RelativePath |
    ForEach-Object {
        "{0}\{1} : ----/--/-- --:--:-- : {2:yyyy/MM/dd HH:mm:ss}" -f $rightName, $_.RelativePath, $_.Time
    }

Write-Host ""
Write-Host "[左側のみ]"
$deleted |
    Sort-Object RelativePath |
    ForEach-Object {
        "{0}\{1} : {2:yyyy/MM/dd HH:mm:ss} : ----/--/-- --:--:--" -f $leftName, $_.RelativePath, $_.Time
    }

Write-Host ""
Write-Host "[変更]"
$changed |
    Sort-Object RelativePath |
    ForEach-Object {
        "{0}\{1} : {2:yyyy/MM/dd HH:mm:ss} : {3:yyyy/MM/dd HH:mm:ss}" -f $leftName, $_.RelativePath, $_.LeftTime, $_.RightTime
    }

Write-Host ""
Write-Host "[更新日時のみ変更]"
$changedTimeOnly |
    Sort-Object RelativePath |
    ForEach-Object {
        "{0}\{1} : {2:yyyy/MM/dd HH:mm:ss} : {3:yyyy/MM/dd HH:mm:ss}" -f $leftName, $_.RelativePath, $_.LeftTime, $_.RightTime
    }