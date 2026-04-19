---
service: "bhuvan"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-europe-west1", "staging-us-west-1", "production-us-central1", "production-europe-west1", "production-eu-west-1"]
---

# Deployment

## Overview

Bhuvan is deployed as a containerized Java 11 JTier/Dropwizard service on Kubernetes. It runs on both GCP (us-central1, europe-west1) and AWS (eu-west-1, us-west-1) clusters. Deployments are managed by DeployBot with environment-specific Kubernetes manifests under `.meta/deployment/cloud/`. The Docker image is published to `docker-conveyor.groupondev.com/geo-fabric/bhuvan`. A Logstash sidecar container handles log forwarding to Kafka.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (app) | Docker | `src/main/docker/Dockerfile` — extends `prod-java11-jtier:3`, bundles MaxMind GeoIP2-City DB |
| Container (CI build) | Docker | `.ci/Dockerfile` — extends `dev-java11-maven:2020-12-04-277a463` |
| Container (Postgres dev) | Docker | `src/main/docker/postgres/Dockerfile` — Postgres 11 + PostGIS |
| Orchestration | Kubernetes | Manifests generated from `.meta/deployment/cloud/` YAML via Conveyor/Raptor |
| Log sidecar | Logstash | `docker-conveyor.groupondev.com/data/logstash_grpn_tls_jmx:1.4` — forwards Finch experiment logs to Kafka |
| Registry | Docker Artifactory | `docker-conveyor.groupondev.com/geo-fabric/bhuvan` |
| Load balancer | Kubernetes Service VIP | Per-environment VIP (see Environments table) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-central1 | Staging (GCP) | GCP us-central1 | `bhuvan.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Staging (GCP EMEA) | GCP europe-west1 | (cluster: `gcp-stable-europe-west1`) |
| staging-us-west-1 | Staging (AWS) | AWS us-west-1 | `bhuvan.staging.service.us-west-1.aws.groupondev.com` |
| production-us-central1 | Production (GCP US) | GCP us-central1 | `bhuvan.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-europe-west1 | Production (GCP EMEA) | GCP europe-west1 | (cluster: `gcp-production-europe-west1`) |
| production-eu-west-1 | Production (AWS EMEA) | AWS eu-west-1 | (cluster: `production-eu-west-1`) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch or branches matching `/^COOR-\d+/`; deployment via DeployBot (`.deploy_bot.yml`)

### Pipeline Stages

1. **Build**: Maven build (`mvn clean verify`) including unit tests, integration tests, and code quality checks (JaCoCo, PMD, FindBugs).
2. **Docker Build**: Create Docker image (`mvn install -DskipTests=true -DskipDocker=false`) and push to `docker-conveyor.groupondev.com/geo-fabric/bhuvan`.
3. **Deploy Staging**: DeployBot triggers Kubernetes deployment to staging clusters (`staging-us-central1`, `staging-europe-west1`, `staging-us-west-1`) automatically.
4. **Promote to Production**: Production deployments (`production-us-central1`, `production-europe-west1`) are `manual: true` in `.deploy_bot.yml` — require explicit promotion after staging validation.

### Deployment Command Examples

```bash
# GCP environments
bash ./.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging bhuvan-staging
bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production bhuvan-production

# AWS environments
bash ./.meta/deployment/cloud/scripts/deploy_aws.sh production-eu-west-1 production bhuvan-production
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min 3 / Max 10–17 replicas; target CPU utilization 60% (`hpaTargetUtilization: 60`) |
| Memory (production GCP US) | Fixed limits | Request: 12Gi / Limit: 15Gi |
| CPU (production GCP US) | Fixed request | Request: 1000m (app) + 50m (envoy) |
| Memory (staging GCP US) | Fixed limits | Request: 4.5Gi / Limit: 5Gi |
| CPU (staging GCP US) | Fixed request | 1500m |

## Resource Requirements

### Production (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (app) | 1000m | - |
| CPU (envoy) | 50m | - |
| Memory (app) | 12Gi | 15Gi |
| Memory (envoy) | 250Mi | - |

### Staging (GCP us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (app) | 1500m | - |
| Memory (app) | 4.5Gi | 5Gi |

### Common (all environments)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (filebeat) | 100m | 200m |
| Memory (filebeat) | 100Mi | 200Mi |
| CPU (logstash) | 75m | 150m |
| Memory (logstash) | 500Mi | 1Gi |

## Health Probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|---------------|--------|
| Readiness | `/grpn/healthcheck` | 8080 | 20s | 5s |
| Liveness | `/grpn/healthcheck` | 8080 | 30s | 15s |
