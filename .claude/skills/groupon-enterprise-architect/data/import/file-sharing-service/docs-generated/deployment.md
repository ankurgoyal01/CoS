---
service: "file-sharing-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

File Sharing Service is containerized using Docker and deployed to Kubernetes via Groupon's Conveyor Cloud (Raptor) platform on GCP. The multi-stage Dockerfile builds an uberjar using Leiningen and packages it into a JVM container. Deployment manifests are stored in `.meta/deployment/cloud/` and managed through the Raptor CLI. The service runs on port `5001` in all deployed environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `.ci/Dockerfile`; builder: `docker.groupondev.com/clojure:lein-2.7.1`; exposes port `5001` |
| Orchestration | Kubernetes (GCP) | Conveyor Cloud / Raptor; manifests in `.meta/deployment/cloud/components/api/` |
| Registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/finance_engineering/file_sharing_service` |
| Load balancer | Kubernetes Service (VIP) | Per-environment VIP hostnames defined in deployment YAML |
| CDN | None | No evidence of CDN in front of this service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | local | `http://localhost:5001` (or `3000` via `lein ring server`) |
| staging | Integration testing and pre-production validation | GCP `us-central1` | `http://file-sharing-service.staging.service.us-central1.gcp.groupondev.com` |
| production | Live service | GCP `us-central1` | `http://file-sharing-service.production.service.us-central1.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push / pull request

### Pipeline Stages

1. **Build**: Runs `docker-compose -f .ci/docker-compose.yml build` to produce `ci_test`, `ci_app`, and `mysql` Docker images
2. **Test**: Runs `docker-compose -f .ci/docker-compose.yml run test` — starts MySQL, waits for DB readiness, runs Leiningen tests inside the container
3. **Package**: `lein ring uberjar` produces `target/file-sharing-service*standalone.jar`
4. **Deploy**: Raptor/Conveyor Cloud deploys the container image to GCP Kubernetes using `.meta/deployment/cloud/scripts/deploy.sh`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 2 |
| Horizontal (production) | Kubernetes HPA | min: 1, max: 3; `hpaTargetUtilization: 100` (common.yml) |
| Memory (staging) | Resource limits | request: `800Mi`, limit: `4Gi` |
| Memory (production) | Resource limits | request: `2Gi`, limit: `2Gi` |
| CPU (staging) | Resource limits | request: `1000m`, limit: `4000m` |
| CPU (production) | Resource limits | request: `100m`, limit: `700m` |

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | `1000m` | `4000m` |
| Memory (main) | `800Mi` | `4Gi` |
| CPU (filebeat) | `10m` | `30m` |
| Memory (filebeat) | not set | not set |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | `100m` | `700m` |
| Memory (main) | `2Gi` | `2Gi` |
| CPU (filebeat) | `10m` | `30m` |
| Memory (filebeat) | not set | not set |

## Health Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|--------------|--------|
| Readiness | `/grpn/healthcheck` | `5001` | `20s` | `5s` |
| Liveness | `/grpn/healthcheck` | `5001` | `30s` | `15s` |

## Database Migrations

- **Tool**: Lobos (`lein-lobos` plugin)
- **Migrations file**: `src/lobos/migrations.clj`
- **Staging**: Run inside a connected pod shell via `kubectl exec`
- **Production**: Submitted as a GDS (Groupon Database Services) ticket with explicit SQL `ALTER TABLE` and `lobos_migrations` INSERT/DELETE scripts for both migrate and rollback paths
