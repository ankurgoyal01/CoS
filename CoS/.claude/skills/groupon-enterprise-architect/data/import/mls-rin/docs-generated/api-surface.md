---
service: "mls-rin"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

MLS RIN exposes a versioned REST API consumed exclusively by internal Groupon services and Merchant Center. All endpoints return `application/json`. Authentication is performed via client-ID role-based access (JTier `jtier-auth-bundle`). The API is documented in `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`. Endpoints are grouped into functional domains: deals, unit search, metrics, history, CLO transactions, insights, and merchant risk.

## Endpoints

### Health / Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ping` | Liveness check — returns ping response | None |
| GET | `/grpn/healthcheck` | Readiness health check | None |
| GET | `/grpn/status` | Application status summary including build info | None |

### Deal Index

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/deals` | List deals filtered by merchant_id, deal_ids, deal_status, inventory_service, and other criteria with selective field projection | client-id |
| POST | `/v1/deals` | List deals with the same query params plus a body filter (`DealIndexBodyFilter`) and date range | client-id |
| POST | `/v1/dealsv2` | List deals — v2 variant accepting body filter with additional start_date/end_date fields | client-id |
| GET | `/v1/deals/{deal_id}` | Fetch single deal by deal UUID with optional merchant_id and field projection | client-id |
| GET | `/v1/deal_counts` | Returns deal counts for a merchant | client-id |

### Unit Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/units/v1/find/{isid}/{uuid}` | Find a single unit by inventory service ID and unit UUID; supports `show` field projection and `locale` | client-id |
| POST | `/units/v1/search` | Search units across inventory services using a `UnitSearchRequest` body | client-id |
| POST | `/units/v2/find` | Batch fetch units by a list of unit references (`UnitBatchRequest`) | client-id |
| POST | `/units/v2/search` | Bulk search units — v2 variant of unit search | client-id |

### Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/metrics` | Returns raw metrics (email/web/mobile impressions, clicks, shares, referrals) for deal UUIDs within a time range with aggregation period | client-id |
| GET | `/v1/performance` | Returns performance timeline data for deals | client-id |
| GET | `/v1/best_of` | Returns best-of deal performance summaries | client-id |

### History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/history` | Returns history event list filtered by event_type, user_type, user_id, merchant_id, deal_id, date range, and rendered_for context; supports pagination | client-id |

### CLO Transactions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/clotransactions/itemized_list` | Returns itemized list of CLO transactions for given deal IDs and date range | client-id |
| POST | `/v2/clotransactions/visits` | Returns CLO visit aggregates for given deal IDs, date range, and locale | client-id |
| POST | `/v2/clotransactions/new_customers` | Returns new customer counts for given merchant deal IDs and date range | client-id |

### Insights

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/insights/merchant/{merchantUUID}/analytics` | Fetches merchant insights analytics for a given merchant UUID | client-id |
| GET | `/v1/insights/merchant/{merchantUUID}/cxhealth` | Fetches merchant CX health insights for a given merchant UUID | client-id |

### Merchant Risk

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/merchant_risk/{merchant_id}` | Returns merchant risk status and threshold data for a given merchant UUID | client-id |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` (required for POST endpoints with request body)
- `Accept: application/json`
- Client authentication is via client-ID header managed by JTier auth bundle (specific header name is framework-managed)

### Error format
Standard Dropwizard/JTier error response: JSON object with `code` and `message` fields. Invalid requests return HTTP 400 (`BadRequestException`) with a descriptive message (e.g., missing required filter fields in CLO endpoints).

### Pagination
Several endpoints support `page` (integer, 1-based) and `per_page` (integer) query parameters. Response bodies include pagination metadata when the `pagination` or `PAGINATION` show-field is requested.

### Field projection (`show` parameter)
Most deal and unit endpoints accept a `show` query parameter (multi-value) that controls which data sections are included in the response. Deal show values include: `pagination`, `deal`, `products`, `counts`, `earnings`, `stats`, `cap`, `expiration`, `replenishment`, `fineprint`, `redemptionLocationIds`, `divisions`, `dws`, `discussion`, `images`, `suggestions`. Unit show values include: `PAGINATION`, `VOUCHER`, `CUSTOMER`, `MERCHANT`, `DEAL`, `ORDER`, `AMOUNTS`, `PRODUCT`, `INVENTORYPRODUCT`, `REDEMPTION`, `REDEEMABILITY`, `FEATURES`, `PAYLOADS`.

## Rate Limits

No rate limiting configured.

## Versioning

URL path versioning: `v1` for most endpoints, `v2` for CLO transactions and the batch unit-find endpoint. The v2 deal endpoint (`/v1/dealsv2`) uses a path-based label rather than a numeric version segment.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml`
- Swagger JSON: `doc/swagger/swagger.json` (referenced by `.service.yml` as `open_api_schema_path`)
- Server-side API stubs generated at build time from `src/main/resources/apis/server-unit-search.yaml` and `src/main/resources/apis/server-insights.yaml` using `swagger-codegen-maven-plugin 3.0.25`
