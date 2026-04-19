---
service: "aws-transfer-for-sftp"
title: "SFTP File Download from S3"
generated: "2026-03-03"
type: flow
flow_name: "sftp-file-download"
flow_type: synchronous
trigger: "SFTP client executes a get command against the managed SFTP endpoint"
participants:
  - "awsTransfer_transferEndpoint"
  - "awsTransfer_edwBucketSftpUserRole"
  - "awsTransfer_edwBucketSftpAccessPolicy"
  - "continuumAwsTransferCloudWatchLogs"
  - "continuumAwsTransferEdwBucket"
  - "continuumAwsTransferLoggingBucket"
architecture_ref: "dynamic-aws-transfer-sftp-to-edw"
---

# SFTP File Download from S3

## Summary

An authorised SFTP client (external partner or internal Groupon system) downloads a file from their designated home directory in the domain S3 bucket. The AWS Transfer Family endpoint authenticates the user via SSH key, resolves the IAM role and scope-down policy, and streams the requested object from S3 to the client. All read activity is logged to CloudWatch Logs and S3 server access logs.

## Trigger

- **Type**: user-action
- **Source**: SFTP client executing a `get` (download) command
- **Frequency**: On demand; driven by partner or internal system file retrieval schedules

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SFTP Client (external/internal) | Requests file download | (external actor) |
| Transfer Endpoint | Accepts SSH connection, authenticates user, reads from S3 and streams to client | `awsTransfer_transferEndpoint` |
| EDW SFTP User Role | IAM role granting `s3:GetObject` and `s3:ListBucket` on the domain bucket | `awsTransfer_edwBucketSftpUserRole` |
| EDW SFTP Access Policy | Enforces scope-down to home directory | `awsTransfer_edwBucketSftpAccessPolicy` |
| CloudWatch Logs | Persists session and download activity | `continuumAwsTransferCloudWatchLogs` |
| Domain S3 Bucket (e.g., EDW) | Source of the file being downloaded | `continuumAwsTransferEdwBucket` |
| SFTP Access Logging Bucket | Receives S3 server access log for the `GetObject` event | `continuumAwsTransferLoggingBucket` |

## Steps

1. **Client Connects**: SFTP client establishes an SSH connection to the AWS Transfer Family endpoint.
   - From: SFTP Client
   - To: `awsTransfer_transferEndpoint`
   - Protocol: SFTP over SSH (port 22)

2. **Authenticates User**: Transfer endpoint validates SSH public key and resolves IAM role and home directory mapping.
   - From: `awsTransfer_transferEndpoint`
   - To: AWS IAM (`awsTransfer_edwBucketSftpUserRole`)
   - Protocol: AWS STS `sts:AssumeRole`

3. **Authorises Read**: Scope-down policy allows `s3:ListBucket` (restricted by `s3:prefix` to the user's home directory) and `s3:GetObject` / `s3:GetObjectVersion` on `$transfer:HomeDirectory/*`.
   - From: `awsTransfer_edwBucketSftpUserRole`
   - To: `awsTransfer_edwBucketSftpAccessPolicy`
   - Protocol: IAM policy evaluation

4. **Reads File from S3**: Transfer endpoint retrieves the requested object from the domain S3 bucket and streams it to the SFTP client.
   - From: `awsTransfer_transferEndpoint`
   - To: `continuumAwsTransferEdwBucket`
   - Protocol: SFTP/S3 (`s3:GetObject`)

5. **Publishes Session Log**: Transfer server emits download activity events to CloudWatch Logs.
   - From: `awsTransfer_transferEndpoint`
   - To: `continuumAwsTransferCloudWatchLogs`
   - Protocol: CloudWatch Logs API (`logs:PutLogEvents`)

6. **S3 Emits Access Log**: S3 records the `GetObject` event and forwards an access log to the centralised logging bucket.
   - From: `continuumAwsTransferEdwBucket`
   - To: `continuumAwsTransferLoggingBucket`
   - Protocol: S3 Server Access Logging (prefix `transfer-log/`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File not found in home directory | S3 returns `NoSuchKey`; Transfer returns SFTP error | Client receives `SSH_FX_NO_SUCH_FILE` |
| IAM scope-down denies access to path | S3 `AccessDenied`; Transfer returns SFTP error | Client receives `SSH_FX_PERMISSION_DENIED`; event logged |
| SSH key not recognised | Connection rejected at authentication | Client receives authentication failure before any S3 access |
| S3 unavailable | Transfer returns SFTP error | Client receives transfer failure; session event logged |

## Sequence Diagram

```
SFTP Client -> awsTransfer_transferEndpoint: SSH connect + authenticate (SSH key)
awsTransfer_transferEndpoint -> AWS IAM: sts:AssumeRole (edwBucketSftpUserRole)
AWS IAM --> awsTransfer_transferEndpoint: Temporary credentials (scoped to home directory)
SFTP Client -> awsTransfer_transferEndpoint: get <filename>
awsTransfer_transferEndpoint -> continuumAwsTransferEdwBucket: s3:GetObject (under $HomeDirectory/filename)
continuumAwsTransferEdwBucket --> awsTransfer_transferEndpoint: File bytes
awsTransfer_transferEndpoint -> continuumAwsTransferCloudWatchLogs: logs:PutLogEvents (session + download activity)
continuumAwsTransferEdwBucket -> continuumAwsTransferLoggingBucket: S3 access log (transfer-log/)
awsTransfer_transferEndpoint --> SFTP Client: File bytes stream
```

## Related

- Architecture dynamic view: `dynamic-aws-transfer-sftp-to-edw`
- Related flows: [SFTP File Upload to S3](sftp-file-upload.md), [SFTP to EDW Transfer Flow](sftp-to-edw-flow.md)
