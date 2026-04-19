---
service: "emailsearch-dataloader"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, staging-us-west-1, staging-us-west-2, production-us-central1, production-us-west-1, production-eu-west-1]
---

# Deployment

## Overview

The Email Search Dataloader is containerized (Docker) and deployed to Kubernetes clusters across two cloud providers: GCP (us-central1, europe-west1) and AWS (us-west-1, eu-west-1). It runs in both staging and production environments. Deployment is managed by the Groupon deploy bot (`raptor`) using `deploy_kubernetes` tooling. The CI/CD pipeline uses Jenkins with the `java-pipeline-dsl` shared library. The container image is published to `docker-conveyor.groupondev.com/rocketman/emailsearch-dataloader`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java17-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes | `.meta/deployment/cloud/scripts/deploy.sh`; deploy bot config in `.deploy_bot.yml` |
| Load balancer | Hybrid Boundary | `hybridBoundary.enableUpstreamCreation: true` on all environments; upstream creation enabled |
| CDN | None observed | Not configured in deployment manifests |

## Environments

| Environment | Purpose | Region | Cloud | URL |
|-------------|---------|--------|-------|-----|
| staging-us-central1 | Staging / QA | us-central1 | GCP | Not publicly exposed |
| staging-europe-west1 | Staging / QA (EMEA) | europe-west1 | GCP | Not publicly exposed |
| staging-us-west-1 | Staging / QA | us-west-1 | AWS | Not publicly exposed |
| staging-us-west-2 | Staging / QA | us-west-2 | AWS | Not publicly exposed |
| production-us-central1 | Production (US/Canada) | us-central1 | GCP | Internal only |
| production-us-west-1 | Production (US/Canada) | us-west-1 | AWS | Internal only |
| production-eu-west-1 | Production (EMEA) | eu-west-1 | AWS | Internal only |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root of repository)
- **Shared library**: `java-pipeline-dsl@latest-2`
- **Trigger**: Push to branch; release from `main`, `DAS-3181`, `DAS-5038` branches
- **Notification**: Slack channel `CFPNF55K5`
- **Code quality**: SonarQube (`sonarqube.groupondev.com`)

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles Java 17 source, runs unit and integration tests
2. **Code Quality**: SonarQube analysis with PMD and FindBugs; JaCoCo coverage (DTO/JDBI/config layers excluded from coverage requirements)
3. **Docker Build**: Builds image from `src/main/docker/Dockerfile`; image tagged and pushed to `docker-conveyor.groupondev.com/rocketman/emailsearch-dataloader`
4. **Deploy to Staging**: Deploys to `staging-us-central1` and `staging-europe-west1` automatically from `main` branch
5. **Promote to Production**: Staging-us-central1 promotes to `production-us-central1`; staging-europe-west1 promotes to `production-eu-west-1` (via `.deploy_bot.yml` `promote_to` configuration)

### Deploy Command

```sh
bash ./.meta/deployment/cloud/scripts/deploy.sh <env> <staging|production> <k8s-namespace>
```

### Docker Entrypoint

In Kafka-enabled environments (most production and staging regions), the container entrypoint runs:
```sh
/var/groupon/jtier/kafka-tls-v2.sh && /var/groupon/jtier/service/run
```
The `kafka-tls-v2.sh` script configures Kafka mTLS using certificates from the mounted Kubernetes secret before the JTier service process starts.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production-us-central1) | Fixed replicas | min: 12 / max: 12 |
| Horizontal (production-us-west-1) | Fixed replicas | min: 12 / max: 12 |
| Horizontal (production-eu-west-1) | HPA | min: 8 / max: 12 |
| Horizontal (staging) | HPA | min: 1 / max: 2 |
| Vertical (GCP envs) | VPA | Enabled on us-central1 (staging and production) |
| General HPA target | CPU utilization | `hpaTargetUtilization: 50` (common config) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 600m | Not set (VPA managed on GCP) |
| Memory (main) | 1Gi | 6Gi |
| CPU (envoy sidecar, GCP prod) | 50m | Not set |
| Memory (envoy sidecar, GCP prod) | 100Mi | Not set |

### Additional Configuration

- **HTTP port**: 9000
- **JMX port**: 8009
- **Log directory**: `/var/groupon/jtier/logs` (JSON format, source type `emailsearch_dataloader`)
- **APM**: Enabled on all environments
- **TLS cert volume**: `/var/groupon/certs` (mounted from `client-certs` volume)
- **Filebeat**: Enabled with `medium` volume type for log shipping
