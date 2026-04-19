---
service: "proximity-notification-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [cookie, client-roles-header]
---

# API Surface

## Overview

The Proximity Notification Service exposes a REST API consumed primarily by Groupon iOS and Android mobile clients (via API proxy) and by the Proximity UI admin interface. The API has two main groups: geofence endpoints that accept location updates and return geofence coordinates, and hotzone management endpoints for administering Hotzone deals and campaigns. All endpoints produce and consume JSON (except the geofence POST which accepts `application/x-www-form-urlencoded`).

## Endpoints

### Geofence (Mobile Location)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/proximity/{countryCode}/location/geofence` | Submit device location, receive geofence set, trigger push notification if eligible | Cookie / X-Client-Roles |
| POST | `/api/mobile/{countryCode}/location/geofence` | Mobile API gateway alias for geofence submission | Cookie / X-Client-Roles |
| POST | `/v2/mobile/location/geofence` | V2 mobile geofence endpoint (no country code in path) | Cookie / X-Client-Roles |

### Hotzone Deal Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/proximity/location/hotzone` | Bulk ingest hotzone deals | client_id query param |
| POST | `/v1/proximity/location/hotzone/browse` | Paginated browse of hotzone deals (DataTable compatible) | client_id query param |
| GET | `/v1/proximity/location/hotzone/{hotzoneId}` | Retrieve a single hotzone deal by UUID | client_id query param |
| DELETE | `/v1/proximity/location/hotzone/{hotZoneId}` | Delete a hotzone deal by UUID | client_id query param |
| POST | `/v1/proximity/location/hotzone/delete-expired` | Delete all expired hotzone deals | client_id query param |
| GET | `/v1/proximity/location/hotzone/categories` | List all hotzone categories | client_id query param |
| GET | `/v1/proximity/location/hotzone/check-hot-zone-jar` | Verify hotzone generator JAR availability | environment query param |
| POST | `/v1/proximity/location/hotzone/execute-batch-job` | Trigger hotzone batch generation job | client_id, environment query params |

### Hotzone Campaign Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/proximity/location/hotzone/campaign` | List all hotzone category campaigns | client_id query param |
| POST | `/v1/proximity/location/hotzone/campaign` | Create a hotzone category campaign | client_id query param |
| GET | `/v1/proximity/location/hotzone/campaign/{id}` | Get a specific campaign by ID | client_id query param |
| POST | `/v1/proximity/location/hotzone/campaign/{id}` | Update a campaign | client_id query param |
| DELETE | `/v1/proximity/location/hotzone/campaign/{id}` | Delete a campaign | client_id query param |
| POST | `/v1/proximity/location/hotzone/campaign/delete-auto` | Delete all auto-generated campaigns | client_id query param |

### Operational / Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/proximity/delete-send-log` | Delete send log for a client device | client_id query param |
| POST | `/v1/proximity/location/hotzone/{consumer_id}/send-email` | Trigger email send for a consumer | client_id query param |
| GET | `/v1/proximity/location/hotzone/users` | List Proximity UI admin users | client_id query param |
| GET | `/heartbeat.txt` | Dropwizard health check result | none |

## Request/Response Patterns

### Common headers

- `Cookie` — session cookie identifying the user (bcookie), classified as personal data class 3
- `X-Request-Id` — distributed tracing request ID, passed through to downstream services
- `X-Client-Roles` — roles header for access control, forwarded to push notification client
- `X-Brand` — brand identifier, defaults to `groupon`

### Geofence request body (form-encoded)

The geofence POST body carries the device location event including:
- `geoPoint` (lat/lng) — classified personal data class 2
- `bcookie` — device identifier, personal data class 3
- `consumerId` (UUID) — user ID, personal data class 3
- `countryCode`, `lang`, `locale`, `brand`
- `action` — enum: `ENTERED`, `EXITED`, `ARRIVED`, `DEPARTED`
- `activity` — enum: `IN_VEHICLE`, `ON_BICYCLE`, `ON_FOOT`, `RUNNING`, `STILL`, `TILTING`, `UNKNOWN`, `WALKING`
- `supports` — set of capability flags: `IN_RESPONSE_NOTIFICATION`, `TITLE`, `MESSAGE_TYPE`, `ALLOW_SEARCH_LINKS`, `APPLE_WATCH`
- `detectTime` — ISO 8601 timestamp of when the location was detected

### Geofence response

Returns a JSON object containing:
- `geofences` — array of geofence objects, each with `id` (UUID), `lat`, `lng`, `radius` (int meters), `validUntil` (ISO 8601 string)
- `muteUntil` — ISO 8601 timestamp; if present, client should suppress further location reports until this time

### Error format

Standard Dropwizard JSON error responses. HTTP 400 is returned for missing or invalid `client_id` on operational endpoints. Push notification failures are logged server-side; the geofence response is returned regardless.

### Pagination

The `/v1/proximity/location/hotzone/browse` endpoint supports DataTable-compatible pagination via the `DatatableRequest` body: `start`, `length`, `draw`, `columns`, `order`, and `search` fields.

## Rate Limits

The service applies **internal per-user rate limits** before sending notifications — these are enforced in the `RateLimitManager` using send log data from PostgreSQL. They are not HTTP-level rate limits on the API itself.

| Tier | Limit | Window |
|------|-------|--------|
| General (all notifications) | 2 per device | 1 day |
| Push type | 1 per device | 1 day |
| Pull type | 1 per device | 1 day |
| Hotzone, CLO, Travel, Coupon, NewDeal, Reminder | Level-based (configurable) | Per `RateLimitConfiguration` |

> No HTTP-level API rate limiting (e.g., token bucket per IP) is configured.

## Versioning

URL path versioning is used for newer endpoints (`/v1/`, `/v2/`). The original `/proximity/{countryCode}/location/geofence` path remains for backward compatibility alongside the `/api/mobile/{countryCode}` alias.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification available at `doc/swagger/swagger.yaml` in the service repository.
