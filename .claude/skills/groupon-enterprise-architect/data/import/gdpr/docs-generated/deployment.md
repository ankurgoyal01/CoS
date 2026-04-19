---
service: "gdpr"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-europe-west1, staging-us-central1, production-eu-west-1, production-europe-west1, production-us-central1]
---

# Deployment

## Overview

The GDPR service is containerized using Docker (multi-stage build) and deployed to Kubernetes clusters across two cloud providers (AWS and GCP) via DeployBot and the `krane` deploy tool. It runs in five deployment targets: two staging environments and three production environments. The Helm chart `cmf-generic-api` (version 3.88.1 from Groupon's internal Artifactory) is used for all Kubernetes manifests. All environments run a single replica (`minReplicas: 1`, `maxReplicas: 1`) — horizontal auto-scaling is not enabled.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` at repo root; builder stage uses `golang:1.23.5-alpine3.21`, runtime stage uses `alpine:3.21` |
| CI Docker image | Docker | `.ci/Dockerfile` — identical multi-stage build for CI pipeline |
| Orchestration | Kubernetes (krane) | Manifests generated via `helm3 template cmf-generic-api` at deploy time |
| Helm chart | cmf-generic-api 3.88.1 | Sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy tool | DeployBot + krane | `.deploy_bot.yml` defines targets; `.meta/deployment/cloud/scripts/deploy.sh` executes `krane deploy` |
| Load balancer | Not applicable | Internal service only; no external load balancer configured |
| CDN | None | Internal tool, not behind a CDN |

## Environments

| Environment | Purpose | Region / Provider | URL |
|-------------|---------|-------------------|-----|
| `staging-europe-west1` | Staging (EMEA) | GCP `europe-west1` / cluster `gcp-stable-europe-west1` | Internal only |
| `staging-us-central1` | Staging (Americas) | GCP `us-central1` / cluster `gcp-stable-us-central1` | Internal only |
| `production-eu-west-1` | Production (EU / Americas) | AWS `eu-west-1` / cluster `production-eu-west-1` | `https://gdpr.production.service.eu-west-1.aws.groupondev.com/` |
| `production-europe-west1` | Production (EMEA, GCP) | GCP `europe-west1` / cluster `gcp-production-europe-west1` | Internal |
| `production-us-central1` | Production (US, GCP) | GCP `us-central1` / cluster `gcp-production-us-central1` | `https://gdpr.production.service.us-west-1.aws.groupondev.com/` |

Staging environments auto-promote to their paired production environment:
- `staging-europe-west1` promotes to `production-eu-west-1`
- `staging-us-central1` promotes to `production-us-central1`

## CI/CD Pipeline

- **Tool**: Jenkins (with shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `main` branch

### Pipeline Stages

1. **Build**: Docker multi-stage build — compiles Go binary in `golang:1.23.5-alpine3.21`, assembles runtime image from `alpine:3.21`
2. **Push**: Pushes Docker image to `docker-conveyor.groupondev.com/aaa/gdpr` with version tag
3. **Deploy to Staging**: DeployBot deploys to `staging-europe-west1` and `staging-us-central1` using `krane` with a 300-second global timeout
4. **Promote to Production**: DeployBot promotes staging to production targets after staging deploy succeeds; deploy events notify via Slack

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (no HPA) | `minReplicas: 1`, `maxReplicas: 1`, `hpaTargetUtilization: 100` |
| Memory | Configured | Request: 100Mi, Limit: 500Mi |
| CPU | Configured | Request: 50m |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 50m | Not specified |
| Memory | 100Mi | 500Mi |
| Disk | Not specified | Not specified |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Primary application port (mapped from `httpPort: 8080` in `common.yml`) |
| 8081 | HTTP | Admin port (exposed as `admin-port` in `exposedPorts`) |
