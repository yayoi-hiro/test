$FOLDER=$args[0]
Get-ChildItem $FOLDER -File -Recurse | ForEach-Object {
#    "$($_.FullName)`t$($_.Length)`t$($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))"
    "$($_.Name)`t$($_.Length)`t$($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))"
}