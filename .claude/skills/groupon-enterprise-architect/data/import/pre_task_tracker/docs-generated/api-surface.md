---
service: "pre_task_tracker"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`pre_task_tracker` does not expose any HTTP, gRPC, or other inbound API surface. It is a purely scheduled and internally-triggered Airflow DAG package. All interactions are driven by the Airflow scheduler, the Airflow UI, and configured cron/continuous schedule intervals. External systems interact with the service's outputs (JSM alerts, Jira tickets, Google Drive documents, MySQL records) rather than calling into the service directly.

## Endpoints

> Not applicable. This service has no inbound API endpoints.

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

> Not applicable. No versioned API exists.

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec, proto files, or GraphQL schema.
