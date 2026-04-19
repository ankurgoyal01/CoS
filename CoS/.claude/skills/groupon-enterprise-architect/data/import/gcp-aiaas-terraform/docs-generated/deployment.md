---
service: "gcp-aiaas-terraform"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "gcp-cloud-run"
environments: [dev, prod]
---

# Deployment

## Overview

The AIaaS platform is deployed exclusively via Terraform and Terragrunt. Each GCP resource type (Cloud Functions, Cloud Run, Cloud Composer, BigQuery, Cloud Storage, API Gateway, Cloud Tasks, Cloud Scheduler, Vertex AI, Secret Manager) is an independent Terragrunt module under `envs/<env>/us-central1/<module>/`. All modules share common environment values via HCL inheritance (`account.hcl`, `region.hcl`, `global.hcl`). Deployment targets two environments — `dev` and `prod` — both in the `us-central1` GCP region. Cloud Run services are containerised (Docker); Cloud Functions are deployed as zip archives uploaded to GCS.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (Cloud Run) | Docker | Images sourced from `us-central1-docker.pkg.dev/prj-grp-aiaas-stable-6113/gcf-artifacts/` (e.g., `image-extraction-api:latest`) |
| Container (Cloud Functions) | Zip archive | Zipped function source uploaded to `artifacts_bucket` (GCS); referenced by Terraform module |
| Orchestration | GCP Cloud Run / GCP Cloud Functions | Serverless; no Kubernetes manifests in this repo |
| Workflow orchestration | GCP Cloud Composer (Airflow 2.6.3) | Managed Airflow environment; DAG files deployed to GCS DAGs bucket |
| API gateway / Load balancer | GCP API Gateway | Routes all `/v1/*` traffic to Cloud Function backends; defined via `doc/swagger.yml` |
| Networking | GCP Shared VPC | `vpc-dev-sharedvpc01` (dev) / `vpc-prod-sharedvpc01` (prod); VPC connector for Cloud Run private networking |
| IaC tool | Terraform + Terragrunt 0.30.7 | All resource state stored in GCP remote backend |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| dev | Development and integration testing | us-central1 | `prj-grp-aiaas-dev-94dd` (project number: `364685817243`) |
| prod | Production workloads | us-central1 | `prj-grp-aiaas-prod-0052` (project number: `462102722170`) |

> Note: No `stable` environment is explicitly configured in this repository's `envs/` directory, though the owners manual references stable. The stable Container Registry project (`prj-grp-aiaas-stable-6113`) is used as the source for production Docker images.

## CI/CD Pipeline

- **Tool**: Jenkins (prod changes) + manual Terragrunt CLI (dev)
- **Config**: Jenkins CI/CD profiles provisioned by CloudCore (ticket-based, e.g., CICD-2130)
- **Trigger**:
  - `dev`: Manual (`make dev/us-central1/<module>/apply`) — developers can apply directly using their Groupon GCP account
  - `prod`: Pull Request approval required; Jenkins applies on PR merge to `main`

### Pipeline Stages

1. **Authenticate**: Run `make <env>/us-central1/<module>/gcp-login` to establish GCP credentials (developer account for dev; service account for prod)
2. **Plan**: Run `make <env>/us-central1/<module>/plan` — Terragrunt resolves module source, runs `terraform plan`, outputs diff
3. **Compliance check**: Terraform compliance tests (disabled by default via `DISABLE_AUTOMATIC_COMPLIANCE_TESTS=true` in `envs/Makefile`)
4. **Apply**: Run `make <env>/us-central1/<module>/apply` — Terragrunt applies the plan, updates GCP resources
5. **PR review (prod only)**: Changes to prod require a PR with at least one peer review before Jenkins triggers apply

### Module Deployment Order (dependency graph)

1. `gcp-buckets` — must be applied first (other modules depend on bucket names as outputs)
2. `gcp-secret-manager` — independent, can run in parallel with buckets
3. `gcp-cloud-functions` / `gcp-cloud-functions-2` — depend on `gcp-buckets` outputs (`artifacts_bucket`, `models_bucket`, `data_bucket`, `project_file_bucket`)
4. `gcp-cloud-run` — independent of buckets module
5. `gcp-api-gateway` — independent
6. `gcp-cloud-task` — independent
7. `gcp-cloud-scheduler` — depends on Cloud Run service being deployed (references Cloud Run URL)
8. `gcp-composer` — independent
9. `gcp-big-query` — independent
10. `gcp-vertex-ai` — independent

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Cloud Composer workers | Horizontal auto-scaling | min: 2, max: 6 workers (`account.hcl`) |
| Cloud Composer scheduler | Fixed count | 2 schedulers (`account.hcl`) |
| Cloud Run | Serverless auto-scaling | min/max instances configurable per module (defaults: 0 min, 5 max per commented config in `gcp-cloud-run/terragrunt.hcl`) |
| Cloud Functions Gen 2 | Serverless auto-scaling | Managed by GCP |
| Vertex AI endpoints | GCP Autoscaling policy | Per-endpoint autoscaling; strategy must be defined in the service ADM (`doc/owners_manual.md`) |

## Resource Requirements

### Cloud Composer (Airflow) — dev and prod

| Resource | Scheduler | Web Server | Worker |
|----------|-----------|-----------|--------|
| CPU | 2 vCPU | 2 vCPU | 2 vCPU |
| Memory | 2 GB | 8 GB | 6 GB |
| Storage | 2 GB | 2 GB | 2 GB |

### Cloud Run (image-extraction-api) — from commented defaults

| Resource | Request | Limit (commented default) |
|----------|---------|-------|
| CPU | Managed by GCP | `2` |
| Memory | Managed by GCP | `4Gi` |
| Timeout | N/A | `400s` |
