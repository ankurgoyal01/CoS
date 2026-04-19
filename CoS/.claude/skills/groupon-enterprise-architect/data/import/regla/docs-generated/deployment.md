---
service: "regla"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production-na, production-emea]
---

# Deployment

## Overview

regla is deployed as two Docker containers managed by Kubernetes: `reglaService` (the Play Framework REST API) and `reglaStreamJob` (the Kafka Streams processing job). Both containers share access to `reglaPostgresDb` (PostgreSQL) and `reglaRedisCache` (Redis), which are managed separately as platform-provisioned data stores. The service is deployed to two production regions — NA (us-west-1) and EMEA (eu-west-1) — to serve regional deal-purchase and browse event streams. Kafka is configured with SSL in all non-development environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (API) | Docker | `reglaService` Play Framework JVM container; Dockerfile in service repo |
| Container (Stream job) | Docker | `reglaStreamJob` Kafka Streams / Scala JVM container; Dockerfile in service repo |
| Orchestration | Kubernetes | Manifests managed by the Emerging Channels team; deployed via CI/CD pipeline |
| Load balancer | Kubernetes Ingress / ALB | Fronts `reglaService` for inbound REST API traffic |
| CDN | None | Internal API service; no CDN layer |
| Database | PostgreSQL (managed) | `reglaPostgresDb`; provisioned by platform team; accessed via JDBC |
| Cache | Redis (managed) | `reglaRedisCache`; TTL 403200 seconds; accessed via jedis 2.8.0 |
| Message broker | Kafka (SSL) | Kafka cluster with SSL; bootstrap servers configured via `KAFKA_BOOTSTRAP_SERVERS` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and unit testing | local | `http://localhost:9000` |
| staging | Pre-production integration testing | AWS us-west-1 | Internal staging URL |
| production-na | Live NA production (North America) | AWS us-west-1 | Internal production URL |
| production-emea | Live EMEA production (Europe, Middle East, Africa) | AWS eu-west-1 | Internal production URL |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: `.github/workflows/` (managed in service repo)
- **Trigger**: On push to feature branches (test + build); on merge to main (deploy to staging); manual dispatch (deploy to production regions)

### Pipeline Stages

1. **Compile**: SBT compiles Java and Scala sources for both `reglaService` and `reglaStreamJob`
2. **Test**: SBT runs unit and integration tests
3. **Package**: SBT assembles fat JARs for both containers
4. **Docker Build (API)**: Builds `reglaService` Docker image from JVM base
5. **Docker Build (Stream job)**: Builds `reglaStreamJob` Docker image from JVM base
6. **Push**: Pushes both images to container registry
7. **Deploy Staging**: Updates Kubernetes deployments in staging cluster (NA us-west-1)
8. **Deploy Production NA**: Updates Kubernetes deployments in production NA cluster (gated by approval)
9. **Deploy Production EMEA**: Updates Kubernetes deployments in production EMEA cluster (gated by approval)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Kubernetes HPA | Min/max replicas managed by Emerging Channels team; scales on CPU/memory utilisation |
| Horizontal (Stream job) | Kafka partition-based | One `reglaStreamJob` pod per Kafka partition assignment; scaling driven by partition count |
| Memory (API) | Kubernetes resource limits | JVM heap size configured via `JAVA_OPTS`; managed by team |
| Memory (Stream job) | Kubernetes resource limits | Kafka Streams JVM heap; managed by team |
| CPU | Kubernetes resource limits | Managed by Emerging Channels team per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (`reglaService`) | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory (`reglaService`) | Deployment configuration managed externally | Deployment configuration managed externally |
| CPU (`reglaStreamJob`) | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory (`reglaStreamJob`) | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Stateless containers; no local persistent storage | — |

> Deployment configuration managed externally by the Emerging Channels team and the Continuum platform team. Contact the Emerging Channels team for specific resource limits, replica counts, and Kafka partition assignments per environment.
