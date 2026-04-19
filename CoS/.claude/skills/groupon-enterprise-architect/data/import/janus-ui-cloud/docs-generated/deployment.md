---
service: "janus-ui-cloud"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev-us-west-2", "staging-us-west-2", "staging-us-central1", "production-us-west-2", "production-us-central1"]
---

# Deployment

## Overview

Janus UI Cloud is containerised with Docker (Node.js 10.13.0 base image) and deployed to Kubernetes clusters on both AWS and GCP via the Groupon Conveyor/DeployBot platform. Helm is used to render Kubernetes manifests from the `cmf-java-api` chart (version 3.88.1). Deployments are promoted through dev to staging and then to production using DeployBot pipeline targets. Jenkins (`Jenkinsfile`) orchestrates the Docker build and image publishing step.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — `FROM node:10.13.0`; bootstrap via `scripts/bootstrap.sh` |
| Image registry | Conveyor | `docker-conveyor.groupondev.com/data-engineering/janus-ui-cloud` |
| Orchestration | Kubernetes | Helm chart `cmf-java-api v3.88.1`; deployed via `krane` |
| Deployment tool | DeployBot / Raptor | `.deploy_bot.yml` targets; deploy script: `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Kubernetes VIP (Conveyor) | VIPs defined per environment in deployment YAML |
| CDN | Not applicable | Static assets served directly from the Express gateway |

## Environments

| Environment | Purpose | Cloud / Region | VIP / URL |
|-------------|---------|----------------|-----------|
| dev-us-west-2 | Development and feature testing | AWS / us-west-2 | Hybrid boundary ingress (custom subdomain `dev`) |
| staging-us-west-2 | Pre-production validation | AWS / us-west-2 | `janus-ui-cloud-staging` namespace |
| staging-us-central1 | Pre-production validation (GCP) | GCP / us-central1 | `janus-ui-cloud.staging.service.us-central1.gcp.groupondev.com` |
| production-us-west-2 | Production traffic | AWS / us-west-2 | `janus-ui-cloud-production` namespace |
| production-us-central1 | Production traffic (GCP) | GCP / us-central1 | `janus-ui-cloud.us-central1.conveyor.prod.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main`, `release`, or `deploytest` branches
- **Shared library**: `java-pipeline-dsl@latest-2`
- **Deployment tool**: DeployBot (`.deploy_bot.yml`) with `krane` for Kubernetes apply

### Pipeline Stages

1. **Docker Build**: Builds the Docker image using `Dockerfile`; tags with commit SHA
2. **Image Push**: Publishes image to `docker-conveyor.groupondev.com/data-engineering/janus-ui-cloud`
3. **Deploy to dev-us-west-2**: Runs `deploy.sh dev-us-west-2 dev` via DeployBot; promotes to staging on success
4. **Deploy to staging-us-west-2**: Runs `deploy.sh staging-us-west-2 staging`; promotes to production on success
5. **Deploy to staging-us-central1**: Runs `deploy.sh staging-us-central1 staging`; promotes to production-us-central1
6. **Deploy to production-us-west-2**: Runs `deploy.sh production-us-west-2 production`
7. **Deploy to production-us-central1**: Runs `deploy.sh production-us-central1 production`

Slack notifications sent to `dnd-ingestion-ops` channel on start, complete, and override events.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Dev: 1/1; Staging: 1/2; Production: 2/15 replicas |
| HPA target | CPU utilisation | `hpaTargetUtilization: 100` (common.yml) |
| Memory | Resource limits | Production: request 1800Mi / limit 4Gi |
| CPU | Resource limits | Production: request 100m; Filebeat sidecar: request 10m / limit 30m |

## Resource Requirements

| Resource | Request (production) | Limit (production) |
|----------|---------------------|--------------------|
| CPU (main) | 100m | Not set (common: 80m) |
| Memory (main) | 1800 Mi | 4 Gi |
| CPU (filebeat) | 10m | 30m |
| Disk | Not specified | Not specified |

## Health Probes

| Probe | Type | Port | Path | Initial Delay | Period |
|-------|------|------|------|--------------|--------|
| Readiness | HTTP | 8080 | `/` | 300s | 20s |
| Liveness | HTTP | 8080 | `/` | 300s | 15s |

> Note: The 300-second initial delay accommodates the webpack build step that runs inside the container at startup via `scripts/bootstrap.sh`.
