---
service: "teradata-self-service-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The Teradata Self Service UI is deployed as a Docker container on GCP-hosted Kubernetes clusters. The build is a two-stage Docker build: a Node.js 14 Alpine stage compiles the Vue.js SPA with Yarn, and an Nginx stable-alpine stage serves the resulting static assets. Nginx also acts as a reverse proxy, forwarding `/api/` traffic to the backend service and injecting user identity cookies from SSO headers. Deployments are managed by Cloud Jenkins (triggered by GitHub release tags) and promoted via Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `Dockerfile` — Node.js 14-alpine (build) + Nginx stable-alpine (runtime) |
| Orchestration | Kubernetes (GCP) | `.meta/deployment/cloud/` — Raptor/Conveyor manifests |
| Load balancer | Kubernetes Service / GCP L7 | VIP hostnames defined per environment in deployment YAML |
| Static server | Nginx stable-alpine | `nginx.conf` — port 8080, gzip, security headers, SPA fallback, `/api/` proxy |
| CDN | None detected | Static assets are cache-controlled with `immutable` headers but no CDN layer is declared |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | GCP `us-central1` (`stable` VPC) | `teradata-self-service-ui.staging.service.us-central1.gcp.groupondev.com` |
| Production | Live internal users | GCP `us-central1` (`prod` VPC) | `teradata-self-service-ui.us-central1.conveyor.prod.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Cloud Jenkins (`cloud-jenkins.groupondev.com`)
- **Config**: `Jenkinsfile` (uses shared library `java-pipeline-dsl@latest-2`)
- **Trigger**: GitHub release tag creation on the `master` branch (semantic version, e.g., `1.2.0`)
- **Promote**: Staging → Production via Deploybot UI (`deploybot.groupondev.com/dnd-tools/teradata-self-service-ui`) using the `Promote` button

### Pipeline Stages

1. **Build Docker image**: Multi-stage Docker build with build args `build_ref` (git SHA), `build_date`, `release` (semver tag); runs `yarn; yarn build`
2. **Publish image**: Pushes tagged image to Groupon Artifactory Docker registry (`docker-conveyor.groupondev.com/dnd_tools/teradata_self_service_ui`)
3. **Deploy to staging**: Deploybot deploys the tagged image to `staging-us-central1` Kubernetes cluster automatically
4. **Promote to production**: Manual `Promote` action in Deploybot UI deploys the same image to `production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | Min: 1, Max: 5, target utilization: 100% |
| Horizontal (production) | Kubernetes HPA | Min: 2, Max: 10, target utilization: 100% |
| Memory | Limit-based | See resource requirements |
| CPU | Request-based | See resource requirements |

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 50m | — |
| Memory | 100Mi | 500Mi |
| Disk | — | — |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 80m | — |
| Memory | 200Mi | 500Mi |
| Disk | — | — |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Application traffic (Nginx; exposed as HTTP port 80 on the Kubernetes Service) |
| 8081 | HTTP | Admin port (exposed via `exposedPorts: admin-port`) |
