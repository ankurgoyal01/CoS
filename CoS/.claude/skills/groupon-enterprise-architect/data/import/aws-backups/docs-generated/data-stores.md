---
service: "aws-backups"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gds-monthly-2y"
    type: "aws-backup-vault"
    purpose: "GDS source backup vault storing RDS/Aurora recovery points in source region"
  - id: "gds-monthly-2y-copytarget"
    type: "aws-backup-vault"
    purpose: "GDS target backup vault receiving cross-region copies of GDS recovery points"
  - id: "deadbolt-weekly-1y"
    type: "aws-backup-vault"
    purpose: "Deadbolt source vault (grpn-security-prod) and target vault (grpn-backup-prod) for cross-account backup"
---

# Data Stores

## Overview

aws-backups does not own any relational databases or caches. The data stores it provisions are AWS Backup Vaults — encrypted object stores managed by the AWS Backup service. Recovery points (backup snapshots) written to these vaults contain the actual backup data for GDS RDS/Aurora databases and Deadbolt EC2/RDS instances. All vaults are KMS-encrypted with customer-managed keys provisioned by this service. Target vaults in production are protected by Vault Lock (WORM).

## Stores

### GDS Source Vault (`gds-monthly-2y`)

| Property | Value |
|----------|-------|
| Type | AWS Backup Vault |
| Architecture ref | `continuumGdsBackupVault` |
| Purpose | Stores monthly RDS/Aurora recovery points in the source region; short-lived (3-day retention before cross-region copy) |
| Ownership | Owned — provisioned by `continuumGdsBackupVault` module |
| Deployed in | `grpn-prod` account; regions: `us-west-1`, `us-west-2`, `eu-west-1` |
| Encryption | Customer-managed KMS key created by `continuumGdsBackupVault` |
| Vault Lock | Not enabled on source vault |
| Vault policy | Allows restore copy-back to target account root user only |

#### Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|-----------|
| Recovery Point | Snapshot of a GDS RDS/Aurora instance | `resource_arn`, `backup_plan_id`, `creation_date`, `lifecycle` |

#### Access Patterns

- **Write**: AWS Backup service writes recovery points using `grpn-backup-service-role` on the monthly schedule (`cron(00 18 1 * ? *)` for US-West-2 prod)
- **Read**: AWS Backup service reads recovery points to execute cross-region copy actions
- **Indexes**: Not applicable (AWS Backup vault)

---

### GDS Target Vault (`gds-monthly-2y-copytarget`)

| Property | Value |
|----------|-------|
| Type | AWS Backup Vault |
| Architecture ref | `continuumGdsBackupVault` |
| Purpose | Receives cross-region copies of GDS recovery points; long-term retention (2 years) with WORM enforcement |
| Ownership | Owned — provisioned by `continuumGdsBackupVault` module |
| Deployed in | `grpn-prod` account; regions: `us-west-2` (copy target for `us-west-1`), `us-west-1` (copy target for `us-west-2`), `eu-central-1` (copy target for `eu-west-1`) |
| Encryption | Customer-managed KMS key; cross-account key policy grants decrypt to source account roots |
| Vault Lock | Enabled (WORM): changeable for 30 days, min retention 729 days, max retention 731 days |
| Vault policy | Allows `CopyIntoBackupVault` for entire AWS organization (`o-scqs2lnin0`) |

#### Access Patterns

- **Write**: AWS Backup service copies recovery points from GDS source vault via cross-region copy action using `grpn-backup-service-role`
- **Read**: Operators initiate restore from recovery points using `grpn-all-backup-operator` IAM role
- **Lifecycle**: Cold storage transition after 30 days; delete after 730 days

---

### Deadbolt Source Vault (`deadbolt-weekly-1y` in `grpn-security-prod`)

| Property | Value |
|----------|-------|
| Type | AWS Backup Vault |
| Architecture ref | `continuumDeadboltBackupVault` |
| Purpose | Stores weekly EC2 and RDS SQL Server recovery points in `grpn-security-prod us-west-2`; short-lived (7-day retention) |
| Ownership | Owned — provisioned by `continuumDeadboltBackupVault` module |
| Deployed in | `grpn-security-prod` account, `us-west-2` region |
| Encryption | Customer-managed KMS key |
| Vault Lock | Not enabled on source vault |
| Vault policy | Allows restore copy-back to `grpn-backup-prod` root user only |

#### Access Patterns

- **Write**: AWS Backup service writes recovery points weekly (`cron(0 08 ? * MON *)`) using `grpn-backup-service-role`
- **Read**: AWS Backup reads recovery points to initiate cross-account copy to `grpn-backup-prod`

---

### Deadbolt Target Vault (`deadbolt-weekly-1y` in `grpn-backup-prod`)

| Property | Value |
|----------|-------|
| Type | AWS Backup Vault |
| Architecture ref | `continuumDeadboltBackupVault` |
| Purpose | Receives cross-account copies of Deadbolt recovery points; long-term retention (1 year) with WORM enforcement |
| Ownership | Owned — provisioned by `continuumDeadboltBackupVault` module |
| Deployed in | `grpn-backup-prod` account, `us-west-2` region |
| Encryption | Customer-managed KMS key; cross-account grants to `grpn-security-prod` root user |
| Vault Lock | Enabled (WORM): changeable for 60 days, min retention 364 days, max retention 731 days |
| Vault policy | Allows `CopyIntoBackupVault` for entire AWS organization (`o-scqs2lnin0`) |

#### Access Patterns

- **Write**: AWS Backup service copies recovery points cross-account from `grpn-security-prod` using `grpn-backup-service-role`
- **Read**: Operators restore from recovery points using `grpn-all-backup-operator` IAM role
- **Lifecycle**: Cold storage transition after 30 days; delete after 365 days

## Caches

> Not applicable. No caches are used or provisioned by this service.

## Data Flows

Recovery points flow in two directions:

1. **Backup (write path)**: AWS Backup scheduler triggers backup job on a tag-selected resource in a source account. `grpn-backup-service-role` performs the backup, writing a recovery point to the source vault. A copy action then copies the recovery point to the target vault (cross-region for GDS, cross-account for Deadbolt).

2. **Restore (read path)**: An operator using the `grpn-all-backup-operator` IAM role selects a recovery point from the target vault and initiates a restore job. `grpn-backup-service-role` performs the restore, creating new RDS/Aurora or EC2 resources from the recovery point in the target account. Operators may also copy a recovery point from the target vault back to the source vault for same-account restoration.
