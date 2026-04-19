---
service: "incentive-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production-snc1, production-sac1, production-dub1, production-cloud]
---

# Deployment

## Overview

The Incentive Service is packaged as a Docker image built on `eclipse-temurin:11-jdk` and deployed to Kubernetes via Conveyor/Krane. It runs in five distinct operational modes (`batch`, `messaging`, `checkout`, `bulk`, `admin`), each deployed as a separate Kubernetes workload targeting the same image but with different `SERVICE_MODE` environment variables. Horizontal Pod Autoscaling (HPA) manages replica count per mode. The service is deployed to three on-premises regions (snc1, sac1, dub1) and a managed GCP cloud environment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `eclipse-temurin:11-jdk`; packaged via `sbt-native-packager` |
| Orchestration | Kubernetes (Conveyor/Krane) | Separate deployment per service mode |
| Load balancer | > No evidence found in codebase. | Kubernetes service / ingress |
| CDN | > No evidence found in codebase. | Not applicable for internal service endpoints |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | local | `localhost:9000` |
| staging | Pre-production validation | > No evidence found in codebase. | > No evidence found in codebase. |
| production-snc1 | Production — US West (on-prem) | snc1 | > No evidence found in codebase. |
| production-sac1 | Production — US West 2 (on-prem) | sac1 | > No evidence found in codebase. |
| production-dub1 | Production — Europe (on-prem) | dub1 | > No evidence found in codebase. |
| production-cloud | Production — GCP managed cloud | cloud (GCP) | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase.
- **Config**: > No evidence found in codebase.
- **Trigger**: > No evidence found in codebase.

### Pipeline Stages

1. **Build**: `sbt compile` — compile Scala sources
2. **Test**: `sbt test` — run unit and integration tests (specs2)
3. **Package**: `sbt docker:publishLocal` — build Docker image via sbt-native-packager
4. **Publish**: Push Docker image to container registry
5. **Deploy**: Conveyor/Krane applies Kubernetes manifests per service mode
6. **Verify**: Kubernetes readiness probe on `GET /health` gates traffic to new pods

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA per deployment mode | Min: 3 replicas, Max: 15 replicas, Target: 70% CPU utilisation |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| CPU | > No evidence found in codebase. | 70% target utilisation per HPA config |

### Deployment Modes and Scaling Notes

| Mode | Scaling Driver | Notes |
|------|---------------|-------|
| `checkout` | Request throughput | Scales with checkout traffic volume |
| `messaging` | Event throughput | Scales with Kafka/MBus event rate |
| `batch` | Schedule / CPU | Scales for qualification sweep volume |
| `bulk` | Job queue depth | Scales with export job demand |
| `admin` | User sessions | Low traffic; minimum replica count typically sufficient |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | > No evidence found in codebase. | > No evidence found in codebase. |
