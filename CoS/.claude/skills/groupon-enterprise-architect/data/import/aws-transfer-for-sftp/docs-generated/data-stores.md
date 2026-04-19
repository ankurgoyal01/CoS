---
service: "aws-transfer-for-sftp"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAwsTransferEdwBucket"
    type: "s3"
    purpose: "EDW inbound/outbound file transfers"
  - id: "continuumAwsTransferCdeBucket"
    type: "s3"
    purpose: "CDE file transfers"
  - id: "continuumAwsTransferCloDistributionBucket"
    type: "s3"
    purpose: "CLO Distribution file transfers"
  - id: "continuumAwsTransferGoodsBucket"
    type: "s3"
    purpose: "Goods file transfers"
  - id: "continuumAwsTransferInfosecBucket"
    type: "s3"
    purpose: "InfoSec file transfers"
  - id: "continuumAwsTransferAugeovoucherBucket"
    type: "s3"
    purpose: "Augeovoucher file transfers"
  - id: "continuumAwsTransferSachinBucket"
    type: "s3"
    purpose: "Sachin file transfers"
  - id: "continuumAwsTransferLoggingBucket"
    type: "s3"
    purpose: "Centralised S3 server access logging"
  - id: "continuumAwsTransferCloudWatchLogs"
    type: "cloudwatch-logs"
    purpose: "SFTP session and authentication audit logs"
---

# Data Stores

## Overview

All persistent storage is implemented as Amazon S3 buckets. There are seven private data buckets (one per business domain), one centralised access-logging bucket, and one CloudWatch Logs log group for SFTP session auditing. All data buckets share a consistent security configuration: AES-256 server-side encryption, versioning enabled, all public access blocked, and S3 server access logging forwarded to the central logging bucket. Lifecycle expiration is configurable per environment via Terraform variables. No relational databases or caches are used.

## Stores

### EDW SFTP Bucket (`continuumAwsTransferEdwBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferEdwBucket` |
| Default bucket name | `{env}-groupon-transfer-s3-edw` |
| Purpose | Stores inbound and outbound files for the Enterprise Data Warehouse (EDW) integration |
| Ownership | owned |
| Migrations path | Not applicable (S3 object storage) |

#### Access Patterns

- **Write**: SFTP users authenticated via `groupon-transfer-user-iam-role-groupon-transfer-s3-edw` upload files; IAM scope-down policy restricts writes to the user's home directory prefix (`$transfer:HomeDirectory/*`)
- **Read**: SFTP users download files from their home directory; downstream EDW processes read directly from S3 using IAM
- **Encryption**: AES-256 SSE (`sse_algorithm = "AES256"`)
- **Versioning**: Enabled; both current and non-current versions expire after the configured `storage_bucket_expiration-edw` days (default: 15 days)
- **Logging**: Access logs forwarded to `{env}-groupon-transfer-s3-bucket-log` under prefix `transfer-log/`

---

### CDE SFTP Bucket (`continuumAwsTransferCdeBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferCdeBucket` |
| Default bucket name | `{env}-groupon-transfer-s3-cde` |
| Purpose | Stores files for CDE (Cardholder Data Environment) file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP users scoped via IAM scope-down policy (`groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-cde`)
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-cde` (default: 15 days)
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### CLO Distribution SFTP Bucket (`continuumAwsTransferCloDistributionBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferCloDistributionBucket` |
| Default bucket name | `{env}-{var.s3-bucket-clo-distribution}` |
| Purpose | Stores files for CLO (Card-Linked Offers) distribution file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP user access scoped by IAM policy
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-clo-distribution`
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### Goods SFTP Bucket (`continuumAwsTransferGoodsBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferGoodsBucket` |
| Default bucket name | `{env}-{var.s3-bucket-goods}` |
| Purpose | Stores files for Goods product file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP user access scoped by IAM scope-down policy (`groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-goods`)
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-goods`
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### InfoSec SFTP Bucket (`continuumAwsTransferInfosecBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferInfosecBucket` |
| Default bucket name | `{env}-{var.s3-bucket-infosec}` |
| Purpose | Stores files for InfoSec team file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP user access scoped by IAM scope-down policy (`groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-infosec`)
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-infosec`
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### Augeovoucher SFTP Bucket (`continuumAwsTransferAugeovoucherBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferAugeovoucherBucket` |
| Default bucket name | `{env}-{var.s3-bucket-augeovoucher}` |
| Purpose | Stores files for Augeovoucher file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP user access scoped by IAM scope-down policy (`groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-augeovoucher`); role bound by `grpn-boundary-infosec-sftp-admin` permissions boundary
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-augeovoucher`
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### Sachin SFTP Bucket (`continuumAwsTransferSachinBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferSachinBucket` |
| Default bucket name | `{env}-{var.s3-bucket-sftp-sachin}` |
| Purpose | Stores files for Sachin file transfers |
| Ownership | owned |

#### Access Patterns

- **Write/Read**: SFTP user access scoped by S3 bucket policy
- **Encryption**: AES-256 SSE
- **Versioning**: Enabled; expiration configured via `storage_bucket_expiration-sftp-sachin`
- **Logging**: Forwarded to `{env}-groupon-transfer-s3-bucket-log`

---

### SFTP Access Logging Bucket (`continuumAwsTransferLoggingBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumAwsTransferLoggingBucket` |
| Default bucket name | `{env}-groupon-transfer-s3-bucket-log` |
| ACL | `log-delivery-write` |
| Purpose | Centralised S3 server access log aggregation for all SFTP data buckets |
| Ownership | owned |

#### Access Patterns

- **Write**: All data buckets emit access logs to this bucket with prefix `transfer-log/`
- **Read**: InfoSec and security audit processes
- **Encryption**: AES-256 SSE
- **Retention**: 365 days (`logging_bucket_expiration`); incomplete multipart uploads aborted after 30 days (`logging_bucket_abort`)

---

### Transfer CloudWatch Logs (`continuumAwsTransferCloudWatchLogs`)

| Property | Value |
|----------|-------|
| Type | cloudwatch-logs |
| Architecture ref | `continuumAwsTransferCloudWatchLogs` |
| Log group name | `/aws/transfer/<server-id>` |
| Purpose | Aggregates SFTP session, authentication, and transfer activity events |
| Ownership | owned |

#### Access Patterns

- **Write**: AWS Transfer Family server writes via `groupon-transfer-server-iam-role` (CloudWatch Logs API)
- **Read**: InfoSec security monitoring, Wavefront dashboard integration
- **Retention**: 365 days (`cloudwatch_log_expiration` in production and sandbox environments)

## Caches

> No evidence found in codebase. This service does not use any cache layer.

## Data Flows

- SFTP clients upload/download files directly through the AWS Transfer endpoint to the relevant S3 data bucket.
- Each data bucket emits S3 server access logs (prefix `transfer-log/`) to `continuumAwsTransferLoggingBucket`.
- The AWS Transfer server publishes session and authentication events to `continuumAwsTransferCloudWatchLogs` via the `groupon-transfer-server-iam-role`.
- Downstream consumers (e.g., EDW pipelines) read files directly from their respective S3 bucket using separate IAM credentials not managed in this repository.
