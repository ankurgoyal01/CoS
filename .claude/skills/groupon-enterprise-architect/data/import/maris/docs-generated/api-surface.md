---
service: "maris"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

MARIS exposes two REST API namespaces: a market rate query endpoint under `/getaways/v2/` and a full inventory management API under `/inventory/v1/`. Consumers use the market rate endpoint to retrieve hotel room pricing and the inventory endpoints to manage products, availability, reservations, and unit lifecycle operations. All endpoints return JSON.

## Endpoints

### Market Rate

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/marketrate/hotels/{id}/rooms` | Retrieves available room types and pricing for a given hotel from Expedia Rapid | Internal service auth |

### Inventory — Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v1/products` | Lists inventory products | Internal service auth |
| GET | `/inventory/v1/products/availability` | Queries availability for inventory products | Internal service auth |

### Inventory — Reservations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/inventory/v1/reservations` | Creates a new hotel reservation via Expedia Rapid | Internal service auth |

### Inventory — Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v1/units` | Retrieves inventory units | Internal service auth |
| PUT | `/inventory/v1/units` | Updates inventory unit state | Internal service auth |
| POST | `/inventory/v1/units/{id}/redemption` | Records redemption of an inventory unit | Internal service auth |
| POST | `/inventory/v1/reverse_fulfillment` | Reverses a fulfilled inventory unit (refund/cancellation path) | Internal service auth |

## Request/Response Patterns

### Common headers

> No evidence found for specific required headers beyond standard internal service authentication. Authentication mechanism follows JTier internal service conventions.

### Error format

> Follows Dropwizard standard JSON error responses. Specific error envelope shape not discoverable from the architecture model.

### Pagination

> Not applicable for reservation and unit endpoints. Product and availability listing endpoints may support query-parameter-based filtering; specific pagination scheme not discoverable from the architecture model.

## Rate Limits

> No rate limiting configured at the MARIS API layer. Expedia Rapid API upstream rate limits apply to outbound calls.

## Versioning

API versioning is embedded in the URL path:
- `/getaways/v2/` — Getaways market rate API, version 2
- `/inventory/v1/` — Inventory management API, version 1

## OpenAPI / Schema References

> No OpenAPI spec or schema file detected in the architecture model inventory. Schema definitions are embedded in the Dropwizard resource and model classes.
