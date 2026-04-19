---
service: "gcp-dataplex-infra"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "hcl-files", "terragrunt-hcl"]
---

# Configuration

## Overview

Configuration is split across three layers. Terragrunt HCL files (`global.hcl`, `account.hcl`, `region.hcl`) supply environment-scoped values that are injected into Terraform as variable files at plan/apply time. Shell environment variables prefixed with `TF_VAR_` are used to pass runtime-sensitive values (project ID, project number, environment stage) into Terragrunt. Terraform module variables (`common.tf`) define the required inputs for each module. Remote state is stored in a GCS backend whose bucket name is assembled from environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TF_VAR_PROJECTNAME` | Unique project name used to name the Terraform remote state bucket | yes | `INVALID` (fails without override) | env |
| `TF_VAR_GCP_PROJECT_NUMBER` | GCP project number for the target project | yes | `INVALID` (fails without override) | env |
| `TF_VAR_GCP_PROJECT_ID` | GCP project ID for the target project | yes | `INVALID` (fails without override) | env |
| `TF_VAR_GCP_ENV_STAGE` | Environment stage (`dev`, `stable`, `prod`) used to select the correct central SA project | yes | `INVALID` (fails without override) | env |
| `GCP_PROJECT_NUMBER` | Passed to `make` targets for Terragrunt plan/apply commands | yes (for apply) | — | env |
| `GCP_PROJECT_ID` | Passed to `make` targets for Terragrunt plan/apply commands | yes (for apply) | — | env |
| `GCP_ENV_STAGE` | Passed to `make` targets for Terragrunt plan/apply commands | yes (for apply) | — | env |
| `GCP_TF_SA` | Terraform service account name override for make targets | no | `grpn-sa-terraform-data-catalog` | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flags are used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global labels (`service=gcp-dataplex-catalog`, `owner=dnd-tools`) and Terraform service account name |
| `envs/stable/account.hcl` | HCL | GCP project number (`198003841171`), project ID (`prj-grp-data-cat-stable-0b72`), environment short name (`dataplex-catalog`), and stage (`stable`) |
| `envs/stable/us-central1/region.hcl` | HCL | GCP region (`us-central1`) for all resources in this environment/region |
| `envs/terragrunt.hcl` | HCL | Root Terragrunt config: GCS remote state backend, service account impersonation mapping per stage, common variable file injection, plan output hook |
| `envs/stable/.terraform-version` | plaintext | Pins Terraform CLI version to `0.15.5` via tfenv |
| `envs/Makefile` | Makefile | Project-level make targets; sets `PROJECTNAME`, `SERVICENAME`, `OWNERNAME`, `TERRAGRUNT_VERSION`, `CLOUD_PROVIDER` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| GCP Application Default Credentials | Authenticates the operator's local session for service account impersonation | gcloud keyring / ADC file |
| `grpn-sa-terraform-data-catalog` service account key | Impersonated by Terraform to apply changes to GCP; key material is never stored in this repo | GCP IAM (central SA project) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Currently only the `stable` environment is configured under `envs/stable/`. The environment directory structure supports additional stages (`dev`, `prod`) as additional subdirectories with their own `account.hcl` files. The root `envs/terragrunt.hcl` maps each stage to the appropriate central service account project:

| Stage | Central SA Project |
|-------|--------------------|
| `dev` | `prj-grp-central-sa-dev-e453.iam.gserviceaccount.com` |
| `stable` | `prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` |
| `prod` | `prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` |

The GCS remote state bucket name is assembled as: `grpn-gcp-<PROJECTNAME>-state-<GCP_PROJECT_NUMBER>`, where both values come from `TF_VAR_PROJECTNAME` and `TF_VAR_GCP_PROJECT_NUMBER` environment variables at runtime.
