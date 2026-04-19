---
service: "my_appointments_client"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

My Appointments Client is containerized (Docker) and deployed to Kubernetes clusters via Conveyor Cloud, using Napistrano as the deploy orchestration tool and Deploybot as the authorization and execution layer. The service is deployed across three production regions (AWS eu-west-1, GCP us-central1, GCP europe-west1) and three staging regions, all fronted by the Hybrid Boundary ingress layer. Deployments follow a staging-gate model where an artifact must pass staging before being promoted to production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker-conveyor.groupondev.com/conveyor/alpine-node16.15.0:2022.05.23-15.21.45-588d07d` |
| Container registry | Conveyor Docker registry | `docker-conveyor.groupondev.com/bookingengine/my-appointments-client` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm + krane templating via Deploybot |
| Load balancer | Hybrid Boundary (HB) | Ingress enabled on all regions; DNS names registered per region |
| Log shipping | Filebeat + Kafka | Logs shipped to ELK via Kafka; Kafka endpoint varies by region and environment |
| CDN | Groupon CDN | Static assets served from `www<1,2>.grouponcdn.com` (production) / `staging<1,2>.grouponcdn.com` (staging) |

## Environments

| Environment | Purpose | Region / Cloud | VIP / URL |
|-------------|---------|----------------|-----------|
| staging | Pre-production integration testing | us-central1 (GCP) | `my-reservations.staging.stable.us-central1.gcp.groupondev.com` / `my-reservations.staging.service` |
| staging | Pre-production integration testing | us-west-2 (AWS) | `my-reservations.staging.service` |
| staging | Pre-production integration testing | europe-west1 (GCP) | `my-reservations.staging.service` |
| production | Live customer traffic | us-central1 (GCP) | `my-reservations.prod.us-central1.gcp.groupondev.com` / `my-reservations.production.service` |
| production | Live customer traffic | eu-west-1 (AWS) | `my-reservations.prod.eu-west-1.aws.groupondev.com` / `my-reservations.production.service` |
| production | Live customer traffic | europe-west1 (GCP) | `my-reservations.prod.europe-west1.gcp.groupondev.com` / `my-reservations.production.service` |

Legacy CoLo VIPs (snc1, sac1, dub1) are defined in `.service.yml` for backward compatibility.

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI / cloud-jenkins)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push to `main` branch; manual deploy via Napistrano / Deploybot

### Pipeline Stages

1. **Install**: Run `npm install` using the pinned Node.js 16 environment
2. **Lint**: Run `npm-run-all lint:*` (ESLint for JS, l10nlint for localization strings)
3. **Unit tests**: Run `c8 mocha test/server` and Jest for client tests
4. **Integration tests**: Run `mocha test/integration` with staging endpoints
5. **Build assets**: Run `webpack -p` to produce fingerprinted JS/CSS bundles
6. **Docker build**: Build and push image to `docker-conveyor.groupondev.com/bookingengine/my-appointments-client`
7. **Stage deploy**: `npx nap --cloud deploy staging <region>` via Napistrano / Deploybot (requires Okta authorization)
8. **QA check**: Auto-check script `./scripts/qa_ci_runner.sh` runs after staging deploy
9. **Production promote**: Only artifacts verified through staging are eligible; `npx nap --cloud deploy production <region>`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 3 replicas per region |
| Horizontal (production) | Kubernetes HPA | min: 2, max: 10 replicas per region |
| Memory | Resource limits | request: 1536Mi, limit: 3072Mi (main container) |
| CPU | Resource limits | request: 1000m (main); request: 400m, limit: 750m (logstash/filebeat) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set |
| Memory (main) | 1536Mi | 3072Mi |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |
| Disk | Not specified | Not specified |

## Deployment Tooling

- **Napistrano** (`^2.180.17`): Generates deploy config files, coordinates artifact promotion, triggers Deploybot jobs
- **Deploybot**: Okta-gated deploy authorization; runs `helm` + `krane` against the target Kubernetes cluster
- **Slack notifications**: Deploy events broadcast to `#bookingnotifications`
- **Logbook**: Changelog-based deploy record emailed to `onlinebooking-devteam@groupon.com`

## Rollback

To roll back to the previous successfully deployed artifact:

```
npx nap --cloud rollback <env> <region>
```

Or via the Deploybot UI: navigate to the deployment version and click "ROLLBACK".
