---
service: "channel-manager-integrator-derbysoft"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

The service is containerized using a custom Docker image based on `docker.groupondev.com/jtier/prod-java11-jtier:3`. It is orchestrated on Kubernetes via Groupon's Raptor/Conveyor platform, deployed across four targets: GCP us-central1 (production and staging), GCP europe-west1 (staging), and AWS eu-west-1 (production). Deployment is managed by the `deploy_bot` (`deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`) using Kubernetes contexts. CI/CD is driven by Jenkins (`java-pipeline-dsl@latest-2`). The service is classified as a SOX-inscope service (`sox-inscope` GitHub org).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base: `docker.groupondev.com/jtier/prod-java11-jtier:3`; includes Kafka TLS certificate setup via `kafka-tls.sh` |
| Orchestration | Kubernetes | Manifest overlays under `.meta/deployment/cloud/components/app/`; component type: `api`, archetype: `jtier` |
| Service image | Docker Registry | `docker-conveyor.groupondev.com/sox-inscope/channel-manager-integrator-derbysoft` |
| CI Build image | Docker | `.ci/Dockerfile` — base: `docker.groupondev.com/jtier/dev-java11-maven:2021-10-14-2047f4d` |
| Load balancer | VIP (internal) | `http://getaways-channel-manager-integrator-ds-app-vip.snc1:8080` (production internal) |
| APM | Elastic APM | Enabled in production (us-central1) and staging; endpoint injected via `JTIER_RUN_CONFIG` |
| Logging | Filebeat | Log source type: `getaways-channel-manager-integrator-derbysoft`; log dir: `/var/groupon/jtier/logs/jtier.steno.log` |

## Environments

| Environment | Purpose | Region / Cloud | URL |
|-------------|---------|---------------|-----|
| `staging-us-central1` | Pre-production testing (promotable) | GCP us-central1 | `https://channel-manager-integrator-derbysoft.us-central1.conveyor.stable.gcp.groupondev.com` |
| `staging-europe-west1` | Pre-production testing EMEA (promotable) | GCP europe-west1 | — |
| `production-us-central1` | Production — US/Canada traffic | GCP us-central1 | `http://getaways-channel-manager-integrator-ds-app-vip.snc1:8080` (internal) / `http://api.groupon.com/getaways/v2/partner/derbysoft/CMService` (external) |
| `production-eu-west-1` | Production — EMEA traffic | AWS eu-west-1 | `http://getaways-channel-manager-integrator-ds-app-vip.sac1` (internal) |
| `uat` | User acceptance testing | snc1 (on-prem) | `http://getaways-channel-manager-integrator-ds-app1-uat.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (`java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch in `sox-inscope/channel-manager-integrator-derbysoft`; `-deploy` suffix branches trigger non-promotable staging deploys

### Pipeline Stages

1. **Build**: Maven build via `.ci/Dockerfile` (dev-java11-maven image); runs tests, produces JAR
2. **Docker Build**: Builds production Docker image tagged with Maven artifact version
3. **Push Artifact**: Publishes image to `docker-conveyor.groupondev.com/sox-inscope/channel-manager-integrator-derbysoft`
4. **Deploy Staging (US)**: Deploys to `gcp-stable-us-central1` via `deploy.sh staging-us-central1`
5. **Deploy Staging (EMEA)**: Deploys to `gcp-stable-europe-west1` via `deploy.sh staging-europe-west1`
6. **Promote to Production (US)**: Promotes staging artifact to `gcp-production-us-central1` via `deploy.sh production-us-central1`
7. **Promote to Production (EU)**: Promotes to `production-eu-west-1` (AWS) via `deploy.sh production-eu-west-1`
8. **Fork Sync**: After release, rebases `travel-fork-sox-repo/channel-manager-integrator-derbysoft` from `sox-inscope` master

CI/CD notifications are sent to Slack channel `CFC3L55QE` (`getaways-cicd`).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (prod US) | Kubernetes HPA | Min: 2 / Max: 15 / Target CPU utilization: 50% |
| Horizontal (prod EU) | Kubernetes HPA | Min: 1 / Max: 5 |
| Horizontal (staging) | Kubernetes HPA | Min: 1 / Max: 2 |
| MBus workers | Thread pool per listener | `iswBookingMessageListenerConfig.numberOfWorkers` (configured in YAML) |
| MALLOC_ARENA_MAX | JVM memory tuning | Set to `4` to prevent container OOM kills |

## Resource Requirements

| Resource | Request (common) | Limit (common) |
|----------|---------|-------|
| CPU (main, prod) | 1000m | — (no limit specified in overlay) |
| CPU (main, common) | 300m | — |
| Memory (main) | 1700Mi | 2000Mi |
| CPU (filebeat, prod) | 100m | 300m |
| Memory (filebeat) | 100Mi | 200Mi |

### Exposed Ports

| Port | Purpose |
|------|---------|
| `8080` | HTTP application port (mapped to service port 80) |
| `8081` | Dropwizard admin port |
| `8009` | JMX port |

### Probes (Production)

| Probe | Delay | Period | Timeout |
|-------|-------|--------|---------|
| Readiness | 60s | 5s | 60s |
| Liveness | 60s | 15s | 60s |
