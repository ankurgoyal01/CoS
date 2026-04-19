---
service: "tripadvisor-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, xml]
auth_mechanisms: [basic-auth, api-key]
---

# API Surface

## Overview

The Getaways Affiliate API exposes a REST/JSON API for hotel availability (used by TripAdvisor and Trivago) and an XML/REST API for Google Hotel Ads integration (query, transaction, and hotel list feed). All endpoints are `POST` methods. The primary external base URL is `http://api.groupon.com/getaways/v2/affiliates`. Internal URLs follow the pattern `http://afl-ta-app-vip.{colo}` on port 8080.

An OpenAPI 2.0 (Swagger) spec exists at `ta-api-v1/doc/swagger/swagger.yaml` (version `0.2.61-SNAPSHOT`).

## Endpoints

### Hotel Availability (TripAdvisor / Trivago)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/{partnerSeoName}/hotel_availability` | Query hotel availability for a named partner (`tripadvisor`, `trivago`, or `google`) | API key (`getaways.api.client.id`) |
| POST | `/getaways/v2/affiliates/{partnerSeoName}/hotel_availability` | Alternate external URL path for partner hotel availability | API key |
| POST | `/hotel_availability` | Deprecated: hotel availability defaulting to TripAdvisor partner | API key |

**Path parameters:**

| Parameter | Values | Description |
|-----------|--------|-------------|
| `partnerSeoName` | `tripadvisor`, `trivago`, `google` | Identifies the requesting CPC partner; drives response format and hotel filtering |

**Query parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `hotels` | yes | Comma-separated list of hotel IDs to query |

**Request body fields (`HotelAvailabilityForm`):**

| Field | Type | Description |
|-------|------|-------------|
| `start_date` | string | Check-in date |
| `end_date` | string | Check-out date |
| `num_adults` | integer | Number of adults |
| `num_rooms` | integer | Number of rooms |
| `currency` | string | Requested currency code |
| `lang` | string | Language code |
| `device_type` | string | Device type hint |
| `user_country` | string | User country code (drives region-specific routing) |
| `party` | string | Party composition string |
| `query_key` | string | Partner-supplied query correlation key |
| `api_version` | integer | API version hint |

**Response (`HotelAvailabilityResponse`):** Returns `api_version`, `currency`, `start_date`, `end_date`, `num_adults`, `num_rooms`, `lang`, `user_country`, `party`, `query_key`, and an array of `hotels`. Each hotel has a `hotel_id` and a map of `room_types` (keyed by room code), each containing `price`, `final_price`, `taxes`, `fees`, `url`, `room_amenities`, and `discounts`.

### Google Hotel Ads

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/google/transaction_query` | Accept a Google pricing query (XML) and return a Transaction XML document with hotel pricing | Internal (no external auth documented) |
| POST | `/google/query_control_message` | Return the Google query control XML document describing booking capabilities | Internal |
| POST | `/google/hotel_list_feed` | Return the Google hotel list feed (CSV/XML) listing all Groupon Getaways properties | Internal |
| GET | `/google/hotel_list_feed_json` | Return the hotel list feed in JSON format | Internal |

### Utility / Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/resources/status.json` | Service status and running Git SHA | None |
| GET/PUT/DELETE | `/resources/manage/heartbeat` | Enable or disable the load-balancer heartbeat file | Basic auth (`heartbeat.user` / `heartbeat.passwd`) |
| GET | `/config` | Returns active Spring configuration profile and settings | Internal |

## Request/Response Patterns

### Common headers

- `x-request-id`: Correlation ID propagated by `XRequestIdRegisterFilter` for tracing across calls
- `X-Forwarded-For`: Extracted by `XForwardedForFilter` for client IP attribution
- `Content-Encoding: gzip` / `Accept-Encoding: gzip`: Supported by `GZIPRequestFilter` and `GZIPResponseFilter`

### Error format

HTTP status codes are returned for error conditions:
- `400 Bad Request` — on `IllegalArgumentException` (e.g., invalid form parameters)
- `404 Not Found` — on `UnknownPartnerException` (unrecognised `partnerSeoName`)
- `500 Internal Server Error` — on unexpected exceptions; error details logged via Steno

The availability endpoint returns an empty hotels array (rather than an error response) on `HotelAvailabilityException` or `URISyntaxException`.

### Pagination

> No evidence found in codebase. Availability responses return all requested hotels in a single response.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| SLA (agreed with TripAdvisor) | 3000 RPM | per minute |

SLA latency targets (from `ta-api-v1/doc/OWNERS_MANUAL.md`):

| Request type | Average | Maximum |
|-------------|---------|---------|
| 1 hotel | 200 ms | 300 ms |
| 10 hotels | 250 ms | 500 ms |
| 50 hotels | 500 ms | 2000 ms |

> No software-enforced rate limiting is configured on the service itself; rate control is external.

## Versioning

The partner-facing availability API uses URL path versioning via the `partnerSeoName` path variable. The deprecated `/hotel_availability` endpoint is the v1 path; `/{partnerSeoName}/hotel_availability` is the current path. The Google Hotel Ads endpoints have no explicit version in the path.

## OpenAPI / Schema References

- Swagger 2.0 spec: `ta-api-v1/doc/swagger/swagger.yaml` (version `0.2.61-SNAPSHOT`)
- Google XML schemas (XSD): `ta-api-v1/src/main/resources/xsd/Query.xsd`, `Transaction.xsd`, `query_control.xsd`
