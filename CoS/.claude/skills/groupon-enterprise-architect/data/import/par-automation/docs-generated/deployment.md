---
service: "par-automation"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [sandbox, staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

PAR Automation is deployed as a containerized Go binary in a Docker image built via a multi-stage Dockerfile (builder stage: `golang:1.20`; runtime stage: `alpine:latest`). It runs as a Kubernetes Deployment on GCP, managed by Conveyor using CMF Helm charts (`cmf-generic-api` chart version `3.90.1`). Deployments are triggered manually through Deploybot after Jenkins builds and pushes the Docker image.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` — builder: `golang:1.20`, runtime: `alpine:latest`, entrypoint: `./main`, port 8080 |
| Orchestration | Kubernetes (GCP Conveyor) | Manifests rendered via `cmf-generic-api` Helm chart; deployed with `krane` |
| Helm chart | `cmf-generic-api` | Version `3.90.1`, from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Load balancer | Istio ingress gateway | Enabled on staging (`enableGateway: true`); disabled on production (`enableGateway: false`) |
| Image registry | `docker-conveyor.groupondev.com/service-mesh-gcp/par-automation` | Built by Jenkins, pushed on main branch |

## Environments

| Environment | Purpose | Region | Notes |
|-------------|---------|--------|-------|
| sandbox (gensandbox) | Developer testing | GCP | `ENV=sandbox`; no Jira tickets created |
| staging-us-central1 | Pre-production validation (US) | GCP us-central1 | `ENV=staging`; Jira sandbox instance |
| staging-europe-west1 | Pre-production validation (EU) | GCP europe-west1 | `ENV=staging`; Jira sandbox instance |
| production-us-central1 | Live traffic (US/Canada) | GCP us-central1 | `ENV=production`; real Jira tickets created |
| production-europe-west1 | Live traffic (EMEA) | GCP europe-west1 | `ENV=production`; real Jira tickets created |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch
- **Deployment trigger**: Manual — via [Deploybot](https://deploybot.groupondev.com/service-mesh-gcp/par-automation)

### Pipeline Stages

1. **Build Docker image**: Jenkins runs `dockerBuildPipeline` shared library, builds the multi-stage Docker image, and pushes it to `docker-conveyor.groupondev.com/service-mesh-gcp/par-automation`
2. **Deploy (manual)**: Engineer triggers deployment in Deploybot; Deploybot runs `.meta/deployment/cloud/scripts/deploy.sh` with the target environment and Helm value files, then applies with `krane deploy` to the appropriate GKE cluster

### Development Flow

1. Submit a PR against `main`
2. Ensure CI checks pass before requesting review
3. Get PR approved and merge to `main`
4. Wait for Jenkins pipeline to complete (image push)
5. Trigger deployment in Deploybot for each target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | `minReplicas: 2`, `maxReplicas: 15` (common); production/staging override to min 1, max 2 per region |
| HPA target | CPU utilization | `hpaTargetUtilization: 50` (50%) |
| Memory | Not configured in visible manifests | — |
| CPU | Not configured in visible manifests | — |

## Resource Requirements

> No evidence found in codebase. CPU and memory requests/limits are not specified in the visible Helm value files; they are likely set in the `cmf-generic-api` chart defaults or in the secrets submodule.

## Health Probes

Both readiness and liveness probes are configured to call `GET /release/healthcheck` on port 8080. These are defined in `common.yml`:

```yaml
probes:
  readiness:
    path: "/release/healthcheck"
    port: 8080
  liveness:
    path: "/release/healthcheck"
    port: 8080
```
