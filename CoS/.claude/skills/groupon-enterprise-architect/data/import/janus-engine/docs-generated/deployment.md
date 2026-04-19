---
service: "janus-engine"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
architecture_refs:
  containers: ["continuumJanusEngine"]
---

# Deployment

## Overview

Janus Engine is a Java 11 / JTier 5.14.0 service deployed as a containerized workload on Kubernetes within the Continuum platform. It runs as a long-lived stream processor with no inbound HTTP port. Multiple deployment instances can be active simultaneously, each configured to a specific `ENGINE_MODE` (e.g., one pod in `KAFKA` mode, another in `DLQ` mode). Production Kafka is addressed via the internal Kubernetes service hostname `kafka.grpn.kafka.bootstrap.kafka.production.svc.cluster.local:9093`. CI/CD is delivered through Jenkins with Mergebot-gated merges.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Java container image; Dockerfile managed in the service repository |
| Orchestration | Kubernetes | Deployed as a Kubernetes Deployment; manifests managed externally by the dnd-ingestion team |
| Load balancer | None | No inbound HTTP traffic; no load balancer required |
| CDN | None | Not applicable — stream processor only |

## Environments

| Environment | Purpose | Region | Notes |
|-------------|---------|--------|-------|
| Development | Local development and integration testing | — | Local Kafka and MBus brokers; Janus metadata service URL points to dev instance |
| Staging | Pre-production validation | — | Staging Kafka cluster and MBus; reduced topic throughput |
| Production | Live event curation | snc1, sac1, dub1 | Kafka at `kafka.grpn.kafka.bootstrap.kafka.production.svc.cluster.local:9093`; Janus metadata at `janus.web.cloud.production.service` |

## CI/CD Pipeline

- **Tool**: Jenkins + Mergebot
- **Config**: Deployment configuration managed externally in the service repository
- **Trigger**: Mergebot-approved merge to main branch; manual dispatch available

### Pipeline Stages

1. **Build**: Maven compiles Java 11 source, runs unit tests, produces a shaded JAR
2. **Package**: Docker image built from JTier base image and tagged with build version
3. **Validate**: Architecture DSL validation (if architecture module is updated)
4. **Deploy to Staging**: Kubernetes deployment updated in staging clusters; smoke validation against staging Kafka and MBus
5. **Deploy to Production**: Rolling Kubernetes deployment to `snc1`, `sac1`, and `dub1` clusters; one `ENGINE_MODE` deployment per applicable mode

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Multiple `ENGINE_MODE`-specific Kubernetes Deployments can run in parallel | Per Kubernetes manifest (managed externally) |
| Memory | JVM heap tuned for Kafka Streams state store and MBus buffering | No evidence found — managed externally |
| CPU | Per-instance throughput determined by stream processing topology depth and partition count | No evidence found — managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | None (stateless; no persistent volumes) | None |

> Deployment configuration, resource requests, and limits are defined in Kubernetes manifests owned by the dnd-ingestion team and are not discoverable from the architecture DSL.

## Health Signaling

Janus Engine does not expose an HTTP health endpoint. Liveness is signaled via a **filesystem health flag** managed by the `janusEngine_healthAndMetrics` component. Kubernetes liveness and readiness probes are expected to be configured as `exec` checks against this flag file. Metrics are emitted to `metricsStack` (Wavefront) and alerts route to PagerDuty schedule `P25RQWA`.
