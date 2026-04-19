---
service: "aws-backups"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "terraform-terragrunt"
environments:
  - grpn-billing
  - grpn-prod
  - grpn-backup-prod
  - grpn-backup-stable
  - grpn-gensandbox1
  - grpn-stable
  - grpn-security-dev
  - grpn-security-prod
---

# Deployment

## Overview

aws-backups is a Terraform/Terragrunt infrastructure-as-code service with no containerized runtime or application server. Deployment means applying Terraform modules to AWS accounts using Terragrunt for environment orchestration and GNU Make as the operator interface. Each module is applied independently per account and per region by engineers with the appropriate IAM role assumption via `aws-okta` or equivalent. There is no CI/CD automated apply — all applies are manual, operator-initiated.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile; infrastructure-only service |
| Orchestration | Terragrunt + GNU Make | `envs/Makefile` wraps `terragrunt plan` and `terragrunt apply` per module path |
| IaC Tool | Terraform 1.0.2 | Pinned in `envs/.environment-template/.terraform-version` |
| Module source | `module-ref` shell script | `envs/.terraform-tooling/bin/module-ref` resolves module source paths at plan time |
| AWS credentials | IAM role assumption | `grpn_all_backup_provisioner` for vault/role modules; `grpn-all-crossaccount-backup-admin` for billing policy module |
| State backend | AWS S3 + DynamoDB (via Terragrunt) | Remote state managed by Terragrunt (standard Landing Zone pattern) |

## Environments

| Environment | Purpose | Region(s) | AWS Account ID |
|-------------|---------|-----------|---------------|
| `grpn-billing` | Management account — hosts all backup policy modules | `us-west-2`, `us-west-1`, `eu-west-1` | 248184355264 |
| `grpn-prod` | Source account — hosts GDS vault and service role modules | `us-west-2`, `us-west-1`, `eu-west-1`, `eu-central-1` | 497256801702 |
| `grpn-backup-prod` | Backup target account for prod resources (Deadbolt target vault) | `us-west-2` | 417123930686 |
| `grpn-backup-stable` | Backup target account for dev/sandbox/stable resources (GDS stable target vault) | `us-west-2` | 098571475921 |
| `grpn-gensandbox1` | Source account — sandbox, hosts GDS vault and service role modules | `eu-central-1`, `eu-west-1` | 549734399709 |
| `grpn-stable` | Source account — staging, sends backups to `grpn-backup-stable` | — | 286052569778 |
| `grpn-security-dev` | Deadbolt source account — dev, hosts backup service role | — | — |
| `grpn-security-prod` | Deadbolt source account — prod, hosts service role and Deadbolt source vault | `us-west-2` | 274116055752 |

## CI/CD Pipeline

- **Tool**: Manual operator-driven (no automated CI/CD apply pipeline)
- **Config**: `envs/Makefile` and `envs/.terraform-tooling/Makefiles/`
- **Trigger**: Manual — operator runs `make <account>/<region>/<module>/plan` then `make <account>/<region>/<module>/APPLY`

### Pipeline Stages

1. **Plan**: Operator runs `make <path>/plan` — Terragrunt calls `terraform plan` with the resolved module source and environment inputs, outputting the diff of resources to be created/modified/destroyed
2. **Apply**: Operator reviews the plan and runs `make <path>/APPLY` (uppercase to require deliberate intent) — Terragrunt calls `terraform apply` to create or update AWS resources
3. **Destroy** (when decommissioning): Operator runs `make <path>/plan-destroy` then `make <path>/DESTROY`

### Example Apply Commands

```
cd envs
make grpn-prod/global/backup_service_role/plan
make grpn-prod/global/backup_service_role/APPLY

make grpn-prod/us-west-2/gds_vault/plan
make grpn-prod/us-west-2/gds_vault/APPLY

make grpn-billing/us-west-2/gds_prod_backup_policies/plan
make grpn-billing/us-west-2/gds_prod_backup_policies/APPLY
```

### Deployment Order

Modules within an account must be applied in dependency order:

1. `backup_service_role` (global, per account) — must be applied first; all vault modules declare a Terragrunt dependency on it
2. `*_backup_vault` (per region, per account) — source and target vaults depend on the service role
3. `*_backup_policies` (in `grpn-billing` only) — policies reference vault ARNs and service role ARN; must be applied after vaults and roles are in place

## Scaling

> Not applicable. This is an infrastructure service with no scaling dimension. The AWS Backup service scales automatically.

## Resource Requirements

> Not applicable. No application compute resources are provisioned. All AWS Backup, KMS, SNS, IAM, and Organizations resources are managed and scaled by AWS.
