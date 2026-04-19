---
service: "aws-transfer-for-sftp"
title: "SFTP to EDW Transfer Flow"
generated: "2026-03-03"
type: flow
flow_name: "sftp-to-edw-flow"
flow_type: synchronous
trigger: "SFTP client uploads or downloads files to/from the EDW S3 bucket"
participants:
  - "continuumAwsTransferSftpServer"
  - "continuumAwsTransferEdwBucket"
  - "continuumAwsTransferLoggingBucket"
  - "continuumAwsTransferCloudWatchLogs"
architecture_ref: "dynamic-aws-transfer-sftp-to-edw"
---

# SFTP to EDW Transfer Flow

## Summary

This flow captures the complete path of file data between the AWS Transfer SFTP server and the EDW (Enterprise Data Warehouse) S3 bucket, as modelled in the architecture dynamic view `dynamic-aws-transfer-sftp-to-edw`. The SFTP server transfers both inbound and outbound files to/from the EDW bucket, the EDW bucket emits object access logs to the centralised logging bucket, and the SFTP server concurrently publishes session and activity logs to CloudWatch Logs. This provides a complete, auditable record of all EDW file exchange activity.

## Trigger

- **Type**: user-action
- **Source**: An authorised SFTP user (EDW partner or internal system) performing a file transfer via the SFTP endpoint
- **Frequency**: On demand, driven by EDW data ingestion and distribution schedules

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AWS Transfer SFTP Server | Manages the SFTP session and routes file I/O to/from S3 | `continuumAwsTransferSftpServer` |
| EDW SFTP Bucket | Stores inbound and outbound EDW files | `continuumAwsTransferEdwBucket` |
| SFTP Access Logging Bucket | Aggregates S3 object access logs from the EDW bucket | `continuumAwsTransferLoggingBucket` |
| Transfer CloudWatch Logs | Receives SFTP session and activity log events | `continuumAwsTransferCloudWatchLogs` |

## Steps

1. **Transfers Inbound/Outbound Files**: The SFTP server accepts client file operations (upload or download) and routes them to the EDW S3 bucket using the user's scoped IAM credentials.
   - From: `continuumAwsTransferSftpServer`
   - To: `continuumAwsTransferEdwBucket`
   - Protocol: SFTP/S3 (`s3:PutObject` for uploads; `s3:GetObject` for downloads)

2. **Emits Object Access Logs**: The EDW S3 bucket records object-level access events and forwards them to the centralised logging bucket with prefix `transfer-log/`.
   - From: `continuumAwsTransferEdwBucket`
   - To: `continuumAwsTransferLoggingBucket`
   - Protocol: S3 Server Access Logging

3. **Publishes Session and Activity Logs**: Concurrently with file transfer, the SFTP server publishes session lifecycle events (connect, authenticate, command, disconnect) to the CloudWatch log group `/aws/transfer/<server-id>`.
   - From: `continuumAwsTransferSftpServer`
   - To: `continuumAwsTransferCloudWatchLogs`
   - Protocol: CloudWatch Logs API (`logs:PutLogEvents`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW bucket unavailable | Transfer returns SFTP error to client | File transfer fails; session event logged to CloudWatch |
| CloudWatch Logs unavailable | Transfer continues; log delivery may be delayed or dropped | File transfer completes; audit trail may be incomplete |
| S3 access logging delayed | AWS S3 delivers access logs on a best-effort basis (may be delayed up to a few hours) | Logs arrive eventually; no retry mechanism is needed |
| User IAM scope-down policy mismatch | S3 rejects write/read with `AccessDenied` | File transfer fails; event recorded in CloudWatch Logs |

## Sequence Diagram

```
SFTP Client -> continuumAwsTransferSftpServer: SFTP file operation (upload or download)
continuumAwsTransferSftpServer -> continuumAwsTransferEdwBucket: Transfers inbound and outbound files (SFTP/S3)
continuumAwsTransferEdwBucket -> continuumAwsTransferLoggingBucket: Emits object access logs (S3 Server Access Logging, transfer-log/)
continuumAwsTransferSftpServer -> continuumAwsTransferCloudWatchLogs: Publishes session and activity logs (CloudWatch Logs API)
continuumAwsTransferEdwBucket --> continuumAwsTransferSftpServer: S3 operation response
continuumAwsTransferSftpServer --> SFTP Client: Transfer result
```

## Related

- Architecture dynamic view: `dynamic-aws-transfer-sftp-to-edw`
- DSL source: `structurizr/import/aws-transfer-for-sftp/architecture/views/dynamics/sftp-to-edw-flow.dsl`
- Related flows: [SFTP File Upload to S3](sftp-file-upload.md), [SFTP File Download from S3](sftp-file-download.md)
