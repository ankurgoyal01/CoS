---
service: "giftcard_service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-us-west-1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

The Giftcard Service is containerized using Docker and deployed to Kubernetes via Helm (chart `cmf-rails-api` version `3.89.0`). Deployment is managed through Deploybot (`.deploy_bot.yml`) using the `deploy_kubernetes` image. The service runs in the `sox-inscope` Docker image namespace and is deployed to Kubernetes namespaces tagged `giftcard-service-{env}-sox`. It runs on both GCP (primary) and AWS clusters across NA and EMEA regions, with a staging-to-production promotion pipeline managed by Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile`; base image `docker.groupondev.com/ruby:2.3.4`; app image `docker-conveyor.groupondev.com/sox-inscope/giftcard_service` |
| Orchestration | Kubernetes (GCP + AWS) | Helm chart `cmf-rails-api 3.89.0`; deploy script `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | nginx (sidecar) | nginx container proxies port 80 to Rails on port 3000 (httpPort: 8080 internally configured); access logs at `/var/groupon/logs/access-steno.log` |
| CDN | None | No CDN configured |

## Environments

| Environment | Purpose | Region / Cloud | URL |
|-------------|---------|---------------|-----|
| `staging-us-central1` | NA staging (auto-deploys, promotes to production-us-central1) | GCP us-central1 | `giftcard-service-staging-sox` namespace |
| `staging-europe-west1` | EMEA staging (auto-deploys, promotes to production-eu-west-1) | GCP europe-west1 | `giftcard-service-staging-sox` namespace |
| `production-us-central1` | NA production | GCP us-central1 | `giftcard-service-production-sox` namespace |
| `production-us-west-1` | NA production | AWS us-west-1 | `giftcard-service-production-sox` namespace; internal VIP: `http://giftcard-service-app-vip.snc1` |
| `production-eu-west-1` | EMEA production | AWS eu-west-1 | `giftcard-service-production-sox` namespace; internal VIP: `http://giftcard-service-app-vip.dub1` |
| `production-europe-west1` | EMEA production | GCP europe-west1 | `giftcard-service-production-sox` namespace |

## CI/CD Pipeline

- **Tool**: Jenkins (via `rubyPipeline` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` or `release` branches
- **Deployment targets**: `staging-us-central1` and `staging-europe-west1` on successful build
- **Promotion**: Staging auto-promotes to production via Deploybot (`promote_to` in `.deploy_bot.yml`)
- **Notifications**: Slack channel `giftcard-service` on start, complete, fail events

### Pipeline Stages

1. **Build**: Runs `docker-compose -f .ci/docker-compose.yml run -T construi build` (runs tests inside Docker)
2. **Release**: Tags release using `.ci/bin/create-release.sh` on releasable branches (`master`, `release`)
3. **Deploy to staging**: Deploybot deploys to `staging-us-central1` and `staging-europe-west1` using `bash ./.meta/deployment/cloud/scripts/deploy.sh`
4. **Promote to production**: Deploybot promotes passing staging deployments to respective production environments

### Deploy Command

```bash
helm3 template cmf-rails-api \
  --repo http://artifactory.groupondev.com/artifactory/helm-generic/ \
  --version '3.89.0' \
  -f .meta/deployment/cloud/components/app/common.yml \
  -f .meta/deployment/cloud/secrets/cloud/{env}.yml \
  -f .meta/deployment/cloud/components/app/{env}.yml \
  --set appVersion="${DEPLOYBOT_PARSED_VERSION}" \
  --set changeCause="${DEPLOYBOT_LOGBOOK_TICKET}" \
| krane deploy giftcard-service-{env}-sox {KUBE_CONTEXT} --global-timeout=300s --filenames=-
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes Horizontal Pod Autoscaler) | Min: 2–3 replicas, Max: 15 replicas, Target CPU utilization: 50% |
| Memory | Fixed request and limit | Request: 500Mi, Limit: 500Mi |
| CPU | Fixed request | Request: 1000m (1 vCPU) |
| VPA | Enabled in `production-us-central1` | `enableVPA: true` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | — (no limit set) |
| Memory | 500Mi | 500Mi |
| Disk | — | Not configured |

## Logging

- Application logs: `/giftcard-service/log/*.log`; multiline log pattern `^Started` (Rails request logging)
- nginx access logs: `/var/groupon/logs/access-steno.log`
- Log source type: `giftcard_service_app` (for log aggregation routing)
- Health check paths (`/grpn/healthcheck`) are blacklisted from Sonoma access logs
