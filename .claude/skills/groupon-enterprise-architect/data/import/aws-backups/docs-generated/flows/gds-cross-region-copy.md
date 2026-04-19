---
service: "aws-backups"
title: "Cross-Region Backup Copy (GDS)"
generated: "2026-03-03"
type: flow
flow_name: "gds-cross-region-copy"
flow_type: scheduled
trigger: "AWS Backup copy action fires after the GDS backup job writes a recovery point to the source vault"
participants:
  - "continuumGdsBackupPolicies"
  - "continuumBackupServiceRole"
  - "continuumGdsBackupVault"
  - "awsBackupApi"
  - "awsKmsApi"
architecture_ref: "dynamic-CrossAccountCopyFlow"
---

# Cross-Region Backup Copy (GDS)

## Summary

This flow describes how GDS RDS/Aurora recovery points are copied from a source region vault to a target region vault within the same AWS account (`grpn-prod`). Because some GDS databases are encrypted with AWS-managed CMK (which cannot be copied cross-account), a same-account cross-region copy pattern is used instead. The copy action is defined in the `gds_backup_policies` module and runs automatically after each scheduled backup job. Target vaults are protected by Vault Lock (WORM) with a 2-year retention window.

## Trigger

- **Type**: schedule (copy action, triggered after backup job completion)
- **Source**: AWS Backup copy action defined in the `gds_backup_policies` org backup policy
- **Frequency**: Monthly (1st of month) — immediately follows the backup job for each `grpn-prod` region

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumGdsBackupPolicies` | Defines the copy action in the org backup policy (target vault ARN, lifecycle, service role) | `continuumGdsBackupPolicies` |
| `continuumBackupServiceRole` (`grpn-backup-service-role`) | IAM role assumed by AWS Backup to authorize cross-region copy operations | `continuumBackupServiceRole` |
| GDS Source Vault (`gds-monthly-2y`) | Source vault holding the primary recovery point in the source region | `continuumGdsBackupVault` |
| GDS Target Vault (`gds-monthly-2y-copytarget`) | Target vault in the cross-region destination; WORM-locked | `continuumGdsBackupVault` |
| AWS KMS (source and target keys) | Encrypts/decrypts the recovery point during cross-region transfer | `awsKmsApi` |

## Cross-Region Vault Mapping

| Source Account / Region | Source Vault | Target Account / Region | Target Vault |
|------------------------|-------------|------------------------|-------------|
| `grpn-prod` `us-west-1` | `gds-monthly-2y` | `grpn-prod` `us-west-2` | `gds-monthly-2y-copytarget` |
| `grpn-prod` `us-west-2` | `gds-monthly-2y` | `grpn-prod` `us-west-1` | `gds-monthly-2y-copytarget` |
| `grpn-prod` `eu-west-1` | `gds-monthly-2y` | `grpn-prod` `eu-central-1` | `gds-monthly-2y-copytarget` |

## Steps

1. **Backup job completes**: The scheduled GDS backup job writes a recovery point to the source vault (`gds-monthly-2y`) in the source region. See [Scheduled Backup Job](scheduled-backup-job.md).

2. **Copy action fires**: AWS Backup evaluates the `copy_actions` block in the active backup plan and initiates a cross-region copy job for each recovery point
   - From: AWS Backup job engine (source region)
   - To: AWS Backup API (target region)
   - Protocol: AWS internal cross-region copy

3. **Assume service role**: AWS Backup assumes `grpn-backup-service-role` to authorize the copy operation
   - From: AWS Backup job engine
   - To: `awsIamService` (STS)
   - Protocol: AWS STS AssumeRole

4. **Verify target vault access**: AWS Backup checks the target vault policy (`gds-monthly-2y-copytarget`) to confirm `CopyIntoBackupVault` is permitted
   - From: AWS Backup job engine
   - To: `continuumGdsBackupVault` (target vault in target region)
   - Protocol: AWS Backup vault policy evaluation; vault allows `backup:CopyIntoBackupVault` for the entire org (`o-scqs2lnin0`)

5. **Re-encrypt with target KMS key**: AWS Backup re-encrypts the recovery point data using the target region KMS key. The target KMS key policy grants cross-account decrypt permissions to source account root, enabling the copy
   - From: AWS Backup job engine
   - To: `awsKmsApi` (target region)
   - Protocol: AWS KMS `GenerateDataKey` / `ReEncrypt` API calls

6. **Write recovery point to target vault**: AWS Backup writes the copied recovery point to `gds-monthly-2y-copytarget` in the target region
   - From: AWS Backup job engine
   - To: `continuumGdsBackupVault` (target vault)
   - Protocol: AWS Backup API

7. **Apply lifecycle transition**: After 30 days, the copy target recovery point transitions to cold storage. After 730 days (2 years), the recovery point is deleted.

8. **Apply source vault lifecycle**: The source vault recovery point is deleted after 3 days (short-lived; the cross-region copy is the long-term retention copy)

9. **SNS notification on copy failure**: If the copy job fails, AWS Backup emits `COPY_JOB_FAILED` to the SNS topic
   - From: AWS Backup vault notification
   - To: `<backup-notifications-DL>`
   - Protocol: AWS SNS email delivery

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Target vault does not exist in target region | Copy job fails with vault not-found error | Operator must apply `gds_backup_vault` module in target region; retry will occur at next backup window |
| Target vault KMS key policy missing cross-account grant | Copy fails with KMS access denied | Re-apply vault module; check `kmsKeyManager` component has correct key policy |
| Source recovery point deleted before copy completes | Copy fails with recovery point not-found | Recovery point lifecycle (3 days) allows ample time for copy; investigate if copy takes longer than expected |
| Vault Lock prevents modification of target vault | Expected behavior — WORM is intentional | Do not attempt to delete or modify Vault Lock during the lock window (30 days for GDS) |

## Sequence Diagram

```
AWS Backup Job Engine -> continuumGdsBackupVault (source gds-monthly-2y): backup job writes recovery point
continuumGdsBackupVault --> AWS Backup Job Engine: recovery point ARN in source region
AWS Backup Job Engine -> awsIamService (STS): AssumeRole grpn-backup-service-role
awsIamService (STS) --> AWS Backup Job Engine: temporary credentials
AWS Backup Job Engine -> continuumGdsBackupVault (target gds-monthly-2y-copytarget): check vault policy (CopyIntoBackupVault permitted)
continuumGdsBackupVault (target) --> AWS Backup Job Engine: access confirmed
AWS Backup Job Engine -> awsKmsApi (target region): ReEncrypt with target KMS key
awsKmsApi --> AWS Backup Job Engine: re-encrypted data key
AWS Backup Job Engine -> continuumGdsBackupVault (target gds-monthly-2y-copytarget): write copied recovery point
continuumGdsBackupVault (target) --> AWS Backup Job Engine: copy job complete
AWS Backup Job Engine -> awsSnsApi: publish COPY_JOB_FAILED (if failure only)
awsSnsApi -> <backup-notifications-DL>: email notification
```

## Related

- Architecture dynamic view: `dynamic-CrossAccountCopyFlow`
- Related flows: [Scheduled Backup Job](scheduled-backup-job.md), [Cross-Account Backup Copy (Deadbolt)](deadbolt-cross-account-copy.md)
