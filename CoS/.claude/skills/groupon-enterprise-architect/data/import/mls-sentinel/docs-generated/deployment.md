---
service: "mls-sentinel"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, staging-us-west-2, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

MLS Sentinel is deployed as a Docker container orchestrated by Kubernetes via Groupon's Conveyor cloud platform. The application is built with Maven, packaged as an über-jar, and wrapped in a JTier base image (`prod-java17-jtier`). Deployment targets span two cloud providers (GCP and AWS) across US and EU regions, with both staging and production environments. Legacy on-premises deployment (SNC1, SAC1, DUB1 datacenters) via Capistrano is also supported.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — based on `docker.groupondev.com/jtier/prod-java17-jtier:2024-12-11-v2` |
| Orchestration | Kubernetes (Conveyor) | Manifests in `.meta/deployment/cloud/components/app/` |
| CI/CD pipeline | Jenkins | `Jenkinsfile` — `jtierPipeline` DSL |
| Container registry | Groupon Docker registry | `docker-conveyor.groupondev.com/mx-jtier/mls-sentinel` |
| Load balancer | Kubernetes Service (Conveyor) | HTTP port 8080 exposed as service port 80; admin port 8081 |
| TLS (Kafka) | OpenSSL + custom script | `kafka-tls.sh` runs at container start to configure Kafka TLS certificates |
| Observability | OpenTelemetry Java agent | Agent bundled in Docker image; OTLP export to Tempo |

## Environments

| Environment | Purpose | Cloud / Region | Internal URL |
|-------------|---------|----------------|-------------|
| staging-us-central1 | Staging (US) | GCP us-central1 | — |
| staging-europe-west1 | Staging (EU) | GCP europe-west1 | — |
| staging-us-west-2 | Staging (US West) | AWS us-west-2 | — |
| production-us-central1 | Production (US) | GCP us-central1 | — |
| production-eu-west-1 | Production (EU AWS) | AWS eu-west-1 | — |
| production-europe-west1 | Production (EU GCP) | GCP europe-west1 | — |
| production (snc1) | Production on-prem (US) | SNC1 datacenter | `http://mls-sentinel-vip.snc1` |
| production (sac1) | Production on-prem (US West) | SAC1 datacenter | `http://mls-sentinel-vip.sac1` |
| production (dub1) | Production on-prem (EU) | DUB1 datacenter | `http://mls-sentinel-vip.dub1` |
| staging (snc1) | Staging on-prem | SNC1 datacenter | `http://mls-sentinel-vip-us-staging.snc1`, `http://mls-sentinel-vip-emea-staging.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` — uses `java-pipeline-dsl@latest-2` shared library
- **Trigger**: On push to `master` or `MCE-.*` branches; releasable builds automatically deployed to staging

### Pipeline Stages

1. **Build**: Maven compile, test, package (`mvn clean package`)
2. **Docker build**: Build and push container image to `docker-conveyor.groupondev.com/mx-jtier/mls-sentinel`
3. **Deploy to staging**: Automatically deploys to `staging-us-central1` and `staging-europe-west1` via Conveyor deploy script
4. **Promote to production**: Manual promotion via Deploybot from staging targets to corresponding production targets (`staging-us-central1` → `production-us-central1`, `staging-europe-west1` → `production-eu-west-1`)
5. **Notify**: Google Chat build report sent to configured space on success

**Deploybot URL**: `https://deploybot.groupondev.com/mx-jtier/mls-rin`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min: 1, Max: 2 replicas; target CPU 100% |
| Horizontal (production) | HPA | Min: 3, Max: 18 replicas (us-central1); Min: 3, Max: 7 (common default); target CPU 100% |
| Manual scale (cloud) | kubectl | `kubectl scale --replicas=<N> deployment/mls-sentinel--app--default` |

## Resource Requirements

### Production (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | 2400m |
| Memory (main) | 5 GiB | 8 GiB |
| CPU (filebeat) | 100m | 300m |
| Memory (filebeat) | 1 GiB | 2 GiB |

### Staging (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1500m | 1800m |
| Memory (main) | 3 GiB | 5 GiB |
| CPU (filebeat) | 100m | 300m |
| Memory (filebeat) | 1 GiB | 2 GiB |

### Common defaults (all cloud environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 500m | 800m |
| Memory (main) | 3 GiB | 5 GiB |

## On-Prem Deployment (Legacy)

Manual deployment via Capistrano:

```sh
cap snc1:production_snc1 deploy:app_servers VERSION=<version> TYPE=release
cap snc1:production_sac1 deploy:app_servers VERSION=<version> TYPE=release
```

Service is managed by runit:
```sh
sudo sv start jtier   # start
sudo sv stop jtier    # stop
```

Logs:
- Runit log: `/var/groupon/log/jtier/runit/current`
- Application log: `/var/groupon/jtier/logs/jtier.steno.log`
