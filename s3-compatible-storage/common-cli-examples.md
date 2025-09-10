# Examples Using Common S3 CLI Tools to Retrieve Certificates

We have recipes for common webservers and platforms, but sometimes you just want to kick the tires or do things manually.  Here are some simple example commands for common S3 CLI tools to retrieve your issued certificates from CertKit.


## S3Cmd
[S3cmd](https://s3tools.org/s3cmd) is a simple and lightweight tool that's available on most platforms.  Using the `sync` feature we can pull everything from the CertKit storage bucket and sync it with a local file system.

```bash
# Get these from the CertKit UI
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""

# The domain your certificate was issued for
CERT_DOMAIN="www.example.com"

s3cmd sync "s3://${S3_BUCKET}/${CERT_DOMAIN}/" ./my-certs/ \
    --access_key="${S3_ACCESS_KEY}" \
    --secret_key="${S3_SECRET_KEY}" \
    --host="storage.certkit.io" \
    --host-bucket="storage.certkit.io"
```


## MinIO Client

[MinIO Client](https://docs.min.io/community/minio-object-store/reference/minio-mc.html) (otherwise known as `mc`) is another full featured and commonly used S3 compatible client.  

One advantage of `mc` is that it can be installed as a single binary copied to the host machine.  Here's a simple command to pull the binary to your current working directory:

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o ./mc
chmod +x mc
```

```bash

# Get these from the CertKit UI
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""

# The domain your certificate was issued for
CERT_DOMAIN="www.example.com"

# Export the ALIAS so MinIO client can see it
export MC_HOST_certkit="https://${S3_ACCESS_KEY}:${S3_SECRET_KEY}@storage.certkit.io"

mc mirror --overwrite "certkit/${S3_BUCKET}/${CERT_DOMAIN}/" ./my-certs/

```

## AWS SDK

No one really likes using Amazon's AWS CLI library - it's ergonomics are beyond questionable - but it's reasonably ubiquitous. So here ya go. 

```bash
# Get these from the CertKit UI
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""

# The domain your certificate was issued for
CERT_DOMAIN="www.example.com"

# --- Export credentials so CLI can use them
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY

# --- Command ---
aws s3 sync "s3://${S3_BUCKET}/${CERT_DOMAIN}" ./my-certs/ \
  --endpoint-url "https://storage.certkit.io" \
  --exact-timestamps

```