---
service: "client-id"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-central1, staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

Client ID Service is fully containerised and runs on Kubernetes. US environments use GCP GKE clusters; EMEA environments use AWS EKS. CI is managed by Jenkins (`Jenkinsfile`). Deployment promotion is handled by [Deploybot](https://deploybot.groupondev.com/groupon-api/client-id). Every merge to `master` triggers a Jenkins build that packages a JAR, builds a Docker image, publishes to Nexus, and auto-deploys to staging. Promotion to production requires manual authorisation in Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Orchestration | Kubernetes (GKE + EKS) | Manifests generated from `.meta/deployment/cloud/` component YAMLs |
| Image registry | Conveyor (internal) | `docker-conveyor.groupondev.com/groupon-api/client-id` |
| Artifact repository | Nexus | `nexus-dev/content/repositories/releases/com/groupon/groupon-api/client-id` |
| Load balancer | Kubernetes Ingress (HTTPS enabled) | `httpsIngress.enabled: true` in common deployment config |
| APM | Elastic APM | Enabled in all environments; staging points to `elastic-apm-http.logging-platform-elastic-stack-staging` |
| Log shipping | Filebeat + Kafka (EMEA) / GCP Cloud Logging (US) | `logConfig.sourceType: client-id` |
| Metrics | Telegraf | `logConfig` and `telegrafUrl` configured per environment |

## Environments

| Environment | Purpose | Cloud / Region | VIP / URL |
|-------------|---------|----------------|-----------|
| `dev-us-central1` | Developer testing | GCP us-central1 | Internal GKE dev cluster |
| `staging-us-central1` | Pre-production staging (US) | GCP us-central1 | `client-id.us-central1.conveyor.stable.gcp.groupondev.com` |
| `staging-europe-west1` | Pre-production staging (EMEA) | GCP europe-west1 | Internal GKE staging cluster |
| `production-us-central1` | Production (US) | GCP us-central1 | `client-id.us-central1.conveyor.stable.gcp.groupondev.com` |
| `production-europe-west1` | Production (EMEA GCP) | GCP europe-west1 | Internal GKE production cluster |
| `production-eu-west-1` | Production (EMEA AWS) | AWS eu-west-1 | Internal EKS production cluster |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` or patch branches (`(.*)--patch(.*)`); Deploybot webhook for promotion

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles source, runs tests, produces fat JAR
2. **Docker build**: Packages JAR into `docker.groupondev.com/jtier/prod-java11-jtier:3`-based image
3. **Publish**: Pushes image to Conveyor registry; publishes JAR to Nexus
4. **Auto-deploy staging**: Deploybot auto-deploys to `staging-us-central1` and `staging-europe-west1` (configured in `Jenkinsfile` `deployTarget`)
5. **Manual promotion**: Developer authorises promotion through Deploybot UI following US path (`staging-us-central1` → `production-us-central1`) and EMEA path (`staging-europe-west1` → `production-eu-west-1`)

### Promotion Paths

**US Path:**
`staging-us-central1` → `production-us-central1`

**EMEA Path:**
`staging-europe-west1` → `production-eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Horizontal Pod Autoscaler (HPA) + Vertical Pod Autoscaler (VPA) | Production US: 8–20 replicas; EMEA: 4–20 replicas; Staging: 1–2 replicas |
| CPU | HPA target utilisation (EMEA) | EMEA `hpaTargetUtilization: 30`; VPA enabled for GCP environments |
| Memory | VPA recommendation | `enableVPA: true` for GCP production and staging; `enableVPA: false` for AWS EU |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main container) | 300m | 900m |
| Memory (main container) | 2 Gi | 3 Gi |
| CPU (filebeat sidecar) | 105m | 300m |
| CPU (log-tail sidecar) | 3m | 10m |
| JVM heap | 1843m (`HEAP_SIZE`) | — |

## Service Ports

| Port | Purpose |
|------|---------|
| `8080` | Application HTTP (`httpPort`) |
| `9001` | Dropwizard admin (metrics, health checks) |

## Rollback

Use Deploybot to re-trigger the previous successful deployment. Alternatively:

```bash
# Rollback to the previous revision
kubectl rollout undo deployment/client-id--app--default -n <namespace>

# Rollback to a specific revision
kubectl rollout undo deployment/client-id--app--default -n <namespace> --to-revision=<revision-number>
```
