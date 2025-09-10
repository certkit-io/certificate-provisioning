# CertKit Uses S3 Compatible Storage for Certificates

All of your issued certificates are stored in S3 compatible storage.  We use [MinIO](https://www.min.io/) for the task.  This allows us to make the storage backend scalable and secure, while allowing access with industry standard tooling.

- **S3-Compatible Storage**: Certificates are stored in S3-based backends (MinIO) for easy retrieval with standard tools.  
- **Secure by Default**: All access uses industry standard request signing, TLS, and least-privilege credentials. No ad-hoc secrets or weak links.  
- **Cross-Platform Tooling**: Ready-to-use scripts and utilities for Linux, Windows, and containerized environments.  
- **Extensible Distribution**: Designed to support any environment that supports S3 access.


## Accessing Certificates

Since CertKit uses an S3-compatible backend, you can retrieve certificates with any standard S3 client or library.  

### CLI Tools
- [AWS CLI](https://docs.aws.amazon.com/cli/)  
- [MinIO Client (`mc`)](https://docs.min.io/community/minio-object-store/reference/minio-mc.html)  
- [s3cmd](https://s3tools.org/s3cmd)  
- [rclone](https://rclone.org/s3/)  

### S3 Command Line Examples

**[`common-cli-examples.md`](./common-cli-examples.md)**  
  We've put together some simple examples using the three major S3 CLI providers (S3Cmd, mc, AWS SDK)

### Language SDKs
- **Go**: [minio-go](https://github.com/minio/minio-go), [AWS SDK for Go](https://docs.aws.amazon.com/sdk-for-go/v2/developer-guide/welcome.html)  
- **Python**: [boto3](https://boto3.amazonaws.com/), [minio-py](https://github.com/minio/minio-py)  
- **JavaScript/TypeScript**: [AWS SDK v3](https://github.com/aws/aws-sdk-js-v3), [minio-js](https://github.com/minio/minio-js)  
- **Java/Kotlin**: [AWS SDK for Java](https://aws.amazon.com/sdk-for-java/), [MinIO Java SDK](https://github.com/minio/minio-java)  
- **C#/.NET**: [AWS SDK for .NET](https://github.com/aws/aws-sdk-net), [MinIO .NET SDK](https://github.com/minio/minio-dotnet)  
- **Rust**: [aws-sdk-rust](https://github.com/awslabs/aws-sdk-rust)  

---

## Want something else?
We've started with S3 compatible storage, but if you have a use case requiring something else, let us know!
