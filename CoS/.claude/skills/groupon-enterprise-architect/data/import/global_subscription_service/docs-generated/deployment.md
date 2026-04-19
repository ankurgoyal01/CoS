---
service: "global_subscription_service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The Global Subscription Service runs as a containerized JVM application on GCP-hosted Kubernetes clusters managed by Groupon's internal cloud platform (Conveyor). It is deployed as two separate Kubernetes components: `gss` (the main REST API service) and `batch` (email subscription calculation worker). Both share the same Docker image (`docker-conveyor.groupondev.com/subscription/global-subscription-service`) but start with different modes via the `BATCH` environment variable. The service is SOX in-scope; production code deployments require RE (Release Engineering) coordination and DBA involvement for schema changes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; production image at `src/main/docker/Dockerfile`; Java 8 base (legacy), JTier runtime at `/var/groupon/jtier` |
| Orchestration | Kubernetes (GCP) | Manifests in `.meta/deployment/cloud/components/gss/` and `.meta/deployment/cloud/components/batch/` |
| Load balancer | Kubernetes Service + Hybrid Boundary (Envoy sidecar) | `hybridBoundary.isDefaultDomain: true` for gss; `false` for batch |
| CDN | Not applicable | Internal service only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live traffic | GCP us-central1 | `http://subscription-service-app-vip.snc1` (legacy), GCP internal |
| Production | Live traffic (EMEA) | GCP europe-west1 | `http://subscription-service-app-vip.dub1` (legacy), GCP internal |
| Production | Live traffic | GCP us-west-1 | `http://subscription-service-app-vip.sac1` (legacy), GCP internal |
| Staging | Pre-production validation | GCP us-central1 | `http://subscription-service-app-staging-vip.snc1` (legacy) |
| Staging | EMEA pre-production | GCP europe-west1 | Internal |
| UAT | User acceptance testing | snc1 | `http://subscription-service-app-uat-vip.snc1` |

## CI/CD Pipeline

- **Tool**: DotCi (legacy Jenkins-based CI) + `deploy_bot` + Capistrano (legacy); Kubernetes manifests via Conveyor
- **Config**: `.ci.yml` (DotCi build config)
- **Trigger**: On push, on release tag (`release.*`), on snapshot tag (`snapshot.*`), on deploy request branch (`deploy_request.*`)

### Pipeline Stages

1. **Build**: Executes `mvn package` (migrated from `activator dist` / sbt); produces JAR/tar.gz artifact
2. **Publish artifact**: Deploys to Nexus (`http://nexus-dev`) as snapshot or release depending on git tag
3. **Deploy request**: On `deploy_request.*` tag, creates an RE ticket for SOX-compliant production deploy
4. **Kubernetes deploy**: Conveyor pulls image and applies `.meta/deployment/cloud/` manifests per environment/region

## Scaling

### GSS Component (REST API)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production us-central1) | HPA | min=10, max=90, targetUtilization=15% |
| Horizontal (production europe-west1) | HPA | min=4, max=64 |
| Horizontal (staging) | HPA + VPA | min=1, max=2, VPA enabled |
| Horizontal (common baseline) | HPA | min=3, max=15, targetUtilization=50% |

### Batch Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min=3, max=15, targetUtilization=50% (common baseline) |

## Resource Requirements

### GSS Component — Common Baseline

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 1500m |
| Memory | 1200Mi | 6000Mi |

### GSS Component — Production US Central 1 Override

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1200m | 10000m |
| CPU (envoy) | 50m | 500m |
| CPU (filebeat) | 50m | 500m |
| Memory (main) | 4Gi | 10Gi |
| Memory (envoy) | 100Mi | 1000Mi |
| Memory (filebeat) | 200Mi | 1500Mi |

### GSS Component — Production Europe West 1 Override

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 2000m | — (inherits common) |
| Memory (main) | 4Gi | 10Gi |

## Notes

- Kafka TLS is initialized at container start by running `kafka-tls-v2.sh` before invoking the JTier service runner (`/var/groupon/jtier/service/run`).
- Logs are written in JSON format to `/var/groupon/jtier/logs/steno.log` with source type `subscription_service_general_v2`, shipped via Filebeat sidecar.
- The `client-certs` volume (mounted at `/var/groupon/certs`) provides Kafka and mTLS certificates injected by the Kubernetes secrets layer.
- SOX compliance requires: schema changes executed by DBA only; production code deploys by RE only; deploy tickets created via `deploy_request.*` git tag pattern.
