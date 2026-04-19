---
service: "magneto-gcp"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

magneto-gcp does not expose any inbound HTTP, gRPC, or message-bus API surface. It is a batch data pipeline service that is triggered exclusively by Apache Airflow DAG schedules and manual Airflow DAG runs. There are no REST endpoints, no GraphQL schema, and no event consumers that external services call. Interaction with the service is through the Airflow UI (to trigger or monitor DAG runs) and through Airflow Variables/Secrets for runtime configuration.

## Endpoints

> Not applicable — magneto-gcp exposes no HTTP endpoints.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable — no inbound API surface.

## Versioning

> Not applicable — no API surface to version.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
