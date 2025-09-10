# CertKit SSL Certificate Provisioning Examples

This repository contains **practical examples** for wiring up SSL/TLS certificate syncing from [CertKit](https://www.certkit.io) into common webservers and platforms.  

Each folder includes configuration samples, helper scripts, and step-by-step instructions to make integration easy.

CertKit handles **certificate automation, renewal, and storage**. These examples show you how to pull those certificates into your own infrastructure.

---

## Repository Structure

- **[`nginx/`](./nginx/)**  
  Example config snippets and scripts to automatically sync certificates into NGINX.

- **[`apache/`](./apache/)**  
  Integration examples for Apache HTTP Server, including SSL config and reload helpers.
<!-- 
- **[`caddy/`](./caddy/)**  
  How to connect CertKit certificates to Caddy, including JSON and Caddyfile examples.

- **[`iis/`](./iis/)**  
  PowerShell and batch scripts to import CertKit certificates into IIS on Windows. -->

---

## Contributing

This repository is **community-driven**. While CertKit provides the core certificate automation platform, every environment is unique.  
If you have improvements, fixes, or additional examples (other servers, load balancers, proxies, or operating systems):

- Submit a **pull request** with your contribution.
- Open an **issue** to share ideas or request guidance.

---

## Feedback

If something doesn’t work as expected, or if you’ve found a better way to wire things up, let us know!  

[Open an issue](../../issues) to submit bugs or tell us what you think.

---

Made by the team behind [CertKit](https://certkit.io), [TrackJS](https://trackjs.com), and [Request Metrics](https://requestmetrics.com).
