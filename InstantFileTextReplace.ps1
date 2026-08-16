
# 直接書き換える前に実行確認版を用意したい

# fcコマンドではUTF8の比較はできない
# UTF8のファイルを書き換えるとBOMつきになる

function Replace-FileText  {
param($f, $e, $old, $new)
$t = gc $f -enc $e
$t = $t.Replace($old, $new)
sc $f -enc $e $t
}

function Replace-FileText-Test  {
param($f, $e, $old, $new)
$t = gc $f -enc $e
$t = $t.Replace($old, $new)
sc "$f.temp" -enc $e $t
fc.exe $f "$f.temp"
}

Replace-FileText-Test ".\app.log" "UTF8" "role=Use" "role=Use2"