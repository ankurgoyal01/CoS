---
service: "getaways-accounting-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id-query-param]
---

# API Surface

## Overview

The Getaways Accounting Service exposes two read-only REST endpoints under the `/v1/` path prefix. Both endpoints are consumed by internal Groupon systems (Enterprise Data Warehouse and Finance Engineering) for accounting and financial reconciliation of Getaways hotel reservations. In addition, the Dropwizard admin interface exposes an admin task endpoint used to trigger CSV generation.

## Endpoints

### Finance

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/finance` | Returns finance reservation data for one or more record locators | Internal (client_id parameter) |

**Query parameters:**
- `record_locators` (required, string): Comma-separated list of booking record locator IDs.

**Response schema:** `FinanceResponseMapper` — a map of record locator string to `FinanceReservation` object.

**`FinanceReservation` fields:**

| Field | Type | Description |
|-------|------|-------------|
| `external_option_id` | string | External hotel option identifier |
| `order_id` | string | Groupon order identifier |
| `first_name` | string | Guest first name |
| `last_name` | string | Guest last name |
| `external_system` | string | Inventory system name |
| `salesforce_option_id` | string | Salesforce option reference |
| `brand` | string | Brand identifier |
| `inventory_product_id` | string | Inventory product identifier |
| `type` | string | Reservation type |

### Reservations Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/reservations/search` | Returns paginated reservations filtered by date range | Internal (client_id parameter) |

**Query parameters:**
- `start_date` (required, string): Start of the date range (ISO date).
- `end_date` (required, string): End of the date range (ISO date).
- `limit` (required, integer, max 200): Number of records per page.
- `offset` (required, integer, min 0): Pagination offset.

**Response schema:** `ReservationsSearchResponseMapper` — contains a `reservations` array of `Reservations` objects.

**`Reservations` fields (selection):**

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Internal reservation ID |
| `deal` | string | Deal title |
| `dealId` / `dealUuid` | string | Deal identifiers |
| `recordLocator` | string | Booking record locator |
| `bookingNumber` | string | Booking number |
| `checkIn` / `checkOut` | string | Check-in/check-out dates |
| `numberOfNights` | integer | Length of stay |
| `numberOfRooms` | integer | Number of rooms booked |
| `numberOfAdults` | integer | Number of adult guests |
| `pricing` | Pricing | Pricing block (totalPrice, hotelPrice, hotelTax, currency, lineItems) |
| `userId` | string | Groupon user identifier |
| `orderId` | string | Groupon order identifier |
| `hotelUuid` | string | Hotel UUID |
| `inventorySource` | string | Inventory system source |
| `externalSystem` | string | External reservation system |
| `createdAt` / `updatedAt` | string | Record timestamps |

### Admin Task

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/tasks/createcsv` (admin port 8081) | Triggers CSV generation and optional SFTP upload | Internal admin only |

**Admin task parameters:**
- `type` (required): `summary`, `detail`, or `all`
- `date` (required): ISO date string for the report date
- `upload` (optional, boolean): If `true`, uploads generated files via SFTP after generation

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` on all responses.

### Error format
Standard Dropwizard/JAX-RS error responses. Input validation failures return HTTP 4xx with a message body.

### Pagination
The `/v1/reservations/search` endpoint uses offset-based pagination with `limit` (max 200) and `offset` query parameters.

## Rate Limits

No rate limiting configured.

## Versioning

All endpoints are versioned via URL path prefix (`/v1/`).

## OpenAPI / Schema References

- OpenAPI 3.0.1 schema: `doc/schema.yml`
- Swagger config: `doc/swagger/config.yml`
- Live schema (production): `http://getaways-accounting-vip.snc1/swagger`
