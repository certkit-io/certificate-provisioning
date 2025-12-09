# Install CertKit Sync Script Using Ansible

An example playbook that installs and configures a script to download a Certkit certificate and keep it up to date.


## Overview

* Uses our [Certkit Sync Role](https://github.com/certkit-io/ansible-role-sync) to install a simple synchronization script.
* Once installed, the script:
  * Syncs the latest certificate from CertKit into a local directory.
  * Copies certificate into place if it is changed or missing.
  * Optionally runs a post-update command (e.g. `nginx -s reload`).
  * Logs all activity to `certkit.log` (keeping last 2000 log lines)
  * Is periodically run on a Cron schedule.


## Setup

1. Download the role from [Ansible Galaxy](https://galaxy.ansible.com/ui/standalone/roles/certkit_io/sync/). In the directory containing your playbook, run:

   ```bash
   ansible-galaxy role install certkit_io.sync
   ```
1. Call the `certkit_io.sync` role from your playbook, passing all the required variables (See example below).
1. Run the playbook:

   ```bash
   ansible-playbook example-playbook.yml
   ```
1. Check the logfile created at `{{certkit_dir}}/certkit.log` to ensure the first sync was successful.


## Example

You can call the role in any way Ansible allows. This example uses a task in the playbook. See [`example-playbook.yml`](example-playbook.yml) for more details:

```yml
- include_role:
    name: certkit_io.sync
  vars:
    # Credentials from the CertKit UI
    certkit_bucket: certkit-1234
    certkit_access_key: YOUR_ACCESS_KEY
    certkit_secret_key: YOUR_SECRET_KEY

    # Certificate and Server specific configuration
    certkit_certificate_id: ab12
    certkit_dir: /opt/certkit-nginx
    certkit_update_cmd: "/usr/sbin/nginx -s reload"
    certkit_pem_destination: "/etc/nginx/yourdomain.pem"
    certkit_key_destination: "/etc/nginx/yourdomain.key"
```
