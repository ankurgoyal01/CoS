---
service: "aws-transfer-for-sftp"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "terraform-managed-aws"
environments: [sandbox, stable, production]
---

# Deployment

## Overview

AWS Transfer for SFTP is a fully infrastructure-as-code service with no application containers, Kubernetes workloads, or runtime processes. All infrastructure is provisioned and managed using Terraform with Terragrunt orchestration. Deployment is performed manually via Make targets that invoke Terragrunt plan/apply commands against a target environment path. Terraform remote state is stored in S3 and locked via DynamoDB. All environments target `us-west-2`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| SFTP Endpoint | AWS Transfer Family (`aws_transfer_server`) | Managed service; created by `modules/sftp/Server/main.tf` |
| Data Buckets | Amazon S3 | 7 domain buckets; created by `modules/sftp/s3storage/` |
| Logging Bucket | Amazon S3 | `{env}-groupon-transfer-s3-bucket-log`; created by `modules/sftp/s3logging/main.tf` |
| IAM Roles & Policies | AWS IAM | Server logging role + per-bucket user roles/policies; created inline in Server and s3storage modules |
| CloudWatch Log Group | Amazon CloudWatch Logs | `/aws/transfer/{server-id}`; 365-day retention; created by `modules/sftp/Server/main.tf` |
| State Backend | Amazon S3 + DynamoDB | `grpn-InfoSec::AWSTransferForSFTP-state-{account_id}` / `grpn-InfoSec::AWSTransferForSFTP-lock-table-{account_id}` |
| IaC Orchestration | Terragrunt 0.18.3 | Module dependency chain managed via `dependencies` blocks in `terraform.tfvars` |
| Container | None | Not containerised |
| Load balancer | None | AWS Transfer Family endpoint is directly accessible |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | AWS Account |
|-------------|---------|--------|-------------|
| `sandbox` | Development and testing | `us-west-2` | `549734399709` |
| `stable` | Pre-production validation | `us-west-2` | (separate account) |
| `production` | Live file transfer workloads | `us-west-2` | `497256801702` |

## CI/CD Pipeline

- **Tool**: Make + Terragrunt (manual invocation; no automated CI pipeline discovered in this repository)
- **Config**: `envs/Makefile`, `envs/.terraform-tooling/Makefiles/`
- **Trigger**: Manual operator invocation via Make targets

### Pipeline Stages (Manual Deployment Sequence)

1. **Authenticate**: Set `AWS_PROFILE` and `TF_VAR_PROJECTNAME` environment variables; run `make <env>/us-west-2/init` to initialise Terraform backends
2. **Validate**: Run `make <env>/us-west-2/validate` — executes `terragrunt validate-all` across all modules in the target environment path
3. **Plan**: Run `make <env>/us-west-2/plan` — executes `terragrunt plan-all` respecting module dependency order (`s3logging` -> `s3storage` -> `Server`)
4. **Apply**: Run `make <env>/us-west-2/APPLY` — executes `terragrunt apply-all` in dependency order
5. **Destroy** (if needed): Run `make <env>/us-west-2/DESTROY-ALL` with confirmation prompt

### Module Dependency Order

```
s3logging  -->  s3storage  -->  Server
```

Terragrunt `dependencies` blocks enforce this order automatically during plan-all and apply-all.

## Scaling

> Not applicable. AWS Transfer Family is a fully managed service that scales automatically. No manual scaling configuration is required or available.

## Resource Requirements

> Not applicable. This service provisions AWS managed resources. There are no compute instances, memory limits, or CPU requests to configure.
