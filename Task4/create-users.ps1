function Create-KubeUserCertificate {
    param (
        [string]$UserName,
        [string]$Organization
    )

    $cert = New-SelfSignedCertificate -Type Custom `
        -Subject "CN=$UserName/O=$Organization" `
        -KeySpec Signature `
        -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 `
        -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My"

    $certPem = "-----BEGIN CERTIFICATE-----`n"
    $certPem += [Convert]::ToBase64String($cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert), [System.Base64FormattingOptions]::InsertLineBreaks)
    $certPem += "`n-----END CERTIFICATE-----"
    [System.IO.File]::WriteAllText("$UserName.crt", $certPem)

    $privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    $privateKeyBytes = $privateKey.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
    $keyPem = "-----BEGIN PRIVATE KEY-----`n"
    $keyPem += [Convert]::ToBase64String($privateKeyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    $keyPem += "`n-----END PRIVATE KEY-----"
    [System.IO.File]::WriteAllText("$UserName.key", $keyPem)

    return $cert
}

Create-KubeUserCertificate -UserName "admin" -Organization "system:masters"
Create-KubeUserCertificate -UserName "developer" -Organization "developers"
Create-KubeUserCertificate -UserName "viewer" -Organization "viewers"

$clusterName = (kubectl config view -o json | ConvertFrom-Json).clusters[0].name

kubectl config set-credentials admin `
    --client-certificate=admin.crt `
    --client-key=admin.key `
    --embed-certs=true

kubectl config set-credentials developer `
    --client-certificate=developer.crt `
    --client-key=developer.key `
    --embed-certs=true

kubectl config set-credentials viewer `
    --client-certificate=viewer.crt `
    --client-key=viewer.key `
    --embed-certs=true

kubectl config set-context admin-context `
    --cluster=$clusterName `
    --user=admin

kubectl config set-context developer-context `
    --cluster=$clusterName `
    --user=developer

kubectl config set-context viewer-context `
    --cluster=$clusterName `
    --user=viewer
