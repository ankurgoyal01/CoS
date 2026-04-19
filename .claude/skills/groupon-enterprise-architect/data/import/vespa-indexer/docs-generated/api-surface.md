---
service: "vespa-indexer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

The Vespa Indexer exposes a lightweight REST API over HTTP on port 8080 (container) / 8000 (local). The API is not intended for general consumers — it serves two internal purposes: health probes for Kubernetes, and trigger endpoints invoked by Kubernetes CronJobs or operators to start background indexing jobs. All indexing operations run asynchronously as FastAPI background tasks; the endpoints return immediately with `202 Accepted`-style responses.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Basic Kubernetes liveness/readiness probe; returns `{"status": "healthy", "service": "vespa-indexer"}` | None |
| `GET` | `/grpn/health` | Detailed health check including Vespa connectivity, thread counts, and process info | None |

### Indexing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/indexing/index-deals` | Index up to 50 specific deal UUIDs on demand by fetching from MDS REST API and writing to Vespa | None |

### Scheduler

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/scheduler/refresh-deals` | Trigger the daily deal refresh background job (called by `cronjob-deal-refresh` CronJob) | None |
| `POST` | `/scheduler/refresh-features` | Trigger the ML feature refresh background job (called by `cronjob-feature-refresh` CronJob) | None |

### Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/metrics` | Prometheus metrics exposition (instrumented by `prometheus_fastapi_instrumentator`) | None |

## Request/Response Patterns

### `POST /indexing/index-deals`

Request body (JSON):
```json
{
  "deal_uuids": ["<uuid1>", "<uuid2>"]
}
```
- `deal_uuids`: Array of deal UUID strings; minimum 1, maximum 50 (constrained by MDS API URL length limit).

Response body:
```json
{
  "message": "Indexing process started for N deal UUIDs",
  "status": "accepted",
  "deal_count": "N"
}
```

### `POST /scheduler/refresh-deals` and `POST /scheduler/refresh-features`

No request body required. Response:
```json
{
  "message": "Deal refresh job started",
  "status": "accepted"
}
```

### Common headers

> No evidence found in codebase of required request headers beyond standard HTTP.

### Error format

FastAPI default error structure:
```json
{
  "detail": "<error description>"
}
```
HTTP 503 is returned when a required use case (e.g. `RefreshFeaturesUseCase`) is not available (e.g. BigQuery is disabled). HTTP 500 is returned for unexpected startup failures.

### Pagination

> Not applicable — endpoints accept bounded input (max 50 UUIDs) and do not return paginated results.

## Rate Limits

No rate limiting configured.

## Versioning

No API versioning strategy. All endpoints are at root path with no version prefix.

## OpenAPI / Schema References

FastAPI auto-generates an OpenAPI schema available at `/docs` (Swagger UI) and `/openapi.json` when the service is running. No static OpenAPI file is committed to the repository.
