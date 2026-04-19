---
service: "larc"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, internal-token]
---

# API Surface

## Overview

The LARC REST API is a Dropwizard (JAX-RS) HTTP API versioned under `/v2/getaways/larc/`. It is consumed by internal Groupon tooling — specifically eTorch and the Getaways extranet app — for managing hotel-to-QL2 mappings, rate descriptions, approved discount percentages, and for triggering on-demand LAR computations and delivery to the Travel Inventory Service. All endpoints return and accept JSON. An OpenAPI 3.0 schema is available at `doc/schema.yml`.

## Endpoints

### Approved Rates and Discount Percentages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/getaways/larc/approved_rates_discount_percentages` | Fetch approved rate discount percentages for one or more rate plans | Internal |
| `PUT` | `/v2/getaways/larc/approved_rates_discount_percentages` | Update approved rate discount percentages for a rate plan | Internal |

### Hotels

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v2/getaways/larc/hotels` | Register a new hotel with its QL2 identifier | Internal |
| `GET` | `/v2/getaways/larc/hotels/{hotel_uuid}` | Fetch a hotel record by UUID | Internal |
| `PUT` | `/v2/getaways/larc/hotels/{hotel_uuid}` | Update a hotel record (e.g., re-map QL2 ID) | Internal |

### Rate Descriptions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions` | Fetch rate descriptions for a hotel | Internal |
| `PUT` | `/v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions` | Update rate description mappings for a hotel | Internal |

### Rates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/v2/getaways/larc/hotels/{hotel_uuid}/room_types/{room_type_uuid}/rate_plans/{rate_plan_uuid}/rates` | Trigger on-demand LAR computation and send computed rates to the Inventory Service | Internal |

## Request/Response Patterns

### Common headers
- `x-request-id` (optional header on all endpoints) — used for request tracing and correlation

### Error format
> No standardized error envelope is documented in the OpenAPI schema. Individual operations return HTTP status codes appropriate to the failure (e.g., 404 for not found, 500 for internal errors). The `LarcError` and `LarcErrors` beans indicate structured error data is available internally.

### Pagination
> Not applicable — no paginated endpoints are defined in `doc/schema.yml`.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are versioned under the `/v2/` URL path prefix. No other versioning strategy is in use.

## OpenAPI / Schema References

- OpenAPI 3.0 specification: `doc/schema.yml` (version `1.0.42-SNAPSHOT`)
- Swagger config: `doc/swagger/config.yml`
