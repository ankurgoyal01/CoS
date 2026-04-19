---
service: "aws-transfer-for-sftp"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumAwsTransferSftpServer"
    - "continuumAwsTransferEdwBucket"
    - "continuumAwsTransferCdeBucket"
    - "continuumAwsTransferCloDistributionBucket"
    - "continuumAwsTransferGoodsBucket"
    - "continuumAwsTransferInfosecBucket"
    - "continuumAwsTransferAugeovoucherBucket"
    - "continuumAwsTransferSachinBucket"
    - "continuumAwsTransferLoggingBucket"
    - "continuumAwsTransferCloudWatchLogs"
---

# Architecture Context

## System Context

AWS Transfer for SFTP sits within the Continuum platform as a security-owned ingress/egress gateway for file-based data exchange. External partners and internal Groupon teams connect over SFTP to a single managed endpoint (`continuumAwsTransferSftpServer`). Files are routed to per-team private S3 buckets (EDW, CDE, CLO Distribution, Goods, InfoSec, Augeovoucher, Sachin). All bucket activity is logged to a centralised access-logging bucket (`continuumAwsTransferLoggingBucket`), and server session activity is published to Amazon CloudWatch Logs (`continuumAwsTransferCloudWatchLogs`). The service has no inbound HTTP API; all interaction is through the SFTP protocol over port 22.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| AWS Transfer SFTP Server | `continuumAwsTransferSftpServer` | Transfer endpoint | AWS Transfer Family | Managed SFTP endpoint accepting client connections and routing file operations to S3 |
| EDW SFTP Bucket | `continuumAwsTransferEdwBucket` | Storage | Amazon S3 | Private S3 bucket for EDW inbound/outbound file transfers |
| CDE SFTP Bucket | `continuumAwsTransferCdeBucket` | Storage | Amazon S3 | Private S3 bucket for CDE file transfers |
| CLO Distribution SFTP Bucket | `continuumAwsTransferCloDistributionBucket` | Storage | Amazon S3 | Private S3 bucket for CLO distribution file transfers |
| Goods SFTP Bucket | `continuumAwsTransferGoodsBucket` | Storage | Amazon S3 | Private S3 bucket for Goods file transfers |
| InfoSec SFTP Bucket | `continuumAwsTransferInfosecBucket` | Storage | Amazon S3 | Private S3 bucket for InfoSec file transfers |
| Augeovoucher SFTP Bucket | `continuumAwsTransferAugeovoucherBucket` | Storage | Amazon S3 | Private S3 bucket for Augeovoucher file transfers |
| Sachin SFTP Bucket | `continuumAwsTransferSachinBucket` | Storage | Amazon S3 | Private S3 bucket for Sachin file transfers |
| SFTP Access Logging Bucket | `continuumAwsTransferLoggingBucket` | Storage / Logging | Amazon S3 | Centralised S3 bucket aggregating server access logs from all data buckets |
| Transfer CloudWatch Logs | `continuumAwsTransferCloudWatchLogs` | Observability | Amazon CloudWatch Logs | Aggregated session, authentication, and transfer activity logs |

## Components by Container

### AWS Transfer SFTP Server (`continuumAwsTransferSftpServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Transfer Endpoint (`awsTransfer_transferEndpoint`) | Public SFTP endpoint accepting client connections and routing file operations | AWS Transfer Family |
| Server Logging IAM Role (`awsTransfer_serverLoggingRole`) | IAM role assumed by the Transfer server to publish logs to CloudWatch | AWS IAM Role |
| Server Logging IAM Policy (`awsTransfer_serverLoggingPolicy`) | Grants `logs:CreateLogStream`, `logs:DescribeLogStreams`, `logs:CreateLogGroup`, `logs:PutLogEvents` on `*` | AWS IAM Policy |
| CloudWatch Log Integration (`awsTransfer_cloudWatchIntegration`) | Routes server activity and authentication events to the `/aws/transfer/<server-id>` log group | AWS CloudWatch Logs |

### EDW SFTP Bucket (`continuumAwsTransferEdwBucket`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| EDW Bucket Storage (`awsTransfer_edwBucketStorage`) | Core S3 object storage for inbound and outbound EDW files | Amazon S3 Bucket |
| EDW SFTP User Role (`awsTransfer_edwBucketSftpUserRole`) | IAM role scoped to EDW bucket granting SFTP user session permissions via `transfer.amazonaws.com` principal | AWS IAM Role |
| EDW SFTP Access Policy (`awsTransfer_edwBucketSftpAccessPolicy`) | IAM policy granting `s3:ListBucket`, `s3:GetBucketLocation`, `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:DeleteObjectVersion`, `s3:GetObjectVersion` | AWS IAM Policy |

> Note: All other data buckets (CDE, CLO Distribution, Goods, InfoSec, Augeovoucher, Sachin) follow the same IAM role + access policy + scope-down policy pattern as the EDW bucket.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAwsTransferSftpServer` | `continuumAwsTransferEdwBucket` | Transfers inbound and outbound files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferCdeBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferCloDistributionBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferGoodsBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferInfosecBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferAugeovoucherBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferSachinBucket` | Transfers files | SFTP/S3 |
| `continuumAwsTransferSftpServer` | `continuumAwsTransferCloudWatchLogs` | Publishes session and authentication logs | CloudWatch Logs API |
| `continuumAwsTransferEdwBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs with prefix `transfer-log/` | S3 Server Access Logging |
| `continuumAwsTransferCdeBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `continuumAwsTransferCloDistributionBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `continuumAwsTransferGoodsBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `continuumAwsTransferInfosecBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `continuumAwsTransferAugeovoucherBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `continuumAwsTransferSachinBucket` | `continuumAwsTransferLoggingBucket` | Emits S3 server access logs | S3 Server Access Logging |
| `awsTransfer_transferEndpoint` | `awsTransfer_serverLoggingRole` | Assumes IAM role for service operations | AWS STS |
| `awsTransfer_serverLoggingRole` | `awsTransfer_serverLoggingPolicy` | Uses attached CloudWatch logging policy | IAM |
| `awsTransfer_edwBucketSftpUserRole` | `awsTransfer_edwBucketSftpAccessPolicy` | Uses bucket access policy | IAM |
| `awsTransfer_edwBucketSftpAccessPolicy` | `awsTransfer_edwBucketStorage` | Grants list/read/write object permissions | IAM / S3 |

## Architecture Diagram References

- Component (SFTP Server): `components-continuum-aws-transfer-sftp-server`
- Component (EDW Bucket): `components-continuum-aws-transfer-edw-bucket`
- Dynamic (SFTP to EDW flow): `dynamic-aws-transfer-sftp-to-edw`
