---
service: "clam-load-generator"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The CLAM Load Generator does not expose any inbound HTTP API. It is a batch-style Spring Boot application that executes its workload on the `ApplicationReadyEvent` and terminates. All traffic is outbound — the service writes to Kafka, Telegraf, or SMA backends, and queries Wavefront for verification.

## Endpoints

> Not applicable. This service has no inbound endpoints.

## Request/Response Patterns

### Common headers

> Not applicable — no inbound HTTP interface.

### Error format

> Not applicable — no inbound HTTP interface.

### Pagination

> Not applicable — no inbound HTTP interface.

## Rate Limits

> No rate limiting configured for inbound requests. Outbound write rate is controlled by the `generator.rate-per-second` configuration property using a Guava `RateLimiter`.

## Versioning

> Not applicable — no API versioned interface.

## OpenAPI / Schema References

The service includes a generated Swagger client for the Wavefront Query API (outbound, read-only). The client specification documents are located at:

- `docs/QueryApi.md` — `GET /api/v2/chart/api` and `GET /api/v2/chart/raw`
- `docs/QueryResult.md` — charting query response model
- `docs/RawTimeseries.md` — raw timeseries response model
