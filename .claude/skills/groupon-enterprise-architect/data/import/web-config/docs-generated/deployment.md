---
service: "web-config"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [uat, staging, production]
---

# Deployment

## Overview

web-config produces Docker images containing generated nginx configuration artifacts. Separate images are built for `uat`, `staging`, and `production` environments during each Jenkins CI run. Images are published to `docker-conveyor.groupondev.com/routing/web-config:{env}_{version}` and then consumed by the `routing-deployment` Kubernetes manifest repository via kustomize image-tag updates. The deployment triggers a rolling update of nginx routing pods across all configured Kubernetes clusters globally.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (config image) | Docker (busybox 1.29.1) | `Dockerfile` — packages `conf/nginx/k8s/{env}/` and `data/{env}/rewrites/` into `/var/conf` |
| Container (validation) | Docker (nginx 1.23.2) | `.ci/docker-compose.yml` — runs `nginx -t` to validate generated config before publish |
| Container (deployment updater) | Docker (kustomize v1.0.11) | `.ci/Dockerfile.deployment` — runs `update_deployment.sh` to patch image tags in `routing-deployment` |
| Orchestration | Kubernetes | `routing-deployment` repo; kustomize overlays per region/environment |
| CI/CD | Jenkins (`java-pipeline-dsl`) | `Jenkinsfile` |
| Image registry | docker-conveyor.groupondev.com | `routing/web-config:{uat,staging,production}_{version}` |
| CDN | Akamai | SureRoute test object served from `/akamai/akamai-sureroute-test-object.htm` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| uat | Pre-production validation | us-west-1, us-west-2, us-central1, europe-west1 | Internal only |
| staging | Staging / pre-prod integration | us-west-1, us-west-2, us-central1, europe-west1 | Internal only |
| production | Live traffic routing | us-west-1 (SNC1), us-central1, eu-west-1 (DUB1), europe-west1 | groupon.com and all international domains |

Legacy on-premises routing hosts were also supported:

| Legacy host group | Environment | Notes |
|-------------------|-------------|-------|
| `routing-app[1-10].snc1` | production (SNC1) | Deployed via `pipenv run fab prod_snc1 deploy:{SHA}` |
| `routing-app[1-10].sac1` | production (SAC1) | Deployed via `pipenv run fab prod_sac1 deploy:{SHA}` |
| `routing-app[1-10].dub1` | production (DUB1) | Deployed via `pipenv run fab prod_dub1 deploy:{SHA}` |
| `routing-app[1-2]-uat.snc1` | UAT | Deployed via `pipenv run fab uat_snc1 deploy` |
| `routing-app1-test.snc1` | test | Deployed via `pipenv run fab test_snc1 deploy` |

## CI/CD Pipeline

- **Tool**: Jenkins (`java-pipeline-dsl@master` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` or `release` branches, or branches matching `*-publish$`; PR builds run validate-only (no publish)

### Pipeline Stages

1. **Prepare**: Computes `version = {YYYY.MM.DD_HH.MM}_{short_sha}`, determines `imageName`, `deploymentRepo`, and whether the build should be published
2. **Build and Test**: Builds three environment-tagged Docker config images (`uat`, `staging`, `production`); starts each image to confirm config was written; runs `nginx -t` validation against the generated config for each environment using the `docker.groupondev.com/routing/nginx:1.23.2-*` image
3. **Publish**: Pushes all three environment images to `docker-conveyor.groupondev.com/routing/web-config` (skipped on PRs and non-releasable branches)
4. **Update versions and initiate deploy**: Clones `routing/routing-deployment`, runs `update_deployment.sh` via the kustomize container to patch image tags in all environment overlays, commits and pushes to `routing-deployment/master`, then creates both `eu_deploy-{version}` and `us_deploy-{version}` tags (plus `gcp-` prefixed variants) to trigger regional Kubernetes deployments

## Scaling

> Deployment configuration managed externally. Replica counts and HPA settings are defined in the `routing-deployment` Kubernetes manifest repository.

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are defined in the `routing-deployment` Kubernetes manifest repository, not in this repository.
