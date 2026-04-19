---
service: "barcode-service-app"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none]
---

# API Surface

## Overview

Barcode Service exposes a REST HTTP API that returns rendered barcode images (PNG, GIF) or JSON metadata in response to GET requests. Consumers embed the code type, payload encoding, and payload data directly in the URL path. The API is versioned via URL path prefix (`/v1/`, `/v2/`, `/v3/`), with `/fubar/` prefixed variants serving the same endpoints via a legacy internal routing alias. There is no authentication — the service is only accessible via internal VIPs within Groupon's network.

## Endpoints

### v1 — Legacy Image Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/fubar/v1/barcode/{codeType}/{payloadType}/{payload}` | Generate barcode image (no file extension; content negotiation via Accept header) | None |
| GET | `/fubar/v1/barcode/mobile/{codeType}/{payloadType}/{payload}.{filetype}` | Generate barcode image for mobile clients with explicit file extension | None |

### v2 — Standard Image Generation (with file extension and optional rotation)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/fubar/v2/barcode/types` | Returns list of supported barcode code types (JSON) | None |
| GET | `/fubar/v2/barcode/{codeType}/width/base64/{payload}` | Returns computed pixel width of a barcode for the given code type and base64-encoded payload | None |
| GET | `/fubar/v2/barcode/{codeType}/{payloadType}/{payload}.{filetype}` | Generate barcode image with explicit file extension; optional `rotate` query param | None |
| GET | `/fubar/v2/barcode/{codeType}/{payloadType}/{payload}/{width}/{height}.{filetype}` | Generate barcode image with explicit dimensions and file extension; optional `rotate` | None |
| GET | `/v2/barcode/types` | Alias for `/fubar/v2/barcode/types` | None |
| GET | `/v2/barcode/{codeType}/width/base64/{payload}` | Alias for `/fubar/v2/barcode/{codeType}/width/base64/{payload}` | None |
| GET | `/v2/barcode/{codeType}/{payloadType}/{payload}.{filetype}` | Alias for v2 image generation endpoint | None |
| GET | `/v2/barcode/{codeType}/{payloadType}/{payload}/{width}/{height}.{filetype}` | Alias for v2 image generation with dimensions | None |

### v3 — Simplified Image Generation (no payloadType path segment)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/fubar/v3/barcode/formats` | Returns list of supported output formats (JSON: `GIF`, `PNG`) | None |
| GET | `/fubar/v3/barcode/types` | Returns list of supported code types (JSON) | None |
| GET | `/fubar/v3/barcode/{codeType}/{payload}.png` | Generate PNG barcode; optional `xdim` (default 2), `pad` (default 0) query params | None |
| GET | `/fubar/v3/barcode/{codeType}/{payload}.gif` | Generate GIF barcode; optional `xdim` (default 2), `pad` (default 0) query params | None |
| GET | `/fubar/v3/barcode/{codeType}/{width}/{height}/{payload}.png` | Generate PNG barcode with explicit dimensions | None |
| GET | `/fubar/v3/barcode/{codeType}/{width}/{height}/{payload}.gif` | Generate GIF barcode with explicit dimensions | None |
| GET | `/fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.png` | Generate PNG barcode for merchant center redemption URL (unencoded path) | None |
| GET | `/fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.gif` | Generate GIF barcode for merchant center redemption URL (unencoded path) | None |

## Request/Response Patterns

### Path Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `codeType` | `code128`, `code128a`, `code128b`, `code128c`, `code25`, `code25i`, `code39`, `code39ext`, `ean13`, `ean8`, `gs1`, `itf`, `qrcode`, `upc`, `pdf417` | Barcode symbology to render |
| `payloadType` | `plain`, `base64`, `base64url` | Encoding of the `payload` path segment |
| `payload` | URL-safe string | Data to encode in the barcode |
| `filetype` | `png`, `gif` | Output image format |
| `width` | integer | Desired image width in pixels |
| `height` | integer | Desired image height in pixels |

### Query Parameters

| Parameter | Endpoints | Default | Description |
|-----------|-----------|---------|-------------|
| `rotate` | v2 image endpoints | none | Rotation angle in degrees (int32) |
| `xdim` | v3 image endpoints | `2` | X dimension (bar width multiplier) |
| `pad` | v3 image endpoints | `0` | Padding in pixels |
| `context` | `/fubar/v1/barcode/{codeType}/{payloadType}/{payload}` | none | Optional context string |

### Common headers

No required custom headers. Standard HTTP `Accept` header is used for content negotiation on endpoints that return multiple content types (`image/png`, `image/gif`, `application/json`, `text/html`).

### Error format

> No evidence found in codebase for a structured error response body. HTTP 4xx status codes are returned for invalid parameters (bad codeType, malformed payload, out-of-bounds dimensions). HTTP 5xx codes indicate service-level failures.

### Pagination

> Not applicable — all endpoints return a single image or a small JSON array.

## Rate Limits

No rate limiting configured.

## Versioning

URL path versioning: `/v1/`, `/v2/`, `/v3/`. All three versions are active. The `/fubar/` prefix on all paths is a legacy internal routing alias and is functionally equivalent to the non-prefixed paths for v2 endpoints.

## OpenAPI / Schema References

- OpenAPI 2.0 spec: `doc/swagger/swagger.yaml`
- Swagger UI (production): `https://barcode-service-vip.snc1/swagger_server`
- API spec source (build-time codegen input): `src/main/resources/apis/swagger_server/api-spec.yaml`
