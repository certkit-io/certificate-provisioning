# Sync CertKit SSL Certificates to NGINX

A lightweight script and config to keep your NGINX TLS certificates updated automatically from CertKit’s S3-compatible storage.

---

## Overview

* Syncs the latest certificates from CertKit into a local directory using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
* Copies them into place if they changed or are missing.
* Optionally runs a post-update command (e.g. `nginx -s reload`).
* Logs all activity to `certkit.log` (keeping last 2000 log lines)

---

## Setup

1. Place `certkit-sync.sh` and `certkit.conf` together in a secure directory.
2. Edit `certkit.conf` with your CertKit S3 credentials, certificate domain, destination paths, and update command.
3. Make the script executable and run once manually:

   ```bash
   chmod +x ./certkit-sync.sh
   ./certkit-sync.sh
   ```

---

## NGINX Configuration

Point your server block to the synced files:

```nginx
ssl_certificate     /etc/ssl/example.com.pem;
ssl_certificate_key /etc/ssl/example.com.key;
```

Reload after the first sync:

```bash
sudo nginx -t && sudo nginx -s reload
```

---

## Automation

* **Cron:**

  ```bash
  (crontab -l 2>/dev/null; echo "0 2 * * * /absolute/path/to/certkit-sync.sh") | crontab -
  ```
* **systemd timer:** Create a service and timer to run daily at 2am.

Either method ensures NGINX certs stay current without manual intervention.

---

## Security Notes

* Protect `certkit.conf` (contains credentials):

  ```bash
  chmod 600 certkit.conf
  ```
* Destination certs should be `0640` with a group readable by NGINX.

---

## Example

Wildcard domain setup in `certkit.conf`:

```bash
# Get S3 credentials from the CertKit UI
CERTKIT_S3_ACCESS_KEY=""
CERTKIT_S3_SECRET_KEY=""
CERTKIT_S3_BUCKET=""

# Domain/NGINX specific configuration
CERTKIT_CERTIFICATE_DOMAIN="*.example.com"
UPDATE_CERTIFICATE_CMD="nginx -s reload"
DESTINATION_PEM_FILE="/etc/nginx/ssl/example.com.pem"
DESTINATION_KEY_FILE="/etc/nginx/ssl/example.com.key"
```
