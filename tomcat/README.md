# Sync CertKit SSL Certificates to Tomcat

A lightweight script and config to keep your Tomcat TLS certificates updated automatically from CertKit’s S3-compatible storage.

---

## Overview

* Syncs the latest certificates from CertKit into a local directory using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
* Places them into a Java-compatible keystore format:

  * **PKCS#12 (`.pfx`/`.p12`)** – recommended, supported natively by Tomcat.
  * **JKS (`.jks`)** – optional, converted automatically if desired.
* Only updates if the certificate has changed.
* Optionally runs a post-update command (e.g. `systemctl restart tomcat9`).
* Logs all activity to `certkit.log` (keeping last 2000 log lines).

---

## Setup

1. Place `certkit-sync-tomcat.sh` and `certkit.conf` together in a secure directory.
2. Edit `certkit.conf` with your CertKit S3 credentials, certificate domain, keystore destination, password, and update command.
3. Make the script executable and run once manually:

   ```bash
   chmod +x ./certkit-sync-tomcat.sh
   ./certkit-sync-tomcat.sh
   ```

---

## Tomcat Configuration

Tomcat’s `server.xml` must point to the keystore file managed by the script.
By default, we recommend PKCS#12:

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           SSLEnabled="true"
           keystoreFile="/etc/tomcat/example.com.pfx"
           keystorePass="changeit" />
```

### JKS Option

If you set `DESTINATION_KEYSTORE_FILE=/etc/tomcat/example.com.jks` in your config,
the script will auto-convert `.pfx` → `.jks` using `keytool`.
Tomcat configuration then changes to:

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           SSLEnabled="true"
           keystoreFile="/etc/tomcat/example.com.jks"
           keystoreType="JKS"
           keystorePass="changeit" />
```

---

## Restarting Tomcat

Tomcat must be restarted to pick up new certificates.
Common approaches:

```bash
# systemd (Debian/Ubuntu package)
sudo systemctl restart tomcat9

# systemd (generic)
sudo systemctl restart tomcat

# manual install
$CATALINA_HOME/bin/shutdown.sh && sleep 5 && $CATALINA_HOME/bin/startup.sh
```

Set this in `certkit.conf` as:

```bash
UPDATE_CERTIFICATE_CMD="systemctl restart tomcat9"
```

---

## Automation

* **Cron:**

  ```bash
  (crontab -l 2>/dev/null; echo "0 6 * * * /absolute/path/to/certkit-sync-tomcat.sh") | crontab -
  ```

* **systemd timer:** Create a service and timer to run daily at 6am.

Either method ensures Tomcat certs stay current without manual intervention.

## Example

Wildcard domain setup in `certkit.conf`:

```bash
# Get S3 credentials from the CertKit UI
CERTKIT_S3_ACCESS_KEY=""
CERTKIT_S3_SECRET_KEY=""
CERTKIT_S3_BUCKET=""

# Certificate specific configuration
CERTKIT_CERTIFICATE_ID=""

# Use PKCS#12 keystore (preferred)
DESTINATION_KEYSTORE_FILE="/etc/tomcat/example.com.pfx"
KEYSTORE_PASSWORD="changeit"

# Restart Tomcat when updated
UPDATE_CERTIFICATE_CMD="systemctl restart tomcat9"
```

To instead generate a JKS:

```bash
DESTINATION_KEYSTORE_FILE="/etc/tomcat/example.com.jks"
KEYSTORE_PASSWORD="changeit"
```