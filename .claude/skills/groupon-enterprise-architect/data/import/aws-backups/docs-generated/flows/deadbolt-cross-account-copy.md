---
service: "aws-backups"
title: "Cross-Account Backup Copy (Deadbolt)"
generated: "2026-03-03"
type: flow
flow_name: "deadbolt-cross-account-copy"
flow_type: scheduled
trigger: "AWS Backup copy action fires after the Deadbolt backup job writes a recovery point to the source vault in grpn-security-prod"
participants:
  - "continuumDeadboltBackupPolicies"
  - "continuumBackupServiceRole"
  - "continuumDeadboltBackupVault"
  - "deadboltDataStores"
  - "awsBackupApi"
  - "awsKmsApi"
architecture_ref: "dynamic-CrossAccountCopyFlow"
---

# Cross-Account Backup Copy (Deadbolt)

## Summary

This flow describes how Deadbolt (Infosec team) EC2 instance and RDS SQL Server recovery points are copied from the source account (`grpn-security-prod`) to a dedicated backup target account (`grpn-backup-prod`). The cross-account pattern is used because Deadbolt resources use customer-managed KMS keys (CMK), which support cross-account copy. The copy action is defined in the `deadbolt_backup_policies` module and runs automatically every Monday. The target vault in `grpn-backup-prod` is protected by Vault Lock (WORM) with a 1-year minimum retention.

## Trigger

