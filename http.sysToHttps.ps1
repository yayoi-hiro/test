# 管理者権限で起動する
$DnsName = Read-Host "DnsName [e.g. test.com]"

# 存在判定
$existing = Get-ChildItem cert:\LocalMachine\My | Where-Object { $_.Subject -like "*CN=$DnsName*" }

if ($existing)
{
    Write-Host "Certificate already exists: $DnsName"
    exit 1
}

# LocalMachineの個人に作成
# 有効期限10年
$cert = New-SelfSignedCertificate -DnsName $DnsName, "localhost" -CertStoreLocation "cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(10)

$OutFile = Read-Host "Output file [e.g. test.cer]"

Export-Certificate -Cert $cert -FilePath $OutFile

Write-Host "Certificate created."
Write-Host "Output: $OutFile"


# HTTPバインド
Write-Host "登録済みポート"
netsh http show sslcert | Select-String "IP:" | ForEach-Object {
 ($_ -split ":\s*", 3)[2]
}

$port = Read-Host "port number"

$GUID = New-Guid
cmd /c "netsh http add sslcert ipport=0.0.0.0:$port certhash=$($cert.Thumbprint) appid={$GUID}"


# 証明書インストール
cmd /c "certutil -addstore Root $OutFile"

#あとはリッスンと送信先アドレスをlocalhostにすればいい https://example.com:8443

