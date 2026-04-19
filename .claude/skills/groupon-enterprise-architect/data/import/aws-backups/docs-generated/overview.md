---
service: "aws-backups"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Infrastructure / Cloud Operations"
platform: "Continuum (AWS Landing Zone)"
team: "Infrastructure Engineering"
status: active
tech_stack:
  language: "HCL (HashiCorp Configuration Language)"
  language_version: ""
  framework: "Terraform"
  framework_version: "1.0.2"
  runtime: "Terragrunt"
  runtime_version: ""
  build_tool: "GNU Make"
  package_manager: "Terragrunt module-ref"
---

# AWS Backups Overview

## Purpose

aws-backups is Groupon's Terraform repository that manages AWS Backup implementation across the Landing Zone multi-account AWS organization. It provisions backup vaults, organization-level backup policies, and the shared IAM service role required to allow AWS Backup to perform backup and restore operations across all participating accounts. The primary consumers are the GDS team (protecting RDS Aurora MySQL and PostgreSQL instances) and the Deadbolt/Infosec team (protecting EC2 instances and RDS SQL Server). The service exists to satisfy data-protection and compliance requirements for production databases and compute workloads by providing scheduled, encrypted, cross-account or cross-region recovery points.

## Scope

### In scope

- Provisioning the shared IAM service role (`grpn-backup-service-role`) with custom backup and restore permission policies to all source and target accounts
- Creating AWS Organizations backup policies (`BACKUP_POLICY` type) in the `grpn-billing` management account and attaching them to source accounts
- Provisioning backup vaults (source and target) with KMS customer-managed encryption keys in all supported regions and accounts
- Enabling AWS Backup resource-type opt-ins (`aws_backup_region_settings`) for all resource types per region
- Configuring SNS vault notifications for backup job failure, restore job, and copy job lifecycle events routed to `<backup-notifications-DL>`
- Configuring Vault Lock (WORM) on target vaults to enforce immutable minimum and maximum retention periods
- Defining backup schedules, lifecycle rules (cold storage promotion and deletion dates), and backup selection tags per team
- Cross-region copy configuration for GDS (same-account cross-region: `gds-monthly-2y` source vault to `gds-monthly-2y-copytarget`)
- Cross-account copy configuration for Deadbolt (cross-account same-region: `grpn-security-prod` to `grpn-backup-prod`, vault `deadbolt-weekly-1y`)

### Out of scope

- Running backup or restore jobs directly (those are executed by the AWS Backup service on behalf of `grpn-backup-service-role`)
- Provisioning the underlying RDS, Aurora, EC2, or other resources being backed up (owned by GDS and Deadbolt teams)
- Additional IAM cross-account roles defined in the AWSLandingZone repo (`grpn-all-crossaccount-backup-admin`, `grpn_all_backup_provisioner`, `grpn-all-backup-operator`, `grpn-all-general-ro-backup`)
- Application-level database migrations or data transformations during restore

## Domain Context

- **Business domain**: Infrastructure / Cloud Operations
- **Platform**: Continuum (AWS Landing Zone)
- **Upstream consumers**: GDS Team (`daas_mysql`, `daas_postgres` RDS/Aurora databases); Deadbolt/Infosec Team (EC2 instances, RDS SQL Server); AWS Backup scheduler (automated job execution)
- **Downstream dependencies**: AWS Organizations control plane, AWS IAM service, AWS Backup API, AWS KMS, AWS SNS, aws-landing-zone repo

## Stakeholders

| Role | Description |
|------|-------------|
| Infrastructure Engineering Team | Service owners; provision and operate the backup infrastructure (infrastructure-engineering@groupon.com) |
| Team Owner | kdeleon |
| Team Members | basingh, blopulisa, kdeleon, nleskiw |
| GDS Team | Primary consumer — RDS Aurora MySQL and PostgreSQL instances are backed up monthly |
| Deadbolt / Infosec Team | Consumer — EC2 instances and RDS SQL Server are backed up weekly |
| on-call (PagerDuty PTQJ9GG) | Incident escalation for backup infrastructure failures |
| <backup-notifications-DL> | Email distribution list receiving SNS vault notifications for all backup/restore/copy lifecycle events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL (HashiCorp Configuration Language) | — | `envs/**/*.hcl`, module `.tf` files |
| IaC framework | Terraform | 1.0.2 | `envs/.environment-template/.terraform-version` |
| Environment orchestration | Terragrunt | — | `envs/.terraform-tooling/Makefile`, all `terragrunt.hcl` files |
| Build tool | GNU Make | — | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Cloud provider | AWS (hashicorp/aws provider) | — | All Terraform modules |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| aws_backup_vault | AWS resource | storage | Creates encrypted backup vaults in source and target accounts |
| aws_backup_vault_policy | AWS resource | security | Controls cross-account `CopyIntoBackupVault` access on each vault |
| aws_organizations_policy | AWS resource | policy | Creates org-level `BACKUP_POLICY` content in billing account |
| aws_organizations_policy_attachment | AWS resource | policy | Attaches org backup policies to source account targets |
| aws_iam_role (`grpn-backup-service-role`) | AWS resource | auth | IAM role assumed by AWS Backup service for job execution |
| aws_kms_key / aws_kms_alias | AWS resource | encryption | Customer-managed keys for vault data encryption; cross-account grants |
| aws_sns_topic / aws_sns_topic_subscription | AWS resource | messaging | Delivers vault lifecycle event notifications to email |
| aws_backup_vault_notifications | AWS resource | monitoring | Binds vault events (`BACKUP_JOB_FAILED`, `RESTORE_JOB_*`, `COPY_JOB_FAILED`) to SNS |
| aws_backup_region_settings | AWS resource | configuration | Opts all resource types in to AWS Backup per region |
| aws_backup_vault_lock_configuration | AWS resource | compliance | Configures WORM vault lock with min/max retention on target vaults |

> Only the most important resources are listed here. See module `.tf` files for the full resource inventory.
