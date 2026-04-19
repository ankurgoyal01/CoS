---
service: "nifi-3pip"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, production-us-central1]
---

# Deployment

## Overview

nifi-3pip is deployed as two Kubernetes StatefulSets (one for NiFi nodes, one for ZooKeeper) on GCP-hosted Kubernetes clusters. Both components run with exactly 3 replicas. Deployment is managed by the Groupon DeployBot system using Helm chart templating (`cmf-java-api` for NiFi, `cmf-java-worker` for ZooKeeper) with Kustomize post-rendering for StatefulSet-specific patches. The CI pipeline uses Jenkins with the `java-pipeline-dsl` shared library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (NiFi) | Docker | `Dockerfile` — `FROM apache/nifi:2.4.0` with custom libs, drivers, and startup scripts |
| Container (ZooKeeper) | Docker | `docker-conveyor.groupondev.com/bitnami/zookeeper` (version set to `3.8.0` in deploy script) |
| Orchestration | Kubernetes (StatefulSet) | `.meta/kustomize/` and `.meta/deployment/cloud/` manifests |
| Helm chart (NiFi) | cmf-java-api 3.88.1 | Sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Helm chart (ZooKeeper) | cmf-java-worker 3.90.2 | Sourced from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Kustomize | Kustomize (post-renderer) | `.meta/kustomize/overlays/nifi/<env>/kustomize`, `.meta/kustomize/overlays/zookeeper/<env>/kustomize` |
| Kubernetes deploy tool | Krane | Used in `deploy.sh` with `--global-timeout=1800s` |
| Load balancer | Kubernetes Service (ClusterIP) | Headless service `headless-nifi-3pip--nifi--default` exposes ports 8082 and 6342 |
| CI/CD | Jenkins | `Jenkinsfile` (uses `java-pipeline-dsl@latest-2`) |
| Image registry | docker-conveyor.groupondev.com | `docker-conveyor.groupondev.com/3pip-cbe/nifi-3pip` |

## Environments

| Environment | Purpose | Region | Kubernetes Context |
|-------------|---------|--------|--------------------|
| staging-us-central1 | Pre-production validation | GCP us-central1 (stable VPC) | `nifi-3pip-gcp-staging-us-central1` |
| production-us-central1 | Production workloads | GCP us-central1 (prod VPC) | `nifi-3pip-gcp-production-us-central1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push (via `dockerBuildPipeline` DSL)
- **Default deploy target**: `staging-us-central1`

### Pipeline Stages

1. **Build**: Builds and tags the `nifi-3pip` Docker image using the root `Dockerfile`
2. **Push**: Pushes the image to `docker-conveyor.groupondev.com/3pip-cbe/nifi-3pip`
3. **Deploy (staging)**: Executes `.meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging nifi-3pip-staging` via DeployBot
4. **Deploy (production)**: Executes `.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production nifi-3pip-production` via DeployBot (manual promotion)

The deploy script templates both the NiFi Helm chart and the ZooKeeper Helm chart, then applies the merged manifests to the target Kubernetes namespace using Krane.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| NiFi Horizontal | Fixed StatefulSet (no auto-scaling) | `minReplicas: 3`, `maxReplicas: 3` |
| ZooKeeper Horizontal | Fixed StatefulSet (no auto-scaling) | `minReplicas: 3`, `maxReplicas: 3` |
| Pod Management | Parallel startup | `podManagementPolicy: Parallel` (both StatefulSets) |

## Resource Requirements

### NiFi Nodes (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 4000m (4 vCPU) |
| Memory | 10 GiB | 20 GiB |
| Content repository disk | — | 20 GiB (PVC) |
| Provenance repository disk | — | 10 GiB (PVC) |
| FlowFile repository disk | — | 5 GiB (PVC) |

JVM heap: `-Xms12g -Xmx24g` (set via `NIFI_JVM_HEAP_INIT`/`NIFI_JVM_HEAP_MAX`).

### ZooKeeper Nodes (per pod)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 150m | Not specified |
| Memory (filebeat sidecar) | 100 MiB | Not specified |
| Data disk | — | 10 GiB (PVC) |

## Probes

### NiFi

| Probe | Type | Path | Port | Config |
|-------|------|------|------|--------|
| Startup | HTTP GET | `/nifi-api/system-diagnostics` | 8080 | `initialDelaySeconds: 60`, `periodSeconds: 10`, `failureThreshold: 30` |
| Readiness | HTTP GET | `/nifi-api/system-diagnostics` | 8080 | `periodSeconds: 10`, `failureThreshold: 3` |
| Liveness | HTTP GET | `/nifi-api/system-diagnostics` | 8080 | `periodSeconds: 15`, `failureThreshold: 5` |

### ZooKeeper

| Probe | Type | Command | Config |
|-------|------|---------|--------|
| Readiness | exec | `echo 'ruok' \| nc -w 2 localhost 2181 \| grep imok` | `delaySeconds: 30`, `periodSeconds: 30`, `timeoutSeconds: 5` |
| Liveness | exec | `echo 'ruok' \| nc -w 2 localhost 2181 \| grep imok` | `delaySeconds: 30`, `periodSeconds: 30`, `timeoutSeconds: 5` |

## Network

- NiFi HTTP port: `8080` (exposed via Kubernetes Service)
- NiFi cluster protocol port: `8082` (headless service)
- NiFi load balancer port: `6342` (headless service)
- ZooKeeper client port: `2181` (Service)
- ZooKeeper follower port: `2888` (headless service)
- ZooKeeper election port: `3888` (headless service)
- ZooKeeper connect string used by NiFi: `nifi-3pip--zookeeper:2181`
- StatefulSet timeout override: `1h` (krane annotation on both StatefulSets)
- Termination grace period (NiFi): 30 seconds

## Security Context

| Component | runAsUser | fsGroup |
|-----------|-----------|---------|
| NiFi main container | 1000 | 1000 |
| ZooKeeper main container | 0 | — |

## Local Development

Run all three NiFi nodes plus ZooKeeper locally using Docker Compose:

```shell
docker-compose up -d
```

Local port mappings: nifi-1 → `8021` (HTTP) / `9444` (HTTPS), nifi-2 → `8022` / `9445`, nifi-3 → `8023` / `9446`. ZooKeeper at `localhost:2181`.
