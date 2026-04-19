---
service: "watson-realtime"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

watson-realtime is deployed as a set of containerized JVM workers. Each Kafka Streams application and the table trimmer job runs as an independent container. Health checking uses a file-based exec probe rather than an HTTP endpoint. Deployment configuration is managed externally to this repository; specific Kubernetes manifests and CI/CD pipeline paths are not discoverable from the architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Each worker packages as a standalone JVM container; Dockerfile paths not discoverable from architecture model |
| Orchestration | Kubernetes | Workers deployed as Kubernetes workloads; manifest paths managed externally |
| Load balancer | Not applicable | No inbound traffic — all workers are outbound-only Kafka consumers |
| CDN | None | No user-facing web traffic |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and integration testing | Not discoverable | Not applicable |
| staging | Pre-production validation | Not discoverable | Not applicable |
| production | Live production (SNC1 data center/region) | SNC1 | Not applicable — no HTTP API |

> Production Kafka topics are suffixed `_snc1` (e.g., `janus-tier2_snc1`), indicating the SNC1 data center region.

## CI/CD Pipeline

- **Tool**: Not discoverable from architecture model
- **Config**: Managed externally to this repository
- **Trigger**: Not discoverable from architecture model

### Pipeline Stages

> Deployment configuration managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kafka Streams partition-based parallelism — additional instances consume additional partitions | Determined by Kafka topic partition count |
| Memory | JVM heap tuning per worker | Not discoverable from architecture model |
| CPU | Not discoverable | Not discoverable from architecture model |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable | Not discoverable |
| Memory | Not discoverable | Not discoverable |
| Disk | Kafka Streams local state store disk | Size depends on state store configuration per worker |

> Deployment configuration managed externally. Contact dnd-ds-search-ranking@groupon.com for infrastructure sizing details.
