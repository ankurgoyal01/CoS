---
service: "killbill-subscription-programs-plugin"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The plugin is packaged as a Docker image layered on `killbill/killbill:0.21.3` and installed as a Kill Bill OSGi bundle via KPM. The image is built by Maven's `dockerfile-maven-plugin` and pushed to `docker-conveyor.groupondev.com`. In cloud environments, the container runs on Google Kubernetes Engine (GCP us-central1) managed by Conveyor (Groupon's internal Kubernetes delivery platform). On-premises (legacy) environments use Ansible for deployment on hosts named `kb-subscriptions[n].[snc1/sac1]`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `Dockerfile` at repo root; base `killbill/killbill:0.21.3`; plugin installed via KPM as `grpn:sp` version `0.4` |
| Orchestration | Kubernetes (GKE/Conveyor) | Kustomize manifests at `.meta/kustomize/`; Conveyor cloud config at `.meta/deployment/cloud/` |
| Service image repo | Docker registry | `docker-conveyor.groupondev.com/org.kill-bill.billing.plugin.java/sp-plugin` |
| Load balancer | Hybrid Boundary (Groupon internal) | Staging: `hybrid-boundary-ui.staging...`; Production: `hybrid-boundary-ui.prod...` |
| CDN | None (internal service) | Not applicable — internal base URLs only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging (cloud) | Pre-production validation | GCP us-central1 (VPC: stable) | `http://kb-subscriptions1-staging.snc1` (on-prem); cloud namespace `subscription-engine-staging-sox` |
| Production (cloud) | Live traffic | GCP us-central1 (VPC: prod) | `http://kb-subscriptions.snc1` / `http://kb-subscriptions.sac1` (on-prem); cloud namespace `subscription-engine-production-sox` |
| On-premises (legacy) | Bare-metal / VM hosts | snc1, sac1 | `http://kb-subscriptions[n].snc1`, `http://kb-subscriptions[n].sac1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push to `master` branch; staging deploy via `staging` branch push

### Pipeline Stages

1. **Build**: `mvn clean install` — compiles the plugin, runs unit tests, generates the OSGi bundle JAR
2. **Docker Build**: `dockerfile-maven-plugin` builds the container image and tags it with the Maven project version
3. **Docker Push**: Pushes the image to `docker-conveyor.groupondev.com` on `mvn deploy`
4. **Staging Deploy**: Push to `staging` branch triggers DeployBot to build and deploy to `staging-us-west-1` (requires operator `AUTHORIZE` action in DeployBot)
5. **Production Deploy**: Merge to `master` triggers DeployBot; operator promotes from staging to `production-us-west-1` via DeployBot UI

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: min 1 / max 4; Production: min 2 / max 8 |
| HPA target | CPU utilization | 80% (`hpaTargetUtilization: 80`) |
| Memory | Kubernetes limits | Request: 4Gi / Limit: 16Gi (`common.yml`) |
| CPU | Kubernetes limits | Request: 400m / Limit: 8000m (`common.yml`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 400m | 8000m |
| Memory | 4Gi | 16Gi |
| Disk | Not specified | Not specified |

> Note: Exit code 137 (OOMKilled) has been observed in production. If pods are OOMKilled, increase memory limits in `.meta/deployment/cloud/components/app/production-us-central1.yml`.
