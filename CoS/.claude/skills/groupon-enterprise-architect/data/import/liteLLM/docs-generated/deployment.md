---
service: "liteLLM"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1, staging-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

LiteLLM is deployed as a containerized Kubernetes workload across four environments: staging and production in US-Central1 (GCP), staging in Europe-West1 (GCP), and production in EU-West-1 (AWS). The upstream open-source Docker image (`litellm/litellm`) is pulled, retagged, and pushed to the Groupon internal Docker registry (`docker-conveyor.groupondev.com/conveyor-cloud/litellm`). Deployments are orchestrated via DeployBot using Helm (`cmf-generic-api` chart v3.96.1) and applied to Kubernetes via `krane`. Horizontal Pod Autoscaling (HPA) is active in all environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | Source: `litellm/litellm`; internal registry: `docker-conveyor.groupondev.com/conveyor-cloud/litellm`; version pinned via `appVersion` in `common.yml` |
| Local Dockerfile | Docker | `Dockerfile` is a stub (`FROM alpine`); actual runtime image is the upstream LiteLLM image |
| Orchestration | Kubernetes (GCP + AWS) | Namespace `litellm-staging` or `litellm-production`; deployment name `litellm--api--default` |
| Helm chart | `cmf-generic-api` v3.96.1 | Sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/`; rendered via `deploy.sh` |
| Deploy tool | DeployBot + krane | DeployBot at `deploybot.groupondev.com/conveyor-cloud/litellm`; krane applies rendered manifests |
| Load balancer | GCP / AWS cloud load balancer | Managed by Kubernetes Service; `hybridBoundary` config exposes public and default namespaces |
| CDN | None | No evidence of CDN configuration |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Staging for US region | GCP us-central1 | `https://litellm-staging.groupondev.com` |
| production-us-central1 | Production for US region | GCP us-central1 | `https://litellm.groupondev.com` |
| staging-europe-west1 | Staging for EU region | GCP europe-west1 | Not configured |
| production-eu-west-1 | Production for EU region | AWS eu-west-1 | Not configured |

## CI/CD Pipeline

- **Tool**: Jenkins (primary build pipeline) + GitHub Actions (image build)
- **Config**: `Jenkinsfile` (Docker build pipeline); `.github/workflows/litellm_build_image.yaml` (image pull/retag/push)
- **Trigger**: Pull request to `main` (when `.meta/deployment/cloud/components/litellm/**` changes) or manual `workflow_dispatch`

### Pipeline Stages

1. **Version Detection**: GitHub Actions reads `appVersion` from changed YAML files in the PR; compares current vs. base branch values.
2. **Registry Check**: Verifies whether the new image version already exists in `docker-conveyor.groupondev.com/conveyor-cloud/litellm`.
3. **Image Pull**: Pulls the upstream `litellm/litellm:<version>` image from Docker Hub.
4. **Image Retag**: Tags the upstream image as `docker-conveyor.groupondev.com/conveyor-cloud/litellm:<version>`.
5. **Image Push**: Pushes the retagged image to the Groupon internal registry.
6. **Staging Deploy**: DeployBot triggers `deploy.sh staging-us-central1 staging litellm-staging`; Helm renders manifests; krane applies to `gcp-stable-us-central1`.
7. **Production Promote**: After staging validation, DeployBot promotes to `production-us-central1` via `deploy.sh production-us-central1 production litellm-production`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Staging US) | HPA (CPU + memory) | Min: 2, Max: 3; CPU target: 50%, Memory target: 75% |
| Horizontal (Production US) | HPA (CPU + memory) | Min: 3, Max: 10; CPU target: 50%, Memory target: 75% |
| Horizontal (Staging EU) | HPA | Min: 1, Max: 2 |
| Horizontal (Production EU) | HPA | Min: 2, Max: 15 |
| VPA | Disabled | `enableVPA: false` in staging and production US |

## Resource Requirements

| Resource | Staging US Request | Staging US Limit | Production US Request | Production US Limit |
|----------|-------------------|------------------|----------------------|---------------------|
| CPU | 200m | (not set) | 200m | (not set) |
| Memory | 1Gi | 2Gi | 1.75Gi | 3.5Gi |
| Disk | Not configured | Not configured | Not configured | Not configured |

## Ports

| Port | Purpose |
|------|---------|
| 4000 | Main HTTP API (OpenAI-compatible inference + health probes) |
| 8081 | Admin UI and management API |
| 25 | Egress to SMTP relay (allowed by NetworkPolicy) |

## Health Probes

| Probe | Path | Port | Initial Delay | Period | Timeout |
|-------|------|------|--------------|--------|---------|
| Readiness | `/health/readiness` | 4000 | 30s | 20s | 10s |
| Liveness | `/health/liveliness` | 4000 | 30s | 20s | 10s |
