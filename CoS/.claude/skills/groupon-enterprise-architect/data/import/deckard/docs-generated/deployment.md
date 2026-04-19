---
service: "deckard"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev-us-west-1", "dev-us-west-2", "staging-us-central1", "staging-europe-west1", "production-us-central1", "production-europe-west1"]
---

# Deployment

## Overview

Deckard is deployed as a Docker container orchestrated on Kubernetes (GCP). It runs in two production regions (us-central1 and europe-west1) and two staging regions. Deployments are promoted through DeployBot using a staging-to-production pipeline. Each environment has independent Kubernetes manifests in `.meta/deployment/cloud/`. The container image is built by Maven's dockerfile-maven-plugin and pushed to `docker-conveyor.groupondev.com/groupon-api/deckard`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker.groupondev.com/jtier/prod-java11:3` |
| Orchestration | Kubernetes (GCP) | Manifests in `.meta/deployment/cloud/components/app/` |
| Image registry | docker-conveyor | `docker-conveyor.groupondev.com/groupon-api/deckard` |
| Load balancer | Hybrid Boundary (HB) | HTTPS ingress enabled; RRDNS and connection balancing configurable per environment |
| Metrics sidecar | Telegraf + Jolokia | Jolokia agent on port 8778; Telegraf sidecar via `.meta/deployment/cloud/components/telegraf-agent/` |
| APM | Elastic APM | Enabled in staging and production; endpoint configured per region |
| Logging | Filebeat + ELK | Log source type `deckard`; log file at `/app/log/application.log`; Kibana index `filebeat-deckard--*` |

## Environments

| Environment | Purpose | Region | VIP / URL |
|-------------|---------|--------|-----------|
| dev-us-west-1 | Local/CI development | us-west-1 (AWS) | Internal only |
| dev-us-west-2 | Local/CI development | us-west-2 (AWS) | Internal only |
| staging-us-central1 | Pre-production validation | GCP us-central1 | `deckard.staging.stable.us-central1.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation | GCP europe-west1 | `deckard.staging.stable.europe-west1.gcp.groupondev.com` |
| production-us-central1 | Production (NA) | GCP us-central1 | `deckard.prod.us-central1.gcp.groupondev.com` |
| production-europe-west1 | Production (EU) | GCP europe-west1 | `deckard.prod.europe-west1.aws.groupondev.com` (GCP migration pending) |

## CI/CD Pipeline

- **Tool**: Jenkins (DotCi/Jenkins on `cloud-jenkins.groupondev.com`)
- **Config**: `.ci.yml` (executes `mvn deploy`)
- **Trigger**: On every merge to `master`; manual dispatch via DeployBot

### Pipeline Stages

1. **Build**: `mvn deploy` — compiles, tests, packages fat JAR, runs integration tests
2. **Package**: Maven shade plugin creates `deckard-fat.jar`; dockerfile-maven-plugin builds and pushes Docker image tagged with version and `latest`
3. **Publish**: Artifact published to Nexus at `http://nexus-dev/content/repositories/releases`
4. **Staging deploy**: DeployBot auto-deploys to `staging-us-central1` and `staging-europe-west1`
5. **Production promote**: Manual DeployBot promotion from staging to production per region

### Deployment Command (manual)

```sh
krane render \
  --current-sha=<VERSION_SHA> \
  --filenames=./.meta/deployment/cloud/components/app/template \
  --bindings='@./.meta/deployment/cloud/components/app/template/config/framework-defaults.yml' \
           '@./.meta/deployment/cloud/components/app/common.yml' \
           '@./.meta/deployment/cloud/components/app/staging-us-central1.yml' \
| krane deploy deckard-staging deckard-staging-us-central1 --filenames=- --no-prune
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 6 replicas |
| Horizontal (production) | Kubernetes HPA + VPA | min: 4, max: 20 replicas (us-central1); min: 2, max: 20 (europe-west1) |
| Vertical Pod Autoscaler | Enabled (`enableVPA: true`) | Adjusts CPU/memory within request/limit bounds |

## Resource Requirements

### Production (us-central1 and europe-west1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1 core | 2 cores |
| Memory (main) | 8 Gi | 10 Gi |
| JVM heap | 5 G (`MIN_HEAP_SIZE`) | 5 G (`MAX_HEAP_SIZE`) |
| CPU (filebeat) | 200m | 800m |
| Memory (filebeat) | 100 Mi | 400 Mi |

### Staging (us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 400m | 700m |
| Memory (main) | 3 Gi | 5 Gi |
| JVM heap | 2 G (`MIN_HEAP_SIZE`) | 4 G (`MAX_HEAP_SIZE`) |
| CPU (filebeat) | 100m | 200m |

## Health Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|--------------|--------|
| Readiness | `/grpn/healthcheck` | 8001 | 90s (prod), 30s (staging) | 15s (prod), 10s (staging) |
| Liveness | `/grpn/healthcheck` | 8001 | 90s (prod), 40s (staging) | 15s (prod), 10s (staging) |

## Exposed Ports

| Port | Purpose |
|------|---------|
| 8001 | HTTP application port |
| 8778 | Jolokia JMX-to-HTTP agent (metrics) |
| 8009 | JMX remote port (localhost only) |

## Rollback

Rollback is performed via DeployBot by selecting a previous deployment version and clicking retry, or by manually running `krane deploy` with the previous SHA. Search Slack `#api-team-announce` for the last successful production deployment SHA if not visible in DeployBot.
