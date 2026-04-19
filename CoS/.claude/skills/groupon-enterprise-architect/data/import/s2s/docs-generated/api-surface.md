---
service: "s2s"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

S2S exposes a small set of HTTP endpoints via two JAX-RS resources (`continuumS2sService_apiResource` and `continuumS2sService_jobResource`). These endpoints are intended for internal operational use — manual deal updates, log level controls, booster status queries, and on-demand Quartz job triggers. The primary inbound traffic path is Kafka/MBus, not HTTP.

## Endpoints

### S2S Resource — Operational Controls

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/update` | Triggers a manual booster deal update; routes through DataBreaker MBus Mapper and DataBreaker Items Processor | Internal |
| GET/POST | `/groupon` | Performs validation calls against Groupon public endpoints | Internal |
| POST | `/logs` | Adjusts log level controls for the service at runtime | Internal |

### Job Resource — Quartz Job Triggers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/jobs/edw/customerInfo` | Triggers Quartz job to backfill customer info from Teradata EDW | Internal |
| POST | `/jobs/edw/aesRetry` | Triggers Quartz job to replay AES retry records from Teradata EDW | Internal |
| POST | `/jobs/bau/display-run` | Triggers the BAU display financial data pipeline job | Internal |

## Request/Response Patterns

### Common headers

- Standard JTier/Dropwizard HTTP headers apply.
- No public-facing authentication headers are required; endpoints are network-restricted to internal Groupon infrastructure.

### Error format

> No evidence found of a standardized error response schema in the architecture model. Dropwizard default error responses (JSON `{"code": N, "message": "..."}`) apply.

### Pagination

> Not applicable — endpoints are action triggers, not collection queries.

## Rate Limits

> No rate limiting configured. Endpoints are internal operational triggers accessed by SEM/Display Engineering operators.

## Versioning

No URL versioning scheme is in use. Endpoints are unversioned internal operations endpoints.

## OpenAPI / Schema References

> No evidence found of an OpenAPI specification or schema file in the architecture model. See the s2s service repository for any `swagger.yml` or OpenAPI annotations on JAX-RS resources.
