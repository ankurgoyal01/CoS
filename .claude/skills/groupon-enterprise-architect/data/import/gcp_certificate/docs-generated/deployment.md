---
service: "gcp_certificate"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "terraform/terragrunt"
environments: [grp-security-dev, grp-security-prod]
---

# Deployment

## Overview

The `gcp_certificate` service deploys GCP infrastructure resources via Terraform and Terragrunt — there is no containerized application to run. The deployment model is operator-driven (Make targets invoke Terragrunt, which calls the Terraform `google` provider). Two GCP environments are managed: `grp-security-dev` and `grp-security-prod`, both targeting the `us-central1` region. Each environment runs two independent Terraform module stacks: `private-ca` (CA pool + intermediate CA + IAM issuance policy) and `certificates` (certificate templates + template IAM policies).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Not applicable — IaC only |
| Orchestration | Terragrunt 0.58.4 | `envs/Makefile` + `.terraform-tooling/Makefiles/` |
| IaC tool | Terraform (1.x) | `modules/private-ca/`, `modules/certificates/`, `modules/certificate-templates/` |
| State backend | GCS | Bucket: `grpn-gcp-<PROJECTNAME>-state-<GCP_PROJECT_NUMBER>`, region `US` |
| Provider auth | GCP service account impersonation | `grpn-sa-terraform-security` via `prj-grp-central-sa-{stage}.iam.gserviceaccount.com` |
| Load balancer | None | Not applicable |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| `grp-security-dev` | Development and testing of CA infrastructure and certificate templates | `us-central1` | `prj-grp-security-dev-ce40` (number: `44618257326`) |
| `grp-security-prod` | Production internal PKI — issues certificates consumed by live services | `us-central1` | `prj-grp-security-prod-1403` (number: `378551787895`) |

### Module Stacks per Environment

Each environment contains two Terragrunt-managed module directories:

| Module Path | Terraform Module | Description |
|-------------|-----------------|-------------|
| `envs/<env>/us-central1/private-ca/` | `modules/private-ca` | CA pool + intermediate CA + issuance IAM policy |
| `envs/<env>/us-central1/certificates/` | `modules/certificates` | All certificate templates (mTLS, client_auth, server_auth, custom) |

## CI/CD Pipeline

- **Tool**: Make + Terragrunt (manual operator-driven; no GitHub Actions pipeline is present in this repository)
- **Config**: `envs/Makefile`, `envs/.terraform-tooling/Makefiles/10-standard-operations.mk`
- **Trigger**: Manual — operator runs Make targets

### Pipeline Stages

1. **Validate**: `make <env>/validate` — runs `terragrunt validate-all` across all modules in the target path
2. **Plan**: `make <env>/plan` — runs `terragrunt plan-all`, writes `plan.output` and `plan.json` per module
3. **Apply**: `make <env>/APPLY` — runs `terragrunt apply-all` using the plan output; requires GCP credentials
4. **Destroy** (destructive): `make <env>/DESTROY-ALL` — interactive confirmation required; runs `terragrunt destroy-all`

### Activating a New Subordinate CA

When creating a CA from scratch, an additional manual step is required (not automatable via Terraform):

1. Run `make <env>/APPLY` — Terraform creates the CA in a pending state
2. Navigate to GCP Console, locate the new CA, and download the CSR
3. Use the Groupon Root CA to sign the CSR and produce a signed certificate
4. Upload the signed certificate via GCP Console to activate the subordinate CA

## Scaling

> Not applicable — this is an IaC-only service. GCP Private CA scales automatically as a managed GCP service. The CA pool tier is `ENTERPRISE`, which supports higher throughput SLAs.

## Resource Requirements

> Not applicable — no compute resources are provisioned for this service. The GCP Private CA and GCS resources are fully managed by Google.
