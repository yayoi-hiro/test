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

foreach ($rel in $leftDict.Keys)
{
    if (-not $rightDict.ContainsKey($rel))
    {
        $deleted += [PSCustomObject]@{
            RelativePath = $rel
            Path         = $leftDict[$rel].FullName
        }
        continue
    }

    $left  = $leftDict[$rel]
    $right = $rightDict[$rel]
# サイズと更新日時で比較
    if ($left.Length -ne $right.Length -or
        $left.LastWriteTime -ne $right.LastWriteTime)
    {
        $changed += [PSCustomObject]@{
            RelativePath = $rel
            Source       = $left.FullName
            Target       = $right.FullName
        }
    }
}

foreach ($rel in $rightDict.Keys)
{
    if (-not $leftDict.ContainsKey($rel))
    {
        $added += [PSCustomObject]@{
            RelativePath = $rel
            Source       = Join-Path $leftPath $rel
            Target       = $rightDict[$rel].FullName
        }
    }
}

# 比較結果の表示
Write-Host "[追加]"
$added |
    Sort-Object RelativePath |
    ForEach-Object { "$rightName\$($_.RelativePath)" }

Write-Host ""
Write-Host "[削除]"
$deleted |
    Sort-Object RelativePath |
    ForEach-Object { "$leftName\$($_.RelativePath)" }

Write-Host ""
Write-Host "[変更]"
$changed |
    Sort-Object RelativePath |
    ForEach-Object { "$leftName\$($_.RelativePath)" }


Write-Host ""
$answer = Read-Host "追加・変更ファイルをコピーしますか？ [y/N]"

if ($answer -notmatch '^[Yy]$')
{
    Write-Host "処理を中止しました。"
    Pause
    exit
}

Write-Host ""

# 追加分コピー
foreach ($item in $added)
{
    $parent = Split-Path $item.Source -Parent

    if (!(Test-Path $parent))
    {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Copy-Item $item.Target $item.Source -Force
    Write-Host "[追加コピー] $leftName\$($item.RelativePath)"
}


# 変更分コピー(バックアップあり)
$backupRoot = Join-Path (Split-Path $leftPath -Parent) "backup"

foreach ($item in $changed)
{
    $rel = $item.RelativePath

    $backupFile = Join-Path $backupRoot $rel
    $backupDir  = Split-Path $backupFile -Parent

    if (!(Test-Path $backupDir))
    {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    Copy-Item $item.Source $backupFile -Force

    Copy-Item $item.Target $item.Source -Force
    Write-Host "[変更コピー] $rightName\$($item.RelativePath)"
    Write-Host "             → $leftName\$($item.RelativePath)"
}


