---
service: "aws-backups"
title: "Scheduled Backup Job"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-backup-job"
flow_type: scheduled
trigger: "AWS Backup scheduler fires the cron expression defined in the org backup policy"
participants:
  - "continuumGdsBackupPolicies"
  - "continuumDeadboltBackupPolicies"
  - "continuumBackupServiceRole"
  - "continuumGdsBackupVault"
  - "continuumDeadboltBackupVault"
  - "gdsDataStores"
  - "deadboltDataStores"
architecture_ref: "dynamic-CrossAccountCopyFlow"
---

# Scheduled Backup Job

## Summary

This flow describes how the AWS Backup service automatically executes a scheduled backup job in a source account based on the backup plan propagated from the `grpn-billing` org backup policy. AWS Backup selects all resources matching the configured backup selection tags, assumes the `grpn-backup-service-role` IAM role, takes a snapshot (recovery point) of each resource, and writes it to the source backup vault. The backup plan also triggers a copy action to move the recovery point to the target vault (cross-region for GDS, cross-account for Deadbolt).

## Trigger

- **Type**: schedule
- **Source**: AWS Backup scheduler executing the cron expression from the org backup policy
- **Frequency**:
  - GDS prod (us-west-2): 1st of every month at 18:00 UTC (`cron(00 18 1 * ? *)`)
  - GDS prod (eu-west-1): 1st of every month at 14:00 UTC (`cron(00 14 1 * ? *)`)
  - GDS stable: daily at 00:30 UTC (`cron(30 00 ? * * *)`)
  - Deadbolt prod: every Monday at 08:00 UTC (`cron(0 08 ? * MON *)`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AWS Backup scheduler | Initiates backup job at the scheduled time | — |
| `continuumBackupServiceRole` (`grpn-backup-service-role`) | IAM role assumed by AWS Backup to access resources and write to vaults | `continuumBackupServiceRole` |
| GDS RDS/Aurora instances (`daas_mysql`, `daas_postgres`) | Source resources selected for backup by `Service` tag | `gdsDataStores` |
| Deadbolt EC2 / RDS SQL Server instances | Source resources selected for backup by `Backup` tag | `deadboltDataStores` |
| `continuumGdsBackupVault` (source vault `gds-monthly-2y`) | Receives GDS recovery points written by the backup job | `continuumGdsBackupVault` |
| `continuumDeadboltBackupVault` (source vault `deadbolt-weekly-1y`) | Receives Deadbolt recovery points written by the backup job | `continuumDeadboltBackupVault` |

## Steps

1. **Schedule fires**: AWS Backup scheduler evaluates the cron expression in the active backup plan (propagated from org policy) and initiates a new backup job
   - From: AWS Backup scheduler
   - To: AWS Backup job engine
   - Protocol: AWS internal

2. **Select resources by tag**: AWS Backup identifies all resources in the source account/region matching the backup selection tag filter
   - GDS selection: `key=Service`, `value=daas_mysql` OR `value=daas_postgres`
   - Deadbolt selection: `key=Backup`, `value=Deadbolt`
   - Protocol: AWS resource tagging API

3. **Assume service role**: AWS Backup job engine assumes `grpn-backup-service-role` to obtain permissions for backup operations
   - From: AWS Backup job engine
   - To: `awsIamService` (STS)
   - Protocol: AWS STS AssumeRole; trust policy allows `backup.amazonaws.com` principal

4. **Take snapshot (create recovery point)**: AWS Backup creates a snapshot of each selected resource (RDS snapshot for Aurora/PostgreSQL/MySQL, EC2 AMI + EBS snapshot for EC2 instances)
   - From: `grpn-backup-service-role`
   - To: GDS RDS/Aurora or Deadbolt EC2/RDS resources
   - Protocol: AWS SDK (RDS `CreateDBClusterSnapshot`, EC2 `CreateImage`, etc.)

5. **Write recovery point to source vault**: AWS Backup stores the recovery point metadata in the source backup vault
   - From: AWS Backup job engine
   - To: `continuumGdsBackupVault` (`gds-monthly-2y`) or `continuumDeadboltBackupVault` (`deadbolt-weekly-1y` in source account)
   - Protocol: AWS Backup API; uses source vault KMS key for encryption

6. **SNS notification on completion or failure**: AWS Backup emits a `BACKUP_JOB_FAILED` or `BACKUP_JOB_EXPIRED` event to the configured SNS topic if the job does not succeed
   - From: AWS Backup vault notification
   - To: `<backup-notifications-DL>` via SNS email subscription
   - Protocol: AWS SNS email delivery

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Resource missing or stopped | Backup job fails with `BACKUP_JOB_FAILED` event; SNS notification sent | Automatic retry at next scheduled window; operator alerted via email |
| `grpn-backup-service-role` not found in account | Backup job fails immediately | Operator must re-apply `backup_service_role` module |
| Resource encrypted with AWS-managed CMK (cross-account restriction) | Backup job succeeds but subsequent cross-account copy fails | Use cross-region copy instead; see [Cross-Region Backup Copy (GDS)](gds-cross-region-copy.md) |
| Vault KMS key unavailable | Recovery point write fails | Check KMS key status; re-enable key if disabled |
| Backup job expires before completing | `BACKUP_JOB_EXPIRED` event; SNS notification sent | Large snapshots may timeout; contact IE team to tune job window |

## Sequence Diagram

```
AWS Backup Scheduler -> AWS Backup Job Engine: trigger backup job (cron fires)
AWS Backup Job Engine -> AWS Resource Tags API: list resources with selection tags
AWS Resource Tags API --> AWS Backup Job Engine: list of matching resource ARNs
AWS Backup Job Engine -> awsIamService (STS): AssumeRole grpn-backup-service-role
awsIamService (STS) --> AWS Backup Job Engine: temporary credentials
AWS Backup Job Engine -> GDS RDS/Aurora (or Deadbolt EC2/RDS): CreateSnapshot / CreateImage
GDS RDS/Aurora --> AWS Backup Job Engine: snapshot ARN
AWS Backup Job Engine -> continuumGdsBackupVault (gds-monthly-2y): write recovery point (encrypted)
continuumGdsBackupVault --> AWS Backup Job Engine: recovery point ARN stored
AWS Backup Job Engine -> awsSnsApi: publish BACKUP_JOB_FAILED (if failure only)
awsSnsApi -> <backup-notifications-DL>: email notification
```

## Related

- Architecture dynamic view: `dynamic-CrossAccountCopyFlow`
- Related flows: [Cross-Region Backup Copy (GDS)](gds-cross-region-copy.md), [Cross-Account Backup Copy (Deadbolt)](deadbolt-cross-account-copy.md)
