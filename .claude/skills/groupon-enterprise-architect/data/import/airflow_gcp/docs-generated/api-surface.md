---
service: "airflow_gcp"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

The Airflow GCP SFDC ETL service does not expose any HTTP API, gRPC interface, GraphQL schema, or message-bus topics to external callers. All execution is internally driven by the Apache Airflow scheduler on Cloud Composer. The service acts exclusively as an outbound integrator: it calls external systems (Teradata EDW, Hive, Salesforce Bulk API, GCS) but does not serve any endpoint.

## Endpoints

> No evidence found. This service exposes no inbound HTTP or RPC endpoints.

## Request/Response Patterns

### Common headers

> Not applicable — no inbound API surface.

### Error format

> Not applicable — no inbound API surface.

### Pagination

> Not applicable — no inbound API surface.

## Rate Limits

> No rate limiting configured. This service makes no inbound connections.

## Versioning

> Not applicable — no inbound API surface.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
