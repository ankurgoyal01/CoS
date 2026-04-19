---
service: "goods-inventory-service-routing"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The service is containerized with Docker and deployed to Google Cloud Platform (GCP) Kubernetes clusters via the JTier/Raptor deployment platform. Staging runs in the `stable` VPC (us-central1) and production runs in the `prod` VPC (us-central1). Deployments are triggered through DeploybotV2 and require manual authorization. The CI/CD pipeline is Jenkins-based using the shared `java-pipeline-dsl` library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| CI build container | Docker | `.ci/Dockerfile` — base image `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |
| Orchestration | Kubernetes (GKE) | Raptor manifests in `.meta/deployment/cloud/components/routing/` |
| Container registry | docker-conveyor.groupondev.com | Image: `docker-conveyor.groupondev.com/inventory/goods-inventory-service-routing` |
| Load balancer | Hybrid Boundary (internal) | Configures `X-HB-Region` routing sidecar; `isDefaultDomain: false` for the routing component |
| CDN | None (internal service) | — |

## Environments

| Environment | Purpose | Region | Namespace |
|-------------|---------|--------|-----------|
| Development | Local developer iteration | localhost | N/A |
| Staging | Pre-production validation | GCP us-central1 (`stable` VPC) | `goods-inventory-service-staging` |
| Production | Live traffic | GCP us-central1 (`prod` VPC) | `goods-inventory-service-production` |

## CI/CD Pipeline

- **Tool**: Jenkins (shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch; releasable branches: `master`
- **Slack notifications**: `#goods-eng-seattle`
- **Submodule clone**: enabled (`cloneSubModules: true`)
- **Auto-deploy target**: `staging-us-central1`

### Pipeline Stages

1. **Build**: Maven build with `mvn clean verify` inside the `.ci/docker-compose.yml` test container
2. **Test**: Unit and integration tests (JUnit 5, Dropwizard testing, DaaS testing)
3. **Docker image build**: Produces image tagged with version and pushed to `docker-conveyor.groupondev.com/inventory/goods-inventory-service-routing`
4. **Deploy to staging**: Automatic deploy to `staging-us-central1` via DeploybotV2 / Raptor on successful master build
5. **Promote to production**: Manual action in DeploybotV2 — select staging version, click **PROMOTE** and then **AUTHORIZE**
6. **Rollback**: Click **ROLLBACK** in DeploybotV2 to revert to the previous production version
7. **Smoke test**: `src/main/resources/smoke_test/smoke_test.rb` (Ruby/Minitest) validates `/grpn/status` endpoint post-deploy

## Scaling

| Environment | Dimension | Strategy | Min | Max |
|-------------|-----------|----------|-----|-----|
| Staging | Horizontal | Kubernetes HPA | 1 | 15 |
| Production | Horizontal | Kubernetes HPA | 3 | 15 |

HPA target utilization is set to `100` in the common Raptor config (i.e., scale out when current load reaches the resource request).

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 250m | 500m |
| Memory | 2 Gi | 3 Gi |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 1500m |
| Memory | 2 Gi | 4 Gi |

### Ports

| Port | Purpose |
|------|---------|
| `8080` | HTTP application traffic (Kubernetes service) |
| `8081` | Dropwizard admin port (metrics, health) |

## Database Deployment

Flyway-style migrations are managed by JTier DaaS and are applied automatically during deployment. Migration scripts are located in `src/main/resources/db/migration/`. The baseline migration (`V0__add_inventory_product_shipping_regions_table.sql`) creates the `inventory_product_shipping_regions` table.
