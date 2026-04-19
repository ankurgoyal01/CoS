---
service: "tronicon-cms"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

Tronicon CMS is a containerized JTier application deployed to Kubernetes via the Groupon Conveyor Cloud platform. It runs in multiple GCP and AWS regions across staging and production environments. Deployments are triggered manually through DeployBot after CI builds succeed on the `main` branch via Cloud Jenkins. Helm renders Kubernetes manifests from the `.meta/deployment/cloud/components/app/` configuration. Production deployments require a 24-hour regional promotion window and automatically create GPROD logbook tickets.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java17-alpine-jtier:2023-12-19-609aedb` |
| CI base image | Docker | `.ci/Dockerfile`; base image `docker.groupondev.com/jtier/dev-java17-maven:2023-02-27-aaff088` |
| Orchestration | Kubernetes (GKE / EKS) | Manifests rendered by Helm via Conveyor Cloud; config in `.meta/deployment/cloud/` |
| Load balancer | Conveyor VIP | Per-environment VIP endpoints (see Environments table) |
| CDN | None | No evidence found |
| Image registry | `docker-conveyor.groupondev.com/tronicon/tronicon-cms` | Groupon internal Docker registry |
| Log shipping | Filebeat (sidecar) | Ships logs from pod filesystem to ELK stack |
| APM | Elastic APM Java agent | Enabled in all production and most staging environments |

## Environments

| Environment | Purpose | Cloud Provider | Region | VIP |
|-------------|---------|----------------|--------|-----|
| `staging-us-central1` | Staging — US | GCP | us-central1 | `tronicon-cms.us-central1.conveyor.stable.gcp.groupondev.com` |
| `staging-europe-west1` | Staging — EMEA | GCP | europe-west1 | `tronicon-cms.europe-west1.conveyor.stable.gcp.groupondev.com` |
| `production-us-central1` | Production — US | GCP | us-central1 | `tronicon-cms.us-central1.conveyor.prod.gcp.groupondev.com` |
| `production-eu-west-1` | Production — EMEA | AWS | eu-west-1 | `tronicon-cms.prod.eu-west-1.aws.groupondev.com` |
| `production-europe-west1` | Production — EMEA | GCP | europe-west1 | Configured via `production-europe-west1.yml` |

## CI/CD Pipeline

- **Tool**: Cloud Jenkins (CI/release) + DeployBot (deployment trigger)
- **Config**: `Jenkinsfile` (CI pipeline), `.deploy_bot.yml` (deployment targets and promotion chains)
- **Trigger**: Merge to `main` triggers Jenkins build; production deploy is manual via DeployBot

### Pipeline Stages

1. **Build and Test**: Jenkins runs `mvn clean verify`; executes unit tests; enforces JaCoCo coverage thresholds (80% method coverage, 70% branch coverage)
2. **Release Creation**: Successful `main` merge triggers automated release artifact creation with version tag (e.g., `1.0.2019.05.31_09.41_06abdbb`)
3. **Docker Build and Push**: JTier build lifecycle produces a Docker image and pushes to `docker-conveyor.groupondev.com/tronicon/tronicon-cms`
4. **Staging Deployment**: Developer manually triggers staging deployment in DeployBot for one or both staging regions (us-central1, europe-west1)
5. **Production Deployment**: After 24-hour promotion window, developer triggers production deployment per region; GPROD logbook ticket is created automatically; Prodcat change policy check runs automatically
6. **Post-Deploy Verification**: Monitor `wolfhound-deployment` Slack channel for deployment success notifications; verify in Grafana and Kibana

### Branching Strategy

- `main` is the release branch and the base branch for PRs
- PRs require approval from two developers before merge
- Each merged PR creates a deployable release

### Promotion Chain

`staging-europe-west1` → `production-eu-west-1` → `production-europe-west1`

`staging-us-central1` → `production-us-central1`

### Rollback

1. Navigate to the affected deployment entry in DeployBot
2. Click the "Rollback" button to revert to the previously successful deployment for that region
3. Repeat for each affected region (US and EMEA independently)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min=1, max=5; `hpaTargetUtilization=50` |
| Horizontal (production US) | Kubernetes HPA | min=2, max=60 |
| Horizontal (production EU/AWS) | Kubernetes HPA | min=2, max=50 |
| Memory (production) | Resource limits | Request 2Gi, Limit 2Gi |
| CPU (production) | Resource limits | Request 1, Limit 2 |

## Resource Requirements

| Resource | Request (production) | Limit (production) | Request (common baseline) | Limit (common baseline) |
|----------|---------------------|-------------------|--------------------------|------------------------|
| CPU (main) | 1 | 2 | 300m | — |
| Memory (main) | 2Gi | 2Gi | 500Mi | 500Mi |
| CPU (envoy sidecar) | 100m | — | 100m | — |
| Memory (envoy sidecar) | 160Mi | — | 160Mi | — |
