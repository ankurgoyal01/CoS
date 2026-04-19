---
service: "travel-affiliates-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, xml-rpc]
auth_mechanisms: [api-key, basic-auth]
---

# API Surface

## Overview

The Travel Affiliates API exposes four endpoint groups over HTTPS: a partner-agnostic hotel availability endpoint used by TripAdvisor and Trivago, Google Hotel Ads-specific Live Query endpoints (transaction query, query control message, hotel list feed), and utility endpoints for health and warmup. The Google Live Query endpoints accept and return XML conforming to Google's published XSD schemas (Query, Transaction, QueryControl). The partner availability endpoint accepts and returns JSON.

## Endpoints

### Partner Hotel Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/getaways/v2/affiliates/{partnerSeoName}/hotel_availability` | Returns hotel availability and pricing for the requested partner, check-in/out dates, occupancy, and hotel list | API key (client_id query param) |

**Path parameter `partnerSeoName`** accepts: `google`, `tripadvisor`, `trivago`

**Request body** (`HotelAvailabilityForm`):

| Field | Type | Description |
|-------|------|-------------|
| `start_date` | string | Check-in date |
| `end_date` | string | Check-out date |
| `num_adults` | integer | Number of adult guests |
| `num_rooms` | integer | Number of rooms |
| `currency` | string | Response currency code |
| `lang` | string | Language code |
| `device_type` | string | Requesting device type |
| `user_country` | string | ISO country code of the requesting user |
| `party` | string | Party composition string |
| `query_key` | string | Partner-supplied query key for correlation |
| `api_version` | integer | API version requested |

**Response body** (`HotelAvailabilityResponse`): mirrors request fields plus `hotels` array, each hotel containing `hotel_id` and `room_types` map.

### Google Hotel Ads Live Query

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/google/transaction_query` | Processes a Google Hotel Ads transaction query (Live Query); returns Transaction XML with pricing results | None (Google-initiated, IP-allowlisted) |
| POST | `/google/query_control_message` | Returns a QueryControl XML document describing itinerary capabilities and hint control settings | None |
| GET | `/google/hotel_list_feed_json` | Returns a JSON array of `HotelDetails` objects for all active Getaways hotel deals | None |

**`POST /google/transaction_query`** request body: Google `Query` XML object (XSD: `src/main/resources/xsd/Query.xsd`). Key fields: `Checkin`, `Nights`, `AffectedNights`, `DeadlineMs`, `PropertyList`, `HotelInfoProperties`.

**`POST /google/transaction_query`** response: Google `Transaction` XML (XSD: `src/main/resources/xsd/Transaction.xsd`). Contains `Result` elements per property with `Baserate`, `Tax`, `OtherFees`, `Rates`, `RoomBundle`, `Refundable`, and `AllowablePointsOfSale`.

**`POST /google/query_control_message`** response: Google `QueryControl` XML (XSD: `src/main/resources/xsd/query_control.xsd`). Contains `HintControl` and `ItineraryCapabilities` sections.

**`GET /google/hotel_list_feed_json`** response: JSON array of `HotelDetails`:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Groupon hotel identifier |
| `name` | string | Hotel name |
| `addr1` | string | Street address |
| `city` | string | City |
| `province` | string | State or province |
| `country` | string | Country |
| `postal_code` | string | Postal code |
| `phone` | string | Phone number |
| `latitude` | number | Geographic latitude |
| `longitude` | number | Geographic longitude |

### Utility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/resources/manage/heartbeat` | Liveness/heartbeat check; returns 200 OK when the application is healthy | None |
| PUT | `/resources/manage/heartbeat` | Enables the heartbeat | Basic auth (admin) |
| DELETE | `/resources/manage/heartbeat` | Disables the heartbeat | Basic auth (admin) |

## Request/Response Patterns

### Common headers
- `x-request-id`: Correlation ID propagated through all outbound calls via `XRequestIdHttpInterceptor`
- `X-Forwarded-For`: Forwarded client IP propagated via `XForwardedForHttpInterceptor`
- `Content-Encoding: gzip` / `Accept-Encoding: gzip`: Supported via `GZIPRequestFilter` and `GZIPResponseFilter`

### Error format
> No evidence found in codebase of a standardized JSON error envelope. Spring MVC default exception responses apply; `LoggingHandlerExceptionResolver` logs exceptions. Google XML endpoints may return HTTP 4xx/5xx with no body on validation failure.

### Pagination
The `/google/hotel_list_feed_json` endpoint returns all active hotels in a single response with no pagination. The Getaways API client (`RemoteGetawaysApiClient.getProductSets()`) handles server-side pagination internally using `offset` and `count` from the upstream response.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Documented SLA | 3000 RPM | 1 minute |

> SLA is defined in `doc/OWNERS_MANUAL.md`. No programmatic rate limiting is configured in the application itself.

## Versioning

The partner availability endpoint uses a URL path version segment: `/getaways/v2/affiliates/...`. The Google Live Query endpoints are not versioned in the path; Google's schema version is managed via XSD schema files (`Query.xsd`, `Transaction.xsd`, `query_control.xsd`).

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`
- Google Query XSD: `src/main/resources/xsd/Query.xsd`
- Google Transaction XSD: `src/main/resources/xsd/Transaction.xsd`
- Google QueryControl XSD: `src/main/resources/xsd/query_control.xsd`
