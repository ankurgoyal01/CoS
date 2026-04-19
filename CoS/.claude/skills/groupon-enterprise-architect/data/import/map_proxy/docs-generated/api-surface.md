---
service: "map_proxy"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

MapProxy exposes a REST HTTP API served by an embedded Jetty server on port 8080. Callers send GET requests with map parameters; the service returns an HTTP 302 redirect to the signed upstream provider URL (for static maps and dynamic JS v1), or a direct `text/javascript` response body (for the v2 dynamic endpoint). No authentication is required from callers — the service is an internal gateway behind Groupon's edge proxy. All personal data fields are classified as `unclassified` per the OpenAPI schema.

The API has two API versions served in parallel:

- **v1** (`/maps/api/*`): Pass-through proxy that signs and forwards requests directly to Google Maps as a redirect. Only supports Google; no provider selection.
- **v2** (`/api/v2/*`): Provider-aware endpoints that select between Google and Yandex based on geography, and provide a composed JavaScript payload for dynamic maps.

The OpenAPI specification is located at `doc/openapi.yml`.

## Endpoints

### Static Map Image (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/maps/api/staticmap` | Creates a map image based on URL parameters; signs the request and redirects (HTTP 302) to Google Maps Static API. Returns `image/png` from the upstream. | None |

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `center` | Conditional (required if `markers` not present) | Map centre as address or `lat,lng` |
| `zoom` | Conditional (required if `markers` not present) | Zoom level 0–21 |
| `size` | Yes | Image dimensions as `{width}x{height}` (e.g. `500x400`) |
| `channel` | No | Tracking channel identifier |
| `scale` | No | Pixel density multiplier |
| `format` | No | Image format (default: `png`) |
| `maptype` | No | `roadmap`, `satellite`, `hybrid`, or `terrain` |
| `language` | No | Language code for map labels |
| `region` | No | Two-character ccTLD for border rendering |
| `markers` | No | One or more marker definitions |
| `path` | No | Polyline path overlay |
| `visible` | No | Locations that must remain visible |
| `style` | No | Custom map style rules |
| `client` | No | Google Maps for Business client ID (auto-appended if absent) |

**Response:** HTTP 302 redirect to `https://maps.googleapis.com/maps/api/staticmap?...&signature=<hmac>`. The upstream returns `image/png`.

---

### Dynamic Map JavaScript Loader (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/maps/api/js` | Provides a signed redirect (HTTP 302) to the Google Maps JavaScript API loader (`text/javascript`). | None |

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `callback` | Yes | JavaScript callback function name invoked when the Maps JS API loads |
| `channel` | No | Tracking channel identifier |
| `v` | No | Maps JS API version |
| `libraries` | No | Comma-separated list of additional Maps JS API libraries |
| `language` | No | Language code |
| `region` | No | Region code |

**Response:** HTTP 302 redirect to the signed Google Maps JS API URL.

---

### Static Map Image (v2 — provider-aware)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/static` | Provider-aware static map endpoint. Selects Google or Yandex by geography and redirects (HTTP 302) to the provider-signed URL. | None |

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `lat` | Yes | Latitude in decimal degrees |
| `lng` | Yes | Longitude in decimal degrees |
| `zoom` | Yes | Zoom level 0–18 (capped at 18 if higher value supplied) |
| `size` | Yes | Image dimensions as `{width}x{height}` |
| `client` | Yes | Client ID string (format: `domain--product--page--usage`) |
| `country` | No | ISO 3166-1 alpha-2 country code for provider selection |
| `markers` | No | `~`-separated marker definitions; each uses `\|`-separated `key:value` pairs for `pos`, `size`, `color`, `label` |

**Response:** HTTP 302 redirect to the provider URL. Returns HTTP 400 if any required parameter is absent.

---

### Dynamic Map JavaScript Payload (v2 — provider-aware)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/dynamic` | Returns a composed `text/javascript` payload containing the provider's JS libraries and Mapstraction wrapper. Provider selected by geography. | None |

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `client` | Yes | Client ID string |
| `country` | No | ISO 3166-1 alpha-2 country code for provider selection |
| `callback` | No | JavaScript callback function name executed after the snippet loads |

**Response:** HTTP 200 with `Content-Type: text/javascript`; body is the composed JS payload. Returns HTTP 400 if `client` is absent.

---

### Operational Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Returns HTTP 200 if the heartbeat file exists at `MapProxy.heartbeatFile`; HTTP 404 otherwise. Used by Kubernetes readiness/liveness probes. | None |
| GET | `/status` | Alias for `/heartbeat`. | None |
| GET | `/changelog` | Returns the service changelog from the classpath `CHANGELOG` resource. | None |
| GET | `/*` (all other) | Tracking servlet: logs request metadata and returns HTTP 204 No Content. | None |

---

### JavaScript Library Files (v2 static assets)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/js/*` | Serves static JavaScript library files (Mapstraction provider adapters) from the classpath `/js-libraries` directory. | None |

## Request/Response Patterns

### Common headers

- `X-Country`: ISO 3166-1 alpha-2 country code. Used by provider selection when the `country` query parameter is absent.
- `X-Forwarded-Proto`: Determines whether to use `http` or `https` in redirect URLs.
- `Referer`: Fallback for country resolution — the service parses the TLD from the Referer host.
- `Host`: Last-resort fallback for country resolution in local/development environments.
- `x-request-id`: Logged in every request log entry for tracing.

### Error format

- **HTTP 400 Bad Request**: Returned by v2 endpoints when required parameters (`lat`, `lng`, `zoom`, `size`, `client` for static; `client` for dynamic) are missing. No response body.
- **HTTP 500 Internal Server Error**: Logged on HMAC signing failures (v1 static). No response body returned to caller in this path.
- **HTTP 404**: Returned by `/heartbeat` and `/status` when the heartbeat file is absent; by v2 dynamic when the provider JS template is not found on the classpath.

### Pagination

> Not applicable. All endpoints return a single response per request.

## Rate Limits

> No rate limiting configured at the MapProxy layer. Google Maps for Business quota limits apply upstream. Usage is tracked via the `client` and `channel` query parameters.

## Versioning

The API uses URL path versioning:
- `/maps/api/*` — v1 (Google-only, redirect-only)
- `/api/v2/*` — v2 (provider-aware, composed JS response for dynamic)

Both versions are served simultaneously from the same running instance.

## OpenAPI / Schema References

- OpenAPI 3.0.1 specification: `doc/openapi.yml` (covers `/maps/api/staticmap` and `/maps/api/js` endpoints)
- Service registry: https://services.groupondev.com/services/map_proxy
