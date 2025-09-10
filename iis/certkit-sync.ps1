# These values come from the CertKit UI
$CERTKIT_S3_ACCESS_KEY = ""
$CERTKIT_S3_SECRET_KEY = ""
$CERTKIT_S3_BUCKET = ""

# These values will need to be configured on a per certificate/site basis
$CERTKIT_CERTIFICATE_DOMAIN = "*.example.com"
$IIS_SITE_NAME = "ExampleWebSite"
$IIS_HOST_HEADER = "www.example.com"


if ($CERTKIT_CERTIFICATE_DOMAIN.StartsWith("*.")) {
    # Wildcard case
    $S3_FOLDER_NAME = $CERTKIT_CERTIFICATE_DOMAIN.Substring(2)      # "example.com"
    $CERT_BASENAME = "wildcard.$($S3_FOLDER_NAME)"                  # "wildcard.example.com"
} else {
    # Normal case
    $S3_FOLDER_NAME = $CERTKIT_CERTIFICATE_DOMAIN                   # "sub.example.com"
    $CERT_BASENAME = $CERTKIT_CERTIFICATE_DOMAIN                    # "sub.example.com"
}

$DESTINATION_PFX_FILE = ".\$CERT_BASENAME.pfx"

$mcPath = ".\mc.exe"
if (-Not (Test-Path $mcPath)) {
    Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" -OutFile $mcPath
}

# Sync PFX from CertKit
& $mcPath alias set certkit https://storage.certkit.io $CERTKIT_S3_ACCESS_KEY $CERTKIT_S3_SECRET_KEY
& $mcPath cp "certkit/$CERTKIT_S3_BUCKET/$S3_FOLDER_NAME/$CERT_BASENAME.pfx" "$DESTINATION_PFX_FILE"

if (-Not (Test-Path $DESTINATION_PFX_FILE)) { throw "Download failed." }

# Import new cert into store
$newCert = Import-PfxCertificate -FilePath $DESTINATION_PFX_FILE -CertStoreLocation "Cert:\LocalMachine\My" -Password (ConvertTo-SecureString $CERTKIT_S3_SECRET_KEY -AsPlainText -Force)

# Find IIS binding
Import-Module WebAdministration
$binding = Get-WebBinding -Name $IIS_SITE_NAME -Protocol "https" -Port 443

# Get current bound cert thumbprint (if any)
$currentThumbprint = $null
if ($binding) {
    $sslHash = $binding.bindingInformation.Split(':') | ForEach-Object { $_ } | Out-Null
    $currentThumbprint = (Get-Item "Cert:\LocalMachine\My\$($binding.CertificateHash -join '')").Thumbprint 2>$null
}

if ($currentThumbprint -eq $newCert.Thumbprint) {
    Write-Host "Certificate already current for $IIS_SITE_NAME. No update needed."
} else {
    Write-Host "Updating IIS binding with new certificate $($newCert.Thumbprint)..."

    if ($binding) {
        $binding.RemoveSslCertificate()
    } else { 
        New-WebBinding -Name $IIS_SITE_NAME -HostHeader $IIS_HOST_HEADER -Protocol "https" -Port 443 -SslFlags 1
    }

    (Get-WebBinding -Name $IIS_SITE_NAME -Protocol "https" -Port 443).AddSslCertificate($newCert.Thumbprint, "My")

    Write-Host "IIS binding updated."
}

# Optional cleanup of old certs for this domain
$oldCerts = Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $_.Subject -eq "CN=$CERTKIT_CERTIFICATE_DOMAIN" -and $_.Thumbprint -ne $newCert.Thumbprint
}
$oldCerts | ForEach-Object {
    Write-Host "Removing old cert: $($_.Thumbprint)"
    Remove-Item $_.PSPath -Force
}