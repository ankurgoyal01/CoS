---
service: "channel-manager-integrator-travelclick"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

The service is containerized with Docker and deployed to Google Cloud Platform (GCP) Kubernetes clusters managed by the JTier/Conveyor platform. Deployment is driven by Jenkins (JTier pipeline DSL) and orchestrated by DeployBot using Helm chart `cmf-jtier-api` version `3.89.0`. Environments span US Central 1 and EU West 1 in both staging and production. Promotions flow from staging to production per region.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (production runtime image: `java:8-jre`); CI image: `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Container registry | Groupon Conveyor | `docker-conveyor.groupondev.com/travel/channel-manager-integrator-travelclick` |
| Orchestration | Kubernetes (GCP) | Helm chart `cmf-jtier-api` v3.89.0; deploy via `.meta/deployment/cloud/scripts/deploy.sh` |
| Deploy tool | Krane | `krane deploy` with 300s global timeout |
| Load balancer | Kubernetes Service | HTTP port 8080 (app), admin port 8081, JMX port 8009 |
| CDN | None configured | — |
| APM | Elastic APM | Sidecar enabled per environment; endpoint varies per region |
| Log shipping | Filebeat | Source type `getaways-channel-manager-integrator-travelclick`; log dir `/var/groupon/jtier/logs` |

## Environments

| Environment | Purpose | Region | Namespace | URL |
|-------------|---------|--------|-----------|-----|
| staging-us-central1 | Pre-production validation (US) | GCP us-central1 | `channel-manager-integrator-travelclick-staging-sox` | `channel-manager-integrator-travelclick.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (EU) | GCP europe-west1 | `channel-manager-integrator-travelclick-staging-sox` | — |
| production-us-central1 | Production (US) | GCP us-central1 | `channel-manager-integrator-travelclick-production-sox` | Internal VIP: `http://getaways-channel-manager-integrator-tc-app-vip.snc1` |
| production-eu-west-1 | Production (EU) | GCP eu-west-1 | `channel-manager-integrator-travelclick-production-sox` | — |

## CI/CD Pipeline

- **Tool**: Jenkins (JTier shared pipeline library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch on the SOX-inscope repo triggers a promotable release to staging; `-deploy` suffixed branches trigger non-promotable staging deployments

### Pipeline Stages

1. **Build**: Maven build with unit tests (`mvn` with JVM flags from `.mvn/jvm.config`)
2. **Unit Test**: Maven Surefire plugin runs tests (excludes `**/integrationtest/**`)
3. **Docker Build**: Builds the runtime Docker image; pushes to `docker-conveyor.groupondev.com`
4. **Release**: Publishes versioned artifact; syncs to maintained fork repos (rebases `master`)
5. **Deploy to Staging**: Deploys to `staging-us-central1` and `staging-europe-west1` via DeployBot/Krane
6. **Integration Test**: Maven Failsafe runs `**/integrationtest/**` tests (release profile only)
7. **Promote to Production**: DeployBot promotes staging artifact to `production-us-central1` and `production-eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | Min 1 / Max 2 replicas |
| Horizontal (production) | Kubernetes HPA | Min 2 / Max 15 replicas; target utilization 50% |
| Memory | Fixed limits | Request 1500Mi / Limit 3000Mi (common) |
| CPU | Fixed request | 300m (common); 1000m (production-us-central1) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (common) | 300m | — |
| CPU (production us-central1) | 1000m | — |
| Memory | 1500Mi | 3000Mi |
| JVM heap | 512m initial | 2048m max (from `.mvn/jvm.config`) |

> Deployment configuration managed via `.meta/deployment/cloud/`. Full operational procedures have been moved to [Confluence](https://confluence.groupondev.com/display/TRAV/Channel+Manager+Integrator+Travelclick).
