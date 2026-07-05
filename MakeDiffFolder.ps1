#変更前
$leftPath  = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file1"
#変更後
$rightPath = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\file2"
#出力先
$newRoot = "C:\Users\miyuj\Desktop\プログラミング\素材\フォルダ比較\new"

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
    # サイズで比較
    if ($left.Length -ne $right.Length)
    {
        $changed += [PSCustomObject]@{
            RelativePath = $rel
            Source       = $left.FullName
            Target       = $right.FullName
        }
    # 更新日時で比較
    } elseif ($left.LastWriteTime -eq $right.LastWriteTime) {
        # サイズも更新日時も同じ → 変更なし
        continue
    # サイズは同じだが更新日時が異なるため、内容を比較
    } else {
        $leftHash  = (Get-FileHash $left.FullName  -Algorithm SHA256).Hash
        $rightHash = (Get-FileHash $right.FullName -Algorithm SHA256).Hash
        if ($leftHash -ne $rightHash)
        {
            # 内容も変更
            $changed += [PSCustomObject]@{
                RelativePath = $rel
                Source       = $left.FullName
                Target       = $right.FullName
            }
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

# $newRoot = Join-Path (Split-Path $leftPath -Parent) "new"

# 追加分コピー
foreach ($item in $added)
{
    $dst = Join-Path $newRoot $item.RelativePath
    $parent = Split-Path $dst -Parent

    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    Copy-Item $item.Target $dst -Force

    # Write-Host "[追加コピー] $rightName\$($item.RelativePath)"
    # Write-Host "             → new\$($item.RelativePath)"
}

# 変更分コピー
foreach ($item in $changed)
{
    $dst = Join-Path $newRoot $item.RelativePath
    $parent = Split-Path $dst -Parent

    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    Copy-Item $item.Target $dst -Force

    # Write-Host "[変更コピー] $rightName\$($item.RelativePath)"
    # Write-Host "             → new\$($item.RelativePath)"
}
