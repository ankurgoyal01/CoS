---
service: "aws-backups"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumBackupPolicies"
    - "continuumGdsBackupPolicies"
    - "continuumDeadboltBackupPolicies"
    - "continuumBackupServiceRole"
    - "continuumBackupVault"
    - "continuumGdsBackupVault"
    - "continuumDeadboltBackupVault"
---

# Architecture Context

## System Context

aws-backups lives within the `continuumSystem` (Continuum Platform) in Groupon's C4 model. It is a pure infrastructure service — there is no running application process. The service provisions Terraform resources that configure the AWS Backup service across Groupon's multi-account AWS Landing Zone. It interacts outward with three AWS control planes: AWS Organizations (policy creation and attachment via the `grpn-billing` management account), AWS IAM (service role provisioning in each account), and the AWS Backup/KMS/SNS APIs (vault, encryption, and notification provisioning). Inward, the GDS and Deadbolt teams' source accounts are the beneficiaries of the backup policies pushed down from the management account.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| backup_policies module | `continuumBackupPolicies` | Terraform module | HCL / Terraform | Creates generic org-level backup policies and attaches them to source accounts via the billing account |
| gds_backup_policies module | `continuumGdsBackupPolicies` | Terraform module | HCL / Terraform | Creates GDS-specific cross-region backup policies targeting RDS/Aurora resources by `Service` tag |
| deadbolt_backup_policies module | `continuumDeadboltBackupPolicies` | Terraform module | HCL / Terraform | Creates Deadbolt-specific cross-account backup policies targeting EC2/RDS by `Backup` tag |
| backup_service_role module | `continuumBackupServiceRole` | Terraform module | HCL / Terraform | Provisions the `grpn-backup-service-role` IAM role with backup and restore permission policies |
| backup_vault module | `continuumBackupVault` | Terraform module | HCL / Terraform | Creates generic source/target vaults, KMS keys, SNS notifications, and region opt-in settings |
| gds_backup_vault module | `continuumGdsBackupVault` | Terraform module | HCL / Terraform | Creates GDS source/target vaults for same-account cross-region copy, with optional Vault Lock |
| deadbolt_backup_vault module | `continuumDeadboltBackupVault` | Terraform module | HCL / Terraform | Creates Deadbolt source/target vaults for cross-account backup with Vault Lock enforced |

## Components by Container

### backup_policies module (`continuumBackupPolicies`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Policy Template Builder | Builds `BACKUP_POLICY` JSON payloads from module input variables | HCL templatefile |
| Organizations Policy Resource | Represents `aws_organizations_policy` resources created in `grpn-billing` | Terraform resource |
| Policy Attachment Manager | Represents `aws_organizations_policy_attachment` resources binding policies to source account IDs | Terraform resource |
| Region Opt-In Manager | Represents `aws_backup_region_settings` opt-in for all AWS Backup resource types | Terraform resource |

### gds_backup_policies module (`continuumGdsBackupPolicies`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GDS Policy Template Builder | Builds GDS `BACKUP_POLICY` JSON for cross-region copy actions with monthly schedule | HCL templatefile |
| GDS Organizations Policy Resource | `aws_organizations_policy` scoped to the GDS backup plan | Terraform resource |
| GDS Policy Attachment Manager | `aws_organizations_policy_attachment` binding to `grpn-prod` source account | Terraform resource |
| GDS Region Opt-In Manager | `aws_backup_region_settings` opt-in for GDS regions | Terraform resource |

### deadbolt_backup_policies module (`continuumDeadboltBackupPolicies`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deadbolt Policy Template Builder | Builds Deadbolt `BACKUP_POLICY` JSON for cross-account copy with weekly schedule | HCL templatefile |
| Deadbolt Organizations Policy Resource | `aws_organizations_policy` scoped to the Deadbolt backup plan | Terraform resource |
| Deadbolt Policy Attachment Manager | `aws_organizations_policy_attachment` binding to `grpn-security-prod` source account | Terraform resource |
| Deadbolt Region Opt-In Manager | `aws_backup_region_settings` opt-in for Deadbolt regions | Terraform resource |

### backup_service_role module (`continuumBackupServiceRole`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Assume Role Trust Policy | Trust policy allowing `backup.amazonaws.com` to assume `grpn-backup-service-role` | `aws_iam_policy_document` |
| Backup Permissions Policy | Custom IAM policy with RDS/EC2/EFS/DynamoDB/FSx/S3 backup actions | `aws_iam_policy` |
| Restore Permissions Policy | Custom IAM policy with RDS/EC2/EFS/DynamoDB/FSx/S3 restore actions | `aws_iam_policy` |
| Service Role Definition | `aws_iam_role` named `grpn-backup-service-role` with permissions boundary | Terraform resource |
| Role Policy Attachments | `aws_iam_role_policy_attachment` resources binding custom backup and restore policies | Terraform resource |

