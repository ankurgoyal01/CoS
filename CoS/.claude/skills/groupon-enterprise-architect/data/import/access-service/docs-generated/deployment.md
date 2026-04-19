---
service: "mx-merchant-access"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [production-us-central1, production-eu-west-1, production-europe-west1, staging-us-central1, staging-europe-west1, staging-us-west-2]
---

# Deployment

## Overview

The Merchant Access Service runs as a Dockerized Java/Tomcat application on Kubernetes, deployed via the Groupon Conveyor platform. The application is packaged as a WAR file deployed into Apache Tomcat 8.5.73 (JRE 11 Temurin). Kubernetes deployments are managed with Helm (`cmf-java-api` chart, version 3.88.1) and applied using `krane`. Two deployment tiers exist: SOX-scoped instances (read-write, for compliance-relevant services) and non-SOX instances (read-only, for general internal consumers). Deployments target multiple cloud regions across GCP and AWS.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `access-webapp/src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java11:2021-10-14-2047f4d`; WAR deployed to Tomcat `webapps/ROOT.war` |
| Orchestration | Kubernetes (GCP GKE, AWS EKS) | Helm chart `cmf-java-api` v3.88.1; manifests generated from `.meta/deployment/cloud/` |
| Deployment tool | krane | Applied via `.meta/deployment/cloud/scripts/deploy.sh` |
| Registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/com.groupon.mx/access-webapp` |
| Load balancer | VIP (internal) | Per-colo VIP addresses defined in `.service.yml` |

## Environments

| Environment | Purpose | Region / Cloud | Internal URL |
|-------------|---------|----------------|--------------|
| production (US, SAC1) | Production SOX read-write | sac1 | `http://merchant-access-us-sox-vip.sac1` |
| production (US, SAC1) | Production non-SOX read-only | sac1 | `http://merchant-access-us-vip.sac1` |
| production (US, SNC1) | Production SOX read-write | snc1 | `http://merchant-access-us-sox-vip.snc1` |
| production (US, SNC1) | Production non-SOX read-only | snc1 | `http://merchant-access-us-vip.snc1` |
| production (EMEA, DUB1) | Production SOX read-write | dub1 | `http://merchant-access-emea-sox-vip.dub1` |
| production (EMEA, DUB1) | Production non-SOX read-only | dub1 | `http://merchant-access-emea-vip.dub1` |
| staging (US SNC1) | Staging US | snc1 | `http://merchant-access-us-staging-vip.snc1` |
| staging (EMEA SNC1) | Staging EMEA | snc1 | `http://merchant-access-emea-staging-vip.snc1` |
| cloud (GCP us-central1, prod) | GCP production US | us-central1 | Kubernetes namespace: `mx-merchant-access-production-sox` |
| cloud (GCP europe-west1, prod) | GCP production EU | europe-west1 | Kubernetes namespace: `mx-merchant-access-production-sox` |
| cloud (AWS eu-west-1, prod) | AWS production EU | eu-west-1 | Kubernetes namespace: `mx-merchant-access-production-sox` |
| cloud (GCP us-central1, staging) | GCP staging US | us-central1 | Kubernetes namespace: `mx-merchant-access-staging-sox` |

## CI/CD Pipeline

- **Tool**: Jenkins (`java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master`, `release`, or `MCE-.*` branches; manual dispatch
- **Docker registry**: `docker-conveyor.groupondev.com`
- **Deployment tool**: deploybot (`https://deploybot.groupondev.com/sox-inscope/access-service`)

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles sources, generates service-discovery schema, packages WAR
2. **Unit tests**: Maven Surefire — excludes `*IntegrationTest`
3. **Integration tests (INTL)**: `mvn verify -PrunITs -Dprofile=intl-it-server` in Docker Compose
4. **Integration tests (US)**: `mvn verify -PrunITs -Dprofile=us-it-server` in Docker Compose
5. **Docker build and push**: Builds image with `dockerfile-maven-plugin` (Spotify), pushes to Conveyor registry
6. **Deploy to staging**: Auto-deploy to `staging-us-central1` and `staging-europe-west1` on releasable branches

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes) | Production: min 2, max 15 replicas, target 50% utilization; Staging: min 1, max 2 |
| VPA | Disabled | `enableVPA: false` in `common.yml` |
| Memory | JVM heap + container limits | Production US: request 6 Gi / limit 8 Gi; Production EU: request 2 Gi / limit 4 Gi; Staging: request 3 Gi / limit 4 Gi |
| CPU | Container requests/limits | Production US: request 1400m / limit 2000m; Production EU + Staging: request 700m / limit 1000m |

## Resource Requirements

| Resource | Request (Production US) | Limit (Production US) |
|----------|------------------------|----------------------|
| CPU (main) | 1400m | 2000m |
| Memory (main) | 6 Gi | 8 Gi |
| CPU (filebeat) | 100m | 2000m |
| Memory (filebeat) | 200 Mi | 400 Mi |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | Main HTTP application port (readiness/liveness probes) |
| 8081 | Admin port (exposed as `admin-port`) |
| 8009 | JMX/RMI port (exposed as `jmx-port`) |
