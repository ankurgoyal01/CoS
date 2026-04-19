---
service: "releasegen"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [rde-dev-us-west-2, rde-staging-us-west-2, staging-us-west-1, staging-us-west-2, staging-us-central1, production-us-west-1, production-us-west-2, production-eu-west-1, production-us-central1]
---

# Deployment

## Overview

Releasegen is containerized (Docker) and deployed to Kubernetes clusters across multiple AWS and GCP regions via Deploybot and the Helm chart `cmf-jtier-api` (version 3.91.3). The CI pipeline runs on Jenkins using the `java-pipeline-dsl@latest-2` shared library. Merges to main automatically deploy to staging; promotion to production is manual via Deploybot. The Releasebot GitHub App (`releasegen` for staging, `releasegen` for production) is what triggers the service for enrolled repositories.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI) | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java17-maven:2023-12-19-609aedb` |
| Container (production) | Docker | `src/main/docker/Dockerfile` — `docker.groupondev.com/jtier/prod-java17-jtier:3` |
| Container registry | Groupon Docker registry | `docker-conveyor.groupondev.com/release-engineering/releasegen` |
| Orchestration | Kubernetes | Deployed via `krane` with Helm-rendered manifests; `.meta/deployment/cloud/scripts/deploy.sh` |
| Helm chart | `cmf-jtier-api` | Version 3.91.3 from `artifactory.groupondev.com/artifactory/helm-generic/` |
| Deployment tool | Kubernetes deploy image | `docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Load balancer | Kubernetes Service | HTTP port 8080 exposed as port 80; admin port 8081; JMX port 8009 |
| CDN | none | Internal-only service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `rde-dev-us-west-2` | Remote dev environment | AWS us-west-2 (gensandbox VPC) | Internal only |
| `rde-staging-us-west-2` | Remote dev staging | AWS us-west-2 | Internal only |
| `staging-us-west-1` | Staging (promotes to production-us-west-1) | AWS us-west-1 | `https://releasegen.staging.service.us-west-1.aws.groupondev.com/` |
| `staging-us-west-2` | Staging (promotes to production-eu-west-1) | AWS us-west-2 | Internal |
| `staging-us-central1` | Staging (promotes to production-us-central1) | GCP us-central1 | Internal |
| `production-us-west-1` | Production — US/Canada | AWS us-west-1 | Internal |
| `production-us-west-2` | Production — US/Canada | AWS us-west-2 | Internal |
| `production-eu-west-1` | Production — EMEA | AWS eu-west-1 (dub1 datacenter) | Internal |
| `production-us-central1` | Production — US/Canada | GCP us-central1 | Internal |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push / PR merge to main; manual dispatch via Deploybot

### Pipeline Stages

1. **Build**: Maven build with Java 17, runs unit and integration tests (`ReleasegenApplicationITest`), enforces 100% JaCoCo coverage (`coveredratio=1.0`, `missedClassCount=0`)
2. **Docker build**: Packages the application into a production Docker image using `src/main/docker/Dockerfile`
3. **Publish**: Pushes the image to `docker-conveyor.groupondev.com/release-engineering/releasegen`
4. **Deploy to staging**: Automatically deploys to `staging-us-west-1` and `staging-us-central1` via Deploybot/Conveyor
5. **Promote to production**: Manual authorization in Deploybot triggers promotion to the associated production target for each staging environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Production: min=2, max=15, target CPU utilization=50%; Staging: min=1, max=2; Dev: min=1, max=1 |
| Memory | Kubernetes limits | Request: 500Mi, Limit: 500Mi |
| CPU | Kubernetes requests | Request: 1000m (1 vCPU); no explicit limit in common.yml |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not explicitly set (inherited from jtier defaults) |
| Memory | 500Mi | 500Mi |
| Disk | Not specified | Not specified |
