---
service: "goods-shipment-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The Goods Shipment Service exposes a REST API over HTTP. It is consumed by internal Groupon services and admin tooling. API key authentication is enforced via a `clientId` query parameter on all protected endpoints. The Aftership webhook endpoint uses HMAC-SHA256 signature validation and/or an `auth_token` query parameter for inbound webhook authentication. The OpenAPI specification is located at `doc/swagger/swagger.yaml`.

## Endpoints

### Shipments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/shipments` | Retrieve shipments by `orderUuid`, `id`, `country`, or `shipmentUuids` | `clientId` API key |
| POST | `/shipments` | Create one or more new shipments (max 50 per request) | `clientId` API key |
| PUT | `/shipments` | Update one or more existing shipments (max 50 per request) | `clientId` API key |

### Admin Shipments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/admin/shipments/refreshCarrier` | Trigger carrier shipment status refresh for all or a named carrier | `clientId` API key |
| PUT | `/admin/shipments/refreshShipments` | Trigger status refresh for specific shipment UUIDs | `clientId` API key |
| POST | `/admin/shipments/sendMobileNotifications` | Manually send mobile push notifications for specific shipment UUIDs | `clientId` API key |
| POST | `/admin/shipments/sendNotifications` | Manually send all notifications for specific shipment UUIDs | `clientId` API key |
| POST | `/admin/shipments/sendOrderFulfillment` | Manually publish order fulfilment notification for given order UUIDs | `clientId` API key |

### Aftership Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/aftership` | Receive inbound Aftership shipment status webhook | HMAC-SHA256 (`Aftership-Hmac-Sha256` header) or `auth_token` query param |

### Carrier

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/carrier/{carrier}/oauth2-token` | Fetch and store OAuth2 token for the named carrier | None (internal) |
| GET | `/carrier/{carrier}/tracking/{trackingNumber}` | Retrieve raw tracking data from the named carrier API | None (internal) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST and PUT requests with a body
- `Aftership-Hmac-Sha256` — HMAC-SHA256 signature sent by Aftership on webhook calls

### Error format

Standard HTTP status codes are used. Error responses are returned as JSON or plain text depending on the framework default. Key status codes:

- `400 Bad Request` — missing or invalid required fields
- `401 Unauthorized` — Aftership webhook signature validation failure
- `404 Not Found` — shipment not found
- `409 Conflict` — duplicate shipment on create
- `413 Payload Too Large` — shipment batch exceeds 50 items
- `500 Internal Server Error` — unexpected processing error

### Pagination

> No evidence found in codebase. The GET `/shipments` endpoint does not define pagination parameters; responses include all matching shipments.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL path versioning is used for the service's own endpoints. Carrier API client stubs are versioned internally (e.g., `UpsOauthCredentials.json` generates `security/v1/oauth/token`; DHL uses `auth/v4/accesstoken` and `tracking/v4/package/open`).

## OpenAPI / Schema References

The Swagger 2.0 specification is maintained at `doc/swagger/swagger.yaml` within the repository and is registered as the `open_api_schema_path` in `.service.yml`.
