---
service: "machine-learning-toolkit"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "aws-mwaa"
environments: ["dev", "stable"]
---

# Deployment

## Overview

The Machine Learning Toolkit is an infrastructure-as-code service deployed entirely via Terraform and Terragrunt. There is no standalone application container to deploy; the platform itself provisions AWS managed services (MWAA, EMR, SageMaker, API Gateway, S3, SNS, SQS, KMS, ECR, CloudWatch). Docker is used during `terraform apply` to push inference container images to ECR. The Jenkins pipeline drives all Terraform plan and apply operations across environments. A secondary GitHub Actions workflow syncs Airflow DAG files directly to S3 on push to `main`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Workflow orchestration | AWS MWAA (Airflow 2.2.2) | `mw1.small` class, 1–10 workers, `PRIVATE_ONLY` webserver, KMS-encrypted |
| Batch compute | AWS EMR | Transient clusters, Spark, configurable instance types, spot instance support with failover policy |
| ML serving | AWS SageMaker | Sync and async endpoint modes; autoscaling per endpoint; configured via Airflow Operators |
| API layer | AWS API Gateway (PRIVATE) | VPC endpoint-bound, API key authentication, per-model version/path routing |
| Container registry | AWS ECR | Per-team/per-model repos; scan-on-push enabled; images managed by `kreuzwerker/docker` Terraform provider |
| IaC orchestration | Terragrunt | Wraps Terraform modules; manages remote S3 backend state; `envs/` directory structure |
| Terraform module | `modules/airflow_platform` | Single reusable module covering all platform resources |
| CI image | `docker.groupondev.com/cloudcore/tf-base-ci:0.13.5.4` | CloudCore-maintained Docker image used for all Jenkins Terraform operations |
| Load balancer | None (private API GW via VPC endpoint) | API Gateway is bound to `data.aws_vpc_endpoint.api_gateway.id` |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | AWS Account ID |
|-------------|---------|--------|----------------|
| `dev` | Development and validation of Terraform changes | `us-west-2` | `575209962483` |
| `stable` | Stable pre-production environment; manual apply required | `us-west-2` | `965578965255` |
| `production` | Production (commented out in Jenkinsfile; not currently active) | `us-west-2` | — |
| `sandbox` | Sandbox environment (Terragrunt config present) | `us-west-2` | — |

## CI/CD Pipeline

- **Primary tool**: Jenkins (`Jenkinsfile` at repo root)
- **Secondary tool**: GitHub Actions (`.github/workflows/deploy.yml` — DAG sync to S3 only)
- **Config (Jenkins)**: `Jenkinsfile`
- **Config (GitHub Actions)**: `.github/workflows/deploy.yml`
- **Trigger (Jenkins)**: GitHub webhook on PR and push events; manual dispatch with environment checkbox parameters (`dev`, `stable`, `production`)
- **Trigger (GitHub Actions)**: Push to `main` branch (syncs DAG files to S3)

### Jenkins Pipeline Stages

1. **formatCheck**: Pulls the `tf-base-ci` Docker image; clones `dssi-credentials` repo and injects `api-keys.json`; runs Terraform format check against the dev environment
2. **tfValidate**: Runs `terraform validate` inside the `tf-base-ci` container for the `dev` environment
3. **dev** (parallel): Auto-plan on PRs to dev; no auto-apply (manual `APPLY` via Jenkins parameter)
4. **stable** (parallel): Auto-plan disabled; no auto-apply; `APPLY` must be triggered manually via Jenkins parameter

### GitHub Actions Pipeline Stages (DAG sync)

1. **Checkout**: Checks out repository at `main`
2. **S3 sync**: Runs `s3-sync-action` to push DAG files to `AWS_S3_BUCKET` (from GitHub secret) in `us-west-2`, excluding non-DAG files (modules, envs, bootstrap, README, etc.)

### Credentials used by Jenkins

- `svcdcos-ssh` — SSH key for cloning `dssi-credentials` repo
- IAM role `grpn-dnd-dssi-af` assumed via `TERRAGRUNT_IAM_ROLE` environment variable

### GitHub Actions Secrets

| Secret | Purpose |
|--------|---------|
| `AWS_S3_BUCKET` | Target S3 bucket name for DAG sync |
| `AWS_ACCESS_KEY_ID` | AWS access key for S3 sync action |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for S3 sync action |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| MWAA workers | Auto-scaling (AWS-managed) | Min 1, Max 10 (`mw1.small`) |
| EMR cluster | Auto-scaling (EMR managed per cluster) | Instance type and count defined per project in EMR job config |
| SageMaker endpoints | Auto-scaling (AWS SageMaker Autoscaling) | Policy defined per project; instance type recommended by SageMaker Inference Recommender |
| API Gateway | Managed by AWS | Stage-level throttle settings via usage plan |

## Resource Requirements

| Resource | Configuration |
|----------|---------------|
| MWAA task storage | Limited to 10 GB per ECS Fargate 1.3 task |
| MWAA environment class | `mw1.small` (upgradable to larger class for high load) |
| EMR instance type | Configured per project team; managed by CloudCore SCP boundaries |
| SageMaker instance type | Recommended by Amazon SageMaker Inference Recommender; varies per project |

## Deployment Checklist (Production)

1. Create a GPROD logbook ticket.
2. Ensure IAM execution role `grpn-dnd-dssi-af` access is available.
3. Clone repo and run `terraform validate` (`envs/{env}/validate` make target) via Jenkins.
4. Run `terraform plan` (`envs/{env}/plan` make target) and review output.
5. Run `terraform apply` (`envs/{env}/APPLY` make target) via Jenkins manual trigger.
6. Verify MWAA scheduler heartbeat in Wavefront dashboard `ds-pnp`.
7. Verify CloudWatch log groups are receiving MWAA logs.
