---
service: "gaurun"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

Gaurun is containerized (Docker, multi-stage build on Alpine) and deployed to Kubernetes via Groupon's Raptor/cloud deployment tooling. It runs in three production regions (GCP US-Central1, GCP Europe-West1, AWS EU-West-1) and two staging regions. Each Pod runs a main Gaurun container plus a Logstash sidecar container for log shipping. Configuration is environment-specific, selected at container startup via the `APPLICATION_ENV` environment variable.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker (multi-stage, golang:alpine3.20 builder + alpine:latest runtime) | `Dockerfile` at repo root |
| Dev container | Docker | `Dockerfile-dev` |
| Orchestration | Kubernetes | Raptor platform (`archetype: generic`, `.meta/.raptor.yml`) |
| Image registry | `docker-conveyor.groupondev.com/mta/gaurun` | Specified in `.meta/deployment/cloud/components/app/common.yml` |
| Sidecar | Logstash | `docker-conveyor.groupondev.com/data/logstash_grpn_tls_jmx:1.4` — ships send/fail logs to Kafka |
| Load balancer | Kubernetes Service (HTTP port 8080, admin port 8081) | Exposed via `httpPort: 8080`, `exposedPorts.admin-port: 8081` |
| CDN | None documented | Not applicable |

## Environments

| Environment | Purpose | Region | Cloud |
|-------------|---------|--------|-------|
| `staging-us-central1` | Pre-production testing | US Central 1 | GCP |
| `staging-europe-west1` | Pre-production testing | Europe West 1 | GCP |
| `production-us-central1` | Production traffic | US Central 1 | GCP |
| `production-eu-west-1` | Production traffic | EU West 1 | AWS |
| `production-europe-west1` | Production traffic | Europe West 1 | GCP |

## CI/CD Pipeline

- **Tool**: Jenkins (declarative pipeline via shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main`, `release`, `DAS-2876`, `staging-release` branches
- **Slack channel**: `AAAAd4lHcHE`

### Pipeline Stages

1. **Build Docker image**: Multi-stage Docker build — compiles Go binary with `make`, produces minimal Alpine runtime image.
2. **Test**: Runs `docker-compose -f .ci/docker-compose.yml build && docker-compose -f .ci/docker-compose.yml run test` — executes Go unit tests in Docker.
3. **Push image**: Pushes built image to `docker-conveyor.groupondev.com/mta/gaurun`.
4. **Deploy to staging**: Deploys to `staging-europe-west1` and `staging-us-central1` automatically on releasable branches.
5. **Deploy to production**: Managed via Raptor tooling (`deploy.sh`); manual or pipeline-triggered per region.

## Scaling

| Dimension | Strategy | Staging Config | Production Config |
|-----------|----------|---------------|-----------------|
| Horizontal (HPA) | CPU + Memory autoscaling | min 1 / max 1 (fixed) | min 10 / max 60 |
| HPA CPU target | 70% | N/A (fixed replicas) | 70% |
| HPA Memory target | 80% | N/A | 80% |
| Vertical (VPA) | Enabled in production | Disabled | Enabled |
| Workers (goroutines) | `core.workers` in TOML | — | Configured per environment |
| Pusher goroutines | `core.pusher_max` or `PUT /config/pushers` | — | Tunable at runtime |

## Resource Requirements

### Production (GCP US-Central1 / Europe-West1 / AWS EU-West-1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | `500m` | Not set (VPA managed) |
| Memory (main) | `3Gi` | `4Gi` |
| Memory limit (Go) | `GOMEMLIMIT=3072MiB` | — |

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | Not set | Not set |
| Memory (main) | `1Gi` | `2Gi` |
| Memory limit (Go) | `GOMEMLIMIT=1024MiB` | — |

### Logstash Sidecar (all environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | `500m` | `1000m` |
| Memory | `1Gi` | `4Gi` |

## Volume Mounts

| Volume | Mount Path | Purpose |
|--------|------------|---------|
| `client-certs` | `/var/groupon/certs` | APNs PEM certificates (external secret volume) |
| `gaurun-send-logs` | `/var/groupon/gaurun/sends/` | Shared volume for send/failed log files (Gaurun main + Logstash sidecar) |

## Sidecar: Logstash

The Logstash sidecar runs alongside the Gaurun main container in every Pod. It:

1. Tails `/var/groupon/logstash/log/send.log` (type: `push_service`) and `/var/groupon/logstash/log/failed.log` (types: `push_service` and `mta_push_bounce`).
2. Ships records to the Kafka cluster using `kafka_java` output plugin with mutual TLS.
3. Maintains sincedb state in `/var/groupon/logstash/sincedb/`.
4. Listens on port `9113` (readiness/liveness TCP probe, initial delay 10 seconds).
5. Runs a `preStop` lifecycle hook with `sleep 60` to ensure log drain before termination.
