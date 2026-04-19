---
service: "merchant-page"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production, catfood]
---

# Deployment

## Overview

The merchant-page service is containerised using Docker (Alpine Node 16) and deployed to Kubernetes via the Conveyor Cloud platform. Deployments are managed by Napistrano and triggered through Deploybot. The service runs in two production regions (GCP `us-central1` for North America; AWS `eu-west-1` for EMEA) and two staging regions (GCP `us-central1`; AWS `us-west-2`). All Kubernetes manifests are generated via Helm using the `cmf-itier` chart. The Hybrid Boundary handles inbound TLS termination and mTLS for service-to-service traffic.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — base image: `docker-conveyor.groupondev.com/conveyor/alpine-node16.16.0:2022.07.22-17.49.19-36872e1` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm chart `cmf-itier` version `3.94.0`; manifests in `.deploy-configs/` |
| Load balancer / Ingress | Hybrid Boundary | mTLS interceptor enabled; ingress and egress enabled per region |
| CDN | Groupon CDN | `www<1,2>.grouponcdn.com` (production), `staging<1,2>.grouponcdn.com` (staging) — for static assets |
| Service mesh / mTLS | Conveyor mTLS (`useCommonMTLS: true`) | All service-to-service traffic uses mutual TLS |
| Log shipping | Filebeat → Kafka → ELK | Kafka endpoint: `kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local` (production) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `staging-us-central1` | Staging (North America) | GCP us-central1 | `https://merchant-page.staging.service.us-central1.gcp.groupondev.com` |
| `staging-us-west-2` | Staging (EMEA gateway) | AWS us-west-2 | `https://merchant-page.staging.service.us-west-2.aws.groupondev.com` |
| `production-us-central1` | Production (North America) | GCP us-central1 | `https://merchant-page.production.service` / `https://merchant-page.prod.us-central1.gcp.groupondev.com` |
| `production-eu-west-1` | Production (EMEA) | AWS eu-west-1 | `https://merchant-page.production.service` / `https://merchant-page.prod.eu-west-1.aws.groupondev.com` |
| `production-europe-west1` | Production (EMEA GCP — promoted from eu-west-1) | GCP europe-west1 | Internal GCP endpoint |
| `catfood-eu-west-1` | Canary / pre-production testing (EU) | AWS eu-west-1 | Same cluster as production eu-west-1 with feature flag overrides |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI — `cloud-jenkins.groupondev.com`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch (CI build); push to `release` branch or Deploybot action (deployment)

### Pipeline Stages

1. **Build**: Install dependencies (`npm ci`), lint (`eslint`, `l10nlint`), unit test (`c8 mocha`), coverage check
2. **Asset build**: Webpack production bundle (`npm run dist-assets`)
3. **Docker image**: Build and push to `docker-conveyor.groupondev.com/seo/merchant-page`
4. **Integration test**: Run `mocha test/integration` against the built artifact
5. **Staging deploy**: Deploybot triggers Napistrano → Helm render → `krane deploy` to staging Kubernetes namespace
6. **Production promote**: Manual promotion via Deploybot from staging artifact to production; requires PagerDuty / Logbook JIRA ticket

### Deployment Commands

```bash
# List available artifacts
npx nap --cloud artifacts -a staging

# Deploy to staging
npx nap --cloud deploy -a <ARTIFACT> staging us-central1

# Deploy to production
npx nap --cloud deploy -j <PROD_JIRA> -a <artifact_build> production us-central1

# Rollback
npx nap --cloud rollback staging us-central1
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (US prod) | Kubernetes HPA-compatible (Harness canary) | min: 2 / max: 3 replicas |
| Horizontal (EU prod) | Kubernetes HPA-compatible (Harness canary) | min: 2 / max: 6 replicas |
| Horizontal (staging) | Manual | min: 1 / max: 3 replicas |
| CPU (EU/US prod main, EU config) | Request-based | request: 1500m (EU) / 1000m (US) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main container) | 1000m (US prod) / 1500m (EU prod) | Not set (soft limit) |
| Memory (main container) | 1536 Mi | 3072 Mi |
| CPU (Filebeat sidecar) | 400m | 750m |
| Memory (Filebeat sidecar) | 100 Mi | 200 Mi |
| CPU (Logstash sidecar) | 400m | 750m |
| Node.js heap | (via `NODE_OPTIONS`) | `--max-old-space-size=1024` (1 GB) |
