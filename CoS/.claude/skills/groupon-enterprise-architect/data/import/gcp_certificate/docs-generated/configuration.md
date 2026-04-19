---
service: "gcp_certificate"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [hcl-var-files, env-vars, terragrunt-hcl]
---

# Configuration

## Overview

Configuration is managed through a layered Terragrunt variable file hierarchy. Global settings are defined in `envs/global.hcl`. Environment-specific settings (GCP project IDs, issuer chain PEM, valid domain suffixes, and the approved certificate list) are defined in per-environment `account.hcl` files. Region-specific settings are in `region.hcl`. At apply time, Terragrunt merges all layers and passes them as Terraform variables. Sensitive values (the issuer chain PEM) are stored inline in the HCL files within the repository; there is no external secrets manager integration for Terraform-time secrets in this service.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TF_VAR_PROJECTNAME` | Uniquely identifies the GCS state bucket for this project | yes | `INVALID` (fails without override) | env / Make |
| `TF_VAR_GCP_PROJECT_NUMBER` | GCP project number used in GCS state bucket name | yes | `INVALID` (fails without override) | env / Make |
| `TF_VAR_GCP_PROJECT_ID` | GCP project ID for resource placement | yes | `INVALID` (fails without override) | env / Make |
| `TF_VAR_GCP_ENV_STAGE` | Deployment stage (`dev`, `stable`, `prod`) — used to select the central SA project | yes | none | env / Make |
| `GCP_TF_SA` | Service account to impersonate for Terraform operations | yes (stable/prod) | none | env / Make |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No feature flags are configured. Certificate template enablement is controlled by presence/absence of entries in the `certificates` map in each environment's `account.hcl`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Sets `terraform_service_account = "grpn-sa-terraform-security"` — used globally across all environments |
| `envs/grp-security-dev/account.hcl` | HCL | Dev environment: GCP project ID/number, issuer chain PEM, valid domain suffixes, approved certificate list |
| `envs/grp-security-prod/account.hcl` | HCL | Prod environment: GCP project ID `prj-grp-security-prod-1403` (number `378551787895`), issuer chain PEM (Groupon Root CA), valid domain suffixes including `.production.service` and `.groupondev.com`, approved certificate list |
| `envs/grp-security-dev/us-central1/region.hcl` | HCL | Sets `gcp_region = "us-central1"` for the dev environment |
| `envs/grp-security-prod/us-central1/region.hcl` | HCL | Sets `gcp_region = "us-central1"` for the prod environment |
| `envs/terragrunt.hcl` | HCL | Root Terragrunt config: GCS remote state backend, required var files, impersonation logic, common.tf code generation |
| `modules/template/common.tf` | HCL | Injected into every module by Terragrunt; defines GCS backend, provider configuration, and service account impersonation logic |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `issuer_chain` (in `account.hcl`) | PEM-encoded Groupon Root CA certificate used as the trust anchor for the subordinate intermediate CA | HCL var file (repository) |
| `grpn-sa-terraform-security` service account key | Allows Terraform to impersonate the deployment SA | GCP Workload Identity / operator credential |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Dev (`grp-security-dev`) | Prod (`grp-security-prod`) |
|---------|--------------------------|---------------------------|
| GCP Project ID | `prj-grp-security-dev-ce40` | `prj-grp-security-prod-1403` |
| GCP Project Number | `44618257326` | `378551787895` |
| `env_short_name` | `security-dev` | `security-prod` |
| `env_stage` | `dev` | `prod` |
| Valid domain suffixes | `.consandbox.service`, `.gensandbox.service`, `.sandbox.service`, `.dev.service`, `.staging.service` | `.groupondev.com`, `.consandbox.service`, `.gensandbox.service`, `.sandbox.service`, `.dev.service`, `.staging.service`, `.production.service` |
| mTLS certificates | `privateca`, `hybrid-boundary` | None (empty list) |
| client_auth certificates | `kafka` | `encore-tagging`, `encore-service` (staging + prod), `mbus` |
| server_auth certificates | None | `tableau-server` (3 CNs), `deadbolt` |
| Custom templates | `PrivateCA-certificate-template-example`, `Conveyor_subordinate_CA-dev` | `conveyor_subordinate_cert_authority` |
| Central SA project | `prj-grp-central-sa-dev-e453` | `prj-grp-central-sa-prod-0b25` |
