---
service: "gcp-aiaas-terraform"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [hcl-files, gcp-secret-manager, terragrunt-inputs]
---

# Configuration

## Overview

Configuration for the AIaaS platform is managed entirely through Terraform/Terragrunt HCL files. Per-environment values are defined in `account.hcl` files at the environment root (`envs/dev/account.hcl`, `envs/prod/account.hcl`). Cross-environment global settings (e.g., Terraform service account) live in `envs/global.hcl`. Module-specific inputs are provided in each service's `terragrunt.hcl`. At runtime, Cloud Run services and Cloud Functions read sensitive values from GCP Secret Manager (provisioned via the `gcp-secret-manager` Terraform module). No application-level environment variable files exist in this IaC repository.

## Environment Variables

### Airflow / Cloud Composer environment variables (set via Terraform)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `AIRFLOW_VAR_ENV` | Identifies the Airflow environment stage | yes | `dev` | `account.hcl` |
| `AIRFLOW_VAR_FINANCE_SERVICE_ACCOUNT` | Service account used by Airflow for GCP resource access | yes | env-specific SA email | `account.hcl` |
| `AIRFLOW_VAR_PROJECT_ID` | GCP project ID for Airflow DAG execution | yes | `prj-grp-aiaas-dev-94dd` (dev) | `account.hcl` |
| `AIRFLOW_VAR_REGION` | GCP region for Airflow operations | yes | `us-central1` | `account.hcl` |
| `AIRFLOW_VAR_SUBNET` | VPC subnetwork for Dataproc ephemeral clusters | yes | `sub-vpc-dev-sharedvpc01-us-central1-private` | `account.hcl` |
| `AIRFLOW_VAR_TAGS` | Network tags applied to Dataproc VMs | yes | `'allow-iap-ssh','dataproc-vm'` | `account.hcl` |

### Cloud Run environment variables (set via Terragrunt inputs)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `environment` | Deployment environment stage (`dev` or `prod`) | yes | none | `gcp-cloud-run/terragrunt.hcl` |
| `deploy_image_extraction` | Feature flag to deploy the image-extraction-api Cloud Run service | yes | `true` | `gcp-cloud-run/terragrunt.hcl` |
| `PYTHONUNBUFFERED` | Ensures Python stdout/stderr are not buffered (optional override) | no | not set | `gcp-cloud-run/terragrunt.hcl` (commented) |

### Cloud Scheduler inputs

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `cloud_run_service_name` | Name of the Cloud Run service to target | yes | `aidg-top-deals` | `gcp-cloud-scheduler/terragrunt.hcl` |
| `cloud_run_url` | HTTPS URL of the Cloud Run service | yes | `https://aidg-top-deals-364685817243.us-central1.run.app/top-deals-async` | `gcp-cloud-scheduler/terragrunt.hcl` |
| `job_name` | Cloud Scheduler job name | yes | `aidg-top-deals-async` | `gcp-cloud-scheduler/terragrunt.hcl` |
| `schedule_cron` | Cron expression for the job | yes | `0 0 * * *` (daily midnight UTC) | `gcp-cloud-scheduler/terragrunt.hcl` |
| `schedule_timezone` | Timezone for cron evaluation | yes | `UTC` | `gcp-cloud-scheduler/terragrunt.hcl` |
| `scheduler_sa_email` | OIDC token service account for Scheduler-to-Cloud-Run auth | yes | `loc-sa-vertex-ai-pipeline@prj-grp-aiaas-dev-94dd.iam.gserviceaccount.com` | `gcp-cloud-scheduler/terragrunt.hcl` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `deploy_image_extraction` | Controls whether the `image-extraction-api` Cloud Run service is deployed | `true` | per-environment (set in `gcp-cloud-run/terragrunt.hcl`) |
| `DISABLE_AUTOMATIC_COMPLIANCE_TESTS` | Disables CloudCore's automatic Terraform compliance test suite on plan | `true` | global (`envs/Makefile`) |
| `dags_are_paused_at_creation` | All new Airflow DAGs are paused on first deploy to prevent accidental execution | `True` | per-environment (`account.hcl`) |
| `sched_catchup_by_default` | Airflow scheduler does not backfill missed DAG runs | `false` | per-environment (`account.hcl`) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global Terraform service account (`grpn-sa-terraform-aiaas`) |
| `envs/dev/account.hcl` | HCL | Dev environment project ID, network settings, Composer config, Airflow env vars |
| `envs/prod/account.hcl` | HCL | Prod environment project ID, network settings, Composer config, Airflow env vars |
| `envs/Makefile` | Makefile | Project name, service name, Terragrunt version, cloud provider |
| `envs/dev/us-central1/gcp-cloud-scheduler/terragrunt.hcl` | HCL | Cloud Scheduler job inputs (cron, target URL, SA) |
| `envs/dev/us-central1/gcp-cloud-run/terragrunt.hcl` | HCL | Cloud Run deployment inputs (environment, image extraction feature flag) |
| `envs/dev/us-central1/gcp-big-query/terragrunt.hcl` | HCL | BigQuery dataset and table configuration |
| `doc/swagger.yml` | YAML (Swagger 2.0) | API Gateway OpenAPI spec defining all routes and Cloud Function backend addresses |
| `PROJECT.ini` | INI | Project metadata (project name, service name, owner email, cloud provider) |
| `.service.yml` | YAML | Service registry metadata (SRE contacts, PagerDuty, Slack, Wavefront dashboard) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `grpn-sa-terraform-aiaas` | Terraform service account used to authenticate Terragrunt plan/apply | GCP IAM / provided by CloudCore |
| `loc-sa-vertex-ai-pipeline` | Runtime service account for Cloud Composer, Cloud Scheduler, and Cloud Run OIDC invocation | GCP IAM |
| `gw_sa` | API Gateway service account for backend invocation | GCP IAM |
| DAAS PostgreSQL credentials | Database credentials for AIDG service read access in `gcp-cloud-functions-2` | Terragrunt inputs (staging); GCP Secret Manager (prod intent) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | dev | prod |
|---------|-----|------|
| GCP Project ID | `prj-grp-aiaas-dev-94dd` | `prj-grp-aiaas-prod-0052` |
| GCP Project Number | `364685817243` | `462102722170` |
| Network project | `prj-grp-shared-vpc-dev-d89e` | `prj-grp-shared-vpc-prod-2511` |
| VPC connector | `con-us-central1-dev` | `con-us-central1-prod` |
| Cloud Composer image | `composer-2.6.6-airflow-2.6.3` | `composer-2.6.6-airflow-2.6.3` |
| Terraform execution | Developer GCP account (dev only) or service account | Service account only (`grpn-sa-terraform-aiaas`) |
| DAG update method | Direct GCS upload allowed for dev | PR-based, Jenkins CI/CD only |
| BigQuery deletion_protection | `false` (dev flexibility) | `false` (temporarily disabled) |

- **dev**: Direct console/CLI access is permitted for GCS DAG updates; Terraform can be run locally with a developer GCP account
- **prod**: All changes require a PR approval and are deployed via Jenkins CI/CD; service account credentials are required for all Terraform operations
