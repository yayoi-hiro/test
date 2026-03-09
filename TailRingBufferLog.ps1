$path = "C:\Users\miyuj\source\repos\ObjectHandle\x64\Debug\test.log"

$HEADER_SIZE = 9
$FILE_SIZE = 1024

$fs = [System.IO.File]::Open($path,'Open','Read','ReadWrite')
$br = New-Object System.IO.BinaryReader($fs)

$headerBytes = $br.ReadBytes(8)
$headerText = [System.Text.Encoding]::ASCII.GetString($headerBytes)

$startPos = [Convert]::ToInt32($headerText,16)

$br.Close()
$fs.Close()

#$lastPos = $HEADER_SIZE

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = [System.IO.Path]::GetDirectoryName($path)
$fsw.Filter = [System.IO.Path]::GetFileName($path)
$fsw.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw Changed -Action {

    Start-Sleep -Milliseconds 50
    
    $fs = [System.IO.File]::Open($path,'Open','Read','ReadWrite')
    $br = New-Object System.IO.BinaryReader($fs)

    # ヘッダ読む（HEX文字列）
    $headerBytes = $br.ReadBytes(8)
    $headerText = [System.Text.Encoding]::ASCII.GetString($headerBytes)

    $writePos = [Convert]::ToInt32($headerText,16)

    if ($writePos -lt $HEADER_SIZE -or $writePos -ge $FILE_SIZE)
    {
        $writePos = $HEADER_SIZE
    }
    
    if (-not $script:initialized)
    {
        $script:lastPos = $startPos
        $script:initialized = $true
    }

    if ($writePos -ge $script:lastPos)
    {
        $size = $writePos - $script:lastPos

        $fs.Seek($script:lastPos, [System.IO.SeekOrigin]::Begin) | Out-Null
        $data = $br.ReadBytes($size)

        $text = [System.Text.Encoding]::UTF8.GetString($data)
        Write-Host $text -NoNewline
    }
    else
    {
        # リングバッファ巻き戻り
        $size1 = $FILE_SIZE - $script:lastPos
        $fs.Seek($script:lastPos, [System.IO.SeekOrigin]::Begin) | Out-Null
        $data1 = $br.ReadBytes($size1)

        $fs.Seek($HEADER_SIZE, [System.IO.SeekOrigin]::Begin) | Out-Null
        $data2 = $br.ReadBytes($writePos - $HEADER_SIZE)

        $text1 = [System.Text.Encoding]::UTF8.GetString($data1)
        $text2 = [System.Text.Encoding]::UTF8.GetString($data2)

        Write-Host ($text1 + $text2) -NoNewline
    }

    $script:lastPos = $writePos

    $br.Close()
    $fs.Close()
} | Out-Null

Write-Host "監視開始"
while ($true) { Start-Sleep 1 }