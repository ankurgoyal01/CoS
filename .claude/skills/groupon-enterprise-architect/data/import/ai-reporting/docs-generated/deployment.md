---
service: "ai-reporting"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

AI Reporting is a JVM-based Dropwizard service deployed as a containerized workload within the Continuum platform. It runs as a long-lived service process handling both synchronous REST requests and asynchronous Quartz-scheduled batch jobs. The service depends on MySQL, Hive, BigQuery, GCS, and JTier Message Bus being available at startup.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM 11 base image; JTier service packaging conventions |
| Orchestration | Kubernetes (inferred from Continuum platform standard) | JTier deployment manifests |
| Load balancer | Internal Continuum load balancer | Routes `/sponsored/`, `/campaigns`, `/merchants/`, `/api/v1/`, `/citrusad/` paths |
| CDN | Not applicable | Backend service — no direct consumer-facing CDN |

> Deployment configuration is managed externally to this repository. Specific Dockerfile paths, Helm chart locations, and Kubernetes manifest paths are maintained in the service's own source repository.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and unit testing | Local / GCP dev | Internal only |
| Staging | Integration testing with staging CitrusAd, Salesforce, and internal services | GCP staging | Internal only |
| Production | Live traffic: Sponsored Listings merchants and Ads platform | GCP production | Internal only |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Groupon standard CI/CD)
- **Config**: `.github/workflows/` in the service source repository
- **Trigger**: On push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Maven compile and package (`mvn clean package`)
2. Test: Unit and integration test suite (`mvn test`)
3. Docker build: Build and tag container image
4. Publish: Push image to Groupon container registry
5. Deploy staging: Rollout to staging environment via JTier deployment tooling
6. Deploy production: Rollout to production after staging validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual scaling via Kubernetes replica count | Determined by Ads Engineering based on campaign volume |
| Memory | JVM heap sizing | Set via `JAVA_OPTS` / JTier config |
| CPU | Kubernetes resource requests/limits | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Deployment configuration managed externally | > Deployment configuration managed externally |
| Memory | > Deployment configuration managed externally | > Deployment configuration managed externally |
| Disk | Ephemeral only (feed files transient via GCS) | — |

> Deployment configuration managed externally. Contact ads-eng@groupon.com for current resource profiles.
