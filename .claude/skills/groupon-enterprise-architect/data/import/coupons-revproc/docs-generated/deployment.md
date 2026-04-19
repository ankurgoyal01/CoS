---
service: "coupons-revproc"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production-us, production-eu]
---

# Deployment

## Overview

coupons-revproc is containerized (Docker) and orchestrated on Kubernetes via Groupon's Conveyor Cloud platform. The same Docker image (`docker-conveyor.groupondev.com/coupons/coupons-revproc`) is shared by the main API service and three cron job components (`coupons-feed-generator`, `redirect-sanitizer`, `redirect-cache-prefill`). Each component is deployed as a separate Kubernetes deployment or cron job object, distinguished by the `JTIER_RUN_CMD` environment variable. Deployments are managed via Deploybot (promotion from staging to production) using Capistrano-based scripts. CI builds are run by Jenkinsfile.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (root), `src/main/docker/Dockerfile`, `.ci/Dockerfile` |
| Orchestration | Kubernetes (Conveyor Cloud) | `.meta/deployment/cloud/components/*/` YAML manifests |
| Service mesh | Envoy sidecar | Injected by Conveyor Cloud; CPU: 30m req / 200m limit |
| Log shipping | Filebeat sidecar | Steno JSON logs shipped to ELK; CPU: 30m req / 200m limit |
| APM | Enabled (production) | `apm.enabled: true` in production environment YAMLs |
| Load balancer | Hybrid Boundary (Conveyor) | `hybridBoundary.isDefaultDomain: true` in common.yml; VIPs defined per region |

## Environments

| Environment | Purpose | Region | URL / VIP |
|-------------|---------|--------|-----------|
| Staging | Pre-production validation | GCP us-central1 | `coupons-revproc.us-central1.conveyor.stable.gcp.groupondev.com` |
| Production US | Serving US traffic | GCP us-central1 | `coupons-revproc.us-central1.conveyor.prod.gcp.groupondev.com` |
| Production EU (GCP) | Serving EU traffic | GCP europe-west1 | VIP configured per region |
| Production EU (AWS) | Serving EU traffic (legacy) | AWS eu-west-1 | `ccoupons-revproc.production.service.eu-west-1.aws.groupondev.com` |

Legacy on-prem VIPs (from `.service.yml`):
- Production snc1: `http://coupon-revproc-vip.snc1`
- Production sac1: `http://coupon-revproc-vip.sac1`
- Staging snc1: `http://coupon-revproc-staging-vip.snc1`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root)
- **Trigger**: Push to `main` branch; pull requests
- **Deploy tool**: Deploybot (`https://deploybot.groupondev.com/Coupons/coupons-revproc`)

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles source, runs tests, builds JAR and Docker image
2. **Test**: Maven Surefire with JaCoCo coverage; integration tests use WireMock and embedded MySQL/Redis via JTier DaaS testing
3. **Package**: Docker image tagged and pushed to `docker-conveyor.groupondev.com/coupons/coupons-revproc`
4. **Deploy to Staging**: Automatic on merge to `main`
5. **Deploy to Production**: Manual promotion via Deploybot (select staging build, authorize)
6. **Rollback**: Deploybot rollback button restores a previous build

## Scaling

### API Service (`coupons-revproc`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (VPA enabled in production) | Staging: 1–2 replicas; Prod US: 2 min/max; Prod EU: 2–15 replicas |
| CPU | Managed | Request: 25–60m; Limit: 1 |
| Memory | Managed | Request: 1 Gi; Limit: 5 Gi |

### Cron Jobs (`coupons-feed-generator`, `redirect-sanitizer`, `redirect-cache-prefill`)

| Component | Schedule | Min/Max Replicas | Memory Limit |
|-----------|----------|-----------------|--------------|
| `coupons-feed-generator` | `0 4 * * *` (04:00 UTC daily) | 1/1 | 2 Gi |
| `redirect-sanitizer` | `0 */12 * * *` (every 12 hours) | 1/1 | 2 Gi |
| `redirect-cache-prefill` | `*/15 * * * *` (every 15 minutes) | 1/1 | 2 Gi |

## Resource Requirements

### API Service

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 40–60m | 1 |
| Memory (main) | 1 Gi | 5 Gi |
| CPU (filebeat) | 30m | 200m |
| Memory (filebeat) | 80 Mi | 400 Mi |
| CPU (envoy) | 30m | 200m |

### Cron Jobs

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 60m | 1 |
| Memory (main) | 1 Gi | 2 Gi |
| CPU (filebeat) | 30m | 200m |
| Memory (filebeat) | 80 Mi | 400 Mi |

## Network Policies

The `coupons-feed-generator` cron job has an egress network policy that allows outbound TCP on port 22 to IP `178.77.214.157/32` (Dotidot SFTP server). Ingress is disabled for the cron job containers.
