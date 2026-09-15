$path = "C:\Users\miyuj\Desktop\プログラミング\★作成物\batファイル\FileInfo\CountCodeSteps\res3.txt"

$content = Get-Content -Path $path -Raw -Encoding Default
# 反対の変更を削除
$content = $content -replace "(?m)^[^<].*", ""

# コメント行削除
$content = $content -replace "(?m)^<\s*//.*", ""

# 空行の変更を削除
$content = $content -replace "(?m)^<\s*$", ""

# 空行の削除
$content = $content -replace "(?m)^\s*\r?\n", ""

Set-Content -Path $path -Value $content -Encoding Default