---
service: "forex-ng"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

Forex NG exposes a lightweight HTTP/JSON REST API for internal Groupon consumers. The primary endpoint returns current exchange rates for a given ISO 4217 base currency or base/quote currency pair. Responses are served from the AWS S3 rate store and are not computed on demand. A secondary endpoint triggers a live rate refresh from NetSuite. All API paths are prefixed with `/v1/rates`.

## Endpoints

### Rate Lookup

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/rates/{currency}.json` | Retrieve all conversion rates for one base currency, or the rate for one base/quote pair | None (internal only) |
| `GET` | `/v1/rates/data` | Trigger an immediate refresh of all forex rates from NetSuite | None (internal only) |

#### Path parameter: `currency`

- **Single base currency**: Uppercase 3-letter ISO 4217 code. Returns rates for all configured quote currencies relative to that base. Example: `USD`, `EUR`.
- **Base/quote pair**: Two concatenated 3-letter codes (6 characters total). Returns the rate for that specific pair. Example: `USDEUR`, `CADUSD`.
- The `.json` extension is required. Requests without it receive HTTP 400.
- Validated by regex: `[A-Za-z]{6}|[A-Za-z]{3}` (from `ForexConstants.CURRENCY_COMBINATION_REGEX`).

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — returned by default on successful responses.
- No custom request headers required.

### Successful response shape (`GET /v1/rates/{currency}.json`)

```json
{
  "status": "ok",
  "base": "USD",
  "rates": {
    "EUR": 0.91,
    "CAD": 1.35
  },
  "timestamp": 1709424000,
  "timestamps": {
    "EUR": 1709424000,
    "CAD": 1709424000
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | `"ok"` on success; `"error"` on failure |
| `base` | string | Uppercase ISO 4217 base currency code requested |
| `rates` | object | Map of quote currency codes to floating-point exchange rates |
| `timestamp` | integer | Unix epoch seconds of the oldest rate update across all quotes |
| `timestamps` | object | Per-quote-currency Unix epoch seconds of last update |
| `error` | string | Human-readable error message; present only when `status` is `"error"` |

### Error format

- HTTP 400: Invalid or malformed `currency` path parameter (missing `.json` extension, wrong character length, invalid characters).
- HTTP 500: Internal error during rate refresh (from `/v1/rates/data` endpoint).
- On HTTP 400, an empty response body is returned. On HTTP 500, the exception message is returned as plain text.

### Pagination

> Not applicable. All rates for a base currency are returned in a single response.

## Rate Limits

> No rate limiting configured.

## Versioning

API version is embedded in the URL path (`/v1/rates/...`). The current version is `v1`. No header-based or query-parameter-based versioning is used.

## OpenAPI / Schema References

- OpenAPI 3.0 spec: `doc/openapi.yml` (in repository root)
- Swagger 2.0 spec: `doc/swagger/swagger.yaml`
- Service portal: `https://services.groupondev.com/services/forex`
