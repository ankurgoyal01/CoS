---
service: "aws-transfer-for-sftp"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| AWS Transfer Family console / `aws transfer describe-server` | AWS API | On demand | N/A |
| CloudWatch Logs `/aws/transfer/<server-id>` | log inspection | Continuous (real-time ingestion) | N/A |
| Wavefront dashboard `AWS-Transfer` | metrics dashboard | Continuous | N/A |

> The `.service.yml` disables the status endpoint (`status_endpoint.disabled: true`). There is no HTTP health check endpoint. Liveness is determined by AWS Transfer Family service health and CloudWatch log flow.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| AWS Transfer Family `FilesIn` | counter | Number of files successfully uploaded via SFTP | PagerDuty alert configured via `PLY1VT8` |
| AWS Transfer Family `FilesOut` | counter | Number of files successfully downloaded via SFTP | PagerDuty alert configured via `PLY1VT8` |
| AWS Transfer Family `BytesIn` | counter | Total bytes uploaded | Dashboard only |
| AWS Transfer Family `BytesOut` | counter | Total bytes downloaded | Dashboard only |
| CloudWatch Logs ingestion rate | gauge | Rate of log events arriving in `/aws/transfer/<server-id>` | Silence indicates potential server issue |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AWS Transfer | Wavefront | https://groupon.wavefront.com/dashboard/AWS-Transfer |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SFTP server unavailable | AWS Transfer Family endpoint unreachable or no sessions logged | critical (P1) | Page InfoSec on-call via `infosec-aws-transfer-service@groupon.pagerduty.com`; check AWS Service Health; escalate to AWS Support if needed |
| CloudWatch Logs not receiving events | Log group `/aws/transfer/<server-id>` receives no events for an unexpected period | warning (P2) | Verify IAM role `groupon-transfer-server-iam-role` trust policy; check policy `groupon-transfer-server-iam-policy` permissions |
| S3 bucket access denied | CloudTrail shows `AccessDenied` on SFTP data buckets | warning (P2) | Review IAM scope-down policy for the affected bucket; verify user role assignment |

## Common Operations

### Restart Service

AWS Transfer for SFTP is a managed service and does not support traditional restart operations. If the SFTP endpoint is unresponsive:

1. Open the AWS Console and navigate to AWS Transfer Family.
2. Verify the server status is `ONLINE`. If it shows `STOPPING` or `OFFLINE`, contact AWS Support.
3. If a configuration change was recently applied, check Terraform state and re-apply if needed: `make production/us-west-2/APPLY`.

### Scale Up / Down

> Not applicable. AWS Transfer Family scales automatically. No manual scaling actions are required.

### Add a New SFTP Bucket / Integration

1. Create a new `<name>Bucket.tf` file in `modules/sftp/s3storage/` following the pattern in `edwBucket.tf`.
2. Create a corresponding `<name>BucketVariables.tf` with bucket name, IAM role, IAM policy, and scope-down policy variable definitions.
3. Add a container definition to the architecture DSL at `structurizr/import/aws-transfer-for-sftp/architecture/models/containers.dsl`.
4. Add a relation from `continuumAwsTransferSftpServer` to the new bucket in `models/relations.dsl`.
5. Run `make <env>/us-west-2/plan` and review the plan before applying.
6. Run `make <env>/us-west-2/APPLY`.

### Rotate / Update SFTP User SSH Keys

SFTP user SSH key management is performed outside this Terraform codebase via the AWS Console or AWS CLI:

```
aws transfer import-ssh-public-key \
  --server-id <SERVER_ID> \
  --user-name <USERNAME> \
  --ssh-public-key-body "$(cat /path/to/id_rsa.pub)"
```

### Update CloudWatch Log Retention

1. Edit `cloudwatch_log_expiration` in `envs/<environment>/us-west-2/env_vars.tfvars`.
2. Run `make <env>/us-west-2/sftp/Server/plan` to preview the change.
3. Run `make <env>/us-west-2/sftp/Server/APPLY`.

## Troubleshooting

### SFTP Client Cannot Connect

- **Symptoms**: Client receives connection refused or timeout when connecting to the SFTP endpoint
- **Cause**: AWS Transfer Family server may be in `OFFLINE` state, or the endpoint DNS has changed
- **Resolution**: Verify server state via `aws transfer describe-server --server-id <SERVER_ID>`; confirm client is using the correct server endpoint hostname; check AWS Service Health Dashboard

### File Upload Fails with Permission Denied

- **Symptoms**: SFTP client receives `SSH_FX_PERMISSION_DENIED` during `put` operation
- **Cause**: SFTP user's IAM scope-down policy does not permit write to the target path, or the user's home directory mapping is incorrect
- **Resolution**: Review the scope-down policy for the relevant bucket (e.g., `groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-edw`); verify that the user's home directory in AWS Transfer matches the policy's `$transfer:HomeDirectory` substitution

### CloudWatch Logs Not Appearing

- **Symptoms**: No log events in `/aws/transfer/<server-id>` despite active SFTP sessions
- **Cause**: `groupon-transfer-server-iam-role` may not be correctly attached, or the IAM policy `groupon-transfer-server-iam-policy` is missing required CloudWatch permissions
- **Resolution**: Verify via AWS Console that the server's logging role ARN matches `groupon-transfer-server-iam-role`; confirm the policy grants `logs:CreateLogStream`, `logs:DescribeLogStreams`, `logs:CreateLogGroup`, `logs:PutLogEvents`

### S3 Access Logs Not Appearing in Logging Bucket

- **Symptoms**: `{env}-groupon-transfer-s3-bucket-log` receives no `transfer-log/` entries
- **Cause**: S3 server access logging is enabled in Terraform but S3 may take up to a few hours to deliver first logs; or the logging bucket ACL (`log-delivery-write`) may have been modified
- **Resolution**: Verify logging configuration on the source bucket via `aws s3api get-bucket-logging --bucket <bucket-name>`; confirm the logging bucket has ACL `log-delivery-write`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | SFTP service completely unavailable; all file transfers blocked | Immediate | InfoSec on-call via PagerDuty `PLY1VT8`; Slack `#global-security` |
| P2 | Degraded transfer performance or partial bucket access failures | 30 min | InfoSec team (infosec@groupon.com); Jira `SECURITY` project |
| P3 | Log delivery delays, non-critical configuration drift | Next business day | Jira `SECURITY` project (https://jira.groupondev.com/projects/SECURITY/issues/SECURITY) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Transfer Family | AWS Service Health Dashboard; `aws transfer describe-server` | No fallback; service is unavailable if Transfer Family is down |
| Amazon S3 | AWS Service Health Dashboard; `aws s3 ls s3://<bucket-name>` | No fallback; file transfers fail if S3 is unavailable |
| AWS IAM | Implicit (if IAM is down, new sessions fail; existing sessions may continue briefly) | No fallback |
| Amazon CloudWatch Logs | Check log group ingestion in AWS Console | Log events may be dropped; transfers continue but audit trail is incomplete |
