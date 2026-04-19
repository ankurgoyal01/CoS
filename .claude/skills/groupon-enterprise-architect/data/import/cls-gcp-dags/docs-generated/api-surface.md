---
service: "cls-gcp-dags"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase. `cls-gcp-dags` is a batch data pipeline service that does not expose a REST, gRPC, GraphQL, or any other inbound API surface. It is triggered exclusively by Google Cloud Scheduler via Airflow's scheduler integration and operates as a scheduled DAG execution engine. External systems interact with pipeline outputs (curated data stores) rather than with this service directly.

## Endpoints

> Not applicable. This service does not expose HTTP or RPC endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> No rate limiting configured. The service is schedule-driven and not exposed to external API consumers.

## Versioning

> Not applicable. DAG versioning is managed through source control (git) on the `cls-gcp-dags` repository (`https://github.groupondev.com/cls/cls-gcp-dags`).

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema exist for this service.
