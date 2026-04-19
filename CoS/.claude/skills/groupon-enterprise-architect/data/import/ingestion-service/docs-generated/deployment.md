---
service: "ingestion-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The ingestion-service is containerized (Docker) and deployed on Groupon's **Conveyor Cloud** Kubernetes platform. It runs in multiple regions across both GCP and AWS to support US and EMEA (EU) traffic. Deployments are managed through **Deploybot V2** with Jenkins CI. The service auto-scales horizontally using Kubernetes HPA (Horizontal Pod Autoscaler).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| CI Docker image | Docker | `.ci/Dockerfile` with `.ci/docker-compose.yml` for CI build environment |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests generated from `.meta/deployment/cloud/components/app/*.yml` via raptor-cli |
| Load balancer | Conveyor / Hybrid Boundary | HB domains: `ingestion-service` (default) and `ingestion-service--public` (public subdomain) |
| CDN | None documented | N/A |
| Image registry | `docker-conveyor.groupondev.com/gso/ingestion-service` | Defined in `common.yml` `appImage` field |
| APM | Conveyor APM | Enabled in `common.yml` (`apm.enabled: true`) |

## Environments

| Environment | Purpose | Region | URL / VIP |
|-------------|---------|--------|-----------|
| Staging (GCP us-central1) | Integration testing / QA | GCP us-central1 | `ingestion-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| Staging (GCP europe-west1) | Integration testing / QA | GCP europe-west1 | `ingestion-service-staging-europe-west1` namespace |
| Staging (AWS us-west-2) | Integration testing / QA | AWS us-west-2 | `ingestion-service-staging-us-west-2` namespace |
| Production (GCP us-central1) | Primary US production | GCP us-central1 | `ingestion-service.us-central1.conveyor.prod.gcp.groupondev.com` |
| Production (GCP europe-west1) | EU production (GCP) | GCP europe-west1 | `ingestion-service-production-europe-west1` namespace |
| Production (AWS eu-west-1) | EU production (AWS) | AWS eu-west-1 | `http://gso-app-ingestionservice-vip.dub1/` (legacy) |
| Production (AWS us-west-1) | US production (legacy) | AWS us-west-1 | `http://gso-app-ticketingestionservice-vip.snc1/` (legacy) |
| Development (local) | Local development | Local | `http://localhost:8080` via `mvn clean compile exec:java` |

## CI/CD Pipeline

- **Tool**: Jenkins (via `java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Merge to `main` or `release.*` branches; releasable branches are `main` and `release.*`

### Pipeline Stages

1. **Build**: Compiles Java source with Maven, runs unit tests, builds Docker image
2. **Docker**: Builds and pushes Docker image to `docker-conveyor.groupondev.com/gso/ingestion-service`
3. **Auto-deploy to Staging**: Every merge to `main` automatically deploys to staging environments: `staging-us-west-2`, `staging-us-central1`, `staging-europe-west1` via Deploybot V2 (`https://deploybot.groupondev.com/CustomerSupport/ingestion-service`)
4. **QA Gate**: QA team validates the staging build
5. **Promote to Production**: Developer clicks **PROMOTE** in Deploybot UI — deploys the same SHA to production us-west-1 / eu-west-1
6. **Staged Regional Rollout**: EU and US production deploys must be separated by a minimum 24-hour window per the Groupon change policy

### Release Process

```sh
# Build and release to Nexus
mvn clean release:clean release:prepare release:perform

# Or deploy snapshot to Nexus
mvn deploy

# Legacy Capistrano deploy (pre-cloud)
cap ${DATACENTER}:${ENVIRONMENT} deploy:app_servers VERSION=${VERSION} TYPE=${release/snapshot}
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min 3, Max 15 (production); Min 1, Max 2 (staging) |
| HPA target | CPU utilization | 100% (`hpaTargetUtilization: 100` in common.yml) |
| Memory (production) | Kubernetes resource limits | Request 3072 MiB, Limit 6144 MiB |
| CPU (production) | Kubernetes resource requests | Request 300m (no limit defined) |

## Resource Requirements

| Resource | Request (Production) | Limit (Production) |
|----------|---------------------|-------------------|
| CPU (main) | 300m | None configured |
| Memory (main) | 3072 MiB | 6144 MiB |
| CPU (filebeat) | 10m | 30m |
| Memory (filebeat) | 100 MiB | 400 MiB |

Ports exposed by Kubernetes service:
- `8080`: HTTP application port (readiness/liveness probes on `/grpn/healthcheck`)
- `8081`: Admin port (Dropwizard admin endpoints)
- `8009`: JMX port
