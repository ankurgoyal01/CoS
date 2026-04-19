---
service: "voucher-inventory-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal-service-auth"]
---

# API Surface

## Overview

The Voucher Inventory Service exposes a REST API (via Ruby on Rails) that serves as the primary interface for voucher inventory operations. The API is organized into versioned namespaces (v1, v2) and covers inventory product management, voucher unit lifecycle, reservations, redemptions, redemption code pools, health checks, and runtime configuration. Consumers include the Orders service (for reservation during checkout), Deal Catalog (for product sync), merchant tools, and internal operational interfaces.

## Endpoints

### Status & Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status` | Basic service health and heartbeat | None (internal) |
| GET | `/healthcheck` | Deep health check including dependency connectivity | None (internal) |

### Inventory Products (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/inventory_products` | List inventory products with filtering | Internal service auth |
| GET | `/v1/inventory_products/:id` | Get inventory product details | Internal service auth |
| POST | `/v1/inventory_products` | Create a new inventory product | Internal service auth |
| PUT | `/v1/inventory_products/:id` | Update inventory product configuration | Internal service auth |

### Inventory Products (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/inventory_products` | List inventory products with enhanced filtering and quantity summaries | Internal service auth |
| GET | `/v2/inventory_products/:id` | Get inventory product details with enriched data | Internal service auth |
| PUT | `/v2/inventory_products/:id` | Update inventory product attributes | Internal service auth |

### Units & Redemptions (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v1/inventory_units` | Search voucher units with filters | Internal service auth |
| PUT | `/inventory/v1/inventory_units/:id` | Update voucher unit status | Internal service auth |
| PUT | `/inventory/v1/inventory_units/bulk_update` | Bulk update voucher unit statuses | Internal service auth |

### Units & Redemptions (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v2/units` | Search units with enhanced query capabilities | Internal service auth |
| GET | `/inventory/v2/units/:id` | Get unit details | Internal service auth |
| PUT | `/inventory/v2/units/:id` | Update unit | Internal service auth |
| POST | `/inventory/v2/redemptions` | Create a redemption for a voucher unit | Internal service auth |
| PUT | `/inventory/v2/redemptions/:id` | Update redemption status | Internal service auth |

### Reservations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/inventory/v1/reservation` | Reserve inventory during checkout with pricing and policy validation | Internal service auth |

### Redemption Code Pools (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/redemption_code_pools` | List redemption code pools | Internal service auth |
| POST | `/v1/redemption_code_pools` | Create a redemption code pool | Internal service auth |
| PUT | `/v1/redemption_code_pools/:id` | Update a redemption code pool | Internal service auth |

### Redemption Code Pools (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/redemption_code_pools/quantity_summary` | Get quantity summary for code pools | Internal service auth |
| POST | `/v2/redemption_code_pools/uploads` | Upload third-party redemption codes | Internal service auth |

### Features & Config

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/features` | Inspect active feature flags | Internal service auth |
| POST | `/config/reload` | Reload runtime configuration | Internal service auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- Internal service authentication headers (service-to-service tokens)

### Error format

> No evidence found in codebase. Standard Rails JSON error responses are expected (e.g., `{ "errors": [...] }`).

### Pagination

> No evidence found in codebase. Standard offset/limit pagination is expected for list endpoints based on Rails conventions.

## Rate Limits

> No evidence found in codebase. Redis-backed rate limiting infrastructure exists via the Cache & Lock Accessors component (`continuumVoucherInventoryApi_cacheAccessors`), but specific rate limit tiers are not defined in the architecture DSL.

## Versioning

The API uses URL-path-based versioning. Endpoints are namespaced under `/v1/` and `/v2/` prefixes. The v2 namespace provides enhanced query capabilities, enriched responses, and refined resource models compared to v1. Both versions are active and served concurrently.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or schema files are present in the architecture DSL.
