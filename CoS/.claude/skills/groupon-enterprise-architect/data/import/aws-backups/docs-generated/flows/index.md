---
service: "aws-backups"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for AWS Backups.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Terraform Module Deployment](terraform-module-deployment.md) | batch | Manual operator `make APPLY` | Applies Terraform modules (service role, vaults, backup policies) to target AWS accounts |
| [Policy Attachment](policy-attachment.md) | batch | Manual operator `make APPLY` in `grpn-billing` | Creates org-level `BACKUP_POLICY` in management account and attaches it to source accounts |
| [Scheduled Backup Job](scheduled-backup-job.md) | scheduled | AWS Backup scheduler (cron expression in org policy) | AWS Backup executes a backup job on tag-selected resources and writes recovery points to the source vault |
| [Cross-Region Backup Copy (GDS)](gds-cross-region-copy.md) | scheduled | AWS Backup copy action (triggered after backup job) | AWS Backup copies GDS RDS/Aurora recovery points from source region vault to target region vault in the same account |
| [Cross-Account Backup Copy (Deadbolt)](deadbolt-cross-account-copy.md) | scheduled | AWS Backup copy action (triggered after backup job) | AWS Backup copies Deadbolt EC2/RDS recovery points from `grpn-security-prod` source vault to `grpn-backup-prod` target vault |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |
| Manual operator-driven | 2 |

## Cross-Service Flows

- The [Scheduled Backup Job](scheduled-backup-job.md) and copy flows span `gdsDataStores` (GDS RDS/Aurora) and `deadboltDataStores` (Deadbolt EC2/RDS) as the source resources.
- The [Policy Attachment](policy-attachment.md) flow spans `continuumBackupPolicies` / `continuumGdsBackupPolicies` / `continuumDeadboltBackupPolicies` containers and `awsOrganizationsControlPlane`.
- Architecture dynamic views referencing these flows: `dynamic-PolicyAttachmentFlow`, `dynamic-CrossAccountCopyFlow` (both currently disabled in federation — stub-only AWS API elements).
