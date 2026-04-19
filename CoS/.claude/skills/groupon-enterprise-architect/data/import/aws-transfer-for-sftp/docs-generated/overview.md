---
service: "aws-transfer-for-sftp"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Security / InfoSec"
platform: "Continuum / AWS"
team: "InfoSec"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform 0.x (Terragrunt-managed)"
  framework: "Terragrunt"
  framework_version: "0.18.3"
  runtime: "AWS Transfer Family"
  runtime_version: "managed"
  build_tool: "Make"
  package_manager: "Terragrunt"
---

# AWS Transfer for SFTP Overview

## Purpose

AWS Transfer for SFTP is a fully managed SFTP service that enables Groupon business units and external partners to securely transfer files using the SSH File Transfer Protocol. It provisions and manages an `aws_transfer_server` endpoint backed by per-team Amazon S3 buckets, with all configuration—server setup, IAM roles, S3 bucket policies, encryption, versioning, lifecycle rules, and CloudWatch logging—defined as code in Terraform and orchestrated via Terragrunt. The service exists to consolidate and standardise secure file ingestion and egress across multiple domains (EDW, CDE, CLO Distribution, Goods, InfoSec, Augeovoucher) without requiring teams to manage SFTP server infrastructure themselves.

## Scope

### In scope

- Provisioning and lifecycle management of the AWS Transfer Family SFTP endpoint (`aws_transfer_server`, identity provider: `SERVICE_MANAGED`)
- Per-team private S3 buckets with AES-256 server-side encryption, versioning, and configurable lifecycle expiration
- IAM roles and policies (server logging role, per-bucket user roles, scope-down policies restricting users to their home directory)
- CloudWatch log group creation and retention configuration (`/aws/transfer/<server-id>`, 365-day retention in production)
- Centralised S3 access logging bucket (`groupon-transfer-s3-bucket-log`) aggregating server access logs from all data buckets
- Terraform state storage and locking in S3 and DynamoDB (`grpn-<PROJECTNAME>-state-<account_id>`, `grpn-<PROJECTNAME>-lock-table-<account_id>`)
- Multi-environment support: sandbox, stable, production

### Out of scope

- SFTP client tooling or file transfer orchestration logic (owned by consuming teams)
- Post-transfer data processing of files deposited into S3 (owned by downstream consumers such as EDW pipelines)
- User credential management beyond IAM role and scope-down policy provisioning
- Monitoring or alerting beyond CloudWatch log retention (dashboards maintained separately in Wavefront)

## Domain Context

- **Business domain**: Security / InfoSec
- **Platform**: Continuum / AWS
- **Upstream consumers**: External partners and internal teams connecting over SFTP (CDE, CLO Distribution, Goods, EDW, InfoSec, Augeovoucher integrations)
- **Downstream dependencies**: Amazon S3 (data buckets and logging bucket), Amazon CloudWatch Logs (session and activity logs), AWS IAM (role and policy management), Amazon Route 53 (DNS — listed in `.service.yml` dependencies)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | sbhatt (InfoSec team) |
| Team | InfoSec (infosec@groupon.com) |
| On-Call | infosec-aws-transfer-service@groupon.pagerduty.com |
| Members | sbhatt, rogden |
| Slack Channel | #global-security |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Infrastructure-as-code | HCL / Terraform | Terragrunt 0.18.3 | `envs/Makefile`, `envs/.terraform-tooling/` |
| Orchestration | Terragrunt | 0.18.3 | `envs/Makefile` (`TERRAGRUNT_VERSION := 0.18.3`) |
| Managed service | AWS Transfer Family | managed | `modules/sftp/Server/main.tf` |
| State backend | Amazon S3 + DynamoDB | managed | `envs/terraform.tfvars`, `modules/sftp/Server/backend.tf` |
| Build system | GNU Make | system | `envs/Makefile`, `envs/.terraform-tooling/Makefiles/` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| aws_transfer_server | Terraform AWS provider | infrastructure | Provisions SFTP managed endpoint |
| aws_iam_role / aws_iam_role_policy | Terraform AWS provider | auth | Server logging role and per-bucket user roles |
| aws_iam_policy (scope-down) | Terraform AWS provider | auth | Home-directory-scoped IAM policies for SFTP users |
| aws_s3_bucket | Terraform AWS provider | storage | Per-team encrypted data buckets |
| aws_s3_bucket_public_access_block | Terraform AWS provider | security | Blocks all public access on every data bucket |
| aws_cloudwatch_log_group | Terraform AWS provider | logging | Creates `/aws/transfer/<id>` log group with 365-day retention |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
