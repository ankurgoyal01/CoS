---
service: "regulatory-consent-log"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments:
  - staging-us-central1
  - staging-europe-west1
  - staging-us-west-1
  - staging-us-west-2
  - production-us-central1
  - production-europe-west1
  - production-us-west-1
  - production-eu-west-1
---

# Deployment

## Overview

The Regulatory Consent Log is deployed as two separate Kubernetes workloads (API and Utility Worker) from a single Docker image, differentiated by the `ENABLE_API` and `ENABLE_UTILITY` environment variables. Deployments are managed by the Raptor/Conveyor platform using the `.meta/deployment/cloud/` manifests and are promoted via DeployBot. The CI/CD pipeline is Jenkins, configured via `Jenkinsfile`. Production environments span two cloud regions (US and EMEA) on both AWS and GCP.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (base: `docker.groupondev.com/jtier/prod-java11-jtier:3`) |
| Image registry | Conveyor | `docker-conveyor.groupondev.com/groupon-api/regulatory-consent-log` |
| Orchestration | Kubernetes (GCP and AWS) | Manifests at `.meta/deployment/cloud/` |
| Deployment system | Raptor / Conveyor | `.meta/.raptor.yml` defines `app` (api) and `util` (worker) components |
| CI/CD | Jenkins | `Jenkinsfile` (uses `java-pipeline-dsl@latest-2`) |
| Load balancer | Hybrid Boundary (HB) / Kubernetes Ingress | `httpsIngress.enabled: true`; `hybridBoundary.useExternalHTTP2: true` |
| Log shipping | Filebeat | Sidecar with `medium` volume; ships to Kafka logging endpoint in staging/production |
| APM | Enabled | `apm.enabled: true` (app component) |
| VPA | Enabled | `enableVPA: true` (app component) |

## Environments

| Environment | Purpose | Region | VIP / URL |
|-------------|---------|--------|-----------|
| `staging-us-central1` | Staging (GCP US) | us-central1 | `regulatory-consent-log.us-central1.conveyor.stable.gcp.groupondev.com` |
| `staging-europe-west1` | Staging (GCP EMEA) | europe-west1 | > No evidence found |
| `staging-us-west-1` | Staging (AWS US) | us-west-1 | > No evidence found |
| `staging-us-west-2` | Staging (AWS EMEA) | us-west-2 | > No evidence found |
| `production-us-central1` | Production (GCP US) | us-central1 | `regulatory-consent-log.us-central1.conveyor.prod.gcp.groupondev.com` |
| `production-europe-west1` | Production (GCP EMEA) | europe-west1 | > No evidence found |
| `production-us-west-1` | Production (AWS US/CA) | us-west-1 | > No evidence found |
| `production-eu-west-1` | Production (AWS EMEA) | eu-west-1 | > No evidence found |

Legacy on-premise datacenter environments (SNC1, SAC1, DUB1) were also supported via Capistrano; these are now superseded by Kubernetes deployments.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Library**: `java-pipeline-dsl@latest-2`
- **Trigger**: On push to `master`, patch branches (`(.*)--patch(.*)`), and `gcp-migration-emea-prod`; pull request builds on any branch.
- **Notifications**: Slack channel `#regulatory-consent` on any fail, any start, releasable branch fail, releasable branch start.

### Pipeline Stages

1. **Build**: `mvn clean compile` — compiles Java source.
2. **Test**: Unit and integration tests (Testcontainers for Postgres and Redis, WireMock for HTTP dependencies).
3. **Package**: `mvn clean package` — produces the fat JAR.
4. **Docker Build**: Builds the Docker image from `src/main/docker/Dockerfile`.
5. **Docker Push**: Pushes image to `docker-conveyor.groupondev.com/groupon-api/regulatory-consent-log`.
6. **Deploy to Staging**: Auto-deploys to `staging-us-central1` and `staging-europe-west1` on releasable branches.
7. **Promote to Production**: Manual approval via DeployBot; `staging-us-central1` promotes to `production-us-central1`; `staging-europe-west1` promotes to `production-eu-west-1`.

## Scaling

### API Component (`app`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes) | Staging: min 1, max 2; Production: min 5, max 30 |
| Memory | VPA + fixed limits | Staging: 1000Mi req/limit; Production: 3Gi req, 5Gi limit |
| CPU | HPA target + fixed limits | Production: 300m request, 700m limit |

### Worker Component (`util`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed | 3 replicas (min 3, max 3); HPA target utilization 50% |
| Memory | Fixed | 500Mi request, 500Mi limit |
| CPU | Fixed | 300m request |
| Rolling deploy | `maxSurge: 25%`, `maxUnavailable: 0` | Zero-downtime rolling update |

## Resource Requirements

### API Component (Production)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | 700m |
| Memory | 3Gi | 5Gi |
| JVM Heap | 2048m | 2048m |

### Worker Component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | (not set) |
| Memory | 500Mi | 500Mi |
