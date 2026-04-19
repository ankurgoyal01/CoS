---
service: "deletion_service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production-na, production-emea]
---

# Deployment

## Overview

The Deletion Service is containerized using Docker and deployed to Kubernetes via Groupon's Conveyor/Raptor platform. It runs in two production regions — NA (GCP us-central1) and EMEA (AWS eu-west-1) — and one staging environment (GCP us-central1). The container image is built and published to Groupon's internal Docker registry by Jenkins on successful builds from the `main` branch. Deployment to staging is automatic after a successful build; promotion to production is performed manually via DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| CI build image | Docker | `.ci/Dockerfile` with `docker-compose.yml` for integration tests |
| Orchestration | Kubernetes (Conveyor/Raptor) | Manifests in `.meta/deployment/cloud/components/deletion-service-component/` |
| Registry | Internal Docker registry | `docker-conveyor.groupondev.com/goods/deletion-service` |
| Load balancer | Conveyor VIP | `deletion-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| CDN | None | Not applicable |
| APM | Enabled | Configured via `apm.enabled: true` in `common.yml` |
| Logging | Filebeat / ELK | Source type `deletion_service`; shipped to NA ELK and EMEA ELK |

## Environments

| Environment | Purpose | Region | Cloud | URL |
|-------------|---------|--------|-------|-----|
| Staging | Pre-production validation | GCP us-central1 | GCP | `deletion-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| Production NA | Live NA traffic | GCP us-central1 | GCP | `deletion-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| Production EMEA | Live EMEA traffic | AWS eu-west-1 | AWS | Not specified in deployment YAMLs |

## CI/CD Pipeline

- **Tool**: Jenkins (via shared JTier pipeline library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch or branches matching the `\d+\.\d+\.\d+` pattern; also `DA-8131-gcp-live-test` branch for GCP live tests
- **Auto-deploy target**: `staging-us-central1` on successful build from `main`

### Pipeline Stages

1. **Build**: Maven clean install, runs unit and integration tests via JTier pipeline
2. **Package**: Builds Docker image and pushes to `docker-conveyor.groupondev.com/goods/deletion-service`
3. **Publish artifact**: Uploads JAR to Nexus on successful build
4. **Auto-deploy to staging**: Triggers DeployBot deployment to `staging-us-central1`
5. **Promote to production**: Manual promotion via DeployBot UI to `production-us-central1` and/or `production-eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Staging) | Kubernetes HPA | Min: 1, Max: 2 |
| Horizontal (Production NA) | Kubernetes HPA | Min: 1, Max: 3 |
| Horizontal (Production EMEA) | Kubernetes HPA | Min: 1, Max: 3 |
| HPA target utilization | CPU-based | 50% (common config) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 160m | Not specified (inherits JTier defaults) |
| Memory | 500Mi | 3Gi |
| Disk | Filebeat volume (`medium` in production, `low` in staging) | Not specified |

## Port Configuration

| Port | Purpose |
|------|---------|
| `8080` | HTTP application port (REST API, health check) |
| `8081` | Admin port (Dropwizard metrics and admin tasks) |
| `8009` | JMX port |

## Rollback

Re-deploy an older release via the DeployBot UI. For releases older than what DeployBot retains, create a branch from the target commit, add it to the `releasableBranches` list in `Jenkinsfile`, build it, and deploy via DeployBot.
