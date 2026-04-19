---
service: "goods-shipment-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

The Goods Shipment Service is containerized using Docker and deployed to Google Cloud Platform (GCP) Kubernetes clusters via Helm charts rendered with `helm3` and applied by Krane. It runs as three Kubernetes components: `app` (REST API), `worker` (background Quartz jobs), and `public` (public-facing API). The deployment is managed by Raptor/DeployBot using Helm chart `cmf-jtier-api` (version 3.94.0) and `cmf-jtier-worker` (version 3.94.0).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (prod runtime); `.ci/Dockerfile` (CI build); base image `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes (GCP) | Helm charts `cmf-jtier-api` and `cmf-jtier-worker` v3.94.0; deployed via Krane |
| App image | Docker | `docker-conveyor.groupondev.com/inventory/goods-shipment-service` |
| Load balancer | GCP internal LB | HTTP port 8080 exposed as `httpPort`; admin port 8081 and JMX port 8009 as `exposedPorts` |
| CDN | None | Not configured |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Pre-production testing | GCP us-central1 | Internal only (namespace: `goods-shipment-service-staging-sox`) |
| staging-europe-west1 | Pre-production testing (EU) | GCP europe-west1 | Internal only |
| production-us-central1 | Production (US/NA) | GCP us-central1 | Internal: `http://goods-shipment-service-vip.snc1` |
| production-europe-west1 | Production (EU/EMEA) | GCP europe-west1 | Internal: `http://goods-shipment-service-vip.dub1` |

Legacy data-centre URLs (still registered in `.service.yml`):

| Data Centre | Environment | Internal URL |
|-------------|-------------|-------------|
| snc1 | production | `http://goods-shipment-service-vip.snc1` |
| snc1 | staging | `http://goods-shipment-service-staging-vip.snc1` |
| snc1 | uat | `http://goods-shipment-service-uat-vip.snc1` |
| sac1 | production | `http://goods-shipment-service-vip.sac1` |
| dub1 | production | `http://goods-shipment-service-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch or tags matching `staging-.*`
- **Shared library**: `java-pipeline-dsl@latest-2`

### Pipeline Stages

1. **Build**: Maven build with Docker (`skipDocker: false`); includes git submodule checkout (`cloneSubModules: true`)
2. **Test**: `mvn clean verify` (unit tests, integration tests, JaCoCo, PMD, FindBugs)
3. **Docker push**: Publishes image to `docker-conveyor.groupondev.com/inventory/goods-shipment-service`
4. **Deploy to staging**: Automatic deployment to `staging-us-central1` and `staging-europe-west1` on `master` build

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | HPA (target utilisation 100%) + VPA enabled | Min 4 / Max 15 replicas |
| Horizontal (staging) | HPA (target utilisation 100%) + VPA enabled | Min 1 / Max 5 replicas |
| Memory (production) | Request/Limit | 3Gi request / 9Gi limit |
| Memory (staging) | Request/Limit | 3Gi request / 9Gi limit |
| CPU (production) | Request only | 500m request (limit managed by VPA) |
| CPU (staging) | Request only | 100m request |

## Resource Requirements

| Resource | Request (production) | Limit (production) |
|----------|---------------------|-------------------|
| CPU | 500m | VPA-managed |
| Memory | 3Gi | 9Gi |
| Disk | — | — |
