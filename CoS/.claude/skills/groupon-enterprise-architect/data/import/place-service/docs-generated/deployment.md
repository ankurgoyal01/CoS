---
service: "place-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

The M3 Place Service is fully containerized and deployed on Kubernetes using Groupon's Conveyor/DeployBot CI/CD platform. The main application runs as a Tomcat WAR deployment inside a Docker image. Two additional worker deployments (`sf-m3-synchronizer-worker` and `m3-reverser-negotiator-worker`) run as separate Kubernetes deployments within the same `m3-placeread` service boundary. Production deployments span two cloud providers: GCP us-central1 (NA) and AWS eu-west-1 (EU/EMEA).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `docker/Dockerfile` — base image `docker.groupondev.com/tomcat:8.5.78-jre11-temurin` |
| Image registry | Groupon Conveyor | `docker-conveyor.groupondev.com/m3/m3-placeread` |
| Orchestration | Kubernetes (GCP GKE + AWS EKS) | Helm charts via Conveyor; manifests in `.meta/deployment/cloud/` |
| Load balancer | Hybrid Boundary (sidecar) | Configured via `.meta/deployment/cloud/components/app/common.yml` |
| Log shipping | Filebeat sidecar | Two log sources: app (`placereadservice.log`) and Tomcat access log |

## Environments

| Environment | Purpose | Cloud / Region | Internal URL |
|-------------|---------|----------------|-------------|
| staging-us-central1 | Pre-production validation (US) | GCP / us-central1 | `http://place-service-staging.snc1` |
| staging-europe-west1 | Pre-production validation (EU) | GCP / europe-west1 | — |
| production-us-central1 | Production traffic (NA) | GCP / us-central1 | `https://m3-placeread.production.service.us-central1.gcp.groupondev.com` |
| production-eu-west-1 | Production traffic (EMEA) | AWS / eu-west-1 | `http://m3-placeread.production.service.eu-west-1.aws.groupondev.com` |

Legacy on-prem environments (snc1, dub1, sac1) are also registered in `.service.yml` but the primary deployment target is cloud.

## CI/CD Pipeline

- **Tool**: Jenkins (Groupon internal `java-pipeline-dsl`)
- **Config**: `Jenkinsfile`
- **Build trigger**: On commit to `master`, `MS.*`, `GPROD-.*`, `MCE-.*` branches
- **Deploy trigger**: Automatic to staging after successful build; promoted manually to production via DeployBot

### Pipeline Stages

1. **Build**: Maven clean verify (`mvn clean verify`), compile Java 1.8, run tests, run Checkstyle, FindBugs, Cobertura
2. **Package**: Build WAR artifact (`placereadservice.war`), build Docker image (`docker-conveyor.groupondev.com/m3/m3-placeread`)
3. **Push**: Push Docker image to Conveyor registry
4. **Deploy to Staging**: DeployBot deploys to `staging-us-central1` and `staging-europe-west1` automatically
5. **Promote to Production**: Manual promotion via DeployBot to `production-us-central1` and `production-eu-west-1`

Useful pipeline links:
- CI: `https://cloud-jenkins.groupondev.com/job/m3/job/place-service/`
- CD: `https://deploybot.groupondev.com/m3/place-service`

### Rollback

Use the rollback button in DeployBot to revert to a previous build version. For Kubernetes-level rollback: `kubectl rollout restart deploy m3-placeread--app--default`.

## Scaling

### Main Application (`app` component)

| Environment | Strategy | Min Replicas | Max Replicas | HPA Target |
|-------------|----------|-------------|-------------|------------|
| staging-us-central1 | HPA | 3 | 5 | 100% CPU |
| production-us-central1 | HPA | 8 | 40 | 30% CPU |
| production-eu-west-1 | HPA | 3 | 25 | 30% CPU |

### Worker Sidecars

| Worker | Min Replicas | Max Replicas |
|--------|-------------|-------------|
| `sf-m3-synchronizer-worker` | 3 | 15 |
| `m3-reverser-negotiator-worker` | 3 | 15 |

## Resource Requirements

### Main Application (production-us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 2500m | 7500m |
| Memory | 14Gi | 16Gi |
| JVM Heap | — | -Xmx12G |

### Main Application (production-eu-west-1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 2500m | 4000m |
| Memory | 5Gi | 10Gi |

### Main Application (staging-us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 2000m |
| Memory | 3200Mi | 3600Mi |
| JVM Heap | — | -Xmx2G |

### Common (all environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (baseline) | 500m | 1000m |
| Memory (baseline) | 500Mi | 2Gi |

## Health Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|--------------|--------|
| Readiness | `/placereadservice/v2.0/status` | 8080 | 20s | 5s |
| Liveness | `/placereadservice/v2.0/status` | 8080 | 30s | 15s |

## Deployment Checklist

1. Create a logbook ticket (use GPROD-93389 as template)
2. Notify SOC in the Production Google Chat channel
3. Notify dev team in Slack (`CFPA9QH8B`) and via email (`merchantdata@groupon.com`)
4. Do not combine helm chart version upgrades or cloud infra changes with feature/bug fix changes
5. Deploy changes independently to allow fast rollback
