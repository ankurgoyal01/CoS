---
service: "JLA_Airflow"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

JLA Airflow does not expose a public HTTP API. It is a batch orchestration service; all interaction occurs through the Apache Airflow web UI (administrator-facing) and via outbound HTTP calls that DAGs make to downstream services. There are no consumer-facing REST, gRPC, or GraphQL endpoints published by this service.

> No evidence found in codebase of any inbound HTTP API exposed to consumers.

## Endpoints

> Not applicable. JLA Airflow does not expose external HTTP endpoints. DAGs are triggered by the Airflow scheduler (cron), `TriggerDagRunOperator` chaining, or manual triggering via the Airflow UI.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No consumer API to version.

## OpenAPI / Schema References

> No evidence found in codebase.
