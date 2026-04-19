---
service: "grouponlive-inventory-service-jtier"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The service is containerized using Docker and deployed to Google Cloud Platform (GCP) in the `us-central1` region via the Groupon Conveyor platform on Kubernetes. Two deployment components are managed: `app` (the HTTP API server) and `worker` (the Quartz job processing worker). Both share the same Docker image (`docker-conveyor.groupondev.com/grouponlive/glive-inventory-jtier`). Deployments are gated through Jenkins CI and promoted manually via Deploybot from staging to production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `src/main/docker/Dockerfile` (base: `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb`) |
| Image registry | Conveyor Container Registry | `docker-conveyor.groupondev.com/grouponlive/glive-inventory-jtier` |
| Orchestration | Kubernetes (GCP GKE) | Managed by Groupon Conveyor / Raptor platform |
| Deployment config | Raptor YAML | `.meta/deployment/cloud/components/app/` and `.meta/deployment/cloud/components/worker/` |
| Service mesh / VIP | Conveyor VIP | Production: `glive-inventory-jtier.us-central1.conveyor.prod.gcp.groupondev.com` |
| APM | Elastic APM | Enabled in both staging and production; endpoint in-cluster via Kubernetes service DNS |
| Logging | Filebeat (Steno structured logs) | `sourceType: grouponlive-inventory-service-jtier_app` |

## Environments

| Environment | Purpose | Region | URL / VIP |
|-------------|---------|--------|-----------|
| staging | Pre-production validation; uses sandbox partner APIs | GCP us-central1 (stable VPC) | `glive-inventory-jtier.us-central1.conveyor.stable.gcp.groupondev.com` |
| production | Live traffic; uses production partner APIs | GCP us-central1 (prod VPC) | `glive-inventory-jtier.us-central1.conveyor.prod.gcp.groupondev.com` |

- **Staging Kubernetes namespace**: `glive-inventory-jtier-staging-sox`
- **Production Kubernetes namespace**: `glive-inventory-jtier-production-sox`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses `java-pipeline-dsl@latest-2` shared library)
- **Trigger**: Push to `main` or `release` branch; `release` branch triggers the Jenkins job at `cloud-jenkins.groupondev.com/job/sox-inscope/job/grouponlive-inventory-service-jtier/`
- **Deploy tool**: Deploybot at `deploybot.groupondev.com/sox-inscope/grouponlive-inventory-service-jtier`

### Pipeline Stages

1. **Build and Test**: `mvn clean verify` — compiles, runs unit tests, integration tests (Docker required), and code quality checks (PMD, FindBugs, JaCoCo coverage)
2. **Package**: `mvn clean package -DskipTests` — produces the JAR artifact
3. **Docker Build**: Builds the Docker image and pushes to Conveyor registry
4. **Deploy to Staging**: Automatic on `release` branch; requires Deploybot authorization
5. **Deploy to Production**: Manual promotion in Deploybot after staging validation and JIRA ticket approval
6. **Post-deploy Monitoring**: Check ELK and Wavefront dashboards for errors

## Scaling

### App component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: min=1, max=15 / Production: min=2, max=20 |
| HPA target utilization | CPU-based | 100% target utilization |

### Worker component

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Staging: not specified / Production: min=2, max=15 |
| HPA target utilization | CPU-based | 100% target utilization |

## Resource Requirements

### App component

| Resource | Staging Request | Staging Limit | Production Request | Production Limit |
|----------|----------------|--------------|-------------------|-----------------|
| CPU | 400m | — | 500m | — |
| Memory | 1Gi | 2Gi | 2Gi | 4Gi |

### Worker component

| Resource | Production Request | Production Limit |
|----------|-------------------|-----------------|
| CPU | 500m | — |
| Memory | 1.5Gi | 3Gi |

## Port Configuration

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (exposed as port 80 on the Kubernetes service) |
| 8081 | Admin port (Dropwizard admin interface) |
| 8009 | JMX port |
