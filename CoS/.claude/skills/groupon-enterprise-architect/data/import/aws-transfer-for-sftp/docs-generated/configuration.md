---
service: "aws-transfer-for-sftp"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [tfvars, env-vars, terragrunt]
---

# Configuration

## Overview

All configuration is managed through Terraform variable files (`terraform.tfvars`, `env_vars.tfvars`) and Terragrunt configuration blocks. There is no runtime application configuration; the service is infrastructure-only. Per-environment values are defined under `envs/<environment>/us-west-2/env_vars.tfvars` and per-module values under `envs/<environment>/us-west-2/sftp/<module>/terraform.tfvars`. Terraform remote state is stored in S3 (`grpn-<PROJECTNAME>-state-<account_id>`) and locked via DynamoDB (`grpn-<PROJECTNAME>-lock-table-<account_id>`). The project name is `InfoSec::AWSTransferForSFTP`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `AWS_PROFILE` | AWS CLI profile used by Terragrunt for authentication | yes | `""` (empty) | env |
| `TF_VAR_PROJECTNAME` | Project name used to construct S3 state bucket and DynamoDB lock table names | yes | `INVALID` (must be set) | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. This service has no feature flag mechanism.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/terraform.tfvars` | HCL / Terragrunt | Root Terragrunt config: S3 remote state backend, DynamoDB lock table, common var file injection |
| `envs/production/us-west-2/env_vars.tfvars` | HCL / tfvars | Production region settings: `aws_account_id`, `aws_region`, `owner`, `env`, `cloudwatch_log_expiration`, `logging_bucket_expiration`, `logging_bucket_abort`, `storage_bucket_expiration`, `storage_bucket_abort` |
| `envs/sandbox/us-west-2/env_vars.tfvars` | HCL / tfvars | Sandbox region settings (same shape as production; `env = "sandbox"`, `aws_account_id = "549734399709"`) |
| `envs/stable/us-west-2/env_vars.tfvars` | HCL / tfvars | Stable region settings |
| `envs/<env>/us-west-2/sftp/Server/terraform.tfvars` | HCL / Terragrunt | Points to `modules/sftp/Server`; depends on `s3storage` |
| `envs/<env>/us-west-2/sftp/s3storage/terraform.tfvars` | HCL / Terragrunt | Points to `modules/sftp/s3storage`; depends on `s3logging` |
| `envs/<env>/us-west-2/sftp/s3logging/terraform.tfvars` | HCL / Terragrunt | Points to `modules/sftp/s3logging`; no dependencies |
| `envs/Makefile` | Makefile | Top-level operations: plan, apply, destroy per environment path; sets `TERRAGRUNT_VERSION := 0.18.3` |

## Terraform Variable Reference

### Server module (`modules/sftp/Server/serverVariables.tf`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `aws_region` | `us-west-2` | AWS region |
| `server-iam-role` | `groupon-transfer-server-iam-role` | IAM role name for the SFTP server |
| `server-iam-policy` | `groupon-transfer-server-iam-policy` | IAM policy name for CloudWatch log permissions |
| `env` | (required) | Environment tag applied to all resources |
| `owner` | (required) | Owner e-mail tag |
| `cloudwatch_log_expiration` | (required) | CloudWatch log group retention in days |

### S3 logging module (`modules/sftp/s3logging/variables.tf`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `logging-bucket` | `groupon-transfer-s3-bucket-log` | Name of the centralised logging bucket |
| `logging_bucket_abort` | `30` | Multipart upload abort after N days |
| `logging_bucket_expiration` | `365` | Object expiration in days |

### S3 storage module — EDW bucket (`modules/sftp/s3storage/edwBucketVariables.tf`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `s3-bucket-edw` | `groupon-transfer-s3-edw` | EDW S3 bucket name suffix |
| `logging-bucket-edw` | `groupon-transfer-s3-bucket-log` | Logging bucket name |
| `user-iam-role-edw` | `groupon-transfer-user-iam-role-groupon-transfer-s3-edw` | SFTP user IAM role name for EDW |
| `user-iam-policy-edw` | `groupon-transfer-user-iam-policy-groupon-transfer-s3-edw` | SFTP user IAM policy name for EDW |
| `user-iam-scope-down-policy-edw` | `groupon-transfer-user-iam-scope-down-policy-groupon-transfer-s3-edw` | Scope-down policy name for EDW |
| `storage_bucket_abort-edw` | `15` | Multipart upload abort threshold (days) |
| `storage_bucket_expiration-edw` | `15` | Object lifecycle expiration (days) |

> CDE, CLO Distribution, Goods, InfoSec, Augeovoucher, and Sachin buckets follow the same variable pattern with their respective name suffixes.

## Secrets

> No evidence found in codebase. AWS credentials are provided at runtime via AWS CLI profiles (`AWS_PROFILE`). No application-level secrets are stored in this repository; SSH keys for SFTP users are managed outside this codebase via AWS Transfer Family user management.

## Per-Environment Overrides

| Environment | `env` value | `aws_account_id` | Key differences |
|-------------|-------------|-----------------|-----------------|
| `production` | `prod` | `497256801702` | `cloudwatch_log_expiration = 365`, `storage_bucket_expiration = 15` |
| `sandbox` | `sandbox` | `549734399709` | `cloudwatch_log_expiration = 365`, `storage_bucket_expiration = 15` |
| `stable` | (not shown) | (not shown) | Same module structure as production and sandbox |

All three environments deploy to `us-west-2` and use the same Terraform module source paths. The environment is differentiated by the `env` variable value, which is prepended to all S3 bucket names (e.g., `prod-groupon-transfer-s3-edw`, `sandbox-groupon-transfer-s3-edw`).
