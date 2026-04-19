---
service: "aws-backups"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Mechanism | Type | Description |
|-----------|------|-------------|
| AWS Backup Console | manual | Inspect backup job status in the AWS Console using the `grpn-all-general-ro-backup` read-only IAM role in production accounts |
| SNS email notification | event-driven | `<backup-notifications-DL>` receives emails for `BACKUP_JOB_FAILED`, `BACKUP_JOB_EXPIRED`, `RESTORE_JOB_*`, and `COPY_JOB_FAILED` events |
| Wavefront dashboard | dashboard | https://groupon.wavefront.com/dashboard/aws-backups (tag: `aws-backups`) |
| PagerDuty | alerting | Service PTQJ9GG — escalation for critical backup failures |

> No HTTP health endpoint exists. Status endpoint is disabled (`status_endpoint.disabled: true`).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Backup job success rate | gauge | Percentage of scheduled backup jobs completing successfully | Alert on any `BACKUP_JOB_FAILED` or `BACKUP_JOB_EXPIRED` event |
| Copy job success rate | gauge | Percentage of cross-region / cross-account copy jobs completing successfully | Alert on any `COPY_JOB_FAILED` event |
| Restore job duration | gauge | Time to complete a restore job initiated by operators | No automated alert; manual monitoring |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AWS Backups Overview | Wavefront | https://groupon.wavefront.com/dashboard/aws-backups |
| AWS Backups Alerts | Wavefront | https://groupon.wavefront.com/u/pbZS7gQMqX?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `BACKUP_JOB_FAILED` | AWS Backup job fails to complete | Error | Check SNS email for error message; verify resource tags, resource availability, IAM role permissions; see troubleshooting section |
| `BACKUP_JOB_EXPIRED` | AWS Backup job exceeds window before completing | Error | Check if source RDS/EC2 resources are running; verify schedule cron expression; re-run manually if needed |
| `COPY_JOB_FAILED` | Cross-account or cross-region copy fails | Error | Check KMS key policies for cross-account grants; verify vault policies allow `CopyIntoBackupVault`; check encryption key type (AWS-managed CMK not supported for cross-account) |
| `RESTORE_JOB_FAILED` | Restore job fails to complete | Error | Check IAM restore permissions; verify target account has sufficient resource quotas; review AWS CloudTrail logs |

## Common Operations

### Apply / Update Terraform Module

```
cd envs
make <account>/<region>/<module>/plan    # review plan output
make <account>/<region>/<module>/APPLY   # apply changes
```

Use `grpn_all_backup_provisioner` IAM role for vault/role modules; use `grpn-all-crossaccount-backup-admin` role for policy modules in `grpn-billing`.

### Plan and Destroy a Module

```
cd envs
make <account>/<region>/<module>/plan-destroy
make <account>/<region>/<module>/DESTROY
```

> Caution: destroying a target vault with Vault Lock enabled is not possible within the lock window. Vault Lock (`WORM`) is permanent once activated.

### Manual Backup Job

Operators with the `grpn-all-backup-operator` IAM role can initiate a manual on-demand backup job via the AWS CLI or Console. Refer to [AWS Backups Restores confluence page](https://groupondev.atlassian.net/wiki/spaces/PRODOPS/pages/55045747316/AWS+Backups+Restores) for examples.

### Scale Up / Down

> Not applicable. AWS Backup is a managed AWS service and scales automatically.

### Database Operations

> Not applicable. aws-backups does not own any databases. Recovery point management is performed through the AWS Backup console or CLI.

## Troubleshooting

### Backup Job Failed — Resource Not Found or Stopped

- **Symptoms**: SNS email with `BACKUP_JOB_FAILED` error referencing a specific RDS or EC2 resource ARN
- **Cause**: The resource tagged for backup may be stopped, deleted, or has changed its ARN
- **Resolution**: Verify that the tagged RDS/EC2 resource (`key=Service, value=daas_mysql/daas_postgres` for GDS; `key=Backup, value=Deadbolt` for Deadbolt) exists and is in an available state. If the resource was replaced, update tags accordingly. The next scheduled backup will retry automatically.

### Copy Job Failed — Unsupported Encryption Key

- **Symptoms**: SNS email with `COPY_JOB_FAILED` for cross-account copy; error mentions KMS or encryption
- **Cause**: Resources encrypted with AWS-managed CMK cannot be copied cross-account. Only customer-managed CMK (CMK) and unencrypted resources are supported for cross-account backup copy.
- **Resolution**: Confirm resource encryption type in RDS console. If AWS-managed CMK, migrate the resource to a customer-managed CMK or use same-account cross-region copy instead. Refer to the GDS implementation for the cross-region pattern.

### Copy Job Failed — Vault Policy Issue

- **Symptoms**: SNS email with `COPY_JOB_FAILED`; AWS CloudTrail shows access denied on `CopyIntoBackupVault`
- **Cause**: Target vault policy may not allow the source account's `grpn-backup-service-role` to copy into the vault, or the KMS key policy may be missing cross-account grants
- **Resolution**:
  1. Verify target vault policy allows `CopyIntoBackupVault` for the organization (`o-scqs2lnin0`) or the specific source account
  2. Verify target KMS key policy grants `kms:GenerateDataKey`, `kms:ReEncrypt*`, and `kms:Decrypt` to source account root
  3. Re-apply vault module if policy drift is detected: `make <account>/<region>/<vault_module>/APPLY`

### Backup Policy Not Applied to Account

- **Symptoms**: Backup jobs never run in a source account; no backup records appear in AWS Backup console
- **Cause**: The `aws_organizations_policy_attachment` may not have been applied, or the backup policy may have a syntax error
- **Resolution**:
  1. Check AWS Organizations in `grpn-billing` console: verify the backup policy exists and is attached to the target account
  2. Check the policy content is valid JSON (`BACKUP_POLICY` format)
  3. Verify `grpn-backup-service-role` is deployed in the source account (`grpn-prod/global/backup_service_role`)
  4. Re-apply the relevant policy module in `grpn-billing`

### Incorrect Backup Tags on Resource

- **Symptoms**: A resource that should be backed up has no recovery points
- **Cause**: Resource is missing the required backup selection tag
- **Resolution**: For GDS resources, add tag `key=Service, value=daas_mysql` or `key=Service, value=daas_postgres`. For Deadbolt resources, add tag `key=Backup, value=Deadbolt`. Wait for next scheduled backup window.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Production backup vault inaccessible; all backup/restore jobs failing | Immediate | Infrastructure Engineering team; PagerDuty PTQJ9GG |
| P2 | Single backup job type failing (e.g., all copy jobs fail); individual vault misconfigured | 30 min | Infrastructure Engineering team; infrastructure-engineering@groupon.com |
| P3 | Single resource not being backed up; notification alert misfiring | Next business day | Infrastructure Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Organizations | Verify backup policies are listed in `grpn-billing` AWS Console > Organizations > Policies | Existing policies remain attached; no new changes until API recovers |
| AWS IAM | Verify `grpn-backup-service-role` exists in each account via IAM Console | Backup jobs fail to start without the service role |
| AWS Backup API | Check job status in AWS Backup Console per account/region | Jobs queue until API recovers |
| AWS KMS | Verify KMS key status is `Enabled` in the KMS console for each vault key | Backup/restore operations requiring encryption fail |
| AWS SNS | Verify topic exists and subscription is confirmed in each account | Notifications silently lost; job outcomes must be checked manually in console |
