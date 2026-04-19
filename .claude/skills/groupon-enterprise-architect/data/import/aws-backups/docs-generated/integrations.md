---
service: "aws-backups"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

aws-backups integrates with five AWS control-plane services (as Terraform-managed resources) and two internal Groupon systems. All integrations are write-time (Terraform apply) rather than runtime — the service provisions configuration that the AWS Backup scheduler then acts on autonomously. The most critical integrations are AWS Organizations (policy distribution), AWS IAM (service role), AWS Backup (vaults and plans), AWS KMS (encryption), and AWS SNS (notifications).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Organizations control plane | AWS SDK (Terraform) | Creates org-level `BACKUP_POLICY` objects and attaches them to source accounts | yes | `awsOrganizationsControlPlane` |
| AWS IAM service | AWS SDK (Terraform) | Creates `grpn-backup-service-role` IAM role, custom backup/restore policies, and policy attachments | yes | `awsIamService` |
| AWS Backup API | AWS SDK (Terraform) | Creates backup vaults, vault policies, vault lock, region opt-ins, and vault notifications | yes | `awsBackupApi` |
| AWS KMS | AWS SDK (Terraform) | Creates customer-managed KMS keys and aliases for vault encryption; manages cross-account key grants | yes | `awsKmsApi` |
| AWS SNS | AWS SDK (Terraform) | Creates SNS topics and email subscriptions for vault lifecycle event delivery | no | `awsSnsApi` |

### AWS Organizations Control Plane Detail

- **Protocol**: AWS SDK via `hashicorp/aws` Terraform provider
- **Base URL / SDK**: AWS Organizations API (accessed via `grpn-all-crossaccount-backup-admin` IAM role in `grpn-billing` account)
- **Auth**: IAM role assumption — Terraform assumes `grpn-all-crossaccount-backup-admin` to manage policies in the management account
- **Purpose**: Pushes `BACKUP_POLICY` type organization policies from the `grpn-billing` management account down to source accounts. This is the mechanism by which AWS Backup backup plans are enforced across the entire organization without needing Terraform in every account.
- **Failure mode**: If the Organizations API is unavailable during Terraform apply, the policy apply fails and source accounts continue using previously attached policies. No data loss occurs.
- **Circuit breaker**: Not applicable (Terraform apply is idempotent and can be retried).

### AWS IAM Service Detail

- **Protocol**: AWS SDK via `hashicorp/aws` Terraform provider
- **Base URL / SDK**: AWS IAM API (accessed via `grpn_all_backup_provisioner` IAM role in each account)
- **Auth**: IAM role assumption per account
- **Purpose**: Creates and manages the `grpn-backup-service-role` IAM role that the AWS Backup service assumes to perform backup and restore operations on RDS, Aurora, EC2, EFS, DynamoDB, FSx, and S3 resources.
- **Failure mode**: If the role is missing or misconfigured, all backup and restore jobs in that account fail.
- **Circuit breaker**: Not applicable.

### AWS Backup API Detail

- **Protocol**: AWS SDK via `hashicorp/aws` Terraform provider
- **Base URL / SDK**: AWS Backup API (accessed via `grpn_all_backup_provisioner` IAM role)
- **Auth**: IAM role assumption per account and region
- **Purpose**: Creates and manages backup vaults (source and target), vault access policies, vault lock configurations, vault notifications bindings, and resource-type opt-in settings.
- **Failure mode**: If vaults are not provisioned, backup policies have no valid copy target and copy actions fail. Vault Lock once activated cannot be removed within the lock window.
- **Circuit breaker**: Not applicable.

### AWS KMS Detail

- **Protocol**: AWS SDK via `hashicorp/aws` Terraform provider
- **Base URL / SDK**: AWS KMS API
- **Auth**: IAM role assumption per account
- **Purpose**: Creates customer-managed KMS keys for encrypting backup vault contents. Cross-account key policies allow source account root users to use target account KMS keys during cross-account copy operations.
- **Failure mode**: If KMS keys are unavailable, backup/restore jobs that require encryption or decryption fail.
- **Circuit breaker**: Not applicable.

### AWS SNS Detail

- **Protocol**: AWS SDK via `hashicorp/aws` Terraform provider
- **Base URL / SDK**: AWS SNS API
- **Auth**: IAM role assumption per account
- **Purpose**: Creates one SNS topic per vault pair; subscribes `<backup-notifications-DL>` via email. Vault notification bindings route selected AWS Backup lifecycle events to these topics.
- **Failure mode**: SNS failure results in missed email notifications; backup jobs themselves are not affected.
- **Circuit breaker**: Not applicable.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| aws-landing-zone | Terraform / IAM | Provides cross-account IAM roles (`grpn-all-crossaccount-backup-admin`, `grpn_all_backup_provisioner`, `grpn-all-backup-operator`, `grpn-all-general-ro-backup`, `grpn-boundary-backup-provisioner`) used by this service | — |
| daas_mysql / daas_postgres | Tag-based selection (AWS resource tags) | GDS RDS Aurora MySQL and PostgreSQL instances are selected for backup via `key=Service, value=daas_mysql` and `key=Service, value=daas_postgres` tags | `gdsDataStores` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| GDS Team | AWS Backup API (manual restore) | Initiates restore operations from GDS recovery points using the `grpn-all-backup-operator` IAM role |
| Deadbolt / Infosec Team | AWS Backup API (manual restore) | Initiates restore operations from Deadbolt recovery points using the `grpn-all-backup-operator` IAM role |
| AWS Backup Scheduler | AWS internal | Automatically executes backup and copy jobs on the schedules defined in the org backup policies |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Terraform apply operations are idempotent and can be safely retried on transient AWS API failures. There are no circuit breakers or health checks at the application level — the service is infrastructure-only. Vault and policy state can be inspected via the AWS Console using the `grpn-all-general-ro-backup` read-only role in production accounts or the `grpn_all_backup_provisioner` role via CLI.
