# Sync CertKit SSL Certificates to Caddy

Caddy can usually handle automatic HTTPs on its own. But in web farm environments or other scenarios (where you might be hitting rate limits or can't expose port `80`) it can be helpful to use CertKit.

---

## Overview

* Syncs the latest certificates from CertKit into a local directory using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
* Copies them into place if they changed or are missing.
* Optionally runs a post-update command (e.g. `caddy reload --config /etc/caddy/Caddyfile --force`).
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

## Caddy Configuration

Turn off `auto_https` in the global section:

```bash
{
	# turn off automatic HTTPs since we're managing certificates ourselves.
  auto_https off
}
```

Point your server block to the synced files:

```bash
example.com {
  # Point at certs provided by certkit
	tls /etc/caddy/ssl/example.com.pem /etc/caddy/ssl/example.com.key

  # ... other config
}
```

Reload after the first sync:

```bash
caddy reload --config /etc/caddy/Caddyfile --force
```

---

## Automation

* **Cron:**

  ```bash
  (crontab -l 2>/dev/null; echo "0 2 * * * /absolute/path/to/certkit-sync.sh") | crontab -
  ```
* **systemd timer:** Create a service and timer to run daily at 2am.

Either method ensures Caddy certs stay current without manual intervention.

---

## Security Notes

* Protect `certkit.conf` (contains credentials):

  ```bash
  chmod 600 certkit.conf
  ```
* Destination certs should be `0640` with a group readable by `caddy`.

---

## Example

Single name domain setup in `certkit.conf`:

```bash
# Get S3 credentials from the CertKit UI
CERTKIT_S3_ACCESS_KEY=""
CERTKIT_S3_SECRET_KEY=""
CERTKIT_S3_BUCKET=""

# Domain/Caddy specific configuration
CERTKIT_CERTIFICATE_DOMAIN="www.example.com"
UPDATE_CERTIFICATE_CMD="caddy reload --config /etc/caddy/Caddyfile --force"
DESTINATION_PEM_FILE="/etc/caddy/ssl/www.example.com.pem"
DESTINATION_KEY_FILE="/etc/caddy/ssl/www.example.com.key"
```
