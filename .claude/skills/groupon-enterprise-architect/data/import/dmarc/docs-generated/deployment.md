---
service: "dmarc"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [rde-dev, staging, production]
---

# Deployment

## Overview

The DMARC service is packaged as a Docker container and deployed to Kubernetes clusters across multiple AWS regions and one GCP region. Deployment is managed by DeployBot using Helm chart `cmf-generic-api` (version `3.89.0`). The CI pipeline is Jenkins-based (`Jenkinsfile`) and produces the Docker image `docker-conveyor.groupondev.com/mta/dmarc`. A Filebeat sidecar is co-deployed to ship application logs to ELK.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage build: `golang:alpine3.19` (build), `alpine:latest` (runtime); binary `dmarc_parser`; `Dockerfile` at repo root |
| Orchestration | Kubernetes | Deployed via `krane` with Helm manifests; namespace pattern `dmarc-{staging|production}` |
| Helm chart | cmf-generic-api v3.89.0 | Charts sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy script | Bash | `.meta/deployment/cloud/scripts/deploy.sh` — renders Helm template and applies via `krane` |
| Logging sidecar | Filebeat | Configured in `common.yml`; reads `/app/logs/dmarc_log.log`; `volumeType: medium` |
| HTTP port | 8080 | Internal health-check server (`/grpn/healthcheck`) |
| Admin port | 8081 | Exposed as `admin-port` on the Kubernetes Service |

## Environments

| Environment | Purpose | Region / Cloud | Kubernetes Context |
|-------------|---------|----------------|--------------------|
| rde-dev | Developer sandbox | AWS us-west-2 (gensandbox VPC) | `dmarc-dev` |
| staging-us-west-1 | Staging validation (US/Canada) | AWS us-west-1 (stable VPC) | `dmarc-staging-us-west-1` |
| staging-us-west-2 | Staging validation (EMEA) | AWS us-west-2 (stable VPC) | `dmarc-staging-us-west-2` |
| staging-us-central1 | Staging validation (GCP US) | GCP us-central1 | `dmarc-gcp-staging-us-central1` |
| production-us-west-1 | Production (US/Canada) | AWS us-west-1 (prod VPC) | `dmarc-production-us-west-1` |
| production-us-west-2 | Production (US/Canada) | AWS us-west-2 (prod VPC) | `dmarc-production-us-west-2` |
| production-eu-west-1 | Production (EMEA) | AWS eu-west-1 (prod VPC) | `dmarc-production-eu-west-1` |
| production-us-central1 | Production (GCP US) | GCP us-central1 | `dmarc-gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (repo root)
- **Trigger**: Push to `master` or `gcp` branch
- **Deployment image**: `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0`
- **Notify events**: start, complete, override
- **Datacenter**: snc1 (default), dub1 (EU)

### Pipeline Stages

1. **Build**: `go build .` inside `golang:alpine3.19`; produces `dmarc_parser` binary
2. **Docker image build**: Multi-stage Dockerfile; final image based on `alpine:latest` with `geoip` package
3. **Push**: Image pushed to `docker-conveyor.groupondev.com/mta/dmarc`
4. **Deploy to staging**: DeployBot deploys to `staging-us-west-1` and `staging-us-central1` (configured in `Jenkinsfile` `deployTarget`)
5. **Promote to production**: Staging promotes to corresponding production targets via DeployBot `promote_to` chain (`staging-us-west-1` → `production-us-west-1`; `staging-us-west-2` → `production-eu-west-1`; `staging-us-central1` → `production-us-central1`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | minReplicas: 1, maxReplicas: 1, hpaTargetUtilization: 100 |
| Horizontal (production) | Kubernetes HPA | minReplicas: 2, maxReplicas: 15 |
| Worker goroutines | Configurable via `config.toml` | `workers = 3` (default) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not explicitly configured (inherits Helm chart defaults) | Not explicitly configured |
| Memory | Not explicitly configured (inherits Helm chart defaults) | Not explicitly configured |
| Disk | Filebeat volume: `medium` type; lumberjack log rotation: 200 MB per file, 10 backups | — |

> Explicit CPU and memory request/limit overrides are commented out in all environment YAML files, indicating Helm chart defaults are in use. Set `cpus.main.request` and `memory.main.request/limit` in the appropriate per-environment YAML to override.
