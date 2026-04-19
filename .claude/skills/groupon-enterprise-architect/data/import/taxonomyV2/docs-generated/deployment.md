---
service: "taxonomyV2"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-west-2, staging-us-central1, staging-europe-west1, production-us-west-1, production-eu-west-1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

Taxonomy V2 is a containerized JTier Java service deployed on Kubernetes via Groupon's Conveyor/Raptor cloud deployment platform. The service is multi-region, running in both US (AWS us-west-1, GCP us-central1) and EMEA (AWS eu-west-1, GCP europe-west1) clusters. Staging environments are deployed automatically on merge to master; production deployments require manual promotion through Deploybot with a GPROD change ticket and QA/prodCAT approvals. The deployment order for production is EU before US.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; image: `docker-conveyor.groupondev.com/hawk/taxonomyv2` |
| Orchestration | Kubernetes (Conveyor/Raptor) | Manifests generated from `.meta/deployment/cloud/` YAML specs; archetype `jtier` |
| Deployment tool | Deploybot | https://deploybot.groupondev.com/hawk/taxonomyV2 |
| CI/CD | Jenkins (`Jenkinsfile`) | Builds on merge to master; auto-deploys to staging targets |
| Load balancer | Internal VIP | VIP per cluster (e.g., `taxonomyv2.us-central1.conveyor.stable.gcp.groupondev.com` for staging) |
| APM | Groupon APM agent | Enabled via `apm.enabled: true` in `common.yml` |
| Log shipping | Filebeat sidecar | Log source type: `taxonomyv2`; structured logging to ELK |

## Environments

| Environment | Purpose | Cloud / Region | Notes |
|-------------|---------|---------------|-------|
| staging-us-west-1 | Staging | AWS us-west-1 | Auto-deployed on master merge |
| staging-us-west-2 | Staging | AWS us-west-2 | Auto-deployed on master merge |
| staging-us-central1 | Staging | GCP us-central1 | VIP: `taxonomyv2.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Staging | GCP europe-west1 | Auto-deployed on master merge |
| production-eu-west-1 | Production | AWS eu-west-1 | Deploy first in production rollout |
| production-us-west-1 | Production | AWS us-west-1 | Deploy second in production rollout |
| production-us-central1 | Production | GCP us-central1 | GCP production cluster |
| production-europe-west1 | Production | GCP europe-west1 | GCP EMEA production cluster |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root of repo)
- **Trigger**: On merge to `master` branch

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles source, runs tests, produces JAR
2. **Release**: `mvn clean release:clean release:prepare release:perform` — tags version and uploads to Nexus artifact repository
3. **Docker build**: Builds Docker image and pushes to `docker-conveyor.groupondev.com/hawk/taxonomyv2`
4. **Staging deploy**: Auto-deploys to `staging-us-west-1` and `staging-us-west-2` via Deploybot
5. **Manual approval**: Engineer reviews staging deployment in Deploybot
6. **Production promotion**: Engineer promotes staging build to production environments via Deploybot, in GPROD-gated order (EU first, then US)

### Production Deployment Order

> staging-europe-west1 → production-eu-west-1 → (verify) → staging-us-central1 → production-us-central1

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes Horizontal Pod Autoscaler) | Min: 3 replicas (prod) / 1–3 (staging), Max: 20, Target CPU: 50% (`hpaTargetUtilization: 50`) |
| Vertical | VPA enabled in production us-west-1 only | `enableVPA: true` (us-west-1 production) |
| Scale-up procedure | Increase `maxReplicas` in environment YAML and redeploy same image | `.meta/deployment/cloud/components/app/<env>.yml` |

## Resource Requirements

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| CPU (main container) | 1000m | 2000m | All environments |
| Memory (main container) | 4Gi (common) / 10Gi (prod per-env) | 6Gi (common) / 15–18Gi (prod per-env) | Production overrides memory for large taxonomy cache builds |
| CPU (Filebeat sidecar) | 10m | 30m | Log shipping sidecar |
| Memory (Filebeat sidecar) | 200Mi | 500Mi | Log shipping sidecar |
| JVM heap | 70% of container memory | 70% of container memory | Controlled via `MIN_RAM_PERCENTAGE` and `MAX_RAM_PERCENTAGE` env vars |

## Ports

| Port | Purpose |
|------|---------|
| `8080` | HTTP application traffic (maps to port 80 on the Kubernetes service) |
| `8081` | Dropwizard admin port (health checks, metrics, tasks) |
| `8009` | JMX port for JVM diagnostics |

## Rollback

Rollback is performed via Deploybot by selecting a previous deployment image version and re-promoting it. The Deploybot URL is: https://deploybot.groupondev.com/hawk/taxonomyV2
