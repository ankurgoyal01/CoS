---
service: "nifi-3pip"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

nifi-3pip has a focused integration footprint at the infrastructure layer. ZooKeeper is the primary internal dependency for cluster coordination. A PostgreSQL JDBC driver is bundled into the Docker image, indicating that NiFi flows connect to PostgreSQL databases, though specific connection targets are not configured in this repository's infrastructure files. Docker images are pulled from Groupon's internal Docker registry (`docker-conveyor.groupondev.com`). Helm charts are sourced from Groupon's internal Artifactory instance.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| docker-conveyor.groupondev.com | docker pull | Pulls the nifi-3pip container image for deployment | yes | External registry |
| artifactory.groupondev.com | HTTP (Helm) | Serves Helm charts (`cmf-java-api`, `cmf-java-worker`) used in deployment | yes | External registry |
| External PostgreSQL database(s) | JDBC | Target store for NiFi inventory ingestion flows (driver bundled at `drivers/postgresql-42.7.5.jar`) | conditional | Not modeled in DSL |

### docker-conveyor.groupondev.com Detail

- **Protocol**: Docker registry HTTP API
- **Base URL / SDK**: `docker-conveyor.groupondev.com/3pip-cbe/nifi-3pip` (`.meta/deployment/cloud/components/nifi/common.yml`)
- **Auth**: Internal Groupon registry credentials (managed by deployment toolchain)
- **Purpose**: Hosts the versioned nifi-3pip Docker image; pulled by Kubernetes during StatefulSet pod creation
- **Failure mode**: Deployment fails if image cannot be pulled; running pods are unaffected
- **Circuit breaker**: No

### artifactory.groupondev.com (Helm) Detail

- **Protocol**: HTTP (Helm chart repository)
- **Base URL / SDK**: `http://artifactory.groupondev.com/artifactory/helm-generic/` (`.meta/deployment/cloud/scripts/deploy.sh`)
- **Auth**: Internal Groupon Artifactory credentials (managed by deployment toolchain)
- **Purpose**: Provides `cmf-java-api` (v3.88.1) and `cmf-java-worker` (v3.90.2) Helm charts for Kubernetes manifest generation
- **Failure mode**: Deployment pipeline fails; running cluster is unaffected
- **Circuit breaker**: No

### External PostgreSQL Detail

- **Protocol**: JDBC
- **Base URL / SDK**: Driver: `drivers/postgresql-42.7.5.jar` bundled in Docker image
- **Auth**: Credentials configured within NiFi flow definitions (not in this repository)
- **Purpose**: NiFi processors read/write inventory data to PostgreSQL as part of 3PIP ingestion flows
- **Failure mode**: Affected NiFi processors fail and backpressure within the flow; other flows continue
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| ZooKeeper (`zookeeper`) | ZooKeeper client (port 2181) | Cluster coordination, leader election, and shared state management for all three NiFi nodes | `zookeeper` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. No callers of nifi-3pip's REST API are modeled in this repository's architecture DSL. Flow management is performed by operators via the NiFi web UI.

## Dependency Health

- **ZooKeeper**: Each NiFi node monitors ZooKeeper connectivity continuously. If ZooKeeper becomes unreachable, NiFi nodes lose cluster coordination and may transition out of the `CONNECTED` state. The health check script (`health-check.sh`) detects this by verifying node status via `/nifi-api/controller/cluster`.
- **ZooKeeper readiness probe**: `echo 'ruok' | nc -w 2 localhost 2181 | grep imok` (period: 30s, timeout: 5s)
- **NiFi readiness/liveness probes**: HTTP GET `/nifi-api/system-diagnostics` on port 8080
