---
service: "librechat"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-central1, staging-us-central1, staging-europe-west1, staging-us-west-2, rde-dev-us-west-2, rde-staging-us-west-2, production-us-central1, production-europe-west1, production-us-west-2, production-eu-west-1]
---

# Deployment

## Overview

LibreChat is deployed as a **modular multi-container system** on Kubernetes (GCP and AWS), managed through Groupon's Conveyor/Raptor internal deployment platform. Each of the five components (app, mongodb, meilisearch, rag-api, vectordb) is packaged as a separate Helm-rendered Kubernetes deployment or statefulset and deployed together via a single `deploy.sh` script using `helm3 template` + `krane deploy`. All five components run in a shared namespace (`librechat-production` or `librechat-staging`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (app) | Docker (Node.js 20 Alpine) | `Dockerfile` at repo root; image `docker-conveyor.groupondev.com/gsilva/librechat` |
| Container (RAG API) | Docker (Python) | Image `docker-conveyor.groupondev.com/gsilva/librechat-rag-api-dev-lite` |
| Container (MongoDB) | Docker (Bitnami MongoDB) | Image `docker-conveyor.groupondev.com/bitnami/mongodb` v8.0.3-debian-12-r0 |
| Container (Meilisearch) | Docker (Meilisearch) | Image `docker-conveyor.groupondev.com/getmeili/meilisearch` v1.7.3 |
| Container (VectorDB) | Docker (pgvector) | Image `docker-conveyor.groupondev.com/ankane/pgvector` v0.5.1 |
| Orchestration | Kubernetes + Helm 3 | Helm chart `cmf-generic-api` / `cmf-generic-worker` v3.91.3-SNAPSHOT |
| Deployment tool | krane | `krane deploy librechat-<env>` with 300s global timeout |
| Config post-processing | Kustomize | Overlays in `.meta/kustomize/overlays/<component>/<production|staging>/` |
| Load balancer | Kubernetes Service (HybridBoundary) | `hybridBoundary` subdomain routing per component |
| Secrets | Kubernetes secrets (submodule) | `git@github.groupondev.com:conveyor-cloud/librechat-secrets.git` |
| Deploy pipeline | DeployBot | `.deploy_bot.yml` defines targets and deploy commands |

## Environments

| Environment | Purpose | Cloud | Region | URL |
|-------------|---------|-------|--------|-----|
| dev-us-central1 | Developer testing | GCP | us-central1 | Internal dev subdomain |
| staging-us-central1 | Pre-production validation | GCP | us-central1 | `https://librechat-staging.groupondev.com` |
| staging-europe-west1 | Pre-production EU validation | GCP | europe-west1 | Internal staging subdomain |
| staging-us-west-2 | Pre-production US West validation | AWS | us-west-2 | Internal staging subdomain |
| rde-dev-us-west-2 | RDE developer environment | AWS | us-west-2 | Internal |
| rde-staging-us-west-2 | RDE staging environment | AWS | us-west-2 | Internal |
| production-us-central1 | Production — US/Canada | GCP | us-central1 | `https://librechat.production.service.us-central1.gcp.groupondev.com` |
| production-europe-west1 | Production — EMEA (GCP) | GCP | europe-west1 | Internal production subdomain |
| production-us-west-2 | Production — US West | AWS | us-west-2 | Internal production subdomain |
| production-eu-west-1 | Production — EMEA (AWS) | AWS | eu-west-1 | Internal production subdomain |

## CI/CD Pipeline

- **Tool**: DeployBot (Groupon's internal continuous delivery system)
- **Config**: `.deploy_bot.yml`
- **Trigger**: Manual dispatch via DeployBot; staging promotes to production after validation

### Pipeline Stages

1. **Helm template rendering**: `helm3 template cmf-generic-api/cmf-generic-worker` merges `common.yml` + secrets + `<env>.yml` for each component
2. **Kustomize post-processing**: Kustomize overlays applied to rendered manifests per component and environment
3. **krane deploy**: All five component manifests are piped to `krane deploy librechat-<env>` for Kubernetes apply with a 300s global timeout
4. **Promotion**: Staging targets define `promote_to` fields; `staging-us-central1` promotes to `production-us-central1`, `staging-europe-west1` promotes to `production-europe-west1`

## Scaling

### App Component (`continuumLibrechatApp`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Horizontal Pod Autoscaler) | min: 2 / max: 15 / target CPU: 50% (staging: min 1 / max 2) |
| Memory | Not specified in common config | — |
| CPU | Not specified in common config | — |

### RAG API Component (`continuumLibrechatRagApi`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min: 2 / max: 15 / target CPU: 50% (staging: min 1 / max 5) |

### MongoDB Component (`continuumLibrechatMongodb`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (StatefulSet) | min: 1 / max: 1 (single replica, replica set `rs0`) |
| Memory | Hard limit | request: 500Mi / limit: 500Mi |
| CPU | Request only | request: 1000m |
| Persistent volume | 100G datadir + 50G tmp | StatefulSet volumes |

### Meilisearch Component (`continuumLibrechatMeilisearch`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min: 2 / max: 15 / target CPU: 50% |
| Persistent volume | 100G data + 10G tmp | StatefulSet volumes |

### VectorDB Component (`continuumLibrechatVectordb`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | min: 2 / max: 15 / target CPU: 50% |
| Persistent volume | 50G at `/var/lib/postgresql/` | StatefulSet volume |

## Resource Requirements

### MongoDB

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not set |
| Memory | 500Mi | 500Mi |
| Disk (datadir) | 100G | 100G |
| Disk (tmp) | 50G | 50G |

> App, RAG API, Meilisearch, and VectorDB resource requests/limits are not explicitly configured in the discovered deployment manifests; they inherit platform defaults.
