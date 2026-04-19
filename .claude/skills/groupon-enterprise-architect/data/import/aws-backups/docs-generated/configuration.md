---
service: "aws-backups"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["terragrunt-hcl", "account-hcl", "region-hcl", "global-hcl"]
---

# Configuration

## Overview

aws-backups has no runtime environment variables or application config files — it is a Terraform infrastructure service configured entirely through Terragrunt HCL files. Configuration is layered hierarchically: global defaults in `envs/global.hcl`, account-level settings in `envs/<account>/account.hcl`, region-level settings in `envs/<account>/<region>/region.hcl`, and module-level inputs in `envs/<account>/<region>/<module>/terragrunt.hcl`. Terraform module source resolution is handled by the `module-ref` shell script in `.terraform-tooling/bin/`.

## Environment Variables

> Not applicable. This is a Terraform infrastructure service. There are no runtime environment variables. AWS credentials and role assumptions are managed via the Terragrunt AWS provider configuration using the IAM roles defined in the `grpn-all-backup-provisioner` pattern.

## Feature Flags

> No evidence found in codebase. No feature flags are used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global defaults: default AWS role (`grpn-all-backup-provisioner`), default region (`us-west-2`), org ID (`o-scqs2lnin0`), common resource tags |
| `envs/<account>/account.hcl` | HCL | Per-account settings: `aws_account_id`, `env_short_name`, `env_stage` |
| `envs/<account>/<region>/region.hcl` | HCL | Per-region settings (region identifier) |
| `envs/<account>/<region>/<module>/terragrunt.hcl` | HCL | Module-level inputs: vault name, schedule, lifecycle days, source/target accounts, selection tags, SNS endpoints, vault lock settings |
| `envs/.environment-template/.terraform-version` | text | Pinned Terraform version (`1.0.2`) for all environments |
| `envs/.terraform-tooling/Makefile` | Makefile | Build targets for plan, apply, destroy operations |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| AWS access credentials (via `grpn-all-backup-provisioner` role) | Terraform authentication to AWS accounts during apply | IAM role assumption (no static credentials) |
| AWS access credentials (via `grpn-all-crossaccount-backup-admin` role) | Terraform authentication for billing account policy management | IAM role assumption (no static credentials) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs across environments through the Terragrunt HCL hierarchy:

### grpn-billing (management account)

- Hosts only backup policy modules (`gds_backup_policies`, `deadbolt_backup_policies`, `backup_policies`)
- Uses `grpn-all-crossaccount-backup-admin` IAM role for policy management
- Policy inputs define schedule, lifecycle, selection tags, and source/target account IDs

### grpn-prod (source account)

- Hosts `backup_service_role` (global) and `gds_backup_vault` / `gds_vault_v2` modules per region
- `aws_account_id = "497256801702"`, `env_stage = "prod"`
- GDS vault inputs: `vault_name = "gds-monthly-2y"`, `backup_target_account = "497256801702"` (same-account cross-region), SNS endpoint `<backup-notifications-DL>`
- GDS vault lock: enabled on target vault, changeable for 30 days, min 729 days, max 731 days

### grpn-backup-prod (backup target account)

- Hosts `backup_service_role` (global) and `deadbolt_backup_vault` (`us-west-2`)
- `aws_account_id = "417123930686"`, `env_stage = "prod"`
- Deadbolt target vault: `vault_name = "deadbolt-weekly-1y"`, `backup_target_account = "417123930686"`, vault lock enabled (changeable 60 days, min 364, max 731)

### grpn-backup-stable (backup target account for non-production)

- Hosts `backup_service_role` and GDS/generic vault modules
- Receives backups from `grpn-gensandbox1` and `grpn-stable` source accounts
- Lifecycle settings are shorter for testing (7-day retention, 1-day cold storage transition)

### grpn-gensandbox1 (source account — sandbox)

- Hosts `backup_service_role` in `global` and `gds_vault` module per region (eu-central-1, eu-west-1)
- Used for sandbox and testing backup operations

### grpn-security-dev / grpn-security-prod (Deadbolt source accounts)

- Hosts `backup_service_role` and `deadbolt_backup_vault` (source vault in `grpn-security-prod us-west-2`)
- Source vault `deadbolt-weekly-1y`: 7-day retention, weekly backup schedule

## Key Backup Schedule Reference

| Team | Module | Schedule | Source Retention | Target Retention | Copy Type |
|------|--------|----------|-----------------|-----------------|-----------|
| GDS prod (us-west-2) | `gds_backup_policies` | `cron(00 18 1 * ? *)` (1st of month, 18:00 UTC) | 3 days | 730 days (2 years) | Same-account cross-region |
| GDS prod (eu-west-1) | `gds_backup_policies` | `cron(00 14 1 * ? *)` (1st of month, 14:00 UTC) | 3 days | 730 days (2 years) | Same-account cross-region |
| GDS stable | `backup_policies` | `cron(30 00 ? * * *)` (daily, 00:30 UTC) | 7 days | 91 days | Cross-account same-region |
| Deadbolt prod | `deadbolt_backup_policies` | `cron(0 08 ? * MON *)` (every Monday, 08:00 UTC) | 7 days | 365 days (1 year) | Cross-account same-region |
