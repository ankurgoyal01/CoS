---
service: "deal-service"
title: Deployment
generated: "2026-03-02"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-central1, production-us-west-1, production-us-central1]
---

# Deployment

## Overview

Deal Service runs as a containerized Kubernetes workload using a Docker image built on `alpine-node16.15.0`. It is deployed across two staging and two production regions in the US. Scaling is managed by Kubernetes HPA (Horizontal Pod Autoscaler), targeting 50% CPU utilization with a range of 3–15 replicas. Deployment is managed by the Rapt CI/CD agent. Logs are shipped from a Filebeat sidecar to Splunk.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `alpine-node16.15.0`; entry point: `coffee --nodejs '--trace-warnings' ./app.coffee` |
| Orchestration | Kubernetes + Rapt | Rapt CI/CD agent manages deployments; Kubernetes manages pod lifecycle |
| Load balancer | Not applicable | Background worker; no inbound traffic |
| CDN | Not applicable | Background worker; no inbound traffic |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `staging-us-west-1` | Pre-production validation | US West 1 | Not applicable (no HTTP surface) |
| `staging-us-central1` | Pre-production validation | US Central 1 | Not applicable (no HTTP surface) |
| `production-us-west-1` | Live production processing | US West 1 | Not applicable (no HTTP surface) |
| `production-us-central1` | Live production processing | US Central 1 | Not applicable (no HTTP surface) |

## CI/CD Pipeline

- **Tool**: Rapt CI/CD agent
- **Config**: `.ci.yml`
- **Trigger**: On push / merge; manual dispatch available via Rapt

### Pipeline Stages

1. **Test**: Runs `npm test` (executes gulp jasmine test suite)
2. **Build**: Builds Docker image from `alpine-node16.15.0` base
3. **Deploy**: Rapt agent deploys the image to target Kubernetes clusters per environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | HPA (Kubernetes) | Min: 3 replicas / Max: 15 replicas / Target: 50% CPU utilization |
| Memory | Limit | Request: 500Mi / Limit: 500Mi |
| CPU | Request + HPA target | Request: 300m / HPA target: 50% |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | > No evidence found (HPA manages scaling) |
| Memory | 500Mi | 500Mi |
| Disk | > No evidence found | > No evidence found |

## Additional Runtime Details

- **Entry point**: `coffee --nodejs '--trace-warnings' ./app.coffee`
- **Log rotation**: cronolog (rotates application logs within the container)
- **Log shipping**: Filebeat sidecar container; source type: `mds_json`; destination: Splunk
- **Health probes**:
  - Readiness: `exec: echo ready` — initial delay 20s, period 5s
  - Liveness: `exec: echo live` — initial delay 30s, period 15s
- **VPA**: Enabled (Vertical Pod Autoscaler monitors resource usage)
- **Restart policy**: Master process forks a worker process on startup; worker is automatically re-forked on crash (see [Worker Process Restart Flow](flows/worker-process-restart.md))
