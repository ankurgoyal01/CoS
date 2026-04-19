---
service: "aws-transfer-for-sftp"
title: "SFTP File Upload to S3"
generated: "2026-03-03"
type: flow
flow_name: "sftp-file-upload"
flow_type: synchronous
trigger: "SFTP client executes a put command against the managed SFTP endpoint"
participants:
  - "awsTransfer_transferEndpoint"
  - "awsTransfer_serverLoggingRole"
  - "awsTransfer_cloudWatchIntegration"
  - "continuumAwsTransferCloudWatchLogs"
  - "continuumAwsTransferEdwBucket"
  - "continuumAwsTransferLoggingBucket"
architecture_ref: "dynamic-aws-transfer-sftp-to-edw"
---

# SFTP File Upload to S3

## Summary

An authorised SFTP client (external partner or internal Groupon system) connects to the AWS Transfer Family managed SFTP endpoint and uploads a file using the standard SFTP `put` command. The Transfer service authenticates the client using their SSH key, resolves the target S3 bucket and home directory prefix via the user's IAM role and scope-down policy, and writes the file directly to the appropriate domain S3 bucket (EDW, CDE, CLO Distribution, Goods, InfoSec, Augeovoucher, or Sachin). Simultaneously, session and transfer events are written to CloudWatch Logs, and S3 records object-level access events to the centralised logging bucket.

## Trigger

- **Type**: user-action
- **Source**: SFTP client executing a `put` (upload) command
- **Frequency**: On demand; driven by partner or internal system file transfer schedules

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SFTP Client (external/internal) | Initiates file transfer | (external actor) |
| Transfer Endpoint | Accepts SSH connection, authenticates user, routes write to S3 | `awsTransfer_transferEndpoint` |
| Server Logging IAM Role | Assumed by Transfer server to publish CloudWatch logs | `awsTransfer_serverLoggingRole` |
| CloudWatch Log Integration | Receives session and file-transfer activity events | `awsTransfer_cloudWatchIntegration` |
| CloudWatch Logs | Persists session and activity log events | `continuumAwsTransferCloudWatchLogs` |
| Domain S3 Bucket (e.g., EDW) | Receives the uploaded file object | `continuumAwsTransferEdwBucket` (or other domain bucket) |
| SFTP Access Logging Bucket | Receives S3 server access log entries for the upload event | `continuumAwsTransferLoggingBucket` |

## Steps

1. **Client Connects**: SFTP client establishes an SSH connection to the AWS Transfer Family endpoint.
   - From: SFTP Client
   - To: `awsTransfer_transferEndpoint`
   - Protocol: SFTP over SSH (port 22)

2. **Authenticates User**: Transfer endpoint validates the client's SSH public key against the user record managed by `SERVICE_MANAGED` identity provider; resolves the IAM role and home directory mapping.
   - From: `awsTransfer_transferEndpoint`
   - To: AWS IAM (`awsTransfer_edwBucketSftpUserRole` / per-bucket user role)
   - Protocol: AWS STS `sts:AssumeRole`

3. **Authorises Operation**: IAM scope-down policy restricts the session to the user's home directory prefix (`$transfer:HomeDirectory/*`) and permits `s3:PutObject` on the target bucket.
   - From: `awsTransfer_edwBucketSftpUserRole`
   - To: `awsTransfer_edwBucketSftpAccessPolicy`
   - Protocol: IAM policy evaluation

4. **Writes File to S3**: Transfer endpoint streams the uploaded file bytes to the target domain S3 bucket object key under the user's home directory.
   - From: `awsTransfer_transferEndpoint`
   - To: `continuumAwsTransferEdwBucket` (or other domain bucket)
   - Protocol: SFTP/S3

5. **Publishes Session Log**: Transfer server emits authentication and file-transfer events to CloudWatch Logs via the server logging role.
   - From: `awsTransfer_transferEndpoint`
   - To: `continuumAwsTransferCloudWatchLogs`
   - Protocol: CloudWatch Logs API (`logs:PutLogEvents`)

6. **S3 Emits Access Log**: S3 records the object write event and forwards an access log entry to the centralised logging bucket.
   - From: `continuumAwsTransferEdwBucket`
   - To: `continuumAwsTransferLoggingBucket`
   - Protocol: S3 Server Access Logging (prefix `transfer-log/`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SSH key not recognised | Transfer endpoint rejects the connection | Client receives `Authentication failed` error; no file is written |
| IAM scope-down policy denies path | S3 `AccessDenied` returned via Transfer endpoint | Client receives `SSH_FX_PERMISSION_DENIED`; event logged to CloudWatch |
| S3 bucket unavailable | Transfer endpoint returns SFTP error code to client | Client receives transfer failure; session event logged to CloudWatch |
| CloudWatch Logs API unavailable | Transfer continues; log event may be dropped | File is written successfully; audit trail may be incomplete |

## Sequence Diagram

```
SFTP Client -> awsTransfer_transferEndpoint: SSH connect + authenticate (SSH key)
awsTransfer_transferEndpoint -> AWS IAM: sts:AssumeRole (edwBucketSftpUserRole)
AWS IAM --> awsTransfer_transferEndpoint: Temporary credentials (scoped to home directory)
SFTP Client -> awsTransfer_transferEndpoint: put <filename>
awsTransfer_transferEndpoint -> continuumAwsTransferEdwBucket: s3:PutObject (under $HomeDirectory/filename)
continuumAwsTransferEdwBucket --> awsTransfer_transferEndpoint: 200 OK
awsTransfer_transferEndpoint -> continuumAwsTransferCloudWatchLogs: logs:PutLogEvents (session + transfer activity)
continuumAwsTransferEdwBucket -> continuumAwsTransferLoggingBucket: S3 access log (transfer-log/)
awsTransfer_transferEndpoint --> SFTP Client: Upload complete
```

## Related

- Architecture dynamic view: `dynamic-aws-transfer-sftp-to-edw`
- Related flows: [SFTP File Download from S3](sftp-file-download.md), [SFTP to EDW Transfer Flow](sftp-to-edw-flow.md)
