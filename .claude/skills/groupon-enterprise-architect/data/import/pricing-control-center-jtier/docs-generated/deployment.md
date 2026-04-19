---
service: "pricing-control-center-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

The service is containerized using Docker and deployed to GCP Kubernetes clusters via Deploybot (Uber Deploy). Three cloud environments are active: dev (`gcp-dev-us-central1`), staging (`gcp-stable-us-central1`), and production (`gcp-production-us-central1`). CI builds are driven by Jenkins (`java-pipeline-dsl`). All deployments go through Deploybot; staging deploys are triggered automatically on merge to `main`, and production deploys require manual promotion plus a GPROD logbook ticket. The service is SOX-scoped, requiring approval audit trails for production changes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — extends `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Container registry | Conveyor / internal | `docker-conveyor.groupondev.com/sox-inscope/pricing-control-center-jtier` |
| Orchestration | Kubernetes (GCP) | Manifests generated from `.meta/deployment/cloud/` YAML components |
| Load balancer | Kubernetes Service | HTTP port 8080; admin port 8081; JMX port 8009 |
| Log shipping | Filebeat sidecar | Source type `pricing_control_center_jtier`; forwarded to Kibana |
| APM | Groupon APM agent | Enabled in all environments |

## Environments

| Environment | Purpose | Region | Kubernetes Cluster | Namespace |
|-------------|---------|--------|-------------------|-----------|
| dev | Development testing | us-central1 | gcp-dev-us-central1 | `pricing-control-center-jtier-dev-sox` |
| staging | Pre-production validation, smoke testing | us-central1 | gcp-stable-us-central1 | `pricing-control-center-jtier-staging-sox` |
| production | Live production traffic (SOX-scoped) | us-central1 | gcp-production-us-central1 | `pricing-control-center-jtier-production-sox` |

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins — `cloud-jenkins.groupondev.com`)
- **Config**: `Jenkinsfile` — uses `java-pipeline-dsl@latest-2` shared library
- **Trigger**: On merge to `main`, `staging`, or `gcp_migration` branches

### Pipeline Stages

1. **Build**: Compiles Java source with Maven (`mvn clean package`); runs unit tests
2. **Docker build**: Builds and pushes container image to Conveyor registry
3. **Staging deploy**: Deploybot auto-deploys to `staging-us-central1` on successful build
4. **Production promote**: Manual promotion via Deploybot after staging validation; requires GPROD logbook ticket and team member approval

### Deploybot Configuration

- Configured in `.deploy_bot.yml`
- Staging promotes to production: `promote_to: production-us-central1`
- Deploy command uses `.meta/deployment/cloud/scripts/deploy.sh`
- Kubernetes deployment image: `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.4-3.13.2-3.0.1-1.29.0`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 5, target utilization: 100% |
| Horizontal (production) | Kubernetes HPA | min: 6, max: 10, target utilization: 100% |
| Vertical Pod Autoscaler | Disabled | `enableVPA: false` in all environments |
| Quartz clustering | PostgreSQL-backed Quartz cluster | `instanceId: AUTO`; `isClustered: true` — only one pod executes each trigger |

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 650m | Not set (common default) |
| Memory | 4 Gi | 6 Gi |
| JVM Heap | 4g (HEAP_SIZE) | Included in memory limit |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 750m | Not set (common default) |
| Memory | 6 Gi | 8 Gi |
| JVM Heap | 5g (HEAP_SIZE) | Included in memory limit |

## Health Check

- **Endpoint**: `/heartbeat.txt` on port 8080 (returns "OK")
- **Admin endpoint**: `localhost:9051/grpn/healthcheck` (local dev port 9051; cloud port 8081)
- **Out-of-Rotation (OOR)**: Remove `/var/groupon/jtier/heartbeat.txt` file to take instance OOR; restore with `touch heartbeat.txt`

## Ports

| Port | Purpose |
|------|---------|
| 8080 | Application HTTP (cloud) / 9050 (local dev) |
| 8081 | Admin / health (cloud) / 9051 (local dev) |
| 8009 | JMX |
