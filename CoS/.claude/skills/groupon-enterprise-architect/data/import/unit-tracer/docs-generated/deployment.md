---
service: "unit-tracer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

Unit Tracer is containerized (Docker) and deployed to Kubernetes clusters via the JTier Conveyor Cloud platform. It is deployed across three environments (dev, staging, production) in two cloud providers (GCP and AWS) and multiple regions. The `deploy-bot` system manages production deployments. Staging deployments are promoted to production automatically after successful staging runs.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| App image | Docker | Published to `docker-conveyor.groupondev.com/finance-engineering/unit-tracer` |
| Orchestration | Kubernetes (JTier Conveyor Cloud) | Manifests in `.meta/deployment/cloud/` |
| Load balancer | VIP (Groupon internal) | Per-environment VIP addresses (see Environments table) |
| Admin port | Dropwizard admin | Port 8081 exposed as `admin-port` on the Kubernetes service |
| App port | HTTP | Port 8080 exposed as the primary HTTP port |

## Environments

| Environment | Purpose | Cloud | Region | VIP |
|-------------|---------|-------|--------|-----|
| dev | Development / integration testing | GCP | us-central1 | `unit-tracer.staging.service.us-central1.gcp.groupondev.com` |
| staging-us-central1 | Pre-production validation (US) | GCP | us-central1 | `unit-tracer.staging.service.us-central1.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (EU) | GCP | europe-west1 | (see `.deploy_bot.yml`) |
| production-us-central1 | Production (North America) | GCP | us-central1 | `unit-tracer.prod.us-central1.gcp.groupondev.com` |
| production-eu-west-1 | Production (EMEA on AWS) | AWS | eu-west-1 | `unit-tracer.prod.eu-west-1.aws.groupondev.com` |
| production-europe-west1 | Production (EMEA on GCP) | GCP | europe-west1 | (see `.deploy_bot.yml`) |

## CI/CD Pipeline

- **Tool**: Jenkins (`cloud-jenkins.groupondev.com`)
- **Config**: `Jenkinsfile` (uses shared library `java-pipeline-dsl@latest-2`, `jtierPipeline` step)
- **Trigger**: Push to `main` or `staging` branches; Docker build is not skipped (`skipDocker: false`)
- **Slack notifications**: `#fed-deploy` channel
- **Build failure alerts**: Email to `financial-engineering-alerts@groupon.com` on `main` branch failures
- **Deploy target on CI**: `staging-us-central1` and `staging-europe-west1` (auto-deployed after successful build)

### Pipeline Stages

1. **Build**: Maven build (`mvn clean verify`) including unit tests, integration tests, and code quality checks (PMD, FindBugs)
2. **Docker build**: Builds Docker image from `src/main/docker/Dockerfile` and pushes to `docker-conveyor.groupondev.com/finance-engineering/unit-tracer`
3. **Deploy to staging**: Deploys to `staging-us-central1` and `staging-europe-west1` via Conveyor Cloud (`bash ./.meta/deployment/cloud/scripts/deploy.sh`)
4. **Promote to production**: Production deployments are triggered via deploy-bot; staging promotes to production via `promote_to` config in `.deploy_bot.yml`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Fixed replicas (common), HPA-capable | `minReplicas: 3`, `maxReplicas: 3` (common); production region: `minReplicas: 1`, `maxReplicas: 3` |
| Horizontal (staging/dev) | Auto-scaling | `minReplicas: 1`, `maxReplicas: 2` |
| HPA target | CPU utilization | `hpaTargetUtilization: 100` (common.yml) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 700m |
| Memory | 500Mi | 1Gi |
| Disk | Not specified | Not specified |

> Resource limits apply consistently across all environments (dev, staging, production) per `.meta/deployment/cloud/components/app/` YAML files.
