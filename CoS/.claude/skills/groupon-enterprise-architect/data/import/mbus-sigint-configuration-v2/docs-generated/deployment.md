---
service: "mbus-sigint-configuration-v2"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging-us-west-1, staging-us-central1, production-us-west-1, production-us-central1]
---

# Deployment

## Overview

The service is containerized using a JTier Java 11 Maven base image and deployed to Kubernetes via the `cmf-jtier-api` Helm chart (version 3.88.1). Deployments are orchestrated by DeployBot (`deploy_bot.yml`) using `krane` for rolling deploys. Two cloud environments are maintained: on-prem `us-west-1` (Kubernetes) and GCP `us-central1` (GCP Kubernetes). A legacy on-prem SNC1 Capistrano-based deployment path also exists for the `snc1` datacenter. Kubernetes namespace: `mbus-sigint-config-<environment>`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes | Helm chart `cmf-jtier-api` v3.88.1 via `krane` deploy |
| Load balancer | Internal VIP | `http://mbus-sigint-config-vip.snc1` (production SNC1); Kubernetes service on port 80/8080 |
| CDN | None | Internal service only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | localhost | `http://localhost:9000` (app), `http://localhost:9001` (admin) |
| staging-us-west-1 | Staging (on-prem) | us-west-1 | `http://mbus-sigint-config-staging-vip.snc1` |
| staging-us-central1 | Staging (GCP) | us-central1 (GCP stable) | Kubernetes service (namespace: `mbus-sigint-config-staging`) |
| production-us-west-1 | Production (on-prem) | us-west-1 | `http://mbus-sigint-config-vip.snc1` |
| production-us-central1 | Production (GCP) | us-central1 (GCP prod) | Kubernetes service (namespace: `mbus-sigint-config-production`) |

## CI/CD Pipeline

- **Tool**: Jenkins + DeployBot
- **Config**: `.deploy_bot.yml`, `.meta/deployment/cloud/scripts/deploy.sh`
- **CI URL**: `https://cloud-jenkins.groupondev.com/job/MBus/job/mbus-sigint-configuration-v2/`
- **Trigger**: Version-tagged releases via DeployBot; Slack notifications to `#mbus-deployments` (`GE052NNDC`)
- **Deployment image**: `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`

### Pipeline Stages

1. **Build**: Maven build and Docker image creation using `.ci/Dockerfile`
2. **Test**: Unit and integration tests via `.ci/docker-compose.yml` (shared Docker socket, Maven local repo cache)
3. **Staging Deploy (us-west-1)**: DeployBot runs `deploy.sh staging-us-west-1 staging mbus-sigint-config-staging` via `krane`
4. **Staging Deploy (us-central1)**: DeployBot runs `deploy.sh staging-us-central1 staging mbus-sigint-config-staging` via `krane`
5. **Promote to Production (us-west-1)**: After staging sign-off, `deploy.sh production-us-west-1 production mbus-sigint-config-production`
6. **Promote to Production (us-central1)**: `deploy.sh production-us-central1 production mbus-sigint-config-production`

> Legacy SNC1 stages use Capistrano (`deploy_cap:2.6.5-bundler2`) with canary promote path: `staging` -> `production_canary_snc1` -> `production_snc1`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min: 2, Max: 4, target utilization: 100% (staging-us-central1) |
| Horizontal (production) | HPA | Min: 1, Max: 2, target utilization: 100% (us-west-1); Min: 1, Max: 1 (us-central1) |
| Memory | Kubernetes limits | Request: 1Gi, Limit: 4Gi (common.yml) |
| CPU | Kubernetes limits | Common request: 50m; Production override: 100m |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 50m (common) / 100m (production) | Not explicitly capped (inherits node limit) |
| Memory | 1Gi | 4Gi |
| Disk | Filebeat log volume: `medium` (production) | — |

### Port Mapping

| Port | Purpose |
|------|---------|
| 8080 (`httpPort`) | Application HTTP — main API |
| 8081 (`admin-port`) | Dropwizard admin interface (healthcheck, metrics, tasks) |
| 8009 (`jmx-port`) | JMX monitoring port |

### Docker image

- **Registry**: `docker-conveyor.groupondev.com/mbus/mbus-sigint-config`
- **Maven coordinates**: `com.groupon.mbus:mbus-sigint-configuration-v2`
- **Version scheme**: `1.0.<patch>` where patch is injected by CI
