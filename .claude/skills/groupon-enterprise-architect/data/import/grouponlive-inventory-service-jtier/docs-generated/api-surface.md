---
service: "grouponlive-inventory-service-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

The service exposes a REST/JSON API consumed by internal Groupon services. Endpoints cover five functional areas: product and event inventory lookup, reservation lifecycle, purchase creation, venue credential management, and merchant reporting. All responses are JSON. The API follows URL versioning under `/v1/`. A Swagger 2.0 spec is available at `doc/swagger/swagger.yaml`.

## Endpoints

### Active Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/active_products` | Returns UUIDs of all currently active products | Internal |

### Events

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/events` | Retrieves all events for a product by `inventoryProductId` | Internal |
| GET | `/v1/events/counts` | Returns sold ticket counts for events of a given `inventoryProductId` | Internal |

### Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/products/{productUuid}/events/availability` | Returns availability for all events under a product | Internal |

### Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inventory/v1/products` | Fetches products by comma-separated `inventoryProductIds` | Internal |

### Reservations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/reservations` | Creates a seat reservation with the appropriate third-party partner | Internal |
| GET | `/v1/reservations/{reservationUuid}` | Retrieves a reservation record by UUID | Internal |

### Purchases

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/purchases` | Creates a ticket purchase on the external partner using reservation, event, and customer data | Internal |

### Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/units/{inventoryUnitUuid}` | Retrieves a single inventory reservation unit by UUID | Internal |

### Merchants

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/merchants/{MERCHANT_UUID}/features` | Returns whether a merchant is a Groupon Live merchant | Internal |
| GET | `/v1/merchants/{merchantUuid}/reports/payments_breakdown` | Returns paginated payment breakdown report for a merchant | Internal |

### Venue Credentials

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/venues_credentials` | Lists all vendor credentials of a given `vendor_type` | Internal |
| POST | `/v1/venues_credentials` | Creates a new vendor credential record | Internal |
| GET | `/v1/venues_credentials/{uuid}` | Retrieves a specific vendor credential by UUID | Internal |
| PUT | `/v1/venues_credentials/{uuid}` | Updates an existing vendor credential | Internal |
| GET | `/v1/venues_credentials/{venuesCredentialsId}/events` | Retrieves events from the vendor for the given credential, filtered by optional params | Internal |

### Alerts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/alerts/{alert_handler}` | Receives and dispatches alert notifications (e.g., third-party purchase errors) | Internal |

### Utility / Diagnostic

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/random` | Returns a random HTTP status code for testing purposes | Internal |
| POST | `/enqueue_job` | Enqueues a Quartz job for testing | Internal |
| POST | `/post/multipart` | Multipart form data upload endpoint | Internal |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for all request and response bodies.

### Error format
Errors are returned as JSON objects. The `ErrorResponse` class provides a structured error payload. HTTP status codes follow standard REST conventions (400 for client errors, 500 for server/partner errors).

### Pagination
The `/v1/merchants/{merchantUuid}/reports/payments_breakdown` endpoint accepts `page` (minimum 1) and `pageSize` (minimum 1) query parameters for paginated results.

## Rate Limits

> No rate limiting configured at the service level. Partner API rate limits are imposed externally by Provenue, Telecharge, AXS, and Ticketmaster.

## Versioning

URL path versioning is used. All primary business endpoints are under `/v1/`. Inventory product lookup uses `/inventory/v1/`.

## OpenAPI / Schema References

Swagger 2.0 specification: `doc/swagger/swagger.yaml`
