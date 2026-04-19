---
service: "suggest"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1]
---

# Deployment

## Overview

The Suggest service is containerised using a multi-stage Docker build on `python:3.12-slim` and deployed to Google Kubernetes Engine (GKE) via the Groupon internal Conveyor/Raptor platform. The image is pushed to `docker-conveyor.groupondev.com/search-next/suggest`. Three environments are configured: production in `us-central1` (min 2, max 5 replicas) and staging in `us-central1` and `europe-west1`. The CI/CD pipeline is Jenkins-based; automated deployment targets staging on every merge to `main`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` — builder stage installs Python dependencies; runtime stage copies app, data, and ONNX encoder; exposes port 8080 |
| Orchestration | Kubernetes (GKE) | Managed via Conveyor/Raptor platform; manifests in `.meta/deployment/cloud/` |
| Image registry | docker-conveyor.groupondev.com | `docker-conveyor.groupondev.com/search-next/suggest` |
| Load balancer | Kubernetes Service (HTTP port 8080) | `httpPort: 8080` in `common.yml`; `hybridBoundary.isDefaultDomain: false` |
| Metrics sidecar | Prometheus + Config Reloader | Prometheus `v2.51.2` sidecar; config reloader `v0.67.0`; remote-write to Thanos |
| Log shipping | JSON log files | Logs written to `/var/groupon/logs/logfile.log`; shipped by platform log agent; source type `search-next-suggest-app` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `staging-us-central1` | Pre-production validation | us-central1 (GCP) | Internal cluster endpoint |
| `staging-europe-west1` | European staging | europe-west1 (GCP) | Internal cluster endpoint |
| `production-us-central1` | Live production traffic | us-central1 (GCP) | Internal cluster endpoint |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `main` branch (test + publish + deploy to `staging-us-central1`); manual dispatch for production

### Pipeline Stages

1. **Build Docker image**: Multi-stage build; injects `FULL_SHA`, `SHORT_SHA`, `TAG`, and `OPEN_CONTAINER_DATE` build args
2. **Test**: Runs `./run_tests.sh` inside Docker (pytest unit and integration tests with coverage)
3. **Publish**: Pushes image to `docker-conveyor.groupondev.com/search-next/suggest`
4. **Deploy (staging)**: Automatically deploys to `staging-us-central1` on `main` branch merges
5. **Deploy (production)**: Manual dispatch required for promotion to `production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | min: 2, max: 5 replicas; `hpaTargetUtilization: 50` |
| Horizontal (staging) | Fixed | min: 1, max: 1 replica |
| VPA | Disabled | `enableVPA: false` in all environments |

## Resource Requirements

| Resource | Request (Production) | Limit (Production) |
|----------|--------|-------|
| CPU | 1000m | Not explicitly set |
| Memory | 1Gi | 2Gi |
| Disk | — | — |

> Staging resource requests are not explicitly configured in `staging-us-central1.yml` (relies on platform defaults).

## Health Check

Configured in `app.yaml` and `common.yml`:

| Property | Value |
|----------|-------|
| Endpoint | `GET /grpn/healthcheck` |
| Port | 8080 |
| Initial delay | 30 seconds |
| Period | 10 seconds |
| Timeout | 5 seconds |
| Success threshold | 1 |
| Failure threshold | 5 |

Readiness and liveness probes both target port 8080; liveness period is 20 seconds (from `common.yml`).

## Observability (Deployment Layer)

- **Prometheus**: ServiceMonitor `suggest-app` scrapes `http` port every 60 seconds; remote-write to Thanos at `http://thanos-receive.telegraf-{ENVIRONMENT}.svc:19291/api/v1/receive`
- **Elastic APM**: `ELASTIC_APM_TRANSACTION_SAMPLE_RATE=1.0` (100% sampling); traces excluded for `/metrics*` and `/healthcheck*` URLs
- **Logs**: JSON-formatted log files in `/var/groupon/logs/`; collected by platform log-shipping agent with source type `search-next-suggest-app`
