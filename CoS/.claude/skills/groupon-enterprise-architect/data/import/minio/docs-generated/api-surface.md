---
service: "minio"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, s3]
auth_mechanisms: [aws-signature-v4]
---

# API Surface

## Overview

MinIO exposes a fully S3-compatible HTTP API on port 9000. Consumers interact with this service using any AWS S3-compatible SDK or client by pointing the endpoint at the MinIO host. The API supports standard S3 operations: bucket management, object put/get/delete, multipart upload, and presigned URLs. All requests follow the AWS Signature Version 4 authentication scheme.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/minio/health/ready` | Readiness probe — returns 200 when MinIO is ready to serve requests | None |
| GET | `/minio/health/live` | Liveness probe — returns 200 when the MinIO process is alive | None |

### S3-Compatible Object Storage API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | List all buckets | AWS Signature V4 |
| PUT | `/{bucket}` | Create a bucket | AWS Signature V4 |
| DELETE | `/{bucket}` | Delete a bucket | AWS Signature V4 |
| GET | `/{bucket}` | List objects in a bucket | AWS Signature V4 |
| PUT | `/{bucket}/{key}` | Upload an object | AWS Signature V4 |
| GET | `/{bucket}/{key}` | Download an object | AWS Signature V4 |
| HEAD | `/{bucket}/{key}` | Get object metadata | AWS Signature V4 |
| DELETE | `/{bucket}/{key}` | Delete an object | AWS Signature V4 |
| POST | `/{bucket}/{key}?uploads` | Initiate multipart upload | AWS Signature V4 |
| PUT | `/{bucket}/{key}?partNumber={n}&uploadId={id}` | Upload a part | AWS Signature V4 |
| POST | `/{bucket}/{key}?uploadId={id}` | Complete multipart upload | AWS Signature V4 |
| GET | `/{bucket}/{key}?presigned` | Generate presigned URL | AWS Signature V4 |

> The full S3 API surface is defined by the MinIO project. Only the health probe paths are explicitly configured in this repository (`common.yml`). All other endpoints are standard MinIO/S3 API behavior.

## Request/Response Patterns

### Common headers
- `Authorization`: AWS Signature V4 credential header (`AWS4-HMAC-SHA256 Credential=...`)
- `x-amz-date`: ISO 8601 timestamp for request signing
- `x-amz-content-sha256`: SHA-256 hash of the request body
- `Content-Type`: MIME type of the uploaded object

### Error format
Errors follow the standard AWS S3 XML error format:
```xml
<Error>
  <Code>NoSuchBucket</Code>
  <Message>The specified bucket does not exist.</Message>
  <BucketName>my-bucket</BucketName>
  <RequestId>...</RequestId>
  <HostId>...</HostId>
</Error>
```

### Pagination
Object listing uses cursor-based pagination via the S3 `list-objects-v2` format with `ContinuationToken` and `MaxKeys` parameters.

## Rate Limits

> No rate limiting configured. MinIO does not impose application-level rate limits by default. Capacity is governed by the Kubernetes HPA settings: minimum 1 replica, maximum 15 replicas, target CPU utilization 100%.

## Versioning

No URL versioning is applied. The S3 API does not use URL-based versioning; object versioning within buckets is a MinIO/S3 bucket configuration option, not an API versioning scheme.

## OpenAPI / Schema References

> No evidence found in codebase. MinIO's S3-compatible API is documented at https://min.io/docs/minio/linux/developers/minio-drivers.html. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
