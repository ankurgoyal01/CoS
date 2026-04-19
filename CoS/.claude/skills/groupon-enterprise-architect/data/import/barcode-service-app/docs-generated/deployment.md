---
service: "barcode-service-app"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Barcode Service is deployed as a containerized JVM application on Kubernetes, managed by Groupon's Conveyor Cloud platform. It runs in both AWS and GCP clusters across NA and EMEA regions. The CI/CD pipeline is Jenkins-based using the `java-pipeline-dsl` shared library. Deployments are promoted from staging to production via Deploybot, with staging targets in `us-central1` and `europe-west1` GCP clusters.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI) | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Container (Runtime) | Docker | `src/main/docker/Dockerfile` — `docker.groupondev.com/jtier/prod-java11-jtier:2023-12-19-609aedb` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests generated from `.meta/deployment/cloud/components/app/*.yml` via Raptor |
| Image registry | `docker-conveyor.groupondev.com/redemption/barcode-service` | Groupon internal Docker registry |
| Load balancer | Internal VIP (on-prem) / Kubernetes Service (cloud) | `http://fubar-vip.snc1`, `http://fubar-vip.sac1`, `http://fubar-vip.dub1` |
| Metrics / logs | Wavefront (metrics), Kibana (logs) | Wavefront dashboards; Filebeat sidecar for log shipping |

## Environments

| Environment | Purpose | Region / Cluster | Internal URL |
|-------------|---------|-----------------|--------------|
| dev-us-central1 | Developer testing | GCP us-central1 | — |
| staging-us-central1 | Pre-production validation (NA) | GCP `gcp-stable-us-central1` | `http://fubar-staging-vip.snc1` |
| staging-us-west-1 | Pre-production (US West) | AWS us-west-1 | — |
| staging-us-west-2 | Pre-production (US West 2 / RDE) | AWS us-west-2 | — |
| staging-europe-west1 | Pre-production validation (EMEA) | GCP `gcp-stable-europe-west1` | — |
| rde-dev-us-west-2 | RDE developer environments | AWS us-west-2 | — |
| rde-staging-us-west-2 | RDE staging | AWS us-west-2 | — |
| production-us-west-1 | Production (NA) | AWS us-west-1, VPC: prod | `http://fubar-vip.snc1` |
| production-us-west-2 | Production (NA West 2) | AWS us-west-2 | — |
| production-us-central1 | Production (NA GCP) | GCP `gcp-production-us-central1` | — |
| production-eu-west-1 | Production (EMEA AWS) | AWS eu-west-1 | `http://fubar-vip.dub1` |
| production-europe-west1 | Production (EMEA GCP) | GCP `gcp-production-europe-west1` | — |

Legacy on-prem colo environments: `snc1` (production + staging), `sac1` (production), `dub1` (production).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch
- **Slack channel**: `post-purchase-notification`

### Pipeline Stages

1. **Build**: Compiles Java source, runs Swagger codegen to generate JAX-RS stubs from `src/main/resources/apis/swagger_server/api-spec.yaml`, packages JAR
2. **Test**: Runs unit tests with JaCoCo coverage checks
3. **Docker build**: Builds production Docker image from `src/main/docker/Dockerfile`
4. **Publish**: Pushes image to `docker-conveyor.groupondev.com/redemption/barcode-service`
5. **Deploy to staging**: Deploys to `staging-us-central1` and `staging-europe-west1` via Deploybot
6. **Promote to production**: Manual or Deploybot promotion from staging targets to their `promote_to` production targets

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | Kubernetes HPA | Min 2 / Max 15 replicas; `hpaTargetUtilization: 100` |
| Horizontal (staging) | Kubernetes HPA | Min 1 / Max 2 replicas |
| Memory | Kubernetes resource limits | Request: `500Mi` / Limit: `500Mi` (all environments) |
| CPU | Kubernetes resource requests | Request: `1000m` (1 vCPU); no limit set in common config |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | Not set (common.yml) |
| Memory | 500Mi | 500Mi |
| Disk | Not configured | — |

### Exposed Ports

| Port Name | Port | Purpose |
|-----------|------|---------|
| `httpPort` | 8080 | Application HTTP traffic |
| `admin-port` | 8081 | Dropwizard admin interface |
| `jmx-port` | 8009 | JMX monitoring |

### Pod Containers

Each pod contains four containers as documented in the README:
- `main` — the Barcode Service application
- `main-log-tail` — log tail sidecar
- `envoy` — service mesh proxy
- `filebeat` — log shipping to Kibana
