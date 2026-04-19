---
service: "push-client-proxy"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-europe-west1", "production-us-central1", "production-europe-west1", "production-eu-west-1"]
---

# Deployment

## Overview

push-client-proxy is containerized with Docker and deployed to Kubernetes clusters across two cloud providers (GCP and AWS) in multiple regions. CI/CD is managed by Jenkins using the `conveyor-ci-util` shared library. On every merge to `main` the pipeline builds, publishes a Docker image to Groupon's internal registry, and triggers deploy-bot to deploy to all configured targets.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `eclipse-temurin:17-jre-jammy`; entrypoint runs `kafka-tls-v2.sh` then starts the JAR |
| CI image | Docker | `docker.groupondev.com/jtier/dev-java17-maven:3` (`.ci/Dockerfile`) |
| Orchestration | Kubernetes | Raptor/Conveyor deployment manifests in `.meta/deployment/cloud/` |
| Image registry | Groupon internal | `docker-conveyor.groupondev.com/rocketman/push-client-proxy-service` (prod), `docker-dev.groupondev.com/rocketman/push-client-proxy-service` (CI push) |
| Load balancer | Hybrid Boundary (Envoy) | `hybridBoundary` configured with `public` and `default` namespaces/subdomains in each environment manifest |
| CDN | Not applicable | — |

## Environments

| Environment | Purpose | Region / Provider | Notes |
|-------------|---------|---------------------|-------|
| `staging-us-central1` | Staging / QA | GCP us-central1 | Min 1 / max 2 replicas; memory 2–4 Gi |
| `staging-europe-west1` | Staging / QA (EMEA) | GCP europe-west1 | Min 1 / max 2 replicas |
| `production-us-central1` | Production (US/Canada) | GCP us-central1 | Min 50 / max 100 replicas; CPU 6000m–12000m; memory 5–10 Gi |
| `production-europe-west1` | Production (EMEA) | GCP europe-west1 | Production-grade sizing |
| `production-eu-west-1` | Production (EMEA) | AWS eu-west-1 | Datacenter `dub1`; deploy via deploy-bot |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to any branch; deploy stages run for `main`, `staging`, and `sg/jenkins_2git` branches
- **Slack notifications**: `subscription-engineering-deployments` channel

### Pipeline Stages

1. **Prepare**: Computes version as `{date}-{shortSha}`, determines branch type, sets deployment flags
2. **Build check and test**: Runs `mvn clean package -DskipTests` inside `maven:3.9.6-eclipse-temurin-17` Docker container
3. **Validate Deploy Config**: Validates `.deploy_bot.yml` against Conveyor deploy validator
4. **Build and publish dockerized application for cloud**: Builds Docker image tagged as `push-client-proxy-service:{version}`, pushes to `docker-dev.groupondev.com/rocketman/push-client-proxy-service`
5. **Deploy**: Invokes `deploybotDeploy` for all targets: `staging-us-central1`, `staging-europe-west1`, `production-us-central1`, `production-eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | Min 50 / max 100 pods, `hpaTargetUtilization: 20` |
| Horizontal (staging) | Kubernetes HPA | Min 1 / max 2 pods |
| Memory (production) | Resource limits | Request: 5000 Mi, Limit: 10000 Mi |
| CPU (production) | Resource limits | Request: 6000m, Limit: 12000m |

## Resource Requirements

### Production (us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 6000m | 12000m |
| CPU (envoy) | 50m | 1000m |
| CPU (filebeat) | 100m | 1500m |
| Memory (main) | 5000 Mi | 10000 Mi |
| Memory (envoy) | 100 Mi | 400 Mi |
| Memory (filebeat) | 100 Mi | 400 Mi |
| Disk | Not specified | — |

### Staging (us-central1)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m (common default) | — |
| Memory (main) | 2 Gi | 4 Gi |

### JVM

- Heap: `-Xms512m -Xmx2g` (Dockerfile default)
- GC: `-XX:+UseG1GC -XX:MaxGCPauseMillis=200` (Maven plugin JVM args)

### Additional Volumes

- `client-certs` mounted at `/var/groupon/certs` — contains Kafka SSL keystores and truststores
- Application port: `8080` (HTTP), `8081` (admin), `8009` (JMX)