### backup_vault module (`continuumBackupVault`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Target Vault Provisioner | Creates target `aws_backup_vault` with KMS key; vault policy allows `CopyIntoBackupVault` for entire LZ org | Terraform resource |
| Source Vault Provisioner | Creates source `aws_backup_vault` with KMS key; vault policy allows restore copy to target account root only | Terraform resource |
| KMS Key Manager | Creates source and target `aws_kms_key` + `aws_kms_alias`; target key grants cross-account decrypt to source account roots | Terraform resource |
| Vault Notification Manager | Creates `aws_sns_topic`, `aws_sns_topic_subscription`, and `aws_backup_vault_notifications` for lifecycle events | Terraform resource |
| Vault Region Opt-In Manager | `aws_backup_region_settings` enabling all AWS resource types for backup | Terraform resource |

### gds_backup_vault module (`continuumGdsBackupVault`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GDS Target Vault Provisioner | Creates GDS cross-region copytarget vault (`gds-monthly-2y-copytarget`) with vault copy-in policy | Terraform resource |
| GDS Source Vault Provisioner | Creates GDS source vault (`gds-monthly-2y`) with restore copy policy | Terraform resource |
| GDS KMS Key Manager | KMS keys and aliases for GDS vault encryption | Terraform resource |
| GDS Vault Lock Manager | Configures `aws_backup_vault_lock_configuration` on target vault (WORM: min 729 days, max 731 days, changeable for 30 days) | Terraform resource |
| GDS Vault Notification Manager | SNS topic/subscriptions and vault notifications for GDS source and target vaults | Terraform resource |

### deadbolt_backup_vault module (`continuumDeadboltBackupVault`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deadbolt Target Vault Provisioner | Creates Deadbolt target vault (`deadbolt-weekly-1y`) in `grpn-backup-prod` with copy-in policy | Terraform resource |
| Deadbolt Source Vault Provisioner | Creates Deadbolt source vault (`deadbolt-weekly-1y`) in `grpn-security-prod` with restore copy policy | Terraform resource |
| Deadbolt KMS Key Manager | KMS keys and aliases for Deadbolt vault encryption | Terraform resource |
| Deadbolt Vault Lock Manager | Vault Lock on target vault (WORM: min 364 days, max 731 days, changeable for 60 days) | Terraform resource |
| Deadbolt Vault Notification Manager | SNS topic/subscriptions and backup vault notifications for Deadbolt vaults | Terraform resource |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBackupPolicies` | `awsOrganizationsControlPlane` | Creates `aws_organizations_policy` and `aws_organizations_policy_attachment` resources | AWS SDK (Terraform) |
| `continuumBackupPolicies` | `continuumBackupServiceRole` | References `grpn-backup-service-role` ARN in BACKUP_POLICY selections | Terraform dependency |
| `continuumBackupPolicies` | `continuumBackupVault` | References target vault ARN for `copy_actions` in generic flows | Terraform dependency |
| `continuumGdsBackupPolicies` | `awsOrganizationsControlPlane` | Creates GDS org backup policies and account attachments | AWS SDK (Terraform) |
| `continuumGdsBackupPolicies` | `continuumBackupServiceRole` | References `grpn-backup-service-role` ARN in GDS selections | Terraform dependency |
| `continuumGdsBackupPolicies` | `continuumGdsBackupVault` | References GDS copytarget vault ARN for cross-region copy | Terraform dependency |
| `continuumDeadboltBackupPolicies` | `awsOrganizationsControlPlane` | Creates Deadbolt org backup policies and account attachments | AWS SDK (Terraform) |
| `continuumDeadboltBackupPolicies` | `continuumBackupServiceRole` | References `grpn-backup-service-role` ARN in Deadbolt selections | Terraform dependency |
| `continuumDeadboltBackupPolicies` | `continuumDeadboltBackupVault` | References Deadbolt target vault ARN for cross-account copy | Terraform dependency |
| `continuumBackupServiceRole` | `awsIamService` | Creates IAM role, custom IAM policies, and policy attachments | AWS SDK (Terraform) |
| `continuumBackupVault` | `continuumBackupServiceRole` | Depends on backup service role deployment in environment wiring | Terragrunt dependency |
| `continuumGdsBackupVault` | `continuumBackupServiceRole` | Depends on backup service role deployment in environment wiring | Terragrunt dependency |
| `continuumDeadboltBackupVault` | `continuumBackupServiceRole` | Depends on backup service role deployment in environment wiring | Terragrunt dependency |

## Architecture Diagram References

- Component views: `components-continuumBackupPolicies`, `components-continuumGdsBackupPolicies`, `components-continuumDeadboltBackupPolicies`, `components-continuumBackupServiceRole`, `components-continuumBackupVault`, `components-continuumGdsBackupVault`, `components-continuumDeadboltBackupVault`
- Dynamic views (disabled in federation — stub-only AWS API elements not in central workspace): `dynamic-CrossAccountCopyFlow`, `dynamic-PolicyAttachmentFlow`
