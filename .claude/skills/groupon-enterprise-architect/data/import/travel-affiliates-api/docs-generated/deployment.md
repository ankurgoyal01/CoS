---
service: "travel-affiliates-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

The Travel Affiliates API is deployed as two separate containerized workloads on the Groupon Conveyor platform (Kubernetes): the main API application (`app` component) and a scheduled batch cron job (`cron` component). Both are built as Docker images from the same Maven project and pushed to `docker-conveyor.groupondev.com/travel/`. The application runs on Apache Tomcat 8.5.73 inside the container. Multi-region production deployments exist in GCP us-central1 and AWS eu-west-1.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (app) | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/tomcat:8.5.73-jre11-temurin`; WAR deployed to Tomcat webapps |
| Container (cron) | Docker | `cron/Dockerfile`; same base image; runs `JobRunner` via `cron.sh` entrypoint |
| Orchestration | Kubernetes (Conveyor) | `.meta/deployment/cloud/` YAML manifests; Raptor components defined in `.meta/.raptor.yml` |
| CI/CD | Jenkins | `Jenkinsfile` in repository root; Maven build with Spotify dockerfile-maven-plugin for image build, tag, and push |
| Cron scheduler | Kubernetes CronJob | Schedule: `0 10 * * *` (daily at 10:00 UTC); restart policy `OnFailure`; backoff limit 0 |
| Load balancer | Conveyor VIP | Staging VIP: `getaways-affiliate-api.us-central1.conveyor.stable.gcp.groupondev.com` |
| APM | Elastic APM | Enabled in all environments; agent injected as sidecar |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 | `getaways-affiliate-api.us-central1.conveyor.stable.gcp.groupondev.com` |
| production | Live traffic | GCP us-central1 | Internal VIP (not publicly documented) |
| production | Live traffic (EU) | AWS eu-west-1 | Internal VIP (not publicly documented) |

### Service ID

The Conveyor service ID is `getaways-affiliate-api` (defined in `.service.yml` and `.meta/deployment/cloud/components/app/common.yml`).

### Docker image repositories

| Component | Image |
|-----------|-------|
| API | `docker-conveyor.groupondev.com/travel/travel-affiliates-api:{version}` |
| Cron | `docker-conveyor.groupondev.com/travel/travel-affiliates-api--cron:{version}` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push / pull request

### Pipeline Stages

1. **Build**: Compiles Java source with Maven (`mvn clean package`); runs unit tests (TestNG + JUnit via Spock); generates WAR artifact
2. **Docker build (app)**: Builds API Docker image using `src/main/docker/Dockerfile`; tags with Maven project version
3. **Docker build (cron)**: Builds cron Docker image using `cron/Dockerfile`; tags with Maven project version
4. **Push**: Pushes both images to `docker-conveyor.groupondev.com/travel/`
5. **Deploy**: Triggered via Conveyor; applies `.meta/deployment/cloud/` manifests to target Kubernetes namespace

## Scaling

### API Container

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA | Min: 2 / Max: 15 / Target CPU: 50% |
| Memory | Fixed limit | Request: 2048Mi / Limit: 2048Mi (staging); 3072Mi (prod us-central1); 4096Mi (prod eu-west-1) |
| CPU | Request only | Request: 100m (main) |

### Cron Container

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed single instance | Min: 1 / Max: 1 |
| Memory | Fixed limit | Request: 512Mi / Limit: 1024Mi (production) |
| CPU | Request only | Request: 500m (main); 10m limit 30m (filebeat) |

## Resource Requirements

### API Container

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | Not set (best-effort) |
| Memory | 2048Mi | 2048Mi (staging) / 3072Mi (prod-us) / 4096Mi (prod-eu) |
| Disk | Standard | Standard |

### Cron Container

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | Not set |
| Memory | 512Mi (prod) | 1024Mi (prod) |
| Disk | Standard | Standard |

## Log Configuration

Both containers emit structured JSON logs to:
- Application log: `/var/groupon/apache-tomcat/logs/travel-affiliates-application.log`
- API access log: `/var/groupon/apache-tomcat/logs/api/travel-affiliates-api-access.log`

Log collection is handled by Filebeat sidecar (volume type `medium` in production).

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application traffic (Tomcat) |
| 8081 | Admin port |
| 8009 | JMX port |
