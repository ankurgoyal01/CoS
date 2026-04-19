---
service: "img-service-primer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1, production-us-west-1, production-eu-west-1]
---

# Deployment

## Overview

Image Service Primer is deployed as a containerized JTier application on Kubernetes using Groupon's Conveyor/DeployBot platform. It runs in two cloud providers — GCP (us-central1) and AWS (us-west-1 and eu-west-1). There are two distinct deployment components: the main `app` (long-running HTTP service) and the `video-transformer-cron` (Kubernetes CronJob running every 5 minutes). Deployments are promoted through environments sequentially: `staging-us-central1` -> `production-us-central1` -> `production-eu-west-1`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `src/main/docker/Dockerfile` — `jtier/prod-java11-jtier:3` + FFmpeg |
| CI image | Docker | `.ci/Dockerfile` — `jtier/dev-java11-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes (Helm) | Helm chart `cmf-jtier-api` version 3.92.0 (app); `cmf-generic-cron-job` version 3.92.0 (video-transformer) |
| Deploy tool | krane | Used for Kubernetes apply via `krane deploy` in `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Kubernetes Service + VIP | `gims-primer.us-central1.conveyor.prod.gcp.groupondev.com` (GCP prod), internal VIPs per datacenter |
| CDN | None | Service does not sit behind CDN; it calls Akamai as a downstream |
| Artifact registry | JFrog Artifactory | `docker-conveyor.groupondev.com/mx/image-service-primer` |

## Environments

| Environment | Purpose | Cloud / Region | URL |
|-------------|---------|----------------|-----|
| `staging-us-central1` | Pre-production validation | GCP / us-central1 | `gims-primer.staging.service.us-central1.gcp.groupondev.com` (internal); `https://gims-primer-staging.groupondev.com` (external) |
| `production-us-central1` | Production — US/Canada traffic | GCP / us-central1 | `gims-primer.us-central1.conveyor.prod.gcp.groupondev.com` |
| `production-us-west-1` | Production — US/Canada fallback | AWS / us-west-1 | `http://gims-primer-vip.snc1` (internal); `https://gims-primer-us.groupondev.com` (external) |
| `production-eu-west-1` | Production — EMEA traffic | AWS / eu-west-1 | `http://gims-primer-vip.dub1` (internal) |

## CI/CD Pipeline

- **Tool**: Cloud Jenkins + DeployBot
- **Config**: `.deploy_bot.yml` (deployment targets and promotion chain), `.meta/deployment/cloud/scripts/deploy.sh` (Helm template + krane)
- **Trigger**: Every PR merge triggers a Cloud Jenkins build (`mvn deploy`); DeployBot creates a `staging-us-central1` tag automatically

### Pipeline Stages

1. **Build**: Cloud Jenkins executes `mvn deploy` on merge to master — produces artifact in JFrog Artifactory
2. **Stage deploy**: DeployBot automatically deploys artifact to `staging-us-central1`
3. **Promote to production-us-central1**: Operator clicks **Promote** on DeployBot UI; GPROD logbook ticket required
4. **Promote to production-eu-west-1**: Operator clicks **Promote** on DeployBot UI from `production-us-central1`
5. **Video-transformer cron**: Separate DeployBot targets (`staging-us-central1-video-transformer`, `production-us-central1-video-transformer`) follow the same promote chain

### Rollback

Rollback is performed by clicking **ROLLBACK** or **RETRY** on the previous stable deployment in the DeployBot UI. No code changes required.

## Scaling

### App component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | Min: 1 replica, Max: 2 replicas (prod); 1 replica (staging) |
| HPA target | CPU utilization | `hpaTargetUtilization: 100` (common config) |

> Note: The common config defines `minReplicas: 3` / `maxReplicas: 15`, but per-environment configs override these to 1–2 in all cloud environments.

### Video-transformer cron component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Concurrency | CronJob `Forbid` policy | Only one job runs at a time; new triggers are skipped if a job is active |
| Schedule | Every 5 minutes | `jobSchedule: "*/5 * * * *"` |
| Timeout | 10 minutes | `activeDeadlineSeconds: 600` |

## Resource Requirements

### App component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (GCP prod) | 100m | — |
| CPU (AWS prod) | 100m | — |
| CPU (staging) | 80m | — |
| Memory (GCP prod) | 4Gi | 8Gi |
| Memory (AWS prod) | 2300Mi | 8Gi |
| Memory (staging) | 1500Mi | 3Gi |
| Disk | Not specified | Not specified |

### Video-transformer cron component

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 600m | 900m |
| CPU (filebeat) | 10m | 30m |
| Memory (main) | 2Gi | 2.5Gi |

> `MALLOC_ARENA_MAX=4` is set on the app component to prevent virtual memory expansion from causing OOM kills in containerized environments.
