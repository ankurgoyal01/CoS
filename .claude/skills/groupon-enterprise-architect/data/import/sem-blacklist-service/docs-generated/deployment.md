---
service: "sem-blacklist-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The SEM Blacklist Service is containerized using Docker and deployed to GCP (Google Cloud Platform) on Kubernetes via the Groupon internal deployment toolchain (DeployBot + Raptor + Helm). Two named environments are configured: `staging-us-central1` (GCP stable VPC) and `production-us-central1` (GCP prod VPC). The Jenkins pipeline builds the service using Maven, packages it into a Docker image, and promotes it from staging to production following a staged deployment workflow. Legacy on-premises VIP addresses (`sem-blacklisting-vip.snc1` and `sem-blacklisting-staging-vip.snc1`) are registered in the service discovery configuration and may reflect an older data-center deployment mode.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — based on `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| CI build container | Docker | `.ci/Dockerfile` — based on `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes | Deployed via Helm chart `cmf-jtier-api` version `3.88.1`, manifests in `.meta/deployment/cloud/` |
| Deploy tool | DeployBot + krane | `.deploy_bot.yml` defines targets; `.meta/deployment/cloud/scripts/deploy.sh` runs `helm3 template | krane deploy` |
| Load balancer | Kubernetes Service | Traffic exposed on HTTP port 8080 via Kubernetes service; admin port 8081 exposed separately |
| CDN | None | No CDN evidence found |

## Environments

| Environment | Purpose | Region | URL / Cluster |
|-------------|---------|--------|---------------|
| staging | Integration and pre-production validation | GCP `us-central1` | `gcp-stable-us-central1`; on-prem alias: `http://sem-blacklisting-staging-vip.snc1` |
| production | Live production traffic | GCP `us-central1` | `gcp-production-us-central1`, namespace `sem-blacklist-service-production`; on-prem alias: `http://sem-blacklisting-vip.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` or `DA-9722_section` branches (releasable branches); Slack notifications sent to `sem-deploy` channel

### Pipeline Stages

1. **Build**: Maven build (`mvn clean compile`) and unit test execution using the CI Docker image (`.ci/Dockerfile`)
2. **Package**: Assemble production JAR and build Docker image tagged with build version
3. **Publish**: Push Docker image to `docker-conveyor.groupondev.com/transam/sem-blacklist-service`
4. **Deploy to staging**: DeployBot triggers `staging-us-central1` deployment via `krane deploy` to `gcp-stable-us-central1`
5. **Promote to production**: After staging validation, DeployBot promotes to `production-us-central1` via `krane deploy` to `gcp-production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min 1 / Max 1 replica; `hpaTargetUtilization: 100` |
| Horizontal (production) | Fixed | Min 2 / Max 2 replicas; VPA enabled |
| Vertical | VPA | `enableVPA: true` in both staging and production manifests |

## Resource Requirements

| Resource | Request (common) | Limit (common) | Production override |
|----------|-----------------|----------------|---------------------|
| CPU | 1000m | (not set) | 100m request (VPA manages limits) |
| Memory | 2Gi | 4Gi | 3Gi request |
| Disk | (not specified) | (not specified) | — |

Additional pod containers:
- `filebeat` sidecar: CPU 10m request / 30m limit (log shipping)

## Port Configuration

| Port | Purpose |
|------|---------|
| `8080` | HTTP — application REST API |
| `8081` | Admin port — Dropwizard admin interface, health checks |
| `8009` | JMX — JVM monitoring |

## Docker Image

- **Production image**: `docker-conveyor.groupondev.com/transam/sem-blacklist-service`
- **Base image**: `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb`
- **Docker org**: `transam`
- **Artifact ID**: `sem-blacklist-service`
