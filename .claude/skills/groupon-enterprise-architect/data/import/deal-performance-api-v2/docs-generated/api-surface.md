---
service: "deal-performance-api-v2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal-network"]
---

# API Surface

## Overview

Deal Performance API V2 exposes a synchronous REST API over HTTP. All three endpoints return pre-aggregated performance metrics from the PostgreSQL database. Requests are scoped to a single deal UUID with an explicit time range. Consumers include Marketing analytics tools and the Search/Ranking pipeline. The API is defined in `src/main/resources/swagger.yaml` and consumer-visible documentation is hosted at the Swagger UI in production.

## Endpoints

### Deal Performance Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/getDealPerformanceMetrics` | Returns time-series performance metrics (purchases, views, CLO claims, impressions) for a deal, grouped by configurable dimensions | Internal network |

**Query parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `shouldUsePrimaryDb` | boolean | No | `false` | Routes the query to the primary (read-write) database instead of the replica |
| `shouldUseNewSQL` | boolean | No | `false` | Selects the optimized single-metric SQL template (only valid for single-metric requests) |

**Request body** (`DealPerformanceMetricsRequest`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dealId` | UUID | Yes | The deal to query |
| `fromTime` | ISO 8601 datetime | Yes | Start of the query window |
| `toTime` | ISO 8601 datetime | Yes | End of the query window |
| `timeGranularity` | `HOURLY` or `DAILY` | Yes | Time bucket granularity |
| `metrics` | Array of `MetricsRequest` | Yes | List of metric definitions to retrieve |

Each `MetricsRequest` element:

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `name` | string (enum) | Yes | `PURCHASES`, `VIEWS`, `CLO_CLAIMS`, `IMPRESSIONS` |
| `groupBy` | array of string (enum) | Yes | `PLATFORM`, `GENDER`, `BRAND`, `TIMESTAMP`, `OPTION_ID`, `DIVISION_ID`, `ACTIVATION` |
| `groupAlias` | string | No | Optional alias for the metric group in the response |

### Deal Option Performance Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/getDealOptionPerformanceMetrics` | Returns purchases and activations per deal option, grouped by configurable dimensions | Internal network |

**Request body** (`DealOptionPerformanceMetricsRequest`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dealId` | UUID | Yes | The deal to query |
| `fromTime` | ISO 8601 datetime | Yes | Start of the query window |
| `toTime` | ISO 8601 datetime | Yes | End of the query window |
| `timeGranularity` | `HOURLY` or `DAILY` | Yes | Routes query to `deal_option_performance_hourly` or `deal_option_performance_daily` |
| `groupBy` | array of string | Yes | Columns to group results by |

### Deal Attribute Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/getDealAttributeMetrics` | Returns daily deal attribute data (NOB, NOR, GR, GB, refunds, unique visitors, redemption rate, promo codes, impressions) | Internal network |

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dealId` | UUID | No | The deal UUID to query |
| `brand` | string (enum) | No | `GROUPON` or `LIVINGSOCIAL` — filters by brand |
| `attributes` | array of string (enum) | No | One or more of: `IMPRESSIONS`, `NOB`, `NOR`, `GR`, `GB`, `REFUNDS`, `UNIQUE_VISITORS`, `REDEMPTION_RATE`, `PROMOCODES` |
| `fromDate` | string | No | Start date (inclusive) |
| `toDate` | string | No | End date (inclusive) |

## Request/Response Patterns

### Common headers

> No evidence found in codebase of custom required headers beyond standard HTTP.

### Error format

> No custom error format defined in the OpenAPI spec; Dropwizard default error responses apply.

### Pagination

> No pagination is implemented. All matching results for the requested time window are returned in a single response.

## Rate Limits

> No rate limiting configured.

## Versioning

The API is versioned by service name (`v2` in `deal-performance-api-v2`). There is no URL-path versioning within the service. The version is encoded in the service identifier.

## OpenAPI / Schema References

- `src/main/resources/swagger.yaml` — canonical OpenAPI 2.0 specification
- `doc/swagger/swagger.yaml` — published copy
- Production Swagger UI: `https://deal-performance-service-v2.production.service.us-central1.gcp.groupondev.com/swagger/?url=.../swagger.json`