- **Type**: schedule (copy action, triggered after backup job completion)
- **Source**: AWS Backup copy action defined in the `deadbolt_backup_policies` org backup policy
- **Frequency**: Weekly (every Monday at 08:00 UTC, `cron(0 08 ? * MON *)`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumDeadboltBackupPolicies` | Defines the cross-account copy action in the org backup policy (target account, vault ARN, lifecycle) | `continuumDeadboltBackupPolicies` |
| `continuumBackupServiceRole` (`grpn-backup-service-role`) | IAM role assumed by AWS Backup in `grpn-security-prod` to perform backup and authorize cross-account copy | `continuumBackupServiceRole` |
| Deadbolt EC2 instances and RDS SQL Server | Source resources selected by tag `key=Backup, value=Deadbolt` in `grpn-security-prod` | `deadboltDataStores` |
| Deadbolt Source Vault (`deadbolt-weekly-1y` in `grpn-security-prod`) | Holds primary recovery points before cross-account copy; 7-day retention | `continuumDeadboltBackupVault` |
| Deadbolt Target Vault (`deadbolt-weekly-1y` in `grpn-backup-prod`) | Receives cross-account copies; WORM-locked; 1-year retention | `continuumDeadboltBackupVault` |
| AWS KMS (source and target keys) | Encrypts and re-encrypts recovery point data during cross-account transfer | `awsKmsApi` |

## Cross-Account Vault Mapping

| Source Account / Region | Source Vault | Target Account / Region | Target Vault |
|------------------------|-------------|------------------------|-------------|
| `grpn-security-prod` `us-west-2` | `deadbolt-weekly-1y` | `grpn-backup-prod` `us-west-2` | `deadbolt-weekly-1y` |

## Steps

1. **Backup job completes in source account**: The weekly Deadbolt backup job selects EC2 instances and RDS SQL Server resources tagged `key=Backup, value=Deadbolt` in `grpn-security-prod us-west-2` and writes recovery points to the source vault. See [Scheduled Backup Job](scheduled-backup-job.md).

2. **Copy action fires**: AWS Backup evaluates the `copy_actions` block in the Deadbolt org backup policy and initiates a cross-account copy job for the new recovery points
   - From: AWS Backup job engine (`grpn-security-prod`)
   - To: AWS Backup API (`grpn-backup-prod`)
   - Protocol: AWS internal cross-account copy

3. **Assume service role in source account**: AWS Backup assumes `grpn-backup-service-role` in `grpn-security-prod` to authorize copy operations
   - From: AWS Backup job engine
   - To: `awsIamService` (STS) in `grpn-security-prod`
   - Protocol: AWS STS AssumeRole

4. **Verify source vault cross-account copy policy**: AWS Backup confirms the source vault (`deadbolt-weekly-1y` in `grpn-security-prod`) allows `CopyIntoBackupVault` for the `grpn-backup-prod` target account root user (restore path only — so target account can copy back during restore)
   - From: AWS Backup job engine
   - To: `continuumDeadboltBackupVault` (source vault)
   - Protocol: AWS Backup vault policy evaluation

5. **Verify target vault access**: AWS Backup checks the target vault policy (`deadbolt-weekly-1y` in `grpn-backup-prod`) to confirm `CopyIntoBackupVault` is permitted for the organization
   - From: AWS Backup job engine
   - To: `continuumDeadboltBackupVault` (target vault in `grpn-backup-prod`)
   - Protocol: AWS Backup vault policy evaluation; vault allows `backup:CopyIntoBackupVault` for entire org (`o-scqs2lnin0`)

6. **Re-encrypt with target account KMS key**: AWS Backup re-encrypts the recovery point using the target account KMS key. The target KMS key policy in `grpn-backup-prod` grants `kms:GenerateDataKey`, `kms:ReEncrypt*`, and `kms:Decrypt` to `grpn-security-prod` account root
   - From: AWS Backup job engine
   - To: `awsKmsApi` (`grpn-backup-prod`)
   - Protocol: AWS KMS `GenerateDataKey` / `ReEncrypt` API calls

7. **Write recovery point to target vault**: AWS Backup writes the copied and re-encrypted recovery point to `deadbolt-weekly-1y` in `grpn-backup-prod`
   - From: AWS Backup job engine
   - To: `continuumDeadboltBackupVault` (target vault)
   - Protocol: AWS Backup API

8. **Apply lifecycle transition on target vault**: After 30 days, the recovery point transitions to cold storage. After 365 days (1 year), the recovery point is deleted.

9. **Apply source vault lifecycle**: The source vault recovery point in `grpn-security-prod` is deleted after 7 days.

10. **SNS notification on copy failure**: If the copy job fails, AWS Backup emits `COPY_JOB_FAILED` to the Deadbolt SNS topic
    - From: AWS Backup vault notification
    - To: `<backup-notifications-DL>`
    - Protocol: AWS SNS email delivery

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Resource encrypted with AWS-managed CMK | Cross-account copy blocked; AWS Backup reports error | Migrate resource to customer-managed CMK; AWS-managed CMK does not support cross-account copy |
| Target vault `CopyIntoBackupVault` policy missing | Copy fails with vault access denied | Re-apply `deadbolt_backup_vault` module in `grpn-backup-prod`; check vault policy |
| Target KMS key in `grpn-backup-prod` does not grant cross-account decrypt | Copy fails with KMS access denied | Re-apply vault module; check `deadboltKmsKeyManager` key policy grants to `grpn-security-prod` root |
| Vault Lock prevents recovery point deletion in target vault | Expected WORM behavior — recovery points are immutable for min 364 days | Do not attempt to delete locked recovery points; they expire naturally after the retention window |
| Source vault recovery point deleted (7-day lifecycle) before copy completes | Copy fails; recovery point no longer exists | If copy consistently takes more than 7 days, increase `backup_rules_lifecycle_delete_after_days` in Terragrunt inputs |

## Sequence Diagram

```
AWS Backup Job Engine (grpn-security-prod) -> deadboltDataStores: backup EC2 + RDS (tagged Backup=Deadbolt)
deadboltDataStores --> AWS Backup Job Engine: snapshots created
AWS Backup Job Engine -> continuumDeadboltBackupVault (source deadbolt-weekly-1y): write recovery point
continuumDeadboltBackupVault (source) --> AWS Backup Job Engine: recovery point ARN stored
AWS Backup Job Engine -> awsIamService (STS, grpn-security-prod): AssumeRole grpn-backup-service-role
awsIamService (STS) --> AWS Backup Job Engine: temporary credentials
AWS Backup Job Engine -> continuumDeadboltBackupVault (target deadbolt-weekly-1y, grpn-backup-prod): check vault policy (CopyIntoBackupVault permitted for org)
continuumDeadboltBackupVault (target) --> AWS Backup Job Engine: access confirmed
AWS Backup Job Engine -> awsKmsApi (grpn-backup-prod): ReEncrypt with target account KMS key
awsKmsApi (grpn-backup-prod) --> AWS Backup Job Engine: re-encrypted data key
AWS Backup Job Engine -> continuumDeadboltBackupVault (target deadbolt-weekly-1y): write copied recovery point
continuumDeadboltBackupVault (target) --> AWS Backup Job Engine: cross-account copy complete
AWS Backup Job Engine -> awsSnsApi: publish COPY_JOB_FAILED (if failure only)
awsSnsApi -> <backup-notifications-DL>: email notification
```

## Related

- Architecture dynamic view: `dynamic-CrossAccountCopyFlow`
- Related flows: [Scheduled Backup Job](scheduled-backup-job.md), [Cross-Region Backup Copy (GDS)](gds-cross-region-copy.md)
