---
service: "vss"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

VSS is containerized as a Docker image built from `src/main/docker/Dockerfile` (based on `prod-java11-jtier:3`) and deployed to Google Cloud Platform Kubernetes clusters via the JTier/DeployBot deployment pipeline. The service runs in GCP `us-central1` for both staging and production. The CI/CD pipeline is driven by Jenkins using the `jtierPipeline` shared library; every PR merge triggers a build and automatic promotion to staging. Production deployments are authorized via DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Container registry | JFrog Artifactory | `docker-conveyor.groupondev.com/bangalore-platform-engineering/vss` |
| Orchestration | Kubernetes (GKE) | Manifests generated via `.meta/deployment/cloud/` RAPT configuration |
| Deploy tool | DeployBot + RAPT | `deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` deployment image |
| Load balancer | Envoy (edge-proxy) | Envoy sidecar proxy; Hybrid Boundary integration available |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Pre-production validation | GCP us-central1 (stable VPC) | `vss.us-central1.conveyor.stable.gcp.groupondev.com` |
| production-us-central1 | Live production traffic | GCP us-central1 (prod VPC) | `vss.us-central1.conveyor.prod.gcp.groupondev.com` |
| production (on-prem SNC1) | Legacy on-prem production | SNC1 datacenter | `http://vss.snc1` |
| production (on-prem SAC1) | Legacy on-prem failover | SAC1 datacenter | `http://vss.sac1` |

> The primary active deployment is GCP `us-central1`. On-prem SNC1/SAC1 environments are documented in `doc/runbook.md` and represent legacy deployment targets.

## CI/CD Pipeline

- **Tool**: Jenkins (cloud-jenkins)
- **Config**: `Jenkinsfile` — uses `@Library("java-pipeline-dsl@latest-2")` with `jtierPipeline`
- **Trigger**: On PR merge to `master` branch; `releasableBranches: ['master']`

### Pipeline Stages

1. **Build**: `mvn deploy -DskipDocker=false` — compiles, tests, and produces Docker image; publishes artifact to JFrog Artifactory
2. **Automatic staging deploy**: DeployBot tag `staging-us-central1` created automatically; deployment executes `.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging vss-staging`
3. **Authorize production**: Engineer reviews and clicks Authorize in DeployBot UI at `https://deploybot.groupondev.com/Bangalore-Platform-Engineering/vss`
4. **Production promotion**: DeployBot promotes from `staging-us-central1` to `production-us-central1`; executes `.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production vss-production`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 2, target CPU utilization: 100% |
| Horizontal (production) | Kubernetes HPA | min: 1, max: 15, target CPU utilization: 100% |
| Memory (staging) | Fixed | request: 3 Gi, limit: 3 Gi |
| Memory (production) | Fixed | request: 10 Gi, limit: 13 Gi |
| CPU (staging) | Fixed | request: 200m |
| CPU (production) | Fixed | request: 300m |

## Resource Requirements

| Resource | Staging Request | Staging Limit | Production Request | Production Limit |
|----------|----------------|--------------|-------------------|-----------------|
| CPU | 200m | — | 300m | — |
| Memory | 3 Gi | 3 Gi | 10 Gi | 13 Gi |
| Disk | — | — | — | — |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application traffic (service API) |
| 8081 | Admin/management port (Dropwizard admin interface) |

## Rollback

- One-click rollback available via DeployBot UI: `https://deploybot.groupondev.com/Bangalore-Platform-Engineering/vss`
- Use **RETRY** to re-run the previous stable deployment or **ROLLBACK** on a specific deployment entry.
- On-prem rollback: `cap snc1:production deploy:app_servers VERSION=<PREVIOUS_VERSION> TYPE=release`

## SLA Targets

| Metric | Target |
|--------|--------|
| Uptime | 99.9% |
| Throughput | 50K RPM |
| Search P99 latency | 500 ms |
| Search P95 latency | 400 ms |
| Criticality Tier | 3 |
