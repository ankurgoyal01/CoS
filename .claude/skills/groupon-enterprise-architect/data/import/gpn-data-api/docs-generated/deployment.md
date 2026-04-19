---
service: "gpn-data-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "production-us-central1"]
---

# Deployment

## Overview

GPN Data API is deployed as a Docker container on Google Cloud Platform (us-central1) using Groupon's Conveyor Cloud platform (Kubernetes). Deployments are managed via Jenkins CI (jtierPipeline) and released to target environments through deployBot. The service uses the JTier archetype with Helm chart `cmf-jtier-api` version `3.88.1` for Kubernetes manifest generation.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java21-jtier:3` |
| Orchestration | Kubernetes (GCP GKE via Conveyor) | Manifests rendered via `helm3 template cmf-jtier-api` (v3.88.1); deployed with `krane` |
| Deploy scripts | Bash | `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Envoy (Hybrid Boundary sidecar) | Sidecar injected by Conveyor; exposes HTTP on port 80 (mapped to container port 8080) |
| Admin port | Dropwizard admin | Container port 8081 (exposed as `admin-port` in Kubernetes service) |
| CDN | None | Internal-only service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Pre-production testing | GCP us-central1 | `http://gpn-data-api.us-central1.conveyor.stable.gcp.groupondev.com` |
| production-us-central1 | Live production traffic | GCP us-central1 | `https://gpn-data-api.us-central1.conveyor.prod.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch, branches matching `AN-.+`, or branches matching `\d+\.\d+\.\d+`
- **Deploy target**: `staging-us-central1` (auto after successful build); production via deployBot manual trigger

### Pipeline Stages

1. **Build & Test**: Runs `mvn clean verify` inside the `.ci/docker-compose.yml` test container; executes unit tests, integration tests, and code quality checks
2. **SonarQube Analysis**: Publishes code quality metrics to `sonarqube.groupondev.com` (forced on non-main branches by the pipeline override)
3. **Docker Build & Push**: Builds the service Docker image and pushes to `docker-conveyor.groupondev.com/afl/gpn-data-api`; image tagged with the Maven `revision` (`major-minor.patch`)
4. **Nexus Publish**: Publishes Maven artifact (`com.groupon.afl:gpn-data-api`) to Nexus repository
5. **Deploy to Staging**: Triggers deployBot deployment to `staging-us-central1` using `krane` via the deploy script

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | min: 1, max: 2, target CPU utilization: 120% |
| Horizontal (production) | HPA + VPA | min: 2, max: 5; VPA enabled |
| Memory (production) | VPA-managed | request: 500Mi, limit: 1500Mi |
| Memory (staging) | VPA-managed | request: 500Mi, limit: 1500Mi |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main, production) | 5m | 1 core |
| CPU (main, staging) | 5m | 50m |
| Memory (main) | 500Mi | 1500Mi (prod) / 1500Mi (staging) |
| CPU (envoy sidecar) | 5m (prod) / 5m (staging) | 200m (common) / 500m (staging) |
| Memory (envoy) | 33Mi | 300Mi |
| CPU (filebeat) | 5m | 200m (common) / 50m (staging) |
| Memory (filebeat) | 50Mi | 500Mi |

> Resource values sourced from `.meta/deployment/cloud/components/api/common.yml`, `staging-us-central1.yml`, and `production-us-central1.yml`.
