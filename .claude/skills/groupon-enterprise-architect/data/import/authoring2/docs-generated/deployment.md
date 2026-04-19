---
service: "authoring2"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Authoring2 is deployed as a containerized Java WAR application on Kubernetes (GCP via Groupon's Conveyor platform). The application pod runs an embedded Apache Tomcat 7 server (via `tomcat7-maven-plugin` exec-war), with an ActiveMQ broker as a sidecar container. The build produces a self-contained `authoring2-<version>-war-exec.jar` artifact which is the container entrypoint. Legacy on-premises (snc1) deployments also exist, using Uber Deploy (Capistrano-based) to deploy the WAR to Apache Tomcat instances behind Nginx.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` (multi-stage: builder `docker.groupondev.com/jtier/dev-java11-maven:3`, runtime `docker.groupondev.com/jtier/prod-java11:3`) |
| Sidecar | Docker | ActiveMQ `docker.groupondev.com/hawk/authoring2-activemq-20220721-120753:5.10.0` |
| Orchestration | Kubernetes (GCP Conveyor) | `.meta/deployment/cloud/components/app/` |
| Container registry | `docker-conveyor.groupondev.com` | Image: `docker-conveyor.groupondev.com/hawk/authoring2` |
| Load balancer | GCP Conveyor VIP | Per-region VIP hostname |
| CDN | None | Not applicable for internal authoring tool |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local developer environment | Local | `http://localhost:8080` (embedded Tomcat) |
| Staging (on-prem snc1) | Pre-production validation | snc1 | `https://taxonomy-authoringv2-app-staging-vip.snc1` |
| Staging (GCP us-central1) | Cloud pre-production | us-central1 | `authoring2.us-central1.conveyor.stable.gcp.groupondev.com` |
| Staging (GCP us-west-1) | Cloud pre-production | us-west-1 | `authoring2.us-west-1.conveyor.stable.gcp.groupondev.com` |
| Production (on-prem snc1) | Live production | snc1 | `https://taxonomy-authoringv2-app-vip.snc1` |
| Production (GCP us-central1) | Live production (cloud) | us-central1 | `authoring2.us-central1.conveyor.prod.gcp.groupondev.com` |
| Production (GCP us-west-1) | Live production (cloud) | us-west-1 | `authoring2.us-west-1.conveyor.prod.gcp.groupondev.com` |
| UAT | User acceptance testing (on-prem) | snc1 | `http://taxonomy-authoringv2-app1-uat.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Build trigger**: Push to `devel` branch (all changes require PR; no direct commits to master)
- **Release**: `mvn clean release:clean release:prepare release:perform` — publishes to Groupon Artifactory
- **Deploy tool**: Deploybot (`https://deploybot.groupondev.com/hawk/authoring2`) with CAT (Change Approval Tool) approval gate for production

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles source, runs unit tests, produces WAR
2. **Docker build**: `spotify docker-maven-plugin` builds image tagged with project version and pushes to `docker-conveyor.groupondev.com/hawk/authoring2`
3. **Release**: Maven release plugin prepares and performs a versioned release to Artifactory
4. **Deploy staging**: Deploybot promotes `us-west-1 staging` automatically after successful release
5. **Deploy production**: Deploybot `us-west-1 staging` promoted to `us-west-1 production` after CAT approval
6. **Rollback**: Via Deploybot UI — redeploy previous version

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 1, max 2 replicas; `hpaTargetUtilization: 100` |
| Horizontal (production) | Kubernetes HPA | min 2, max 4 replicas (GCP); min 3, max 15 replicas (common baseline) |
| Memory | Kubernetes resource limits | Request: 500Mi, Limit: 4Gi (main container) |
| CPU | Kubernetes resource requests | Request: 100m (main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | `100m` | — |
| CPU (ActiveMQ sidecar) | `10m` | `30m` |
| CPU (filebeat sidecar) | `10m` | `30m` |
| Memory (main) | `500Mi` | `4Gi` |
| Memory (ActiveMQ sidecar) | `512Mi` | `2Gi` |
| Memory (filebeat sidecar) | `200Mi` | `500Mi` |

## Ports

| Port | Purpose |
|------|---------|
| `8080` | HTTP application port (primary) |
| `8081` | Admin port |
| `8009` | JMX port |
| `61616` | ActiveMQ JMS broker (sidecar) |

## Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|--------------|--------|
| Readiness | `GET /props` | 8080 | 240s | 20s |
| Liveness | `GET /props` | 8080 | 240s | 20s |
| ActiveMQ Readiness | TCP socket port 61616 | 61616 | 180s | 30s |
| ActiveMQ Liveness | TCP socket port 61616 | 61616 | 180s | 30s |
