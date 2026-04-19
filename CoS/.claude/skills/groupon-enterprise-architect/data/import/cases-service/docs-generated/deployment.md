---
service: "cases-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

MCS is containerized using Docker and deployed to Kubernetes clusters via Groupon's internal Conveyor cloud platform. It runs in multiple regions (GCP US Central1, GCP/AWS Europe) for production, with a staging environment per region. Legacy on-prem deployments (SNC1, SAC1, DUB1) remain supported via Capistrano. The cloud deployment is managed through deploy-bot manifest files in `.meta/deployment/cloud/`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java21-jtier:2024-12-11-v2` with OpenTelemetry Java agent |
| Orchestration | Kubernetes (Conveyor) | Manifests in `.meta/deployment/cloud/components/app/` |
| Deploy tool | deploy-bot / Capistrano | `.deploy_bot.yml` for Kubernetes; `Capfile` + `Gemfile` for on-prem |
| Image registry | docker-conveyor.groupondev.com | Image: `mx-jtier/cases-service` |
| APM | OpenTelemetry Java agent | Bundled in Docker image at `/var/groupon/jtier/opentelemetry-javaagent.jar`; OTLP export to Tempo |
| Logging | ELK (Steno log) | `loggingPlatform: elk`; log source type `mx-merchant-cases`; log file `/var/groupon/jtier/logs/jtier.steno.log` |

## Environments

| Environment | Purpose | Region / Provider | Internal URL |
|-------------|---------|-------------------|--------------|
| `staging-us-central1` | Staging — US Canada | GCP us-central1 (`gcp-stable-us-central1`) | `http://mx-merchant-cases.staging.service` |
| `staging-europe-west1` | Staging — EMEA | GCP europe-west1 (`gcp-stable-europe-west1`) | `http://mx-merchant-cases.staging.service` |
| `production-us-central1` | Production — US Canada | GCP us-central1 (`gcp-production-us-central1`) | `http://mx-merchant-cases.production.service` |
| `production-europe-west1` | Production — EMEA (GCP) | GCP europe-west1 (`gcp-production-europe-west1`) | `http://mx-merchant-cases.production.service` |
| `production-eu-west-1` | Production — EMEA (AWS) | AWS eu-west-1 (Dublin DUB1) | `http://mx-merchant-cases.production.service` |
| `snc1:production` (on-prem) | Production — US (legacy) | SNC1 on-prem | `http://mx-merchant-cases.production.service` |
| `sac1:production` (on-prem) | Production — US SAC1 (legacy) | SAC1 on-prem | `http://mx-merchant-cases.production.service` |
| `dub1:production` (on-prem) | Production — EMEA (legacy) | DUB1 on-prem | `http://mx-merchant-cases.production.service` |

## CI/CD Pipeline

- **Tool**: Jenkins (on-prem) + deploy-bot (Kubernetes cloud)
- **Config**: `Jenkinsfile` (build/test), `.deploy_bot.yml` (Kubernetes deploy targets)
- **Trigger**: On merge to `master` branch; manual dispatch via deploy-bot; staging auto-promotes to production (`promote_to` field in `.deploy_bot.yml`)

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles Java, generates API stubs from OpenAPI specs, packages JAR
2. **Test**: `mvn verify` — runs unit and integration tests (rest-assured, WireMock)
3. **Docker build**: Builds Docker image from `src/main/docker/Dockerfile`, tags with version
4. **Push**: Pushes image to `docker-conveyor.groupondev.com/mx-jtier/cases-service`
5. **Deploy staging**: `bash .meta/deployment/cloud/scripts/deploy.sh <region> staging mx-merchant-cases-staging` via deploy-bot
6. **Promote to production**: Triggered by `promote_to` config or manual approval; runs deploy script for production namespace

### Manual Deployment (Kubernetes)

```sh
# Scale replicas immediately
kubectl scale --replicas=<N> deployment/mls-sentinel--app--default

# Deploy to staging GCP US
bash .meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging mx-merchant-cases-staging

# Deploy to production GCP US
bash .meta/deployment/cloud/scripts/deploy.sh production-us-central1 production mx-merchant-cases-production
```

### Manual Deployment (On-prem Capistrano)

```sh
cap snc1:production deploy:app_servers VERSION=<version> TYPE=release TICKET=GPROD-XXX
cap sac1:production deploy:app_servers VERSION=<version> TYPE=release TICKET=GPROD-XXX
cap dub1:production deploy:app_servers VERSION=<version> TYPE=release TICKET=GPROD-XXX
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | `minReplicas: 1`, `maxReplicas: 2` |
| Horizontal (production) | Kubernetes HPA | `minReplicas: 2`, `maxReplicas: 25`, `hpaTargetUtilization: 100` |
| JVM thread pool | Fixed thread pool | `maxThreads: 500`, `minThreads: 500` (cloud); 50/8 (development) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 1500m |
| Memory | 3Gi | 5Gi |
| Filebeat CPU | 10m | 300m |

## Health and Readiness

- **Readiness probe**: `GET /grpn/healthcheck` on port 8080; `delaySeconds: 40`, `periodSeconds: 10`
- **Liveness probe**: `GET /grpn/healthcheck` on port 8080; `delaySeconds: 40`, `periodSeconds: 10`
- **Status endpoint**: `GET /grpn/status` on port 8080 (disabled in `.service.yml` for service discovery but available)
- **Admin port**: 8081 (Dropwizard admin interface)
- **JMX port**: 8009
