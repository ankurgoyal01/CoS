---
service: "gcp-dataplex-infra"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "terraform-terragrunt"
environments: ["stable"]
---

# Deployment

## Overview

`gcp-dataplex-infra` is not a containerised runtime service. It is an infrastructure-as-code repository deployed via Terraform and Terragrunt. Operators run Make targets that invoke Terragrunt, which orchestrates Terraform to plan and apply changes to the `prj-grp-data-cat-stable-0b72` GCP project. Remote state is stored in a GCS bucket. Service account impersonation ensures that changes are applied under the designated Terraform SA rather than individual operator credentials.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Not containerised; pure IaC repository |
| Orchestration | Terragrunt 0.30.7 | Wraps Terraform; config in `envs/terragrunt.hcl` |
| Terraform CLI | Terraform 0.15.5 | Pinned via `.terraform-version` (tfenv) |
| Remote state backend | Google Cloud Storage | Bucket: `grpn-gcp-<PROJECTNAME>-state-<GCP_PROJECT_NUMBER>`, location: `US` |
| GCP Provider auth | Service account impersonation | SA: `grpn-sa-terraform-data-catalog@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` |
| Build tooling | Make + CloudCore gcp-terraform-base | `envs/Makefile`, `envs/.terraform-tooling/` |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| stable | Production-equivalent data catalog environment | `us-central1` | `prj-grp-data-cat-stable-0b72` (project number: `198003841171`) |

## CI/CD Pipeline

- **Tool**: Make (manual operator workflow); no automated CI pipeline config file found in repository
- **Config**: `envs/Makefile`, `envs/.terraform-tooling/Makefiles/*.mk`
- **Trigger**: Manual operator execution via make targets

### Pipeline Stages

1. **Login**: Operator authenticates with GCP using `make stable/gcp-login` (calls `gcloud auth application-default login`)
2. **Plan**: Operator runs `make stable/us-central1/plan` — Terragrunt assembles variable files and calls `terraform plan-all`, outputs `plan.output` and `plan.json`
3. **Review**: Operator reviews the generated `plan.json` and optionally runs compliance tests (`make stable/us-central1/test-compliance`)
4. **Apply**: Operator runs `make stable/us-central1/APPLY` — Terragrunt calls `terraform apply-all` under service account impersonation
5. **Validate**: Operator can run `make stable/us-central1/validate` to run `terraform validate-all` without applying changes
6. **Logout**: Operator runs `make stable/gcp-logout` to revoke GCP credentials

## Scaling

> Not applicable. This repository provisions static GCP managed resources (entry types, entry group, GCS bucket) that do not require horizontal or vertical scaling.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Terraform operator machine | Standard developer laptop or CI runner | — |
| GCS state bucket | Minimal (Terraform state JSON files) | — |
| GCP Dataplex quota | Determined by GCP project quota for Dataplex Entry Types and Entry Groups | — |

> Deployment configuration for additional environments (dev, prod) would follow the same pattern by adding new subdirectories under `envs/` with appropriate `account.hcl` files.
