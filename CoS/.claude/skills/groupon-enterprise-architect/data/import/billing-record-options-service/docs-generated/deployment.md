---
service: "billing-record-options-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

BROS is containerized and deployed to Kubernetes via Groupon's Conveyor platform using the `cmf-jtier-api` Helm chart (version 3.89.0). The service runs in five Kubernetes environments across two cloud providers (GCP and AWS) and two geographic regions (NA and EMEA). Deployments are managed by Deploybot (automated deploy bot) and initiated via Jenkins CI. Secrets are stored in a separate git submodule and mounted at deploy time.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes (Conveyor) | Helm chart `cmf-jtier-api` v3.89.0; deployed via `krane` with `--global-timeout=300s` |
| Load balancer | VIP (Conveyor-managed) | One VIP per region/environment (see Environments table) |
| CDN | None | Internal service only; not publicly exposed |
| Metrics | Telegraf | Region-specific `telegrafUrl` configured per environment |
| Log shipping | Filebeat | `filebeatKafkaEndpoint` per environment; log source type `bros_app` |

## Environments

| Environment | Purpose | Cloud | Region | VIP |
|-------------|---------|-------|--------|-----|
| Staging NA | Pre-production NA testing | GCP | us-central1 | `bros.us-central1.conveyor.stable.gcp.groupondev.com` |
| Staging EMEA | Pre-production EMEA testing | GCP | europe-west1 | `bros.europe-west1.conveyor.stable.gcp.groupondev.com` |
| Production NA (GCP) | Live NA traffic | GCP | us-central1 | `bros.us-central1.conveyor.prod.gcp.groupondev.com` |
| Production EMEA (AWS) | Live EMEA traffic | AWS | eu-west-1 | `bros.prod.eu-west-1.aws.groupondev.com` |
| Production EMEA (GCP) | Live EMEA traffic | GCP | europe-west1 | `bros.europe-west1.conveyor.prod.gcp.groupondev.com` |

Legacy on-premises VIPs (registered in `.service.yml`) still route traffic in some colos:
- SNC1 production: `http://global-payments-config-service-us.snc1`
- SAC1 production: `http://global-payments-config-service-us.sac1`
- DUB1 production: `http://global-payments-config-service-row.dub1`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch; branches matching `/^GPP-\d+/`
- **Library**: `java-pipeline-dsl@latest-2` (JTier shared pipeline)
- **Slack channel**: `orders-and-payments`
- **Deploy targets**: `staging-us-central1`, `staging-europe-west1` (auto-deploy on master merge)
- **Releasable branches**: `master`

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles, runs unit tests, integration tests, and code quality checks (FindBugs, PMD — PMD currently skipped)
2. **Docker build**: `mvn install -DskipTests=true -DskipDocker=false` — builds Docker image tagged `docker-conveyor.groupondev.com/payments/billing-record-options-service:<version>`
3. **Docker push**: Pushes image to JFrog Artifactory Docker registry
4. **Deploy to staging**: Deploys to `staging-us-central1` and `staging-europe-west1` via `krane` using the `cmf-jtier-api` Helm chart
5. **Production deploy**: Triggered manually by Deploybot for production environments

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Staging) | HPA | Min: 1, Max: 2 replicas |
| Horizontal (Production NA) | HPA | Min: 2, Max: 15, target utilization: 25% |
| Horizontal (Production EMEA AWS) | HPA | Min: 6, Max: 15, target utilization: 25% |
| Horizontal (Production EMEA GCP) | HPA | Min: 2, Max: 15, target utilization: 25% |
| Vertical Pod Autoscaler | Disabled | `enableVPA: false` |

## Resource Requirements

| Resource | Request (Staging/Common) | Limit (Staging/Common) | Request (Production) | Limit (Production) |
|----------|--------------------------|------------------------|---------------------|-------------------|
| CPU | 125m | 400m | 125m | 400m |
| Memory | 2Gi | 4Gi | 4Gi | 8Gi |
| Disk | Not specified | Not specified | Not specified | Not specified |

## Ports

| Port | Role |
|------|------|
| 8080 | HTTP application port (exposed on Kubernetes service port 80) |
| 8081 | Admin port (exposed via `exposedPorts: admin-port: 8081`) |

## APM

Application Performance Monitoring is enabled for regions `eu-west-1` and `us-central1` (`apm.enabled: true` in common.yml).
