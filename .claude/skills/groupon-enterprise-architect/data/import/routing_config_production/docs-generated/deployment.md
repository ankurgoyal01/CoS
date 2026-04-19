---
service: "routing_config_production"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["production-us-west-1", "production-eu-west-1", "production-us-central1", "production-europe-west1", "on-prem-snc1", "on-prem-sac1", "on-prem-dub1"]
---

# Deployment

## Overview

`routing_config_production` is deployed as a Docker image containing the compiled Flexi routing configuration under `/var/conf`. The CI/CD pipeline (Jenkins) renders templates, validates the config, builds the image, and then updates Kustomize overlays in a separate `routing-deployment` repository to trigger a rolling deployment to Kubernetes-managed routing service pods in four production regions. A legacy on-premises SSH-based deployment path also exists, targeting up to 10 routing app nodes in each of three data centers.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (config image) | Docker / BusyBox 1.29.1 | `Dockerfile` — copies `src/` to `/var/conf`; image tag: `docker-conveyor.groupondev.com/routing/routing-config:production_<version>` |
| CI Docker (build/test) | Docker / `routing-config-ci:0.4.0` | `.ci/Dockerfile` — provides Java 1.8 + Gradle for validation |
| Orchestration (cloud) | Kubernetes via Kustomize | `routing-deployment` repo overlays; image tags updated by `update_deployment.sh` |
| Orchestration (on-prem) | Direct SSH via Gradle SSH plugin | Deploys tarball (`build/routing-config.tgz`) to `/var/groupon/routing-config-2/releases/<timestamp>/` |
| CI system | Jenkins | `Jenkinsfile` at repo root; node label `dind_2gb_2cpu` |
| Container registry | `docker-conveyor.groupondev.com` | Internal Groupon Docker registry |
| Deployment repo | `routing-deployment` (GitHub Enterprise) | Holds Kustomize overlays; receives image tag commits and deploy Git tags |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production-us-west-1 | Cloud production (AWS US West) | US West | Kustomize overlay: `routing-service-production-us-west-1` |
| production-eu-west-1 | Cloud production (AWS EU West) | EU West | Kustomize overlay: `routing-service-production-eu-west-1` |
| production-us-central1 | Cloud production (GCP US Central) | US Central | Kustomize overlay: `routing-service-production-us-central1` |
| production-europe-west1 | Cloud production (GCP Europe West) | Europe West | Kustomize overlay: `routing-service-production-europe-west1` |
| on-prem-snc1 | On-premises production (US) | Santa Clara DC | `routing-app[1-10].snc1` |
| on-prem-sac1 | On-premises production (US) | Sacramento DC | `routing-app[1-10].sac1` |
| on-prem-dub1 | On-premises production (EU) | Dublin DC | `routing-app[1-10].dub1` (via bastion `b.dub1.groupon.com`) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` or `release` branch; PR builds run test/validate only (no publish or deploy)

### Pipeline Stages

1. **Prepare**: Computes version (`<date>_<short-sha>`), determines releasable-branch status, renders Jinja2 Flexi templates via `docker-compose run test python render_templates.py`
2. **Test**: Runs `./gradlew validate` inside the CI Docker container to compile and validate all Flexi DSL files
3. **Publish**: Builds Docker image tagged `docker-conveyor.groupondev.com/routing/routing-config:production_<version>` and pushes to internal registry (only on releasable branches)
4. **Update versions and initiate deploy**: Clones `routing-deployment` repo, runs `update_deployment.sh` to set image tags in Kustomize overlays for all four cloud environments, commits, pushes, and applies `eu_deploy-<version>`, `us_deploy-<version>`, `gcp-eu_deploy-<version>`, and `gcp-us_deploy-<version>` Git tags to trigger the deployment pipeline

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (on-prem) | Fixed pool of 10 app nodes per data center | `routing-app[1-10].<dc>` in `build.gradle` |
| Horizontal (cloud) | Managed by Kubernetes HPA in routing-deployment repo | Not directly visible in this repo |
| Memory | Managed by routing service runtime | Not visible in this config repo |
| CPU | Managed by routing service runtime | Not visible in this config repo |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally. | — |
| Memory | Deployment configuration managed externally. | — |
| Disk | Config artifact is small (Flexi text files in BusyBox image) | — |

> The config Docker image itself is minimal (BusyBox 1.29.1 + text files). Compute resource requirements belong to the routing service runtime, not this config repo.
