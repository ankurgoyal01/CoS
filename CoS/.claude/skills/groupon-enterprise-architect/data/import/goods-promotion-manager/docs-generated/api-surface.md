---
service: "goods-promotion-manager"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

Goods Promotion Manager exposes a REST API over HTTP/HTTPS using Jersey (JAX-RS). All business endpoints are versioned under `/v1/`. The API is intended for internal Groupon consumers and is protected by client-ID-based authentication via the JTier auth bundle. Clients pass a `clientId` query parameter or header; role-based access control is applied per `clientIds` configuration.

## Endpoints

### Health and Utility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status.json` | Health check — returns `{"isHealthy": true}` | None |
| GET | `/grpn/status` | JTier deployment metadata and commit SHA | None |
| GET | `/` | Root hello-world probe | None |

### Countries

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/countries` | Retrieve all supported countries sorted alphabetically by country code | client-id |

### Promotions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/promotions` | List all promotions, optionally filtered by `promotionStatus` (`CREATED`, `LOCKED`, `SUBMITTED`, `DONE`) and `isActive` | client-id |
| POST | `/v1/promotions` | Create a new promotion | client-id |
| GET | `/v1/promotions/{promotionUuid}` | Retrieve full promotion detail by UUID | client-id |
| PUT | `/v1/promotions/{promotionUuid}` | Update an existing promotion (status transitions enforced) | client-id |
| POST | `/v1/promotions/csv_data` | Stream ILS pricing data for given promotion UUIDs as a CSV download | client-id |
| POST | `/v1/promotions/{promotionUuid}/deals` | Retrieve all promotion deals associated with a promotion, with optional search filters | client-id |
| POST | `/v1/promotions/{promotionUuid}/metrics` | Retrieve metrics associated with a promotion, with optional search filters | client-id |

### Promotion Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/promotion_deals` | Create promotion deal associations | client-id |
| PUT | `/v1/promotion_deals` | Update promotion deal associations | client-id |
| POST | `/v1/promotion_deals/delete` | Delete promotion deal associations | client-id |

### Promotion Ineligibilities

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/v1/promotion_ineligibilities` | Create or update promotion ineligibility records | client-id |

### Promotion Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/promotion_inventory_products` | Retrieve promotion inventory products by `dealUuid` and `promotionUuid` | client-id |
| PUT | `/v1/promotion_inventory_products` | Update promotion inventory products (e.g., ILS price fields) | client-id |

### Deal Promotion Eligibility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/deal_promotion_eligibilities` | Evaluate eligibility of deals (by permalink) for given promotion UUIDs | client-id |

### Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/metrics` | Retrieve metric reference data filtered by `show_on_creation` boolean | client-id |

### Background Jobs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/jobs/import-products` | Manually trigger the import product Quartz job for a set of deal UUIDs | client-id |

## Request/Response Patterns

### Common headers

- `x-remote-user` (optional, string): Identifies the user performing write operations; recorded as `createdBy`/`updatedBy` in the database.
- `clientId` (optional, query param or header): Used for authentication and role-based authorization.
- `Content-Type: application/json` for all JSON request bodies.

### Error format

The service returns standard HTTP status codes:
- `400 Bad Request` — validation failures (e.g., missing required fields, invalid UUID format, status transition violations). Response body is a plain string describing the error.
- `404 Not Found` — resource does not exist (e.g., unknown `promotionUuid`).
- `500 Internal Server Error` — unhandled server-side errors.

### Pagination

> No evidence found in codebase. The API does not implement pagination; all matching records are returned in a single response.

## Rate Limits

> No rate limiting configured.

## Versioning

All business endpoints are versioned with a `/v1/` URL path prefix. No other versioning strategy (header or query param) is used.

## OpenAPI / Schema References

- OpenAPI (Swagger 2.0) spec: `openapi.yml` and `doc/swagger/swagger.yaml` in the repository root.
- Swagger UI config: `doc/swagger/config.yml`.
