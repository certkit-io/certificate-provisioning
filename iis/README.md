# Sync CertKit SSL Certificates to IIS (Windows)

A PowerShell script and config to keep your IIS TLS certificates updated automatically from CertKit’s S3-compatible storage.

---

## Overview

* Downloads the latest certificate (PFX) from CertKit using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
* Imports the certificate into the **LocalMachine\My** certificate store.
* Cleans up previous certificate for that binding if necessary, to avoid clutter.
* Binds the new certificate to the specified IIS site.
* Can be scheduled via Windows Task Scheduler for hands-free automation.

---

## Setup

1. Place `certkit-sync.ps1` in a secure directory.
2. Edit `certkit-sync.ps1` with your S3 credentials and IIS website details
3. Run once manually:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\certkit-sync.ps1
   ```

---

## IIS Configuration

The script will automatically import the PFX into `Cert:\LocalMachine\My` and assign it to your site’s HTTPS binding.

If no HTTPS binding exists, it will create one on port 443.

---

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

---

## Security Notes

* For production use it would be wise to use environment variables or Windows Credential Manager to manage secrets.
* Ensure the service account running the scheduled task has **read access** to the script and write access to the certificate store.
* Limit PFX permissions: the script imports into the machine store so private keys are protected by Windows.

---