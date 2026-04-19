---
service: "itier-merchant-inbound-acquisition"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, uat, production]
---

# Deployment

## Overview

The service is containerized (Docker) and deployed to Kubernetes clusters managed by Groupon's Conveyor Cloud platform. It runs on Google Cloud Platform (GCP) as the primary provider and historically also on AWS (eu-west-1). Deployments are managed via the `napistrano` (`npx nap`) toolchain, which orchestrates artifact creation, logbook ticketing, and Kubernetes rollout approval. The service follows a promotion model: staging must be healthy before production is unlocked.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `alpine-node16.15.0:2022.05.23` |
| Registry | docker-conveyor.groupondev.com | Image: `merchant-experience/itier-merchant-inbound-acquisition` |
| Orchestration | Kubernetes (Conveyor Cloud) | Namespaces: `merchant-inbound-acquisition-staging`, `merchant-inbound-acquisition-production` |
| Log shipping | Filebeat → Kafka | Kafka endpoint configured per cluster (`filebeatKafkaEndpoint`); sourcetype `merchant-inbound-acquisition_itier` → Splunk index `steno` |
| Service mesh | mTLS interceptor | `mtlsInterceptor: true` in deploy configs |
| Ingress | Hybrid Boundary | `hbUpstream: true`; ingress and egress enabled in all active clusters |
| CI/CD | Conveyor CI (CCI) + Napistrano | Jenkins-based (`Jenkinsfile`) |
| Monitoring | Wavefront + Pingdom | Dashboards: Wavefront container and application dashboards |

## Environments

| Environment | Purpose | Cloud / Region | Internal VIP | External URL |
|-------------|---------|---------------|-------------|-------------|
| Development | Local development | Local (`yarn start-dev`) | — | — |
| Staging (us-central1) | Pre-production testing | GCP us-central1 | `merchant-inbound-acquisition.staging.stable.us-central1.gcp.groupondev.com` | `https://staging.groupon.com/merchant/signup` |
| Staging (europe-west1) | Pre-production testing | GCP europe-west1 | — | `https://staging.groupon.co.uk/merchant/signup` |
| UAT (snc1) | User acceptance testing | On-premise snc1 | `conveyor-itier-merchant-inbound-acquisition-uat-vip.snc1` | `https://uat.groupon.com/merchant/signup` |
| Production (us-central1) | US production | GCP us-central1 | `merchant-inbound-acquisition.prod.us-central1.gcp.groupondev.com` | `https://www.groupon.com/merchant/signup` |
| Production (eu-west-1) | INTL production | AWS eu-west-1 | `conveyor-itier-merchant-inbound-acquisition-vip.dub1` | `https://www.groupon.co.uk/merchant/signup` |
| Production (sac1 / snc1) | US on-premise production | On-premise | `conveyor-itier-merchant-inbound-acquisition-vip.sac1` / `vip.snc1` | `https://www.groupon.com/merchant/signup` |

## CI/CD Pipeline

- **Tool**: Conveyor CI (Jenkins) + Napistrano
- **Config**: `Jenkinsfile` (repo root), `.deploy_bot.yml`, `.deploy-configs/*.yml`
- **Trigger**: Git tag push (version tag `v<X.Y.Z>`) triggers CI artifact build

### Pipeline Stages

1. **Build**: `npm install` + `webpack` bundling + `tsc` compilation triggered by CI on tag push
2. **Test**: `npm test` (mocha unit tests + linting) — must pass before artifact is promoted
3. **Artifact creation**: CCI builds Docker image; tagged as `<date>-<time>-<sha>`
4. **Staging deploy**: `npx nap --cloud deploy <artifact> staging` — deploys to staging clusters; gated on artifact availability
5. **Production logbook**: `npx nap --cloud logbook --deploy <version> production <datacenter>` — creates GPROD ticket for approval
6. **Production deploy**: SOC approval required; `npx nap --cloud deploy -j <GPROD> -a <artifact> production <datacenter>`
7. **Verification**: QA executes manual smoke tests against `/merchant/signup`

## Scaling

| Dimension | Strategy | Staging Config | Production Config |
|-----------|----------|---------------|-------------------|
| Horizontal | Manual / Napistrano-controlled replicas | 1–3 replicas (GCP) | 3 replicas (GCP us-central1); 3 replicas (AWS eu-west-1) |
| Canary | Harness canary-compatible | `harnessCanaryCompatible: true` | `harnessCanaryCompatible: true` |

## Resource Requirements

| Resource | Staging Request | Staging Limit | Production Request | Production Limit |
|----------|----------------|---------------|-------------------|-----------------|
| Memory (main) | 1536Mi | 3072Mi | 2048Mi | 4096Mi |
| CPU (main) | 1000m | — | 1000m | — |
| CPU (logstash) | 400m | 750m | 400m | 750m |
| CPU (filebeat) | 400m | 750m | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi | 100Mi | 200Mi |

Rollback is performed via `npx nap --cloud rollback <env> <datacenter>`, which redeploys the most recently successful artifact.
