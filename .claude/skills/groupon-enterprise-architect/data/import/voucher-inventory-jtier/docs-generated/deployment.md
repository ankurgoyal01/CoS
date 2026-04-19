---
service: "voucher-inventory-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Voucher Inventory JTier is deployed as Docker containers orchestrated by Kubernetes (Conveyor Cloud) across multiple AWS and GCP clusters in US and EU regions. The service runs three distinct Kubernetes components per cluster: `app` (API), `worker` (MessageBus consumer), and `telegraf` (metrics sidecar). An additional `ouroboros-jtier` component handles the replenishment job in select clusters. Deployments are managed by Deploybot, which triggers Helm-based Krane deployments using the `cmf-jtier-api` and `cmf-jtier-worker` Helm charts. The service operates in a SOX-compliant namespace (`voucher-inventory-production-sox` / `voucher-inventory-staging-sox`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` (base: `docker.groupondev.com/jtier/dev-java11-maven:2023-02-27-aaff088`); image: `docker-conveyor.groupondev.com/sox-inscope/voucher-inventory-jtier` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm charts `cmf-jtier-api` v3.9.1, `cmf-jtier-worker` v3.9.1, `cmf-generic-telegraf` v3.9.1 |
| Deployment tool | Krane + Helm 3 | `.meta/deployment/cloud/scripts/deploy.sh`, `deploy_emea.sh`, `deploy_ouroboros.sh` |
| Config management | Kustomize + Helm | `.meta/kustomize/` for worker; `.meta/deployment/cloud/components/` for Helm values |
| Load balancer | Hybrid Boundary | Upstream domain: `voucher-inventory--app`; VIP: `voucher-inventory.prod.{region}.aws.groupondev.com` |
| Metrics | Telegraf sidecar | StatsD/UDP from app; forwarded to Wavefront |
| Logging | Filebeat sidecar | Steno structured logs; shipped to Elasticsearch (Kibana) via Kafka |
| APM | Enabled | `apm.enabled: true` in all production components |

## Environments

| Environment | Purpose | Region | Cluster / Namespace |
|-------------|---------|--------|---------------------|
| dev-us-west-1 | Developer testing | AWS us-west-1 | `stable-us-west-1` |
| staging-us-west-2 | Staging (EMEA path) | AWS us-west-2 | `stable-us-west-2` / `voucher-inventory-staging-sox-us-west-2` |
| staging-us-central1 | Staging (NA, promotes to production-us-central1) | GCP us-central1 | `gcp-stable-us-central1` / `voucher-inventory-gcp-staging-sox-us-central1` |
| staging-europe-west1 | Staging (EU, promotes to production-eu-west-1) | GCP europe-west1 | `gcp-stable-europe-west1` / `voucher-inventory-gcp-staging-sox-europe-west1` |
| production-us-west-1 | Production (NA, on-prem) | AWS us-west-1 | `voucher-inventory-production-sox` |
| production-us-central1 | Production (NA, GCP) | GCP us-central1 | `gcp-production-us-central1` / `voucher-inventory-gcp-production-sox-us-central1` |
| production-eu-west-1 | Production (EMEA, AWS) | AWS eu-west-1 | `production-eu-west-1` / `voucher-inventory-production-sox-eu-west-1` |
| production-europe-west1 | Production (EMEA, GCP) | GCP europe-west1 | `gcp-production-europe-west1` / `voucher-inventory-gcp-production-sox-europe-west1` |

**On-premises VIPs (non-cloud):**

| Colo | Environment | Internal VIP |
|------|-------------|-------------|
| SNC1 | production | `http://voucher-inventory-japp-read-vip.snc1` |
| SAC1 | production | `http://voucher-inventory-japp-read-vip.sac1` |
| DUB1 | production | `http://voucher-inventory-japp-read-vip.dub1` |
| SNC1 | staging | `http://voucher-inventory-jorigin-staging-vip.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (CCI / Deploybot)
- **Config**: `Jenkinsfile`, `.deploy_bot.yml`
- **CI image**: `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`
- **Trigger**: PR merge to master triggers staging deployment via Deploybot (manual authorization required); production deployment via "Promote" in Deploybot UI

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles Java, runs tests, packages `.tar.gz` and Docker image
2. **Push**: Docker image pushed to `docker-conveyor.groupondev.com/sox-inscope/voucher-inventory-jtier`
3. **Deploy to Staging**: Deploybot automatically deploys to configured staging clusters on merge to master (manual authorization)
4. **Validate Staging**: Engineer verifies staging via status endpoint (`/grpn/status`) and Kibana/Wavefront dashboards
5. **Promote to Production**: Engineer clicks "Promote" in Deploybot UI, provides GPROD Logbook ticket
6. **Deploy to Production**: Krane deploys via `deploy.sh` / `deploy_emea.sh` to production clusters
7. **Post-deploy Monitoring**: Engineer monitors Wavefront dashboards and Kibana for errors; checks `/grpn/status` for deployed SHA

## Scaling

### App Component (API)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min: 3 (staging), 5 (production us-west-1); max: 30 (common), 60 (production us-west-1) |
| HPA target | CPU utilization | 100% (`hpaTargetUtilization: 100`) |
| Vertical | VPA enabled | `enableVPA: true` |

### Worker Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (no HPA) | min: 3, max: 3 |
| Vertical | VPA enabled | `enableVPA: true` |

## Resource Requirements

### App Component (production us-west-1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 4 cores | 6 cores |
| CPU (envoy) | 350m | N/A |
| CPU (filebeat) | 350m | 750m |
| Memory (main) | 6,000 Mi | 6,000 Mi |
| Memory (telegraf) | 6 Gi | 7 Gi |
| Memory (filebeat) | 400 Mi | 700 Mi |
| Memory (envoy) | 500 Mi | N/A |

### Worker Component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 2 cores | N/A |
| Memory (main) | 6,000 Mi | 7,000 Mi |

### JVM Heap

JVM heap is configured as a percentage of available container memory via `MIN_RAM_PERCENTAGE` and `MAX_RAM_PERCENTAGE` (default 67% for both).
