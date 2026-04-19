---
service: "proximity-notification-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments:
  - staging-us-west-1
  - staging-us-central1
  - staging-europe-west1
  - production-us-west-1
  - production-us-central1
  - production-eu-west-1
  - production-europe-west1
---

# Deployment

## Overview

The Proximity Notification Service is containerized with Docker and deployed on Kubernetes via the Groupon Conveyor Cloud platform. It runs across multiple AWS and GCP regions. CI/CD is managed by a Jenkins pipeline using `jtierPipeline` with Deploybot handling staged promotion from staging to production. The service also has legacy on-premises deployments in snc1, sac1, and dub1 colos.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `docker.groupondev.com/jtier/prod-java11-alpine-jtier:3` |
| CI build container | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java11-maven:3` |
| Orchestration | Kubernetes (Conveyor Cloud) | Deployment manifests in `.meta/deployment/cloud/` |
| Image registry | Groupon Docker registry | `docker-conveyor.groupondev.com/emerging-channels/proximity-notifications` |
| Load balancer | Conveyor Cloud VIP | Configured per-environment in `*.yml` under `.meta/deployment/cloud/components/app/` |
| Log shipping | Logstash sidecar + Kafka | `logstash_grpn_tls_jmx:1.4` sidecar, ships `mobile_proximity_locations.log` and `finch.log` to Kafka |
| APM | Enabled | `apm.enabled: true` in common.yml |

## Environments

| Environment | Purpose | Region / Cloud | VIP |
|-------------|---------|----------------|-----|
| staging-us-west-1 | Staging (US) | AWS us-west-1 | `proximity-notifications.staging.stable.us-west-1.aws.groupondev.com` |
| staging-us-central1 | Staging (US GCP) | GCP us-central1 | — |
| staging-europe-west1 | Staging (EMEA) | GCP europe-west1 | — |
| production-us-west-1 | Production (US) | AWS us-west-1 | `proximity-notifications.prod.us-west-1.aws.groupondev.com` |
| production-us-central1 | Production (US GCP) | GCP us-central1 | — |
| production-eu-west-1 | Production (EMEA AWS) | AWS eu-west-1 | — |
| production-europe-west1 | Production (EMEA GCP) | GCP europe-west1 | `proximity-notifications.prod.europe-west1.gcp.groupondev.com` |
| snc1 (on-prem) | Production (US on-prem) | Sunnyvale DC | `http://ec-proximity-vip.snc1` |
| sac1 (on-prem) | Production (US on-prem) | Sacramento DC | `http://ec-proximity-vip.sac1` |
| dub1 (on-prem) | Production (EMEA on-prem) | Dublin DC | `http://ec-proximity-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (`jtierPipeline` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `main` branch; releasable branches: `main`
- **Slack notifications**: `#emerging-channel-noti` (channel `CFQF6KK55`)

### Pipeline Stages

1. **Build**: Maven build and unit test (`mvn clean package`)
2. **Docker build**: Build and push Docker image to Groupon registry
3. **Deploy staging**: Automatically deploy to `staging-us-west-1`, `staging-us-central1`, `staging-europe-west1`
4. **Promote to production**: Manual authorization via Deploybot to promote staging deployments to production
5. **Tag release**: Git tag created with the Nexus release version after promotion

### Deployment Promotion Order (Cloud)

```
staging-us-west-1     → production-us-west-1
staging-us-central1   → production-us-central1
staging-europe-west1  → production-eu-west-1 / production-europe-west1
```

### Deployment Promotion Order (On-Prem)

```
staging → canary_snc1 (ec-proximity-app1.snc1) → snc1 production → sac1 production → dub1 production
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | minReplicas: 2, maxReplicas: 10, hpaTargetUtilization: 50% |
| Horizontal (staging) | Kubernetes HPA | minReplicas: 1, maxReplicas: 3, hpaTargetUtilization: 50% |
| CPU | HPA target | 50% CPU utilization triggers new pod allocation |

## Resource Requirements

| Resource | Request (staging) | Limit (staging) | Request (production) | Limit (production) |
|----------|-------------------|-----------------|---------------------|-------------------|
| CPU | 500m | — | 500m | — |
| Memory | 2Gi | 2Gi | 6Gi | 6Gi |
| Logstash sidecar CPU | 200m | 500m | 200m | 500m |
| Logstash sidecar memory | 2Gi | 4Gi | 2Gi | 4Gi |

Application HTTP port: `8080`; Admin port: `8081`
