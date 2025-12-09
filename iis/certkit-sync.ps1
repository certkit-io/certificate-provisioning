$ErrorActionPreference = "Stop"

# These values come from the CertKit UI
$CERTKIT_S3_ACCESS_KEY = ""
$CERTKIT_S3_SECRET_KEY = ""
$CERTKIT_S3_BUCKET = ""

# These values will need to be configured on a per certificate/site basis
$CERTKIT_CERTIFICATE_ID = ""
$IIS_SITE_NAME = "ExampleSite"
$IIS_HOST_HEADER = "www.example.com"

# Base S3 folder is /certificate-{id}/
$S3_FOLDER_NAME = "certificate-$CERTKIT_CERTIFICATE_ID"
$SCRIPT_DIR = Split-Path -Parent $PSCommandPath
$CERT_DIR = Join-Path $SCRIPT_DIR "certs/$S3_FOLDER_NAME"

$MC_BIN = Join-Path $SCRIPT_DIR "mc.exe"
if (-Not (Test-Path $MC_BIN)) {
    Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" -OutFile $mcPath
}

# Sync PFX from CertKit
& $MC_BIN alias set certkit https://storage.certkit.io $CERTKIT_S3_ACCESS_KEY $CERTKIT_S3_SECRET_KEY
& $MC_BIN mirror --overwrite "certkit/$CERTKIT_S3_BUCKET/$S3_FOLDER_NAME" "$CERT_DIR"

$PFX_FILE = (Get-ChildItem $CERT_DIR -Filter *.pfx | Select-Object -First 1).FullName

# Import new cert into store
$newCert = Import-PfxCertificate -FilePath $PFX_FILE -CertStoreLocation "Cert:\LocalMachine\My" -Password (ConvertTo-SecureString $CERTKIT_S3_SECRET_KEY -AsPlainText -Force)

# Make sure we set the FriendlyName to something reasonable
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

$certInStore = $store.Certificates |
    Where-Object { ($_.Thumbprint -replace ' ', '') -ieq $newCert.Thumbprint }

if ($certInStore) {
    $certInStore.FriendlyName = " CertKit Certificate $CERTKIT_CERTIFICATE_ID"
}

# Find IIS binding
Import-Module WebAdministration
$binding = Get-WebBinding -Name $IIS_SITE_NAME -Protocol "https" -Port 443

# Get current bound cert thumbprint (if any)
$currentThumbprint = $null
if ($binding) {
    $thumb = ($binding.CertificateHash -join '')
    $certPath = "Cert:\LocalMachine\My\$thumb"

    if (Test-Path $certPath) {
        $currentThumbprint = (Get-Item $certPath).Thumbprint
    }
}

if ($currentThumbprint -eq $newCert.Thumbprint) {
    Write-Host "Certificate already current for $IIS_SITE_NAME. No update needed."
} else {
    Write-Host "Updating IIS binding with new certificate $($newCert.Thumbprint)..."
    if ($binding) {
        if($currentThumbprint) {
            $binding.RemoveSslCertificate()
        }
    } else { 
        New-WebBinding -Name $IIS_SITE_NAME -HostHeader $IIS_HOST_HEADER -Protocol "https" -Port 443 -SslFlags 1
    }

    (Get-WebBinding -Name $IIS_SITE_NAME -Protocol "https" -Port 443).AddSslCertificate($newCert.Thumbprint, "My")

    Write-Host "IIS binding updated."

    # Optional cleanup of old certs for this domain
    $oldCerts = Get-ChildItem Cert:\LocalMachine\My | Where-Object {
        $_.Thumbprint -eq $currentThumbprint -and $_.Thumbprint -ne $newCert.Thumbprint
    }
    $oldCerts | ForEach-Object {
        Write-Host "Removing old cert: $($_.Thumbprint)"
        Remove-Item $_.PSPath -Force
    }
}
