---
service: "general-ledger-gateway"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-central1, production-us-west-1, production-us-central1]
---

# Deployment

## Overview

GLG is deployed as a Dockerised JVM application on Kubernetes, managed via Groupon's internal Conveyor Cloud tooling. Deployments are triggered through DeployBot after CI builds complete on Jenkins. Both AWS (us-west-1) and GCP (us-central1) regions are supported with separate Kubernetes clusters. The service runs in a SOX-inscoped namespace, which applies additional change-control restrictions.

> **Current status**: As of August 2022, pods are scaled to zero in all environments. The infrastructure and configuration remain intact for rapid scale-up.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes | Manifests managed via `.meta/deployment/cloud/` |
| Service image | Docker Registry | `docker-conveyor.groupondev.com/fed/general-ledger-gateway` |
| Deploy tool | DeployBot + deploy.sh | `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Kubernetes Service | HTTP port 8080, admin port 8081, JMX port 8009 |
| CDN | None | Not applicable — internal service only |

## Environments

| Environment | Purpose | Region / Provider | Kubernetes Cluster | Namespace |
|-------------|---------|------------------|--------------------|-----------|
| staging-us-west-1 | Pre-production testing (AWS) | us-west-1 / AWS | stable-us-west-1 | `general-ledger-gateway-staging-sox` |
| staging-us-central1 | Pre-production testing (GCP) | us-central1 / GCP | gcp-stable-us-central1 | `general-ledger-gateway-staging-sox` |
| production-us-west-1 | Production (AWS) | us-west-1 / AWS | production-us-west-1 | `general-ledger-gateway-production-sox` |
| production-us-central1 | Production (GCP) | us-central1 / GCP | gcp-production-us-central1 | `general-ledger-gateway-production-sox` |

## CI/CD Pipeline

- **Tool**: Jenkins (cloud-jenkins) + DeployBot
- **Config**: `Jenkinsfile`
- **Source repo**: `sox-inscope/general-ledger-gateway` (restricted; developers fork via `finance-engineering/general-ledger-gateway`)
- **Trigger**: Merge to `main` branch (origin) or force-push to `dev` branch (fork for staging tests)

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles, runs unit and integration tests, runs code quality checks
2. **Docker build**: Produces Docker image tagged with build version
3. **Publish**: Pushes image to `docker-conveyor.groupondev.com/fed/general-ledger-gateway`
4. **Deploy staging**: DeployBot deploys to staging via `deploy.sh staging-us-west-1`; must be authorised in DeployBot
5. **Promote**: Staging build is promoted to production in DeployBot
6. **Deploy production**: DeployBot deploys to production via `deploy.sh production-us-west-1`; requires `Authorize` action

> PRs must be created in `finance-engineering/general-ledger-gateway` fork and merged into `sox-inscope/general-ledger-gateway` via mergebot ("ship it;" comment).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Fixed | `minReplicas: 2`, `maxReplicas: 2` (scaled to 0 while on hold) |
| Horizontal (production) | Fixed | `minReplicas: 3`, `maxReplicas: 3` (scaled to 0 while on hold) |
| HPA target | CPU utilisation | `hpaTargetUtilization: 50` |

Scale-up commands when resuming service:

```shell
# Staging
kubectl config use-context stable-us-west-1
kubens general-ledger-gateway-staging-sox
kubectl -n general-ledger-gateway-staging-sox scale deployment general-ledger-gateway--api--default --replicas=2

# Production
kubectl config use-context production-us-west-1
kubens general-ledger-gateway-production-sox
kubectl -n general-ledger-gateway-production-sox scale deployment general-ledger-gateway--api--default --replicas=3
```

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not set |
| Memory | 550Mi | 1000Mi |
| Disk | Not specified | Not specified |

## Port Mapping

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port |
| 8081 | Dropwizard admin port (metrics, health checks) |
| 8009 | JMX port |
