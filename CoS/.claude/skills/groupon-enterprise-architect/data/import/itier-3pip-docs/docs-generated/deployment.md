---
service: "itier-3pip-docs"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-europe-west1", "staging-us-west-2", "production-us-central1", "production-eu-west-1"]
---

# Deployment

## Overview

`itier-3pip-docs` is containerized (Docker, Node.js 16.15.0 base image) and deployed to Kubernetes clusters across multiple cloud providers (GCP and AWS) using Helm via the napistrano deployment toolchain. Deployments are managed via the `deploy_bot` (`krane`-based Kubernetes deployment). Staging is deployed automatically on merge to `master`; production promotion is manual via deploy bot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — `FROM docker-conveyor.groupondev.com/conveyor/alpine-node16.15.0:2022.05.23-15.21.45-588d07d` |
| Orchestration | Kubernetes (Helm) | Helm chart `cmf-itier` v3.94.0 from Artifactory; manifests generated via `helm3 template` |
| Deployment tool | napistrano + krane | `.deploy_bot.yml`, `.deploy-configs/*.yml`; deployed via `krane deploy` |
| Image registry | docker-conveyor.groupondev.com | `docker-conveyor.groupondev.com/engage/itier-3pip-docs` |
| Hybrid Boundary | mTLS interceptor | `mtlsInterceptor: true`, `hbUpstream: true` — service is exposed via Groupon's Hybrid Boundary layer |
| Log shipping | Filebeat + Kafka | Logs written to `/var/groupon/logs/steno.log.*`; shipped via Filebeat to Kafka (`filebeatKafkaEndpoint`) |

## Environments

| Environment | Purpose | Cloud | Region | VIP / DNS |
|-------------|---------|-------|--------|-----------|
| staging-us-central1 | Pre-production (US) | GCP | us-central1 | `tpis-docs-ita.staging.stable.us-central1.gcp.groupondev.com` / `tpis-docs-ita.staging.service` |
| staging-europe-west1 | Pre-production (EMEA) | GCP | europe-west1 | `tpis-docs-ita.staging.stable.europe-west1.gcp.groupondev.com` / `tpis-docs-ita.staging.service` |
| staging-us-west-2 | Pre-production (US West) | AWS | us-west-2 | `tpis-docs-ita.staging.stable.us-west-2.aws.groupondev.com` / `tpis-docs-ita.staging.service` |
| production-us-central1 | Production (US) | GCP | us-central1 | `tpis-docs-ita.prod.us-central1.gcp.groupondev.com` / `tpis-docs-ita.production.service` |
| production-eu-west-1 | Production (EMEA) | AWS | eu-west-1 | `tpis-docs-ita.prod.eu-west-1.aws.groupondev.com` / `tpis-docs-ita.production.service` |

Public URLs:
- Production: `https://developers.groupon.com`
- Staging: `https://developers-staging.groupon.com`

## CI/CD Pipeline

- **Tool**: Jenkins (`itier-pipeline-dsl`)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to configured branches; production is promoted manually via deploy bot

### Pipeline Stages

1. **Lint**: Runs `npm run lint` (CoffeeLint, ESLint, l10nlint)
2. **Client tests**: Runs `npm run test-client` (Testem + Chrome)
3. **Server tests**: Runs `npm run test-server` (Mocha unit tests with c8 coverage)
4. **Integration tests**: Runs `npm run test-integration` (Mocha integration tests)
5. **Deploy to staging**: Auto-deploys `master` branch to `staging-europe-west1` and `staging-us-central1`
6. **Promote to production**: Manual promotion via deploy bot to `production-eu-west-1` and `production-us-central1`

Slack notifications sent to `#partner-ops-notifications`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (via napistrano) | Staging: min 1, max 10 replicas; Production: min 2, max 10 replicas |
| Canary | Harness Canary compatible | `harnessCanaryCompatible: true` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m (1 vCPU) | Not set (unbounded) |
| Memory (main) | 1536Mi | 3072Mi |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |

> Source: `.deploy-configs/staging-us-central1.yml` and `.deploy-configs/production-us-central1.yml`
