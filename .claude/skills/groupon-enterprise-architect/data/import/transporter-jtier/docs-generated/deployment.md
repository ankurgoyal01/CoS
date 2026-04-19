---
service: "transporter-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1]
---

# Deployment

## Overview

Transporter JTier is deployed as two separate Kubernetes components within the Groupon Conveyor platform on GCP: an `api` component serving HTTP requests and an `sf-upload-worker` component running the Quartz bulk upload job. Both share the same Docker image (`docker-conveyor.groupondev.com/salesforce/transporter-jtier`). Deployments are managed by DeployBot, triggered by Jenkins CI builds on merge to `master`. Kubernetes configurations are managed via Kustomize overlays layered on Helm templates.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `docker-dev.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` (CI); runtime image: `docker-conveyor.groupondev.com/salesforce/transporter-jtier` |
| Orchestration | Kubernetes (GCP / Conveyor) | Kustomize overlays at `.meta/kustomize/overlays/` |
| Configuration management | Kustomize + Helm (Conveyor) | `.meta/deployment/cloud/components/` |
| Load balancer | Edge Proxy (Envoy) | `transporter-jtier.production.service` host header routing |
| APM | Conveyor APM sidecar | `apm: enabled: true` in deployment config |
| Log shipping | Filebeat → Kafka → Kibana | `sourceType: transporter-jtier`; Kafka endpoint per environment |

## Environments

| Environment | Purpose | Region | Namespace |
|-------------|---------|--------|-----------|
| staging-us-central1 | Pre-production testing; auto-deployed on PR merge | GCP us-central1 | `transporter-jtier-staging` |
| production-us-central1 | Live production traffic | GCP us-central1 | `transporter-jtier-production` |

Historical references to `us-west-1` exist in some config files (VPC labels), but the active DeployBot targets are `staging-us-central1` and `production-us-central1`.

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins) + DeployBot
- **Config**: `Jenkinsfile` (uses `java-pipeline-dsl@latest-2`); `.deploy_bot.yml`
- **Trigger**: On push/merge to `master` branch; releasable branches also include `staging` and `release.*`

### Pipeline Stages

1. **Build**: Jenkins executes `mvn clean verify` — compiles Java 11 source, runs unit and integration tests, performs code quality checks (PMD, FindBugs, JaCoCo)
2. **Docker publish**: Docker image published to Groupon Artifactory at `docker-conveyor.groupondev.com/salesforce/transporter-jtier`
3. **Auto-deploy staging**: DeployBot deploys to `staging-us-central1` (`transporter-jtier-staging` namespace) automatically
4. **Promote to production**: Manual promotion from `staging-us-central1` to `production-us-central1` via DeployBot UI
5. **Slack notify**: Deployment events notified to `salesforce-deploy` Slack channel

## Scaling

| Component | Dimension | Strategy | Staging Config | Production Config |
|-----------|-----------|----------|---------------|-------------------|
| `api` | Horizontal | HPA | min 1 / max 2 | min 2 / max 6 |
| `sf-upload-worker` | Horizontal | HPA | min 1 / max 2 | min 2 / max 6 |
| Both | HPA target | CPU utilization | 100% (common.yml) | 100% (common.yml) |

## Resource Requirements

| Component | Resource | Request | Limit |
|-----------|----------|---------|-------|
| `api` (main container) | CPU | 1000m | Not set |
| `api` (main container) | Memory | 4Gi | 6Gi |
| `sf-upload-worker` (main container) | CPU | 1000m | Not set |
| `sf-upload-worker` (main container) | Memory | 4Gi | 6Gi |

## Port Configuration

| Port | Purpose |
|------|---------|
| `8080` | HTTP application port (exposed as port 80 on Kubernetes service) |
| `8081` | Dropwizard admin port (health checks, metrics) |

## IAM / Identity

- **GCP Workload Identity**: Each pod authenticates to GCP via a Conveyor-managed GCP service account
  - Staging: `con-sa-transporter-jtier@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com`
  - Production: `con-sa-transporter-jtier@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com`
- **AWS IRSA (sf-upload-worker only)**: The worker pod uses a projected service account token (`sts.amazonaws.com` audience) to assume IAM role `tr-iam-role-upload-production` / `tr-iam-role-upload-staging` for S3 access

## Rollback

Rollback is performed via the DeployBot UI:
- Click **RETRY** on the previous stable deployment, or
- Click **ROLLBACK** on a specific deployment entry in the DeployBot UI at `https://deploybot.groupondev.com/salesforce/transporter-jtier`
