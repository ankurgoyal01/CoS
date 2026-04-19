---
service: "afl-rta"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

AFL RTA is deployed as a containerized JTier service on GCP using Kubernetes (Conveyor Cloud platform), managed via DeployBot. The service runs in the `afl` Docker organisation on Groupon's internal container registry. Two environments are active: staging (GCP us-central1 stable VPC) and production (GCP us-central1 prod VPC). The deployment uses a rolling update strategy with no unavailable pods during rollout. Horizontal Pod Autoscaling (HPA) and Vertical Pod Autoscaling (VPA) are both enabled in production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Image: `docker-conveyor.groupondev.com/afl/afl-rta` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests generated from `.meta/deployment/cloud/components/app/template/` via ERB templates |
| Load balancer | Conveyor VIP | Staging: `afl-rta.us-central1.conveyor.stable.gcp.groupondev.com`; Production: `afl-rta.us-central1.conveyor.prod.gcp.groupondev.com` |
| Service mesh | Envoy (optional Hybrid Boundary sidecar) | Enabled for GCP regions via hybrid boundary config in `framework-defaults.yml` |
| Log shipping | Filebeat 7.5.2 sidecar | Ships to ELK; index `filebeat-afl-rta_app--*` |
| Metrics | Telegraf / Wavefront | Metrics atom = current git SHA; endpoint configured via `TELEGRAF_URL` |
| CDN | None | Not applicable for a Kafka consumer service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 (stable VPC) | `afl-rta.us-central1.conveyor.stable.gcp.groupondev.com` |
| production | Live traffic (NA + EMEA) | GCP us-central1 (prod VPC) | `afl-rta.us-central1.conveyor.prod.gcp.groupondev.com` |

> The service supports NA and EMEA regions. EMEA (international) production Kibana is at `prod-kibana-unified-eu.logging.prod.gcp.groupondev.com`.

## CI/CD Pipeline

- **Tool**: Jenkins (JTier shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Merge to `main` branch (releasable branch); deployTarget is `staging-us-central1`

### Pipeline Stages

1. **Build**: Maven build, unit tests, static analysis (SonarQube, PMD, FindBugs), code coverage (JaCoCo >= 50%)
2. **Docker Build**: Builds and pushes image to `docker-conveyor.groupondev.com/afl/afl-rta`
3. **Staging Deploy**: Automatic deploy to `staging-us-central1` via DeployBot (`promote_to: production-us-central1`)
4. **Production Deploy**: Manual promotion from staging to `production-us-central1` via DeployBot
5. **Verify**: Post-deploy verification via Wavefront dashboards and Kibana log review

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA + VPA | Min: 1 / Max: 2 replicas; `hpaTargetUtilization: 120` |
| Horizontal (production) | HPA + VPA | Min: 2 / Max: 10 replicas; `hpaTargetUtilization: 120` |
| Topology | Node spread enabled | `topologySpreadConstraints.node.enabled: true`; zone constraints disabled |
| Deployment strategy | Rolling update | `maxSurge: 25%`; `maxUnavailable: 0` |

## Resource Requirements

### Staging (`staging-us-central1`)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 15m | 200m |
| Memory (main) | 750 Mi | 2 Gi |
| CPU (envoy sidecar) | 10m | 100m |
| Memory (envoy sidecar) | 30 Mi | 300 Mi |
| CPU (filebeat sidecar) | 10m | 100m |
| Memory (filebeat sidecar) | 50 Mi | 500 Mi |

### Production (`production-us-central1`)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 155m | VPA managed |
| Memory (main) | 750 Mi | 2 Gi |
| CPU (envoy sidecar) | 16m | VPA managed |
| Memory (envoy sidecar) | 40 Mi | 300 Mi |
| CPU (filebeat sidecar) | 25m | VPA managed |
| Memory (filebeat sidecar) | 50 Mi | 500 Mi |

> Rollback: Re-deploy a previous version from the [DeployBot deployment history](https://deploybot.groupondev.com/AFL/afl-rta). Kubernetes context: `afl-rta-gcp-production-us-central1` or `afl-rta-gcp-staging-us-central1`.
