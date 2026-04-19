---
service: "ad-inventory"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Ad Inventory is containerized (Docker) and deployed to Kubernetes via Groupon's Raptor/Conveyor platform on Google Cloud Platform (GCP, us-central1). The service runs as two distinct Kubernetes components: an `api` component that serves real-time placement and audience management requests, and a `worker` component that executes scheduled Quartz batch jobs (report pipelines, audience cache loads). Both components share the same Docker image (`docker-conveyor.groupondev.com/sox-inscope/ad-inventory`). The repo is in the `sox-inscope` GitHub organization, indicating SOX in-scope controls apply to the build and release process. Deployments are gated through Deploybot with manual approval before promotion to production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; image: `docker-conveyor.groupondev.com/sox-inscope/ad-inventory` |
| Orchestration | Kubernetes (GCP GKE) | `.meta/deployment/cloud/components/api/` and `.meta/deployment/cloud/components/worker/` manifests; Raptor archetype: `jtier` |
| Load balancer | Conveyor / GCP Load Balancer | VIP: `ad-inventory.us-central1.conveyor.production.gcp.groupondev.com` |
| CI/CD | Jenkins | `Jenkinsfile`; build server: `cloud-jenkins.groupondev.com/job/sox-inscope/job/ad-inventory/` |
| Secret management | Kubernetes secrets | Secrets repo: `https://github.groupondev.com/sox-inscope/ad-inventory-secrets` |
| Log shipping | Filebeat sidecar | Source type: `ad-inventory`; destination: Kibana unified logging stack |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production integration and smoke testing | GCP us-central1 (stable VPC) | `ad-inventory.us-central1.conveyor.stable.gcp.groupondev.com` |
| Production | Live traffic serving | GCP us-central1 (prod VPC) | `ad-inventory.us-central1.conveyor.production.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On PR open/update (test + build); on merge to `main` (build + artifact publish); manual dispatch via Deploybot for staging and production promotion

### Pipeline Stages

1. **Test**: Runs `mvn clean verify` (unit tests, JaCoCo coverage, PMD, FindBugs)
2. **Build**: Packages the Dropwizard fat JAR and builds the Docker image
3. **Publish**: Pushes Docker image to `docker-conveyor.groupondev.com/sox-inscope/ad-inventory`
4. **Deploy to Staging**: Deploybot applies the new image to `ad-inventory-staging-sox` namespace; requires approval
5. **Smoke Test**: Manual verification — check heartbeat, logs in Kibana, Wavefront dashboards
6. **Promote to Production**: Deploybot promotes the staging-validated image to `ad-inventory-production-sox` namespace; requires approval

## Scaling

### API Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: min 1 / max 2; Production: min 3 / max 15; target CPU utilization: 50% |
| Memory | Kubernetes limits | Staging: 3Gi request / 4Gi limit; Production: 4Gi request / 5Gi limit |
| CPU | Kubernetes requests | Staging: 300m (common); Production: 500m request |

### Worker Component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | min 2 / max 5; target CPU utilization: 50% |
| CPU | Kubernetes requests | 1000m (1 full vCPU) — elevated for batch processing |

## Resource Requirements

### API Component (Production)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | Not explicitly set (default Kubernetes limit) |
| Memory | 4Gi | 5Gi |
| Filebeat CPU | 200m | 300m |
| Filebeat Memory | 200Mi | 500Mi |

### Worker Component (Common)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not explicitly set |
| Memory | Not explicitly set in common.yml | — |
| Filebeat CPU | 10m | 30m |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (Dropwizard main connector) |
| 8081 | Dropwizard admin connector (health checks, metrics, tasks) |
| 8009 | JMX port |

## Namespaces

| Environment | Kubernetes Namespace |
|-------------|---------------------|
| Staging | `ad-inventory-staging-sox` |
| Production | `ad-inventory-production-sox` |

## Deployment Checklist (from OWNERS_MANUAL)

1. Merge PR to `main` branch
2. Wait for Jenkins build to succeed
3. Approve Deploybot release to staging
4. Verify heartbeat: `curl -v "https://ad-inventory.production.service.us-central1.gcp.groupondev.com/heartbeat.txt"`
5. Check Kibana logs: `us-*:filebeat-ad-inventory--*`
6. Verify Wavefront dashboards: `ad-inventory-app-metrics`, `ad-inventory--sma`
7. Promote to production via Deploybot
