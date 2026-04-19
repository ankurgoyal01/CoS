---
service: "aes-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

AES is containerized (Docker) and deployed on GCP Kubernetes (via the Raptor/JTier cloud deployment framework) in GCP us-central1. Two environments are maintained: staging (VPC `stable`, low replica count) and production (VPC `prod`, auto-scaled 2–20 replicas with VPA). Deployments are triggered by Jenkins on merge to the `main` branch; production deploys require manual approval via DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; image: `docker-conveyor.groupondev.com/da/aes-service` |
| CI image | Docker | `.ci/Dockerfile` + `.ci/docker-compose.yml` for build environment |
| Orchestration | Kubernetes (GKE) | Raptor `.meta/deployment/cloud/` manifests; `archetype: jtier` |
| HTTP port | 8080 | Application HTTP traffic |
| Admin port | 8081 | Dropwizard admin endpoints |
| JMX port | 8009 | JVM monitoring |
| APM | Enabled | `apm.enabled: true` in common.yml |
| Log shipping | Filebeat sidecar | `sourceType: aes-service`; medium volume in production |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 (VPC: stable) | Internal — accessible via port-forward or internal DNS |
| production | Live audience export | GCP us-central1 (VPC: prod) | `https://aes-service.production.service.us-central1.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On merge to `main` branch; manual dispatch also supported
- **Deploy UI**: https://deploybot.groupondev.com/da/aes-service

### Pipeline Stages

1. **Build**: `mvn clean verify` — compiles, runs unit and integration tests, code quality checks (PMD, FindBugs/SpotBugs)
2. **Docker Build**: Builds image from `src/main/docker/Dockerfile`, tags with version
3. **Publish**: Pushes image to `docker-conveyor.groupondev.com/da/aes-service`
4. **Deploy Staging**: Automatic deployment to staging environment via Raptor/DeployBot on successful main-branch build
5. **Deploy Production**: Manual approval required via DeployBot; rollback available through DeployBot

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | min: 1, max: 2, target utilization: 100% |
| Horizontal (production) | HPA + VPA | min: 2, max: 20, target utilization: 100%; VPA enabled |
| Memory | Requests/Limits | request: 5Gi, limit: 15Gi |
| CPU | Requests | request: 300m |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not specified (VPA manages in production) |
| Memory | 5Gi | 15Gi |
| Disk | Filebeat: medium volume (prod), low (staging) | — |

## Notes

- `MALLOC_ARENA_MAX=4` is set to prevent virtual memory explosion under high memory pressure.
- Database connectivity in development requires SSH port forwarding to staging/production DB hosts (see README).
- Service is a JTier application; `sudo sv start/stop jtier` manages the service process on VM-based environments.
