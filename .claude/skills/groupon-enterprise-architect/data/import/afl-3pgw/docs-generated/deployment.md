---
service: "afl-3pgw"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

AFL-3PGW is a containerized JTier service deployed on Groupon's Conveyor Cloud platform (GCP-hosted Kubernetes). It runs as the `app` component with a single `default` instance. Deployments are managed by DeployBot and the Conveyor CI/CD pipeline. The service is deployed to two regions: US (us-central1) and EMEA (eu-west-1). Each environment has its own region-specific YAML configuration loaded at startup via `JTIER_RUN_CONFIG`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; image published to `docker-conveyor.groupondev.com/afl/afl-3pgw` |
| Orchestration | Kubernetes (GCP) | Manifests generated from ERB templates in `.meta/deployment/cloud/components/app/template/` |
| Load balancer | Conveyor VIP | Staging: `afl-3pgw.us-central1.conveyor.stable.gcp.groupondev.com`; Production: `afl-3pgw.us-central1.conveyor.prod.gcp.groupondev.com` |
| CDN | None | Not applicable — internal backend service |
| Service mesh | Envoy sidecar | Hybrid Boundary ingress/egress enabled for us-central1 environments |
| Log shipping | Filebeat sidecar | Ships to ELK under index `filebeat-afl-3pgw_app--*` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Pre-production testing | GCP us-central1 (stable VPC) | `afl-3pgw.us-central1.conveyor.stable.gcp.groupondev.com` |
| production-us-central1 | Production US/Canada traffic | GCP us-central1 (prod VPC) | `afl-3pgw.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-emea | Production EMEA traffic | GCP eu-west-1 (prod VPC) | Managed separately |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI — `java-pipeline-dsl@latest-2` shared library)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `main` branch; releasable branches: `main`

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles source, runs unit and integration tests, PMD, SpotBugs, and SonarQube quality checks
2. **Docker build**: Builds Docker image tagged with commit SHA; pushes to `docker-conveyor.groupondev.com/afl/afl-3pgw`
3. **Publish**: Publishes Maven artifact to Nexus with auto-versioned patch number
4. **Deploy to staging**: Automatically deploys to `staging-us-central1` via DeployBot (`bash .meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging afl-3pgw-staging`)
5. **Promote to production**: Manual promotion step from DeployBot to `production-us-central1` (`bash .meta/deployment/cloud/scripts/deploy.sh production-us-central1 production afl-3pgw-production`)

### Submodule Handling

The pipeline clones submodules (`cloneSubModules: true`) to include the `afl-3pgw-secrets` submodule containing environment secrets.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | Min: 1, Max: 2, Target CPU utilization: 250% |
| Horizontal (production) | Kubernetes HPA | Min: 2, Max: 5, Target CPU utilization: 250% |
| Vertical | VPA enabled | `enableVPA: true` in staging and production environment configs |

## Resource Requirements

### Staging (us-central1)

| Resource | Container | Request | Limit |
|----------|-----------|---------|-------|
| CPU | main | 10m | 1 |
| Memory | main | 300Mi | 2Gi |
| CPU | envoy | 5m | 100m |
| Memory | envoy | 30Mi | 60Mi |
| CPU | filebeat | 5m | 150m |
| Memory | filebeat | 40Mi | 100Mi |

### Production (us-central1)

| Resource | Container | Request | Limit |
|----------|-----------|---------|-------|
| CPU | main | 20m | — |
| Memory | main | 425Mi | 3Gi |
| CPU | envoy | 20m | 160m |
| Memory | envoy | 30Mi | 160Mi |
| CPU | filebeat | 3m | 100m |
| Memory | filebeat | 40Mi | 100Mi |

## Rollback

Rollback is performed by redeploying a previous artifact version from the deployment history in DeployBot at `https://deploybot.groupondev.com/AFL/afl-3pgw`. The DeployBot page lists all available deployment versions.

## Ports

| Port | Name | Purpose |
|------|------|---------|
| 8080 | http-port | Main application HTTP traffic; health check target |
| 8081 | admin-port | Dropwizard admin interface |
| 8009 | jmx-port | JMX monitoring |
