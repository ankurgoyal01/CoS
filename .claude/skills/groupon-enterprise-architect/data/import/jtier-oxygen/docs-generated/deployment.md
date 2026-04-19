---
service: "jtier-oxygen"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

JTier Oxygen is containerized via Docker and deployed on Kubernetes using Kustomize overlays and Helm-compatible deployment YAMLs managed by the Raptor/Conveyor platform. The service runs as two Kubernetes components: `app` (the long-running HTTP service) and `schedule` (a cron-triggered Kubernetes Job). Deployments are promoted through a CI pipeline: CI build → staging → production. The service is deployed in multiple GCP and AWS regions for US and EMEA coverage.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Image: `docker-conveyor.groupondev.com/com.groupon.jtier/oxygen` |
| Orchestration | Kubernetes (Kustomize) | Base: `.meta/kustomize/base/`; overlays per environment under `.meta/kustomize/overlays/` |
| Deployment config | Raptor YAML | `.meta/deployment/cloud/components/app/` and `.meta/deployment/cloud/components/schedule/` |
| Load balancer | Hybrid Boundary / Envoy (Istio) | Envoy version 2.1.0; HTTPS ingress on port 9443; `useExternalHTTP2: true` |
| Local dev | Docker Compose | `.meta/deployment/development/docker-compose-without-app.yml` (DaaS + MBus + Redis) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Developer sandbox for GCP deployment testing | GCP us-central1, GCP europe-west1 | Configured via `JTIER_RUN_CONFIG` pointing to `dev-us-central1.yml` |
| staging | Integration and pre-production validation | GCP us-central1, GCP europe-west1, AWS us-west-1, AWS us-west-2 | `http://jtier-oxygen-staging.snc1` (on-prem VIP); `selfCheckUrl: http://jtier-oxygen.staging.service` |
| production | Live environment (US and EMEA) | GCP us-central1, GCP europe-west1, AWS us-west-1, AWS us-west-2, AWS eu-west-1 | `http://jtier-oxygen.snc1` (US); `http://jtier-oxygen.sac1`; `http://jtier-oxygen.dub1` (EMEA); `selfCheckUrl: http://jtier-oxygen.production.service` |
| uat | User acceptance testing | snc1 (on-prem) | `http://jtier-oxygen-uat.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (via shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile` at repository root
- **Trigger**: Push to `master` branch or version branches matching `/^\d+\.\d+\.\d+/`

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles, runs unit tests, integration tests, and code quality checks (PMD, FindBugs)
2. **Docker build**: Builds the service image tagged with the Maven version (`${major-minor}.${patch}`)
3. **Deploy to staging**: Promotes the image to `staging-us-central1` and `staging-europe-west1` (as configured in `Jenkinsfile`)
4. **BFM verification**: Validates BFM (Business Flow Monitor) tests pass in the staging environment
5. **Promote to production**: Manual or automated promotion via Deploybot (`https://deploybot.groupondev.com/jtier/oxygen`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Manual / Kubernetes replicas | `minReplicas: 3`, `maxReplicas: 3` (common app config); regional overrides set 1-3 replicas |
| Horizontal (staging) | Manual | `minReplicas: 1`, `maxReplicas: 1` |
| Horizontal (dev) | Manual | `minReplicas: 1`, `maxReplicas: 2` |
| HPA target | CPU utilization | `hpaTargetUtilization: 75` |
| Schedule component | Kubernetes CronJob | `jobSchedule: "0 20 * * *"` (daily at 20:00 UTC) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (app) | 500m | 500m |
| Memory (app) | 6670Mi | 6670Mi |
| CPU (schedule) | 1000m | not set |
| Memory (schedule) | 500Mi | 500Mi |

## Port Configuration

| Port | Purpose |
|------|---------|
| `8080` | HTTP application listener (primary) |
| `8081` | Admin port (Dropwizard admin connector) |
| `8443` | HTTPS application listener (development only) |
| `9001` | Dropwizard admin (development default) |
| `9443` | HTTPS ingress via Hybrid Boundary / Envoy |
