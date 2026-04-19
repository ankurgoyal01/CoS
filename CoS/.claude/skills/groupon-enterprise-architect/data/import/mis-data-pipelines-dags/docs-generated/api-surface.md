---
service: "mis-data-pipelines-dags"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`mis-data-pipelines-dags` does not expose any HTTP API surface. It is a pure orchestration service driven by the Airflow scheduler (Cloud Composer). All interactions are outbound — the service calls external systems (MDS API, Kafka, Hive/EDW, GCP APIs) rather than serving inbound requests. Operational interaction with DAGs is performed through the Cloud Composer Airflow web UI or via the Airflow REST API provided by Cloud Composer itself (not owned by this service).

## Endpoints

> No evidence found in codebase. This service exposes no HTTP endpoints.

## Request/Response Patterns

### Common headers

> Not applicable. No inbound HTTP interface.

### Error format

> Not applicable. No inbound HTTP interface.

### Pagination

> Not applicable. No inbound HTTP interface.

## Rate Limits

> Not applicable. No inbound HTTP interface.

## Versioning

> Not applicable. No inbound HTTP interface.

## OpenAPI / Schema References

> Not applicable. No inbound HTTP interface.
