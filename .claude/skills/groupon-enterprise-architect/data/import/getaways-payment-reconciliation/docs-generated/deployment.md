---
service: "getaways-payment-reconciliation"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

The service is containerized (Docker, JTier base image) and deployed to Google Cloud Platform (GCP) Kubernetes clusters managed by Deploybot. Two deployment components exist: `app` (HTTP API + web UI pod) and `worker` (scheduled reconciliation and email import pod). Both run the same Docker image distinguished by the `POD_ROLE` environment variable. The image is hosted at `docker-conveyor.groupondev.com/travel-fork-sox-repo/getaways-payment-reconciliation`. The service lives in the `sox-inscope` GitHub organization, which means it is subject to SOX audit controls and follows a dual-repo branching policy.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (base: `prod-java11-jtier:3`, includes Python 3 venv) |
| Orchestration | Kubernetes (GCP) | Manifests in `.meta/kustomize/` (base + env overlays) |
| Deployment tool | Deploybot | `.deploy_bot.yml` — targets: `staging-us-central1`, `production-us-central1`, `dev-us-central1` |
| Config management | Kustomize | `.meta/kustomize/overlays/{app,worker}/{dev,staging,production}/` |
| Load balancer | Internal VIP (JTier) | `http://getaways-payment-reconciliation-vip.snc1` (legacy) / GCP ingress for cloud envs |
| APM | Elastic APM | Sidecar agent; endpoint set per environment in deployment overlays |
| Log shipping | Filebeat | Reads `/var/groupon/jtier/logs/jtier.steno.log` (JSON format) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Developer testing | us-central1 (GCP dev VPC) | Internal dev cluster |
| staging | Pre-production validation | us-central1 (GCP stable VPC) | `getaways-payment-reconciliation.us-central1.conveyor.stable.gcp.groupondev.com` |
| production US | Live production (North America) | us-central1 (GCP prod VPC) | `http://getaways-payment-reconciliation-vip.snc1` |
| production EU | Live production (Europe) | eu-west-1 (GCP prod VPC) | `http://getaways-payment-reconciliation-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root of repository)
- **Trigger**: On push/merge to `master` branch (sox repo); also on push to `main` branch (non-sox mirror)

### Pipeline Stages

1. **Build**: `mvn -U -B clean verify` inside `docker-compose -f .ci/docker-compose.yml`
2. **Docker build and push**: Builds image tagged with revision; pushes to `docker-conveyor.groupondev.com`
3. **Deploy to staging**: Deploybot auto-deploys to `staging-us-central1` on master merge
4. **Promote to production**: Manual promotion via Deploybot "Promote" button; creates GPROD Jira ticket

### Branching / SOX policy

- Changes are first merged to the **non-sox repo** (`travel-fork-sox-repo/getaways-payment-reconciliation`)
- Then the non-sox master is merged into the **sox repo** (`sox-inscope/getaways-payment-reconciliation`)
- Every PR requires at least one "ship it" approval from Getaways Engineering

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| App pod — horizontal | HPA | Min 2 / Max 15 replicas (production); target 50% CPU utilization |
| App pod — staging | Fixed | 1 replica |
| Worker pod — all envs | Fixed | 1 replica (no HPA on worker) |
| Memory | Limits | App: 1500Mi request / 3000Mi limit (common); Worker: 1000Mi request/limit (production) |
| CPU | Limits | App: 1500m request; Worker: 1000m request |

## Resource Requirements

| Resource | Component | Request | Limit |
|----------|-----------|---------|-------|
| CPU | app | 1500m | — (managed by parent) |
| CPU | worker | 1000m | — |
| Memory | app | 1500Mi | 3000Mi |
| Memory | worker | 500Mi (common) / 1000Mi (production) | 750Mi (common) / 1000Mi (production) |
| Disk | — | — | — |

## Kubernetes Namespaces

| Environment | Namespace |
|-------------|-----------|
| Production | `getaways-payment-reconciliation-production-sox` |
| Staging | `getaways-payment-reconciliation-staging-sox` |
| Dev | `getaways-payment-reconciliation-dev-sox` |

## Network Policies

A custom egress `NetworkPolicy` (`gmail-egress-network-policy`) is applied in both staging and production worker namespaces to allow outbound IMAP (port 993) and SMTP (port 587) traffic to Gmail (`0.0.0.0/0`).
