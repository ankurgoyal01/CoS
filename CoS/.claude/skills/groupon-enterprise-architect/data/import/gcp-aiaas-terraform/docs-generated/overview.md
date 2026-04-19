---
service: "gcp-aiaas-terraform"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Science / Machine Learning"
platform: "Continuum"
team: "DSSI (Deal Structure and Supply Intelligence)"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform >= 1.0"
  framework: "Terragrunt"
  framework_version: "0.30.7"
  runtime: "GCP"
  runtime_version: "Cloud Composer 2.6.6 / Airflow 2.6.3"
  build_tool: "Make"
  package_manager: "Terragrunt module-ref"
---

# GCP AIaaS Terraform Overview

## Purpose

`gcp-aiaas-terraform` is Groupon's Infrastructure-as-Code repository for the GCP AI-as-a-Service (AIaaS) platform, owned by the DSSI (Deal Structure and Supply Intelligence) team. It provisions and manages the full suite of GCP resources — Cloud Composer (Airflow), Vertex AI, Cloud Run, Cloud Functions, BigQuery, Cloud Storage, API Gateway, Cloud Tasks, Cloud Scheduler, and Secret Manager — that together form the platform Data Science teams use to train, host, and serve ML models. All resource changes across `dev` and `prod` environments flow exclusively through Terraform/Terragrunt, enforcing infrastructure governance and repeatability.

## Scope

### In scope

- Provisioning GCP Cloud Composer (Airflow) environments for workflow orchestration
- Provisioning GCP Vertex AI resources: model registry, endpoints, batch transform jobs
- Provisioning GCP Cloud Run services for containerised ML inference APIs
- Provisioning GCP Cloud Functions (Gen 1 and Gen 2) for lightweight AI inference and utility functions
- Provisioning GCP API Gateway as the front door for all HTTP-accessible AI endpoints
- Provisioning GCP Cloud Tasks queues and Cloud Scheduler jobs for asynchronous background workloads
- Provisioning GCP Cloud Storage buckets (DAGs, ETL inputs/outputs, model artifacts, project files)
- Provisioning GCP BigQuery datasets and tables (e.g., `merchant_data_center`)
- Provisioning GCP Secret Manager secrets for runtime configuration
- IAM service account and role management for all deployed resources
- Terraform remote state management via Terragrunt across `dev` and `prod`

### Out of scope

- Application source code for Cloud Functions or Cloud Run images (hosted in separate service repos)
- Airflow DAG business logic (DAG files are deployed separately to GCS)
- ML model training code and notebooks
- Data Science experimentation environments (Google Colab / Vertex AI Workbench)
- Non-GCP infrastructure (AWS, on-premises)

## Domain Context

- **Business domain**: Data Science / Machine Learning — specifically the Merchant Advisor (AI) team's AI features such as Google Reviews analysis, image scoring, USP generation, and content generation
- **Platform**: Continuum (Groupon's core commerce platform ecosystem)
- **Upstream consumers**: Internal Data Science teams (DSSI / Merchant Advisor) consuming the provisioned endpoints; GCP API Gateway consumers calling `/v1/*` endpoints
- **Downstream dependencies**: GCP managed services (Cloud Composer, Vertex AI, Cloud Run, BigQuery, Cloud Storage, Secret Manager, API Gateway, Cloud Tasks, Cloud Scheduler)

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Owner / Admin | DSSI team (cs_ds@groupon.com) — owns the Terraform execution role and manages the platform |
| Service Consumer | Data Science / Merchant Advisor teams who deploy DAGs, Cloud Functions, and Cloud Run services onto this platform |
| CloudCore Team | Groupon's Cloud Native infrastructure team; supplies Terraform service accounts, execution roles, and CI/CD profiles |
| SRE | cs_ds@groupon.com — on-call for platform alerts via PagerDuty (`PREMYX7`) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL (Terraform) | >= 1.0 | `envs/dev/us-central1/*/terragrunt.hcl` |
| Framework | Terragrunt | 0.30.7 | `envs/Makefile` (`TERRAGRUNT_VERSION`) |
| Runtime | GCP | N/A | `envs/dev/account.hcl`, `envs/prod/account.hcl` |
| Build tool | Make | N/A | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Workflow orchestration | GCP Cloud Composer (Airflow) | composer-2.6.6 / airflow-2.6.3 | `envs/dev/account.hcl` (`composer_image_version`) |
| IaC orchestration | Terragrunt module-ref | N/A | `envs/.terraform-tooling/bin/module-ref` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Terraform GCP Provider | locked per `.terraform.lock.hcl` | IaC provider | Manages all GCP resource lifecycle |
| Terragrunt | 0.30.7 | scheduling / orchestration | DRY Terraform wrapper; manages dependencies between modules |
| GCP Cloud Composer | composer-2.6.6 | scheduling | Managed Apache Airflow for DAG orchestration |
| GCP Vertex AI | managed | ml-platform | Model hosting, endpoints, batch jobs |
| GCP Cloud Run | managed | compute | Serverless container runtime for inference APIs |
| GCP Cloud Functions Gen 2 | managed | compute | Event-driven functions for AI workflows |
| GCP API Gateway | managed | http-framework | Unified HTTPS front door with API key auth |
| GCP BigQuery | managed | db-client | Analytics warehouse for ML datasets and results |
| GCP Secret Manager | managed | auth | Centralised secret injection for runtime services |
| GCP Cloud Tasks | managed | message-client | Asynchronous task queue for background jobs |
| GCP Cloud Scheduler | managed | scheduling | Cron-based trigger for periodic Cloud Run jobs |

> Only the most important infrastructure components are listed here. Transitive GCP dependencies are omitted. See `envs/dev/us-central1/*/terragrunt.hcl` for a full list of provisioned modules.
