---
service: "inventory_outbound_controller"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

inventory_outbound_controller exposes a REST HTTP API used by internal Continuum services, operations tooling, and admin interfaces. The API covers four functional areas: order cancellation, sales order and shipment queries, fulfillment management (manifests, deal config, state tooling), and admin job/consumer control. Versioning is mixed — some endpoints use `/v1/` or `/v2/` path prefixes, while others are unversioned.

## Endpoints

### Order Cancellation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/cancel_sales_order/:soid` | Cancel a sales order by order ID | Internal service auth |
| POST | `/sales_orders/:id/cancellation` | Request cancellation for a specific sales order | Internal service auth |
| PUT | `/v2/sales-orders/cancel` | Bulk or updated cancellation endpoint (v2) | Internal service auth |
| PUT | `/v1/inventory/units/cancel` | Cancel inventory units associated with an order | Internal service auth |

### Sales Orders & Shipments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goods-outbound-controller/v1/sales-orders` | List sales orders managed by this service | Internal service auth |
| GET | `/sales_orders` | Query sales orders (unversioned path) | Internal service auth |
| GET | `/shipments/quantity` | Query shipment quantity data | Internal service auth |

### Carrier & Rate

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/carriers` | List available fulfillment carriers | Internal service auth |
| GET | `/v1/rate_estimator` | Estimate shipping rates for a given shipment | Internal service auth |

### Fulfillment Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/fulfillment-manifests` | Submit or import a fulfillment manifest | Internal service auth |
| PUT | `/fulfillments/create` | Create a fulfillment record | Internal service auth |
| GET | `/fulfillment_deal_config` | Retrieve fulfillment configuration for a deal | Internal service auth |
| PUT | `/fulfillment_deal_config` | Update fulfillment configuration for a deal | Internal service auth |
| GET | `/fulfillment_states_tool` | Retrieve fulfillment state data (operations tooling) | Admin |
| POST | `/fulfillment_states_tool` | Update fulfillment state (operations tooling) | Admin |

### Admin & Job Control

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/start-scavenger` | Manually trigger the scavenger job | Admin |
| POST | `/fulfillment-import-job` | Manually trigger the fulfillment import job | Admin |
| POST | `/admin/jobs/schedule` | Schedule or reschedule a Quartz job | Admin |
| POST | `/admin/consumers/start` | Start a JMS message consumer | Admin |
| POST | `/admin/consumers/stop` | Stop a JMS message consumer | Admin |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — used for all JSON request/response bodies
- `Accept: application/json` — expected on all API calls

### Error format

> No evidence found in codebase for a standardized error response envelope. Play Framework defaults to JSON error responses with HTTP status codes. Consult service owner for the exact error schema.

### Pagination

> No evidence found in codebase. List endpoints (`/sales_orders`, `/goods-outbound-controller/v1/sales-orders`) are expected to support query parameters for filtering; pagination strategy not confirmed from inventory.

## Rate Limits

> No rate limiting configured. This is an internal service not exposed to external consumers. Rate control is expected at the infrastructure / load balancer level.

## Versioning

Mixed versioning strategy observed:
- `/v1/` prefix used for: `cancel_sales_order`, `carriers`, `rate_estimator`, `sales-orders`, `inventory/units/cancel`
- `/v2/` prefix used for: `sales-orders/cancel`
- Unversioned paths used for: `sales_orders`, `shipments/quantity`, `fulfillment-manifests`, `fulfillments/create`, `fulfillment_deal_config`, `fulfillment_states_tool`, admin endpoints

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or proto file is published by this service.
