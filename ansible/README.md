# Install CertKit Sync Script Using Ansible

An Ansible role that will install and configure a script that downloads a Certkit certificate and keeps it up to date.

---

## Overview

* Installs a simple syncronization script to whichever directory you specify.
* Requires some variables to configure which certificate should be downloaded.
* Builds a configuration file from variables you give it.
* Syncronizes a single certificate.
  * To sync multiple certificates, call the role multiple times. Each call should use a different `certkit_dir`!
* Once installed, the script:
  * Syncs the latest certificates from CertKit into a local directory using [minio-client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart).
  * Copies them into place if they changed or are missing.
  * Optionally runs a post-update command (e.g. `nginx -s reload`).
  * Logs all activity to `certkit.log` (keeping last 2000 log lines)
  * Is periodically run on a Cron schedule.

---

## Setup

1. Place the `certkit.sync` role directory in your roles directory.
2. Call the `certkit.sync` role from your playbook, passing all the required variables (See Example Below).
3. Check the logfile created at `{{certkit_dir}}/certkit.log` to ensure the first sync was successful.

---

## Example

Place this task in your playbook. See `example-playbook.yml` for more details:

```yml
- include_role:
    name: certkit.sync
  vars:
    # Credentials from the CertKit UI
    certkit_bucket: certkit-1234
    certkit_access_key: YOUR_ACCESS_KEY
    certkit_secret_key: YOUR_SECRET_KEY

    # Domain/Server specific configuration
    certkit_common_name: "*.yourdomain.com"
    certkit_dir: /opt/certkit-nginx
    certkit_update_cmd: "/usr/sbin/nginx -s reload"
    certkit_pem_destination: "/etc/nginx/yourdomain.pem"
    certkit_key_destination: "/etc/nginx/yourdomain.key"
```
