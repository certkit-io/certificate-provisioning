# Simple example of using PowerShell to download a local copy of a Certkit certificate.
# Set this script as a scheduled task to keep the certificate up to date when a new version is issued.
#
# NOTE: This script uses 'AWS Tools for PowerShell' to pull from Certkit's storage. Certkit storage provides an S3 compatible API.
# Read more about AWS Tools for Powershell here: https://docs.aws.amazon.com/powershell/v5/userguide/pstools-getting-set-up-windows.html


#
# FILL OUT THE BELOW VARIABLES:
#

# These values come from the CertKit UI
$CERTKIT_ACCESS_KEY = ""
$CERTKIT_SECRET_KEY = ""
$CERTKIT_BUCKET = ""

# Find your certificate's storage key using the Certkit storage browser UI.
$CERTKIT_STORAGE_KEY = "certificate-ab12/example.com.wildcard.ec.pfx"

# Where to store the downloaded certificate
$LOCAL_PFX_DESTINATION = "example.com.wildcard.ec.pfx"

#
# END VARIABLES
#


$CommonParams = @{}
$CommonParams['AccessKey'] = $CERTKIT_ACCESS_KEY
$CommonParams['SecretKey'] = $CERTKIT_SECRET_KEY
$CommonParams['EndpointUrl'] = "https://storage.certkit.io"

$CertificateChanged = $false

if (-not (Test-Path $LOCAL_PFX_DESTINATION)) {
    # First download
    $FileInfo = Read-S3Object -BucketName $CERTKIT_BUCKET -Key $CERTKIT_STORAGE_KEY -File $LOCAL_PFX_DESTINATION @CommonParams
    if ($null -eq $FileInfo) {
        Write-Output "Certificate download failed"
        exit 1
    }
    Write-Output "Certificate downloaded for the first time"
    $CertificateChanged = $true
} else {
    # Local certificate already exists, check whether it needs updating
    $LocalCert = Get-Item $LOCAL_PFX_DESTINATION
    $RemoteCertMetadata = Get-S3ObjectMetadata -BucketName $CERTKIT_BUCKET -Key $CERTKIT_STORAGE_KEY @CommonParams
    if ($RemoteCertMetadata.HttpStatusCode -ne [System.Net.HttpStatusCode]::OK) {
        Write-Output "Certificate check failed, got bad status code"
        exit 1
    }

    if ($RemoteCertMetadata.ContentLength -ne $LocalCert.Length -or $RemoteCertMetadata.LastModified -gt $LocalCert.LastWriteTimeUtc) {
        $FileInfo = Read-S3Object -BucketName $CERTKIT_BUCKET -Key $CERTKIT_STORAGE_KEY -File $LOCAL_PFX_DESTINATION @CommonParams
        if ($null -eq $FileInfo) {
            Write-Output "Certificate download failed"
            exit 1
        }
        Write-Output "Certificate was updated"
        $CertificateChanged = $true
    } else {
        Write-Output "Certificate already up to date"
    }
}

if ($CertificateChanged) {
    Write-Output "The certificate has changed, if further processing needs to be done, do so here!"
    # Add any additional logic here for configuring your software to use the new certificate.
}
