---
service: "marketing-and-editorial-content-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-europe-west1, staging-us-central1, production-eu-west-1, production-europe-west1, production-us-central1]
---

# Deployment

## Overview

MECS runs as a containerized Java service on Kubernetes (GCP GKE clusters and one AWS EKS cluster). Deployments are managed by Groupon's internal Deploy Bot using Helm chart `cmf-jtier-api` version `3.88.1` via `krane`. The Docker image is built from `docker.groupondev.com/jtier/dev-java17-maven` and published to `docker-conveyor.groupondev.com/mars/marketing-and-editorial-content-service`. There are two staging and three production deployment targets across EMEA and US/Canada regions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — based on `docker.groupondev.com/jtier/dev-java17-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes (GKE + EKS) | Helm chart `cmf-jtier-api` v3.88.1 deployed via `krane` |
| Load balancer | Kubernetes Service + Conveyor VIP | VIP: `marketing-and-editorial-content-service.us-central1.conveyor.prod.gcp.groupondev.com` (production US) |
| CDN | Not applicable | No CDN for this service; image CDN is handled by GIMS |
| APM | Elastic APM | Enabled in production; endpoint at `elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |
| Log shipping | Filebeat | `volumeType: medium` (staging), `high` (production) |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster |
|-------------|---------|--------|-------------------|
| `staging-europe-west1` | Staging EMEA | europe-west1 (GCP) | `gcp-stable-europe-west1` |
| `staging-us-central1` | Staging US/Canada | us-central1 (GCP) | `gcp-stable-us-central1` |
| `production-eu-west-1` | Production EMEA (AWS) | eu-west-1 (AWS) | `production-eu-west-1` |
| `production-europe-west1` | Production EMEA (GCP) | europe-west1 (GCP) | `gcp-production-europe-west1` |
| `production-us-central1` | Production US/Canada | us-central1 (GCP) | `gcp-production-us-central1` |

**Promotion chain:**
- `staging-europe-west1` promotes to `production-eu-west-1`
- `staging-us-central1` promotes to `production-us-central1`
- `production-eu-west-1` promotes to `production-europe-west1`

## CI/CD Pipeline

- **Tool**: Groupon Deploy Bot (internal)
- **Config**: `.deploy_bot.yml`
- **Deploy script**: `.meta/deployment/cloud/scripts/deploy.sh`
- **Trigger**: Manual dispatch via Deploy Bot; promotion is triggered after staging validation

### Pipeline Stages

1. **Build**: Maven builds the fat JAR using `jtier-service-pom` build toolchain; Docker image is created from `.ci/Dockerfile`
2. **Test**: Integration tests run inside Docker Compose (`.ci/docker-compose.yml`) with host network and Docker socket access
3. **Publish**: Docker image tagged with version and pushed to `docker-conveyor.groupondev.com/mars/marketing-and-editorial-content-service`
4. **Deploy Staging**: Deploy Bot renders Helm chart with environment-specific secrets and deploys to staging Kubernetes cluster via `krane`
5. **Deploy Production**: After staging promotion, Deploy Bot deploys to production clusters using the same Helm chart with production-specific overrides

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Fixed | `minReplicas: 3`, `maxReplicas: 3` (no autoscaling in staging) |
| Horizontal (production) | HPA | `minReplicas: 1`, `maxReplicas: 6`, VPA enabled (`enableVPA: true`) |
| HPA target utilization | CPU | `hpaTargetUtilization: 100` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main container) | 60m | not set (VPA manages in production) |
| CPU (Envoy sidecar) | 100m | not set |
| Memory (main container) | 1.6Gi | 4Gi |
| Memory (Envoy sidecar) | 100Mi | not set |

## Port Configuration

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (exposed as port 80 on Kubernetes Service) |
| 8081 | Dropwizard admin port (exposed as `admin-port`) |

## Health Probes

| Probe | Initial Delay | Notes |
|-------|--------------|-------|
| Readiness | 90 seconds | Allows JVM and connection pool warm-up before traffic |
| Liveness | 100 seconds | Additional buffer beyond readiness to prevent premature restarts |
