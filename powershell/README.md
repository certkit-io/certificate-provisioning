# Sync CertKit SSL Certificates Using PowerShell (Windows)

A PowerShell script to automatically keep your Certkit TLS certificates updated. Certificates are downloaded from Certkit's servers which expose an S3-compatible API.


## Overview

* Downloads the latest certificate (PFX) from CertKit using [AWS Tools for PowerShell](https://docs.aws.amazon.com/powershell/v5/userguide/pstools-getting-set-up-windows.html).
* On subsequent runs, checks whether the certificate needs to be updated. Downloads the certificate only when needed.
* Provides a hook for any further PowerShell scripting needed to provision the certificate.
* Can be scheduled via Windows Task Scheduler for automatic updates.


## Setup

1. Place `certkit-sync.ps1` in a secure directory.
2. Edit `certkit-sync.ps1` with your Certkit credentials and certificate details
3. Run once manually:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\certkit-sync.ps1
   ```


## Result

The script will automatically download the Certificate in PFX format into the location specified by the `$LOCAL_PFX_DESTINATION` variable.

No further action is taken. However, the script has a spot for you to add any additional logic needed to provision the certificate when it is updated.


## Automation

Use **Task Scheduler** to run the script daily:

1. Open Task Scheduler → Create Task.
2. Run as a dedicated service account with least privileges.
3. Trigger: Daily at 8am.
4. Action: Start a program:

   ```
   Program/script: powershell.exe
   Arguments: -ExecutionPolicy Bypass -File "C:\path\to\certkit-sync.ps1"
   ```


## Security Notes

* For production use it would be wise to use environment variables or Windows Credential Manager to manage secrets.
* Ensure the service account running the scheduled task has **read access** to the script and write access to the certificate store.
