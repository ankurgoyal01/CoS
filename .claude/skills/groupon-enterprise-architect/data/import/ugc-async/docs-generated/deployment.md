---
service: "ugc-async"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging-us-central1, staging-europe-west1, staging-us-west-2, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

ugc-async is containerized with Docker and orchestrated on Kubernetes using Kustomize overlays. It runs as a `worker` component archetype (no inbound load balancer required for application traffic). The service is deployed across two cloud providers: GCP (primary; us-central1 and europe-west1 regions) and AWS (eu-west-1 region). CI/CD is driven by a Jenkins pipeline using the internal `java-pipeline-dsl` shared library with deploy-bot for promotion from staging to production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Image registry | Groupon internal Docker registry | `docker-conveyor.groupondev.com/usergeneratedcontent/ugc-async` |
| Orchestration | Kubernetes | Kustomize overlays at `.meta/kustomize/overlays/worker/{dev,staging,production}/` |
| Load balancer | Service LB (Kubernetes) | `enableGateway: true` for staging and production environments |
| APM | Groupon APM (enabled) | `apm.enabled: true` in common deployment config |
| Log shipping | Filebeat to Kafka/ELK | `filebeatKafkaEndpoint` set per environment; steno log source type `ugc_async_steno` |
| CDN | None | Not applicable for a worker service |

## Environments

| Environment | Purpose | Region / Cloud | VIP / URL |
|-------------|---------|----------------|-----------|
| development | Local developer testing | Local JVM | `java -jar target/ugc-async-*.jar server ./development.yml` |
| staging-us-central1 | Pre-production validation (Americas) | GCP us-central1 (stable VPC) | `ugc-async.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (EMEA) | GCP europe-west1 (stable VPC) | Configured in staging-europe-west1 overlay |
| staging-us-west-2 | Pre-production validation (AWS Americas) | AWS us-west-2 | Configured in staging-us-west-2 overlay |
| production-us-central1 | Production traffic (Americas) | GCP us-central1 (prod VPC) | `ugc-async.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-eu-west-1 | Production traffic (EMEA/AWS) | AWS eu-west-1 | Kubernetes context `ugc-async-production-eu-west-1` |
| production-europe-west1 | Production traffic (EMEA/GCP) | GCP europe-west1 (prod VPC) | Kubernetes context `ugc-async-gcp-production-europe-west1` |

## CI/CD Pipeline

- **Tool**: Jenkins (java-pipeline-dsl shared library `@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch; manual dispatch supported
- **Slack notifications**: `ugc-notifications` channel
- **Deploy targets (automatic)**: `staging-europe-west1`, `staging-us-central1`
- **Promotion**: `staging-us-central1` promotes to `production-us-central1`; `staging-europe-west1` promotes to `production-eu-west-1`
- **Deploy tool**: `deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` (deploy-bot)
- **Deploy command**: `.meta/deployment/cloud/scripts/deploy.sh {target-env} {staging|production} {namespace}`

### Pipeline Stages

1. Build: `mvn clean package` — compiles source, runs unit tests (JUnit + Mockito), generates JaCoCo coverage report
2. Docker build: Packages JAR into Docker image using `src/main/docker/Dockerfile`
3. Push: Pushes image to `docker-conveyor.groupondev.com/usergeneratedcontent/ugc-async`
4. Deploy staging: Applies Kustomize overlay for staging target environments via deploy-bot
5. Promote production: On approval/auto-promote, deploys to production target environments

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes) | Min: 3 / Max: 15 replicas (common); overridden: staging min 1 / max 1; production min 2 / max 3 |
| HPA target | CPU utilization | 50% target utilization |
| VPA | Disabled | `enableVPA: false` in production configs |

## Resource Requirements

Production (us-central1):

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1500m | Not specified (governed by HPA) |
| Memory (main) | 23Gi | 25Gi |
| CPU (filebeat) | 100m | 400m |
| Memory (filebeat) | 450Mi | 500Mi |

Common (baseline):

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | Not specified |
| Memory (main) | 500Mi | 500Mi |
| CPU (filebeat) | 10m | 30m |

> Production instances are significantly over-provisioned in memory (23-25Gi) compared to the common baseline (500Mi), reflecting the large in-memory Quartz job and message processing footprint.

## Application Ports

| Port | Purpose |
|------|---------|
| 9000 | Application HTTP port (health check, Dropwizard main connector) |
| 9001 | Dropwizard admin port (metrics, health check endpoint) |
| 8009 | JMX port |
