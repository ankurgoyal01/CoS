---
service: "minio"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

MinIO is deployed as a containerized Kubernetes worker using the `cmf-generic-worker` Helm chart (version 3.92.0). The deployment is managed by DeployBot and targets five Kubernetes clusters across two cloud providers (AWS and GCP) in two geographic regions (US and EMEA). The Docker image is sourced from Groupon's internal Conveyor Docker registry and is pinned to a specific upstream MinIO release tag.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (Alpine base) | `Dockerfile` — `FROM alpine`; application image: `docker-conveyor.groupondev.com/minio/minio:RELEASE.2025-09-07T16-13-09Z` |
| Orchestration | Kubernetes | Helm chart: `cmf-generic-worker` v3.92.0 from `artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy tool | krane | Kubernetes resource deployment with 300-second global timeout; manifests streamed from `helm3 template` output |
| Load balancer | Kubernetes Service (internal) | Port 9000 exposed within the cluster; no external ingress configured in this repository |
| CDN | None | Not applicable for an internal object storage service |

## Environments

| Environment | Purpose | Cloud | Region | Kubernetes Cluster |
|-------------|---------|-------|--------|-------------------|
| staging-us-central1 | Staging (US) | GCP | us-central1 | gcp-stable-us-central1 |
| staging-europe-west1 | Staging (EMEA) | GCP | europe-west1 | gcp-stable-europe-west1 |
| production-us-central1 | Production (US) | GCP | us-central1 | gcp-production-us-central1 |
| production-eu-west-1 | Production (EMEA) | AWS | eu-west-1 | production-eu-west-1 |
| production-europe-west1 | Production (EMEA) | GCP | europe-west1 | gcp-production-europe-west1 |

Kubernetes namespaces follow the pattern `minio-{environment}` (e.g., `minio-production`, `minio-staging`).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push (via `dockerBuildPipeline`); auto-deploys to `staging-us-central1`
- **Deployment tool**: DeployBot (`deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`)

### Pipeline Stages

1. **Docker Build**: Builds the Docker image from `Dockerfile` (`FROM alpine`) and publishes to `docker-conveyor.groupondev.com/minio/minio`
2. **Deploy to Staging (us-central1)**: Automatically deploys to `minio-gcp-staging-us-central1` on successful build
3. **Deploy to Production / Other Staging**: Triggered via DeployBot for remaining environments (`staging-europe-west1`, `production-eu-west-1`, `production-europe-west1`, `production-us-central1`)

The deploy script (`deploy.sh`) uses `helm3 template` to render Kubernetes manifests from the `cmf-generic-worker` chart, merging `common.yml`, the environment-specific secrets file, and the environment override file. The rendered manifests are piped into `krane deploy` with a 300-second timeout.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | Min: 1, Max: 2, Target CPU utilization: 100% |
| Horizontal (production US) | Kubernetes HPA | Min: 1, Max: 2, Target CPU utilization: 100% |
| Horizontal (production EMEA) | Kubernetes HPA | Min: 2, Max: 15, Target CPU utilization: 100% |
| Memory | Kubernetes resource limits | Request: 100Mi, Limit: 500Mi |
| CPU | Kubernetes resource requests | Request: 10m (no CPU limit set) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 10m | Not set (burstable) |
| Memory | 100Mi | 500Mi |
| Disk | Depends on volume provisioner | Not specified in Helm values |

## Deployment Command

The MinIO container is started with:
```
minio server /home/shared
```

Data is persisted to the `/home/shared` directory inside the container. The lifecycle hooks (`postStart` and `preStop`) are disabled.
