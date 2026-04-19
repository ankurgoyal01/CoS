---
service: "billing-record-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-us-west-1", "staging-us-west-2", "staging-europe-west1", "production-us-west-1", "production-us-central1", "production-eu-west-1"]
---

# Deployment

## Overview

Billing Record Service is a containerized Java WAR application packaged as a Docker image and deployed to Kubernetes clusters across multiple AWS and GCP regions. The CI/CD pipeline is Jenkins-based, using the internal `java-pipeline-dsl` shared library. Deployment to staging is automatic from the master branch; promotion to production is managed via deploy-bot targets. Kubernetes deployment manifests are managed in `.meta/deployment/cloud/`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (base: `maven:3.9.6-ibmjava-8`); image: `docker-conveyor.groupondev.com/com.groupon.billingrecord/billing-record-service` |
| Orchestration | Kubernetes | Manifest configuration in `.meta/deployment/cloud/components/app/`; deployed via `deploy.sh` script |
| Application server | Apache Tomcat 7 | WAR deployed to Tomcat; HTTP port 8080 |
| Build system | Maven 3 | `Dockerfile.tomcat` / `docker/build/Dockerfile` for build image |
| Database migrations | Liquibase + Capistrano | Schema changes applied via `Capfile.liquibase` before application deployment |
| Load balancer | Kubernetes Service | Traffic directed to pods on port 8080; healthcheck at `/grpn/healthcheck` and `/heartbeat.txt` |

## Environments

| Environment | Purpose | Region / Cloud | Notes |
|-------------|---------|----------------|-------|
| staging-us-central1 | Staging | GCP us-central1 | Promoted to production-us-central1; min 1 replica |
| staging-us-west-1 | Staging | AWS us-west-1 | Promoted to production-us-west-1; min 1 replica |
| staging-us-west-2 | Staging | AWS us-west-2 | EMEA proxy staging; min 1 replica |
| staging-europe-west1 | Staging | GCP europe-west1 | Promoted to production-eu-west-1; min 1 replica |
| production-us-west-1 | Production NA | AWS us-west-1 | Min 2 / max 15 replicas; namespace `billing-record-service-production` |
| production-us-central1 | Production NA | GCP us-central1 | Min 2 / max 15 replicas; namespace `billing-record-service-production` |
| production-eu-west-1 | Production EMEA | AWS eu-west-1 | Min 4 / max 15 replicas; datacenter `dub1`; namespace `billing-record-service-production` |

## CI/CD Pipeline

- **Tool**: Jenkins (using `java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch or `(*_deploy)` branches; manual dispatch also supported
- **Docker image registry**: `docker-conveyor.groupondev.com`
- **Deploy notification channel**: `#billing-record-servic` (Slack)

### Pipeline Stages

1. **Checkout**: Clones the repository (full clone, no shallow)
2. **Build**: Runs Maven build with `-DskipTests=true` for packaging; produces WAR artifact
3. **Test**: Runs integration tests via `docker-compose -f .ci/docker-compose.yml run test`
4. **Docker Build**: Builds and tags Docker image with the project version
5. **Docker Push**: Pushes image to `docker-conveyor.groupondev.com`
6. **Validate Deploy Config**: Validates Kubernetes deployment YAML
7. **Deploy to Staging**: Deploys to `staging-us-central1`, `staging-us-west-2`, `staging-europe-west1` automatically on releasable branches
8. **Deploy to Production**: Triggered via deploy-bot `promote_to` after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 1 / max 5 replicas |
| Horizontal (production NA) | Kubernetes HPA | min 2 / max 15 replicas; target utilization 50% |
| Horizontal (production EMEA) | Kubernetes HPA | min 4 / max 15 replicas; target utilization 50% |
| Memory | Vertical limit | Request: 3Gi / Limit: 5Gi (common.yml) |
| CPU | Vertical request | Request: 500m (common.yml) |
| VPA | Disabled | `enableVPA: false` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | Not specified |
| Memory | 3Gi | 5Gi |
| JVM Heap | Xms 1024M | Xmx 4096M (via `JAVA_OPTS`) |
| JMX Port | 9111 | Exposed via `exposedPorts.jmx-port` |

> Health probes: readiness at `/grpn/healthcheck` (initial delay 180s, period 5s, timeout 5s); liveness at `/grpn/healthcheck` (initial delay 200s, period 15s, timeout 5s). Deployment timeout override: 10 minutes (`krane.shopify.io/timeout-override`).
