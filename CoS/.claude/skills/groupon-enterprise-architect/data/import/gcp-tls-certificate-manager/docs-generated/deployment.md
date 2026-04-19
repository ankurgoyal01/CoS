---
service: "gcp-tls-certificate-manager"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

GCP TLS Certificate Manager has no long-running application server. All processing occurs during pipeline execution. The deployment model is GitOps-driven: a commit to the `main` branch containing changes in the `requests/` directory triggers a Jenkins pipeline that calls DeployBot, which runs a containerized deploybot image (`gcp_tls_certificate_manager_deploybot:1.8-test-legacy`) in Conveyor Cloud Kubernetes. The container applies cert-manager Certificate resources in environment-specific namespaces, retrieves the issued TLS material, and publishes it to GCP Secret Manager. Environments are promoted sequentially: dev → staging → production, with manual approval required for production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `docker.groupondev.com/dnd_gcp_migration_infra/gcp_tls_certificate_manager_deploybot:1.8-test-legacy` (managed in separate repo `gcp-tls-certificate-manager-deploybot`) |
| Orchestration | Kubernetes (Conveyor Cloud) | Namespaces: `gcp-tls-certificate-manager-dev`, `gcp-tls-certificate-manager-staging`, `gcp-tls-certificate-manager-production` |
| CI runner | Jenkins | Agent label: `dind_2gb_2cpu`; library: `conveyor-ci-util@latest` |
| Deployment tool | DeployBot | Deployment image version pinned in `.deploy_bot.yml` |
| Certificate issuance | cert-manager v1 | Kubernetes CRD-based certificate issuance within Conveyor Cloud namespaces |
| Secret storage | GCP Secret Manager | Per-project, per-environment secrets created/updated via `gcloud` CLI |
| Load balancer | none | No HTTP traffic; pipeline-only service |
| CDN | none | No web traffic |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| dev | Certificate provisioning validation and initial testing | us-central1 (GCP) | `gcp-stable-us-central1` |
| staging | Pre-production certificate validation | us-central1 (GCP) | `gcp-stable-us-central1` |
| production | Live certificate provisioning for GCP production workloads | us-central1 (GCP) | `gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch (via GitHub push event) or monthly cron schedule (`H 12 1-7 * 1` — first Monday of each month at noon UTC)

### Pipeline Stages

1. **Init**: Resolves branch/tag info, short SHA, checks for request file changes using `has-cert-requests.sh`, determines whether trigger is a push event or timer
2. **Validate Deploy Config**: Validates `.deploy_bot.yml` using `deploybotValidate()` when request changes exist or when triggered by timer
3. **DeployNewUpdated**: Invokes `deploybotDeploy()` targeting `dev-gcp` when push event detected changes in `requests/`; DeployBot then promotes through `staging-gcp` → `production-gcp` (manual)
4. **DeployRefresh**: Invokes `deploybotDeploy()` targeting `dev-gcp-refresh` when triggered by monthly cron; DeployBot then promotes through `staging-gcp-refresh` → `production-gcp-refresh` (manual)

### DeployBot Execution (within each environment)

1. Sets Kubernetes context to `gcp-tls-certificate-manager-{env}`
2. Clones the repository at the target commit SHA from GitHub Enterprise
3. Activates GCP service account credentials from the `tls-certificate-cicd-sa-key` Kubernetes secret
4. Detects request file changes (Add/Modify/Delete) from git history
5. For each changed request file, creates or updates cert-manager Certificate resources via `kubectl`
6. Retrieves the issued TLS material from the resulting Kubernetes Secret
7. Creates or updates the GCP Secret Manager secret (`tls--{org}-{service}`) with the TLS material JSON
8. For legacy requests (`cntype: legacy`), additionally publishes to AWS ACM
9. On delete actions, removes the GCP Secret Manager secret and cert-manager resources

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable (ephemeral pipeline execution; no persistent pods) | — |
| Memory | Jenkins agent | `2gb` (dind_2gb_2cpu label) |
| CPU | Jenkins agent | `2cpu` (dind_2gb_2cpu label) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 2 cores (Jenkins agent) | 2 cores |
| Memory | 2 GB (Jenkins agent) | 2 GB |
| Disk | Ephemeral (git clone only) | Not specified |

> Deployment configuration for the deploybot container image itself (CPU/memory limits within Conveyor Cloud) is managed in the separate `gcp-tls-certificate-manager-deploybot` repository.
