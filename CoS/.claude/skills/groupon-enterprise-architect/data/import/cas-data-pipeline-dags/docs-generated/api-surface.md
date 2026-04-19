---
service: "cas-data-pipeline-dags"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`cas-data-pipeline-dags` is a batch orchestration service. It does not expose any HTTP, gRPC, or other inbound API surface. All pipeline execution is triggered by GCP Cloud Composer (Airflow scheduler) reading the DAG files from the configured `COMPOSER_DAGS_BUCKET`. Consumers do not call this service directly.

## Endpoints

> Not applicable. This service exposes no inbound endpoints.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No inbound API exists.

## Versioning

> Not applicable. No API versioning is needed; pipeline versions are managed via the assembly JAR version referenced in DAG configs (`artifact_version`).

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec exists for this service.
