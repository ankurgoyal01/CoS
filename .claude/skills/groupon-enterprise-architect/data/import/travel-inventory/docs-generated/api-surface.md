---
service: "travel-inventory"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

Getaways Inventory Service exposes a comprehensive REST API under the `/v2/getaways/inventory/` path prefix, serving nine distinct API groups. The API supports Extranet (merchant-facing) operations, consumer shopping flows, OTA integrations, channel manager hierarchy mappings, audit queries, worker/task management, and operational diagnostics. All endpoints use JSON request/response bodies and are served via Jersey/Skeletor on Tomcat.

## Endpoints

### Extranet API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/hotels` | List hotels | Internal service auth |
| GET | `/v2/getaways/inventory/hotels/{hotelId}` | Get hotel details | Internal service auth |
| POST | `/v2/getaways/inventory/hotels` | Create hotel | Internal service auth |
| PUT | `/v2/getaways/inventory/hotels/{hotelId}` | Update hotel | Internal service auth |
| GET | `/v2/getaways/inventory/hotels/{hotelId}/roomtypes` | List room types for a hotel | Internal service auth |
| POST | `/v2/getaways/inventory/hotels/{hotelId}/roomtypes` | Create room type | Internal service auth |
| PUT | `/v2/getaways/inventory/roomtypes/{roomTypeId}` | Update room type | Internal service auth |
| GET | `/v2/getaways/inventory/roomtypes/{roomTypeId}/rateplans` | List rate plans for a room type | Internal service auth |
| POST | `/v2/getaways/inventory/roomtypes/{roomTypeId}/rateplans` | Create rate plan | Internal service auth |
| PUT | `/v2/getaways/inventory/rateplans/{ratePlanId}` | Update rate plan | Internal service auth |
| GET | `/v2/getaways/inventory/productsets/*` | Product set operations | Internal service auth |
| GET | `/v2/getaways/inventory/taxes/*` | Tax configuration operations | Internal service auth |
| GET | `/v2/getaways/inventory/bookingfees/*` | Booking fee operations | Internal service auth |

### Shopping API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/availability/summary` | Availability summary for shopping | Internal service auth |
| GET | `/v2/getaways/inventory/availability/detail` | Detailed availability with pricing | Internal service auth |
| GET | `/v2/getaways/inventory/availability/calendar` | Calendar-based availability view | Internal service auth |
| POST | `/v2/getaways/inventory/reservations` | Create a reservation | Internal service auth |
| DELETE | `/v2/getaways/inventory/reservations/{reservationId}` | Cancel a reservation | Internal service auth |
| POST | `/v2/getaways/inventory/reservations/{reservationId}/reverse` | Reverse fulfilment for a reservation | Internal service auth |
| GET | `/v2/getaways/inventory/unity/products` | Unity product APIs for shopping | Internal service auth |

### Connect API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/connect/hierarchy` | Retrieve inventory hierarchy mappings for channel managers | Internal service auth |

### Backfill API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/getaways/inventory/backfill` | Configure and trigger inventory product backfill jobs | Internal service auth |

### OTA Update API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/getaways/inventory/ota/rates` | Process OTA rate updates | Internal service auth |
| POST | `/v2/getaways/inventory/ota/inventory` | Process OTA inventory updates | Internal service auth |

### Audit API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/audit` | Query inventory audit logs | Internal service auth |

### Worker API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/getaways/inventory/reporter/generate` | Trigger daily inventory report generation | Internal service auth |
| GET | `/v2/getaways/inventory/workers/tasks` | List background worker tasks | Internal service auth |
| POST | `/v2/getaways/inventory/workers/tasks` | Start a background worker task | Internal service auth |

### Configuration API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/config` | Read runtime configuration values | Internal service auth |
| PUT | `/v2/getaways/inventory/config` | Update runtime configuration (dev environments only) | Internal service auth |

### Operational Utility API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/getaways/inventory/status/db` | Database status and metadata for operational diagnostics | Internal service auth |
| GET | `/v2/getaways/inventory/status/logging` | Logging level diagnostics | Internal service auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- Internal service authentication headers (service-to-service tokens managed by the platform)

### Error format

Standard JSON error responses with HTTP status codes (400 for validation errors, 404 for not found, 500 for internal errors). Error body typically includes an error message and optional error code.

### Pagination

Extranet list endpoints (hotels, room types, rate plans) support pagination via query parameters (e.g., `offset`, `limit` or similar). Shopping availability endpoints may use date-range and hotel-scoped parameters for result bounding.

## Rate Limits

No rate limiting configured at the application level. Rate limiting may be applied at the load balancer or API gateway layer.

## Versioning

API versioning is path-based: all endpoints are served under `/v2/getaways/inventory/`. The `v2` prefix indicates the current API version.

## OpenAPI / Schema References

No OpenAPI spec files found in the federated model. API contracts are defined in Jersey resource classes within the service codebase.
