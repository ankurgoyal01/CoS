---
service: "itier-tpp"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-us-west-2, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

I-Tier TPP is containerized using Docker and deployed to Groupon's Conveyor Cloud platform, which runs on Kubernetes (GCP and AWS). Deployments are orchestrated by Napistrano via the Deploybot CI/CD system. Docker images are built by Conveyor CI and stored in `docker-conveyor.groupondev.com/engage/itier-tpp`. The service runs behind the Hybrid Boundary service mesh and is accessible externally via `tpp.groupondev.com` (production) and `tpp-staging.groupondev.com` (staging).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `FROM docker-conveyor.groupondev.com/conveyor/alpine-node16.15.0`; `Dockerfile` in repo root |
| Orchestration | Kubernetes (GCP / AWS) | Helm chart `cmf-itier v3.94.0` deployed via Deploybot + krane |
| Service mesh | Hybrid Boundary (mTLS) | `mtlsInterceptor: true`; `hbUpstream: true` in all environments |
| Log shipping | Filebeat + Kafka | Logs streamed to Kafka; source type `itier-tpp_itier`; index `steno` |
| Tracing | Logstash | `tracky=tracky.log.*` sidecar label |
| DNS | GCP / AWS Kubernetes ingress | Per-environment `dnsNames` in `.deploy-configs/*.yml` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Primary staging environment | GCP us-central1 | `https://tpp-staging.groupondev.com` |
| staging-us-west-2 | Secondary staging environment | AWS us-west-2 | `https://tpp-staging.groupondev.com` |
| production-us-central1 | Primary production | GCP us-central1 | `https://tpp.groupondev.com` |
| production-eu-west-1 | EMEA production | AWS eu-west-1 | `https://tpp.groupondev.com` |

Internal Hybrid Boundary endpoints:
- Production: `https://itier-tpp.production.service`
- Staging: `https://itier-tpp.staging.service`

## CI/CD Pipeline

- **Tool**: Conveyor CI (Jenkins-based) + Napistrano + Deploybot
- **Config**: `.deploy_bot.yml`, `.deploy-configs/*.yml`
- **Trigger**: Merging to `master` automatically deploys to cloud staging (`staging-us-central1`) with manual approval; production deploys require explicit `nap --cloud deploy` invocation

### Pipeline Stages

1. **Build**: Conveyor CI builds Docker image from `Dockerfile`; image tagged with commit SHA
2. **Lint + Test**: `npm run lint` and `npm run test` (unit, integration, client tests)
3. **Stage Deploy**: `nap --cloud deploy <artifact> staging us-central1` triggers Deploybot to apply Helm chart to `itier-tpp-staging` namespace
4. **Manual QA**: Verification against `tpp-staging.groupondev.com`
5. **Promote to Production**: `nap --cloud deploy <artifact> production us-central1` (promotes the staging artifact); requires logbook JIRA ticket
6. **Production Verify**: Manual verification at `https://tpp.groupondev.com`; monitor Splunk and Wavefront graphs
7. **Rollback (if needed)**: `nap --cloud rollback production us-central1` deploys the previously successful artifact

Branching strategy:
- `master` — main integration branch; no direct commits
- `staging` — cut from master before staging deploy
- `release` — cut from staging before production deploy

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Fixed replicas | 3 replicas (min: 3, max: 3) across `us-central1` and `eu-west-1` |
| Horizontal (staging) | Auto-scaling | min: 1, max: 3 replicas |
| Memory | Fixed limits | Request: 400 Mi, Limit: 4096 Mi (main container) |
| CPU | Request only | Production: 500 m request; Staging: 400 m request; no CPU limit set |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 400 m (staging) / 500 m (production) | Not set |
| Memory (main) | 400 Mi | 4096 Mi |
| CPU (filebeat sidecar) | 50 m | 750 m |
| Memory (filebeat sidecar) | 100 Mi | 200 Mi |
