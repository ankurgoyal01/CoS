---
service: "mds-feed-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [rde-dev, staging, production]
---

# Deployment

## Overview

The Marketing Feed Service is containerized (Docker) and deployed to Google Cloud Platform (GCP) Kubernetes clusters using Kustomize manifests. The service runs as a StatefulSet (to support the 100G feed download volume mount at `/var/tmp/`). Deployment is managed by the Deploybot tool (Groupon's internal deploy orchestrator), triggered from Jenkins CI. Production runs in GCP `us-central1`; staging runs in the same region. A dev environment (`rde-dev`) runs in AWS `us-west-2` for isolated development.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | Base: `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` (build); runtime image pushed to `docker-conveyor.groupondev.com/mis/mds-feed-api` |
| Orchestration | Kubernetes (GCP) | Kustomize base at `.meta/kustomize/base/kustomization.yml`; overlays at `.meta/kustomize/overlays/app/` |
| Deployment tool | Deploybot | `https://deploybot.groupondev.com/MIS/mds-feed-api`; config at `.deploy_bot.yml` |
| Deploy scripts | Bash | `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Kubernetes Service | HTTP port 8080 exposed; admin port 8081 exposed |
| StatefulSet volume | GCP Persistent Disk | 100G volume mounted at `/var/tmp/` for feed file downloads |
| Network policies | Kubernetes NetworkPolicy | SFTP egress policy at `.meta/deployment/cloud/components/api/network-policy-production-sftp.yml` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| rde-dev (us-west-2) | Developer sandbox / isolated testing | AWS us-west-2 | Internal only |
| staging (us-central1) | Integration / UAT testing | GCP us-central1 | `http://mds-feed-staging.snc1` |
| production (us-central1) | Live production traffic | GCP us-central1 | `http://mds-feed-vip.snc1` / `http://mds-feed-vip.sac1` |

> Legacy on-prem VIPs exist at `snc1` and `sac1` colos for production and staging.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On pull request (build + tests); on merge to `main` (build + deploy to staging); manual promotion to production via Deploybot
- **Library**: `java-pipeline-dsl@latest-2`

### Pipeline Stages

1. **Build**: Compiles Java source with Maven (`mvn clean compile`)
2. **Unit Tests**: Runs unit tests; JaCoCo coverage enforced (60% complexity minimum per class)
3. **Integration Tests**: Runs `IntegrationTestSuite.java` via Maven Failsafe plugin
4. **Docker Build**: Builds container image and pushes to `docker-conveyor.groupondev.com/mis/mds-feed-api`
5. **Deploy to Staging**: Automatically deploys to `staging-us-central1` via Deploybot on merge to `main`
6. **Promote to Production**: Manual promotion via Deploybot from staging to `production-us-central1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min: 1 / Max: 2 / Target utilization: 100% |
| Horizontal (production) | HPA + VPA | Min: 3 / Max: 10 / VPA enabled |
| Topology | Node-spread | Zone constraints disabled (`BSTR-719`); node spread enabled |
| Pod management | OrderedReady | StatefulSet `podManagementPolicy: OrderedReady` |

## Resource Requirements

### Production (us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 500m | VPA-managed |
| Memory (main) | 5 Gi | 7 Gi |
| CPU (filebeat) | 200m | 250m |
| Memory (filebeat) | 250 Mi | 500 Mi |
| Disk (`/var/tmp/`) | 100G | 100G |

### Staging (us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 50m | VPA-managed |
| Memory (main) | 1 Gi | 4 Gi |
| Memory (filebeat) | 250 Mi | 500 Mi |
| Disk (`/var/tmp/`) | 100G | 100G |
