---
service: "conveyor_k8s"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Conveyor K8s does not expose an HTTP or gRPC API surface. It is an infrastructure automation platform that operates entirely through CI/CD pipelines (Jenkins and GitHub Actions). Consumers interact with cluster infrastructure by triggering pipeline jobs, not by calling service endpoints. The Go utility binaries (`conveyorK8sPipelineUtils`) expose CLI interfaces invoked by pipeline scripts, not network APIs.

## Endpoints

> Not applicable. This service has no network endpoints. All interaction is via Jenkins pipeline job triggers or GitHub Actions workflow dispatch.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> No rate limiting configured. Cluster operations are gated by Jenkins build concurrency and GitHub Actions runner availability.

## Versioning

Pipeline definitions and utility binaries are versioned together via SemVer git tags (e.g., `v1.2.18`). The Jenkins shared library `conveyor-pipeline-dsl` is pinned per pipeline file (e.g., `@v1.0.167`). GitHub Actions release workflow (`release.yaml`) creates GitHub releases on each `v*.*.*` tag push.

## OpenAPI / Schema References

> Not applicable. No OpenAPI, proto, or GraphQL schemas exist in this repository.
