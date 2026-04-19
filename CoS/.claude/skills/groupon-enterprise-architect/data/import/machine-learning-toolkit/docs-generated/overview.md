---
service: "machine-learning-toolkit"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Pricing and Promotions Data Science"
platform: "AWS"
team: "P&P DS (Pricing and Promotions Data Science)"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform >= 0.13"
  framework: "Terragrunt"
  framework_version: "managed via .terraform-tooling"
  runtime: "AWS MWAA / Apache Airflow"
  runtime_version: "2.2.2"
  build_tool: "Jenkins + GitHub Actions"
  package_manager: "Terraform providers via Terragrunt"
---

# Pricing and Promotions Data Science Machine Learning Toolkit Overview

## Purpose

The Machine Learning Toolkit is an AWS Cloud platform that allows the Pricing and Promotions Data Science team to deploy services and pipelines related to data science and machine learning. It provisions and wires together a managed Airflow environment (AWS MWAA), transient EMR clusters, SageMaker model endpoints, a private API Gateway, and supporting storage and messaging infrastructure—all declared as Terraform/Terragrunt code. Its purpose is to give ML practitioners a repeatable, self-service platform for model training, feature engineering, endpoint deployment, and inference serving without requiring deep AWS infrastructure expertise.

## Scope

### In scope
- Provisioning and operating the AWS MWAA (Managed Workflows for Apache Airflow) environment for workflow orchestration.
- Launching transient AWS EMR clusters for batch feature engineering and data preparation jobs.
- Registering, versioning, and deploying AWS SageMaker model endpoints (synchronous and asynchronous).
- Exposing model inference APIs through a private AWS API Gateway secured by API keys.
- Managing all supporting S3 buckets (DAG storage, ETL data, model artifacts, feature store, EMR logs, client output).
- Providing SNS/SQS alerting for workflow success, failure, and general notifications.
- Managing platform secrets via AWS Secrets Manager and runtime config via AWS SSM Parameter Store.
- Publishing MWAA and EMR logs to CloudWatch and forwarding to centralized ELK/Kinesis streams.
- ECR repository management for inference and processing container images.

### Out of scope
- Business logic or model code (owned by individual project teams using the platform).
- Training data sourcing (upstream ETL pipelines are external).
- Serving SageMaker endpoints to public internet traffic (API Gateway is PRIVATE_ONLY).
- Model monitoring and drift detection pipelines (not evidenced in this repo).

## Domain Context

- **Business domain**: Pricing and Promotions Data Science
- **Platform**: AWS (us-west-2), operated in the `dnd-accounts` environment group
- **Upstream consumers**: Data science practitioners and internal ML project teams (via DAG authorship and API key–secured inference endpoints)
- **Downstream dependencies**: AWS MWAA, AWS EMR, AWS SageMaker, AWS API Gateway, AWS S3, AWS SNS/SQS, AWS SSM, AWS Secrets Manager, AWS KMS, AWS ECR, AWS CloudWatch, centralized logging stack (ELK/Kinesis), centralized metrics stack (Wavefront)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | P&P DS team (dnd-ds-pnp@groupon.com), primary contact eduquette |
| SRE / On-call | local-ds@groupon.com, Slack channel #ds-pnp-service-alerts (ID: C039QJMGEQM) |
| Platform Admin | Cloudcore team — manages IAM boundary policies and execution roles |
| Platform Users | Data science practitioners authoring DAGs and requesting API endpoints |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Infrastructure language | HCL (Terraform) | >= 0.13 | `modules/airflow_platform/versions.tf` |
| IaC orchestration | Terragrunt | managed via `.terraform-tooling` | `envs/Makefile`, `envs/terragrunt.hcl` |
| Workflow runtime | Apache Airflow | 2.2.2 | `modules/airflow_platform/mwaa.tf` |
| AWS provider | hashicorp/aws | 4.6.0 | `modules/airflow_platform/versions.tf` |
| Container management | kreuzwerker/docker | 2.16.0 | `modules/airflow_platform/versions.tf` |
| CI/CD | Jenkins (primary), GitHub Actions (DAG sync) | docker image `tf-base-ci:0.13.5.4` | `Jenkinsfile`, `.github/workflows/deploy.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| hashicorp/aws provider | 4.6.0 | infrastructure | Full AWS resource management (MWAA, EMR, SageMaker, API GW, S3, SNS, SQS, KMS, SSM, Secrets Manager) |
| hashicorp/local | 2.2.2 | infrastructure | Writes local secret JSON files for Secrets Manager seeding |
| hashicorp/archive | 2.2.0 | infrastructure | Zips EMR bootstrap artifacts for Artifactory upload |
| kreuzwerker/docker | 2.16.0 | container | Manages ECR image push/pull during Terraform apply |
| hashicorp/null | latest | infrastructure | Uploads EMR bootstrap zip to Artifactory via curl |
| hashicorp/external | latest | infrastructure | Module reference resolution for Terragrunt |
| AWS MWAA Airflow secrets backend | built-in | config | Reads Airflow connections and variables from Secrets Manager at runtime |
| Airflow AWS Provider | built-in | scheduling | EMR operators, SageMaker operators, SNS notification operators used in DAGs |
