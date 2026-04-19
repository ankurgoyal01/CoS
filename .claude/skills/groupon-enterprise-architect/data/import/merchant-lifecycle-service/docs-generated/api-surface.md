---
service: "merchant-lifecycle-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jtier-auth]
---

# API Surface

## Overview

The `continuumMlsRinService` exposes a REST API consumed by merchant-facing portals, internal tooling, and analytics consumers. All endpoints are served over HTTP via Dropwizard/JTier. The API is organized into three groups: unit/inventory queries, merchant insights, and operational/utility endpoints.

## Endpoints

### Unit and Inventory

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/units/v1/search` | Search units by criteria; returns aggregated inventory results | JTier Auth |
| GET | `/units/v1/find/{isid}/{uuid}` | Retrieve a specific unit by inventory source ID and UUID | JTier Auth |
| GET | `/units/v1/counts` | Return unit counts for a given query context | JTier Auth |

### Merchant Insights

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/insights/merchant/{uuid}/analytics` | Retrieve aggregated merchant analytics data | JTier Auth |
| GET | `/insights/merchant/{uuid}/cxhealth` | Retrieve CX health metrics for a merchant | JTier Auth |

### History and CLO

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/history` | Retrieve merchant deal history events | JTier Auth |
| GET | `/clo/transactions` | Retrieve CLO (Card-Linked Offers) transaction records | JTier Auth |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ping` | Health check / liveness probe | None |

## Request/Response Patterns

### Common headers
- `Authorization` — JTier token for authenticated endpoints
- `Content-Type: application/json` — required for POST endpoints

### Error format
> No evidence found in the architecture inventory. Standard Dropwizard/JTier error envelope is expected (HTTP status code with JSON body).

### Pagination
> No evidence found in the architecture inventory. Pagination patterns to be confirmed by service owner.

## Rate Limits

> No rate limiting configured — not evidenced in the architecture inventory.

## Versioning

URL path versioning is used for unit endpoints (`/units/v1/`). Insights, history, and CLO endpoints do not carry a version prefix in the known paths.

## OpenAPI / Schema References

> OpenAPI spec generated via Swagger Codegen 3.0.25. Spec location within the service repository to be confirmed by service owner.
