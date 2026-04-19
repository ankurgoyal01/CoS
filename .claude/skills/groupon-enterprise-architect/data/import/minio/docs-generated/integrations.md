---
service: "minio"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 0
---

# Integrations

## Overview

MinIO has no explicitly configured outbound integrations in this repository. It is a self-contained object storage server that responds to inbound S3 API calls. Infrastructure-level integrations include the Groupon internal Docker registry (for pulling the application image), the Helm chart repository (for deployment), and the Kubernetes secrets submodule (for secret injection). No application-level integrations with external services or internal Continuum services are defined.

## External Dependencies

> No evidence found in codebase. No outbound HTTP, gRPC, or SDK calls to external systems are present. The deployment toolchain references the following infrastructure endpoints, but these are not runtime application dependencies:

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| docker-conveyor.groupondev.com | docker pull | Source of the MinIO container image at deploy time | yes (deploy-time only) | N/A |
| artifactory.groupondev.com/artifactory/helm-generic/ | HTTP/Helm | Source of the `cmf-generic-worker` Helm chart at deploy time | yes (deploy-time only) | N/A |
| minio-secrets (git submodule) | git | Kubernetes secret values injected into the deployment | yes (deploy-time only) | N/A |

## Internal Dependencies

> No evidence found in codebase. No runtime calls from MinIO to other internal Continuum services are defined in this repository's architecture model. Per `models/relations.dsl`: "No additional container relationships are defined."

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Internal Continuum platform services that require S3-compatible object storage connect to this service over the S3 HTTP API on port 9000. The specific consumers are not enumerated in this repository.

## Dependency Health

MinIO exposes two HTTP health endpoints for Kubernetes probe integration:

- **Readiness**: `GET /minio/health/ready` — checked every 10 seconds, 5-second timeout, 3 failure threshold, with a 10-second initial delay
- **Liveness**: `GET /minio/health/live` — checked every 10 seconds, 5-second timeout, 3 failure threshold, with a 20-second initial delay

No circuit breakers or retry wrappers are configured (not applicable for a storage server).
