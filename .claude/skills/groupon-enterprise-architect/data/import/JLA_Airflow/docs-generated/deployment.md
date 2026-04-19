---
service: "JLA_Airflow"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

JLA Airflow is deployed to Google Cloud Composer (Composer-managed Apache Airflow on Kubernetes) across three environments: dev, staging (uat), and production — all in the `us-central1` GCP region. DAG files are packaged and deployed using Deploybot via a Docker image (`docker.groupondev.com/fsa/deploybot_fsa_gcs:fsa-v3.0.2`). The CI/CD pipeline is driven by Jenkins using the `fsa-pipeline-dsl@latest-2` shared library. Branch-to-environment mapping is defined in the `Jenkinsfile`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (deployment image) | `docker.groupondev.com/fsa/deploybot_fsa_gcs:fsa-v3.0.2` |
| Orchestration | Kubernetes (Google Cloud Composer) | Composer manages the Airflow scheduler, worker, webserver pods |
| DAG storage | Google Cloud Storage | `COMPOSER_DAGS_BUCKET` per environment |
| Load balancer | Composer-managed | Airflow webserver exposed by Composer |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | Cluster |
|-------------|---------|--------|---------|
| dev | Active development and testing | `us-central1` | `gcp-stable-us-central1` |
| staging | Stable pre-production validation (uat branch) | `us-central1` | `gcp-stable-us-central1` |
| production | Live accounting pipelines | `us-central1` | `gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Shared Library**: `fsa-pipeline-dsl@latest-2`
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `dev`, `uat`, or `main` branch
- **Artifact pattern**: `scripts/**,orchestrator/**`

### Branch-to-Environment Mapping

| Branch | Deploy Target | Manual Approval |
|--------|--------------|----------------|
| `dev` | `dev-us-central1` | No |
| `uat` | `staging-us-central1` | Yes |
| `main` | `production-us-central1` | Yes |

### Pipeline Stages

1. **Build**: Jenkins loads the `fsa-pipeline-dsl@latest-2` shared library and evaluates branch logic
2. **Notify**: Sends deployment start notification to environment-specific Google Chat space
3. **Deploy**: Deploybot copies `scripts/**` and `orchestrator/**` artifacts to the Composer DAGs GCS bucket (`COMPOSER_DAGS_BUCKET`) using `docker.groupondev.com/fsa/deploybot_fsa_gcs:fsa-v3.0.2`
4. **Notify**: Sends deployment complete or failure notification to Google Chat

### Deploybot Notification Events

- `start` — notified when deployment begins
- `complete` — notified on successful deployment
- `override` — notified if a deployment is manually overridden

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Composer-managed (GKE Autopilot or standard) | Managed by GCP Composer |
| Memory | Composer-managed | Managed by GCP Composer |
| CPU | Composer-managed | Managed by GCP Composer |

## Resource Requirements

> Deployment configuration managed by Google Cloud Composer. Specific resource request/limit values are not defined in this repository.
