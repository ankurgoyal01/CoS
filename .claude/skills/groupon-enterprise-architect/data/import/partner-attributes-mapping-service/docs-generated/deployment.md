---
service: "partner-attributes-mapping-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

PAMS is deployed as a Docker container on Google Cloud Platform (GCP) Kubernetes clusters, managed by Groupon's JTier deployment platform. The deployment is fully automated via Jenkins CI (Jenkinsfile using `java-pipeline-dsl`) and DeployBot for promotion across environments. The service runs in the `partner-attributes-mapping-service` Kubernetes namespace in both staging and production, each in the `us-central1` region.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI/build) | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java17-maven:2023-12-19-609aedb` |
| Container (production runtime) | Docker | `src/main/docker/Dockerfile` — `docker.groupondev.com/jtier/prod-java17-jtier:3` |
| Container registry | Groupon internal Docker registry | `docker-conveyor.groupondev.com/clo/partner-attributes-mapping-service` |
| Orchestration | Kubernetes (GCP GKE) | Helm chart `cmf-jtier-api` version `3.94.0`; deployed via `krane` |
| Helm chart | `cmf-jtier-api` | Version `3.94.0` from `artifactory.groupondev.com/artifactory/helm-generic/` |
| Deployment tool | `krane` | `--global-timeout=300s`; managed by `deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Load balancer | Kubernetes Service | HTTP port 8080 exposed as port 80; admin port 8081; JMX port 8009 |
| APM | Elastic APM | Enabled in all cloud environments via `common.yml` |
| Log shipping | Filebeat | Source type `partner_attributes_mapping_service`; `medium` volume in production |

## Environments

| Environment | Purpose | Region | GCP VPC |
|-------------|---------|--------|---------|
| Local | Developer workstation (`mvn exec:java` or JAR) | N/A | N/A |
| UAT | Automatic deploy on merge to `main` via DeployBot | snc1 (legacy reference) | N/A (DeployBot managed) |
| Staging | Promoted from UAT; GCP Kubernetes | us-central1 | `stable` |
| Production | Promoted from Staging; GCP Kubernetes | us-central1 | `prod` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch (releasable branch); pull requests trigger validation

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles, runs tests, packages JAR; uses CI Dockerfile for build environment
2. **Docker image**: Builds production Docker image (`src/main/docker/Dockerfile`) and pushes to `docker-conveyor.groupondev.com/clo/partner-attributes-mapping-service`
3. **Deploy to UAT**: DeployBot automatically picks up the new image and deploys to UAT; Slack notification sent to `#clo-notifications`
4. **Promote to Staging**: Manual promote action in DeployBot; deploys to `gcp-stable-us-central1` cluster in `partner-attributes-mapping-service-staging` namespace
5. **Promote to Production**: Manual promote action in DeployBot; deploys to `gcp-production-us-central1` cluster in `partner-attributes-mapping-service-production` namespace

DeployBot deployment command (staging):
```
bash ./.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging partner-attributes-mapping-service-staging
```

DeployBot deployment command (production):
```
bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production partner-attributes-mapping-service-production
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: min 1 / max 3; Production: min 2 / max 15; HPA target CPU utilization: 50% |
| Memory | Container limit | Request: 500Mi; Limit: 2Gi (from `common.yml`) |
| CPU | Container request | Request: 1000m (from `common.yml`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m (1 vCPU) | Not explicitly set (inherits cluster default) |
| Memory | 500Mi | 2Gi |
| Disk | Not specified | Not specified |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application traffic (exposed as port 80 on the Kubernetes Service) |
| 8081 | Dropwizard admin port (health checks, metrics, tasks) |
| 8009 | JMX monitoring port |
