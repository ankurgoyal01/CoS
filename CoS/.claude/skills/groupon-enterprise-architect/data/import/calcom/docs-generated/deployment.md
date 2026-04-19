---
service: "calcom"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Calcom is a containerized service deployed to Kubernetes across both AWS and GCP cloud providers. It runs in Groupon's Conveyor cloud platform using the `cmf-generic-api` Helm chart. The service consists of a single worker component (`calcom::worker`) that serves both the web/API and background worker roles. Deployments are managed by the DeployBot system and follow a promote-to-production pattern from staging.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `FROM calcom/cal.com:v4.3.5` (single-line Dockerfile) |
| Container registry | Artifactory | `docker-conveyor.groupondev.com/conveyor-cloud/calcom` |
| Orchestration | Kubernetes | Namespaces: `calcom-staging`, `calcom-production` |
| Helm chart | cmf-generic-api 3.88.1 | `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy tool | krane | Manifest deployment via `krane deploy` with 600s timeout |
| Deploy bot image | `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` | Defined in `.deploy_bot.yml` |
| Load balancer | Kubernetes service (internal) | Port 3000 |
| CDN / Public domain | Akamai / Groupon edge | `https://meet.groupon.com` (production) |

## Environments

| Environment | Purpose | Cloud | Region | URL |
|-------------|---------|-------|--------|-----|
| staging-us-west-1 | Integration testing | AWS | us-west-1 | `https://calcom.staging.service.us-west-1.aws.groupondev.com` |
| staging-us-central1 | Integration testing | GCP | us-central1 | `https://calcom.staging.service.us-central1.gcp.groupondev.com` |
| production-us-west-1 | Live production (AWS) | AWS | us-west-1 | `https://meet.groupon.com` / `https://calcom.production.service.us-west-1.aws.groupondev.com` |
| production-us-central1 | Live production (GCP) | GCP | us-central1 | `https://meet.groupon.com` (VIP: `calcom.us-central1.conveyor.prod.gcp.groupondev.com`) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `main` branch
- **Deploy tool**: DeployBot (`.deploy_bot.yml`)

### Pipeline Stages

1. **Docker Build**: Builds the `calcom/cal.com:v4.3.5`-based Docker image using the single-line `Dockerfile`
2. **Push to Registry**: Pushes the tagged image to `docker-conveyor.groupondev.com/conveyor-cloud/calcom`
3. **Deploy to Staging**: Deploys to `calcom-staging` namespace in `staging-us-west-1` and `staging-us-central1` via deploy script
4. **Promote to Production**: Deploy bot promotes from staging to production targets (`production-us-west-1`, `production-us-central1`) upon approval

### Deploy Script Behavior

The deploy script (`.meta/deployment/cloud/scripts/deploy.sh`) runs `helm3 template` to generate Kubernetes manifests by merging:
1. `common.yml` (base config)
2. Environment-specific secrets from `.meta/deployment/cloud/secrets/cloud/<target>.yml`
3. Environment-specific overrides from `.meta/deployment/cloud/components/worker/<target>.yml`

The rendered manifests are piped directly to `krane deploy` with a 600-second global timeout.

## Scaling

| Dimension | Strategy | Staging Config | Production Config |
|-----------|----------|--------------|--------------------|
| Horizontal | Kubernetes HPA | min: 1, max: 2 | min: 2, max: 4 |
| HPA target utilization | CPU | 100% (common) | 100% (common) |
| Network policy | Egress-only | Enabled | Enabled |

## Resource Requirements

### Worker (common baseline)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | — |
| Memory | 500Mi | 1500Mi |

### Worker (production override)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 200m | — |
| Memory | 1000Mi | 3000Mi |

> Note from README: CPU lower than 1000m and memory lower than 1500Mi can cause crashing when a single user actively uses the service. Production limits are intentionally set higher.

## Health Probes

| Probe | Path | Port | Initial Delay |
|-------|------|------|--------------|
| Readiness | `/` | 3000 | 180 seconds |
| Liveness | `/` | 3000 | 180 seconds |

## Kubernetes Access

Access to Kubernetes namespaces requires AD group membership. Request access via [ARQ](https://arq.groupondev.com/ra/request/service) by selecting the `calcom` service and requesting groups:
- `grp_conveyor_privileged_calcom`
- `grp_conveyor_production_calcom`
- `grp_conveyor_stable_calcom`
