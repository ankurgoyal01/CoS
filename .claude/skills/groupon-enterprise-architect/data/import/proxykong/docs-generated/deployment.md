---
service: "proxykong"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-west-2, production-us-west-1, production-eu-west-1]
---

# Deployment

## Overview

ProxyKong is a containerized Node.js service deployed to Kubernetes via Groupon's Conveyor Cloud platform and Napistrano tooling. It runs in multiple AWS regions across staging and production environments. Deployments are triggered by merges to master via the Conveyor CI Jenkins pipeline and promoted through environments using DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker-conveyor.groupondev.com/conveyor/alpine-node14.20.0:2022.07.22-17.49.19-36872e1` |
| Orchestration | Kubernetes (Conveyor Cloud) | Deploy manifests in `.deploy-configs/`; namespace `proxykong-{staging\|production}` |
| Load balancer | Hybrid Boundary | Ingress and egress enabled; upstream creation enabled per region |
| Ingress | Hybrid Boundary | Staging: `proxykong.staging.service`; Production: `proxykong.production.service` |
| Log shipping | Filebeat → Kafka → ELK | Logs tagged `proxykong_itier--*`; shipped to ELK via Kafka |
| Metrics | Telegraf → Wavefront | Standard Measurement Architecture; dashboard at `https://groupon.wavefront.com/dashboard/gapi-overview` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-west-1 | Pre-production validation | AWS us-west-1 | `proxykong.staging.stable.us-west-1.aws.groupondev.com` |
| staging-us-west-2 | Pre-production validation (EU pipeline staging) | AWS us-west-2 | `proxykong.staging.service` (us-west-2) |
| production-us-west-1 | Production (North America) | AWS us-west-1 | `proxykong.prod.us-west-1.aws.groupondev.com` |
| production-eu-west-1 | Production (EMEA) | AWS eu-west-1 | `proxykong.prod.eu-west-1.aws.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On merge to master (automatic staging deploy); production promotion is manual via DeployBot

### Pipeline Stages

1. **Build**: Conveyor CI builds the Docker image and tags it with a timestamp-based artifact ID (e.g., `2019.04.20-23.42.42-cafed06`).
2. **Test**: Unit and integration tests run in the CI pipeline.
3. **Publish**: Artifact is pushed to `docker-conveyor.groupondev.com/groupon-api/proxykong`.
4. **Deploy to Staging**: DeployBot automatically deploys the artifact to `staging-us-west-1` and `staging-us-west-2` upon merge to master. An engineer authorizes via DeployBot.
5. **Deploy to Production**: An engineer selects a successfully staged artifact in DeployBot and promotes it to `production-us-west-1` and/or `production-eu-west-1`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min: 1, max: 3 replicas |
| Horizontal (production) | Kubernetes HPA | min: 2, max: 3 replicas |
| Memory | Resource limits set | Request: 1536Mi, Limit: 3072Mi (main container) |
| CPU | Request set, no hard limit | Request: 1000m (main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | none configured |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (main) | 1536Mi | 3072Mi |
| Memory (filebeat) | 100Mi | 200Mi |
| Disk | — | Ephemeral; `/api-proxy-config` clone and `/tmp` for PR workdirs |

## Container Startup Sequence

At container startup, `bin/start-proxykong.sh` executes the following steps:

1. Sets the Git remote URL for `/api-proxy-config` to include the `GITHUB_TOKEN` credential: `git remote set-url origin https://svc_proxykong:${GITHUB_TOKEN}@github.groupondev.com/groupon-api/api-proxy-config`
2. Starts the cron daemon (`crond`) which runs `cron/gitRefreshMaster.sh` every 10 minutes to keep the local clone current.
3. Starts the Node.js server via `node core/worker-shim.js`.

All startup steps log to `/proc/1/fd/1` for Kubernetes log capture.
