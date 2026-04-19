---
service: "janus-user-activity-store"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Janus User Activity Store is a batch data pipeline — it does not expose an HTTP API, gRPC service, or any synchronous consumer-facing interface. All processing is triggered by the Airflow scheduler (Cloud Composer). The service reads from GCS and writes to Bigtable; it has no inbound network surface.

## Endpoints

> Not applicable. This service has no HTTP, gRPC, or GraphQL endpoints.

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

> Not applicable. No inbound HTTP interface. The Spark JAR is versioned via Maven semver (`major-minor.patch`) and referenced by path in the Airflow DAG configuration.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema present.
