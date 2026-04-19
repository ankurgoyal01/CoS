---
service: "mls-yang"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1, snc1-production, sac1-production]
---

# Deployment

## Overview

mls-yang runs as a containerised Kubernetes worker on GCP (us-central1), deployed via Groupon's Raptor/Conveyor platform. There is no HTTP ingress — the service operates as a background worker consuming Kafka topics and running Quartz batch jobs. Legacy on-premise deployments in snc1 and sac1 colos are referenced in `.service.yml` but the primary active deployment target is GCP.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `docker.groupondev.com/jtier/dev-java11-maven:2023-02-27-aaff088` (CI); runtime image: `docker-conveyor.groupondev.com/mx-jtier/mls-yang` |
| Orchestration | Kubernetes (GKE) | Worker deployment via Raptor (`.meta/deployment/cloud/`); namespace `mls-yang-production` / `mls-yang-staging` |
| Load balancer | None | Worker service — no inbound HTTP load balancing |
| APM | OpenTelemetry | OTLP export to Tempo (`otel-collector-opentelemetry-collector.tempo-production:4318`) |
| Log shipping | Filebeat | Sidecar container ships logs from `/var/groupon/jtier/logs` to centralised logging |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `staging-us-central1` | Pre-production testing | GCP us-central1 | `http://mls-yang-app1-staging.snc1:8080` (legacy colo reference) |
| `production-us-central1` | Live production | GCP us-central1 | `http://mls-yang-app1.snc1:8080` (legacy colo reference) |
| `snc1-production` | Legacy on-premise | snc1 | `http://mls-yang-app1.snc1:8080`, `http://mls-yang-app2.snc1:8080` |
| `sac1-production` | Legacy on-premise | sac1 | `http://mls-yang-app1.sac1:8080`, `http://mls-yang-app2.sac1:8080` |

## CI/CD Pipeline

- **Tool**: Groupon Deploy Bot (`deploy_bot`) with Raptor Kubernetes deploy
- **Config**: `.deploy_bot.yml`, `.meta/deployment/cloud/scripts/deploy.sh`
- **Trigger**: Merge to `master` branch auto-promotes to staging; staging promotes to production after validation
- **Merge policy**: 2 ship-it approvals required (`approval_by_review`), squash merge (`.ghe-bot.yml`)

### Pipeline Stages

1. **Build**: Maven build with Java 11 inside Docker CI container (`.ci/Dockerfile`)
2. **Test**: Unit and integration tests (includes embedded Kafka via `kafka-junit` and in-memory DB via `jtier-daas-testing`)
3. **Docker push**: Push image to `docker-conveyor.groupondev.com/mx-jtier/mls-yang`
4. **Deploy staging**: `bash ./.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging mls-yang-staging`
5. **Promote to production**: `bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production mls-yang-production`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed replica count (Kubernetes) | Staging: `minReplicas: 3, maxReplicas: 3`; Production: `minReplicas: 1, maxReplicas: 2` |
| HPA | Disabled (hpaTargetUtilization: 100, fixed replicas) | Common config |
| Quartz | Clustered (PostgreSQL-backed JobStore) | `isClustered: true`, 5 worker threads per node |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | 2000m |
| Memory (main) | 6Gi | 9Gi |
| CPU (log-tail sidecar) | 30m | 100m |
| CPU (Filebeat sidecar) | 500m | 700m |
| Memory (Filebeat sidecar) | 200Mi | 400Mi |

### Additional Notes

- `MALLOC_ARENA_MAX=4` is set to prevent JVM native memory (vmem) explosion from glibc malloc arenas on multi-core hosts.
- JMX port `8009` and admin port `8081` are exposed for internal monitoring.
- HTTP port `8080` hosts the REST API and health endpoint (`/grpn/status`).
- Client certificates for Kafka SSL are mounted as a volume (`client-certs` at `/var/groupon/certs`).
