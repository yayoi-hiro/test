$certs = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object HasPrivateKey

for($i=0; $i -lt $certs.Count; $i++)
{
    Write-Host "$($i+1) : $($certs[$i].Subject)"
}

$input = Read-Host "Delete index"

$index = 0
if ([int]::TryParse($input, [ref]$index) -and
    $index -ge 1 -and
    $index -le $certs.Count)
{
    $index = $index - 1
}
else
{
    Write-Host "1～$($certs.Count) の整数を入力してください"
    exit 1
}

Remove-Item $certs[$index].PSPath

Write-Host "[$($certs[$index].Subject)] is Deleted"

# ipポート登録削除
$thumb = $certs[$index].Thumbprint.Replace(' ', '').ToLower()

$ipport = $null
foreach ($line in (netsh http show sslcert))
{

    if ($line.Contains($thumb))
    {
        netsh http delete sslcert ipport=$ipport
        Write-Host "[$ipport] is Deleted"
        
        break
    }

    if ($line -like '*IP:*')
    {
        $ipport = ($line -split ':\s*', 3)[2]
        
    }
}

#証明書削除
cmd /c "certutil -delstore Root $thumb"

