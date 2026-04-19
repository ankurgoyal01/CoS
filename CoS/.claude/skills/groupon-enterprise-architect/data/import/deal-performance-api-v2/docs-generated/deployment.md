---
service: "deal-performance-api-v2"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["development", "staging", "production"]
---

# Deployment

## Overview

Deal Performance API V2 is containerized using Docker and deployed to Groupon's Conveyor Cloud platform (Kubernetes on GCP `us-central1`). CI/CD is managed by Jenkins and Deploybot. Merging to `main` triggers automatic staging deployment; promotion to production requires manual authorization in Deploybot. Horizontal pod autoscaling (HPA) is enabled in both environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` (build image: `dev-java11-maven:2023-12-19`), `src/main/docker/Dockerfile` (runtime image: `prod-java11-jtier:3`) |
| Orchestration | Kubernetes (Conveyor Cloud / GCP) | Deployment manifests in `.meta/deployment/cloud/components/app/` |
| Load balancer | Kubernetes Service + Hybrid Boundary | `httpPort: 8080`, admin port `8081`, JMX port `8009` |
| CDN | None detected | Internal service only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development (local) | Local development and debugging | — | `http://localhost:9000` |
| Staging NA | Pre-production validation | GCP us-central1 (stable) | `https://deal-performance-service-v2.staging.service.us-central1.gcp.groupondev.com/grpn/healthcheck/grpn/status` |
| Production US | Production traffic | GCP us-central1 (prod) | `https://deal-performance-service-v2.production.service.us-central1.gcp.groupondev.com/grpn/status` |

Legacy on-premises VIP endpoints are also registered in `.service.yml`:

| Colo | Environment | Internal URL |
|------|-------------|-------------|
| snc1 | Production | `http://deal-performance-api-v2-vip.snc1` |
| snc1 | Staging | `http://deal-performance-api-v2-staging-vip.snc1` |
| sac1 | Production | `http://deal-performance-api-v2-vip.sac1` |
| dub1 | Production | `http://deal-performance-api-v2-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins + Deploybot
- **Config**: `Jenkinsfile`
- **Trigger**: Merge to `main` triggers automatic build and staging deployment; production requires manual Deploybot authorization

### Pipeline Stages

1. **Build**: Maven `clean verify` — compiles, runs unit and integration tests, static analysis (PMD, FindBugs), code coverage (JaCoCo)
2. **Docker Build**: Builds production Docker image tagged as `docker-conveyor.groupondev.com/push/deal-performance-service-v2`
3. **Deploy to Staging**: Deploybot automatically deploys artifact to `deal-performance-service-v2-staging-us-central1` Kubernetes context
4. **Authorize**: Engineer reviews staging, then clicks "Authorize" in Deploybot to promote to production
5. **Deploy to Production**: Deploybot promotes artifact to `deal-performance-service-v2-production-us-central1` Kubernetes context
6. **Verify**: Engineer checks health endpoint and Wavefront dashboards post-deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Staging) | Kubernetes HPA | Min: 2 / Max: 3 / Target CPU: 100% |
| Horizontal (Production) | Kubernetes HPA | Min: 3 / Max: 10 |
| Vertical (VPA) | Kubernetes VPA | `enableVPA: true` (`common.yml`) |

## Resource Requirements

### Staging

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 500m | — |
| CPU (filebeat) | 10m | 30m |
| Memory (main) | 1900Mi | 2000Mi |

### Production

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 3000m | — |
| Memory (main) | 4500Mi | 5500Mi |

## Rollback

To roll back, locate the previous successful deployment in Deploybot and click **RETRY**. No redeployment chain promotion is needed for rollback — previous artifact versions can be redeployed directly to any environment.
