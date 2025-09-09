# Sync CertKit SSL Certificates to Apache2

A lightweight script and config to keep your Apache2 TLS certificates updated automatically from CertKit’s S3-compatible storage.

---

## Overview

* Syncs the latest certificates from CertKit into a local directory using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
* Copies them into place if they changed or are missing.
* Optionally runs a post-update command (e.g. `systemctl reload apache2`).
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

## Apache Configuration

By convention, Apache stores certificates and private keys in different folders (`/etc/ssl/certs` and `/etc/ssl/private`). Update your virtual host to point to the synced files:

```apache
<VirtualHost *:443>
    ServerName example.com
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.com.pem
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
</VirtualHost>
```

### Ensure SSL module is enabled (This is onyl necessary if you haven't used SSL before)
```bash
# On Debian/Ubuntu
a2enmod ssl

# On RedHat
yum install mod_ssl
```

### Manually Reload Apache when Testing

```bash
sudo systemctl reload apache2
```

Alternative reload methods:

```bash
apachectl graceful
# or
service apache2 reload
```

---

## Automation

* **Cron:**

  ```bash
  (crontab -l 2>/dev/null; echo "0 6 * * * /absolute/path/to/certkit-sync.sh") | crontab -
  ```
* **systemd timer:** Create a service and timer to run daily at 6am.

Either method ensures Apache certs stay current without manual intervention.

---

## Security Notes

* Protect `certkit.conf` (contains credentials):

  ```bash
  chmod 600 certkit.conf
  ```
* Private key files should be stored in `/etc/ssl/private` with strict permissions (`0600`), only readable by root.
* Certificate files in `/etc/ssl/certs` may be `0644`.

---

## Example

Wildcard domain setup in `certkit.conf`:

```bash
# Get S3 credentials from the CertKit UI
CERTKIT_S3_ACCESS_KEY=""
CERTKIT_S3_SECRET_KEY=""
CERTKIT_S3_BUCKET=""

# Domain/Apache specific configuration
CERTKIT_CERTIFICATE_DOMAIN="*.example.com"
UPDATE_CERTIFICATE_CMD="systemctl reload apache2"
DESTINATION_PEM_FILE="/etc/ssl/certs/example.com.pem"
DESTINATION_KEY_FILE="/etc/ssl/private/example.com.key"
```
