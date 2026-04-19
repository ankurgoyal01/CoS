---
service: "s-partner-orchestration-gateway"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, jwt]
---

# API Surface

## Overview

S-POG exposes a REST API over HTTP consumed primarily by the Google Pay application. The two primary business endpoints handle "Save to Wallet" payload generation and save-to-wallet callback processing. Wallet type is passed as a path parameter (`GOOGLE` or `APPLE`); the Apple variant returns an empty response (not yet implemented). The API is versioned under `/v1/`. The service also exposes standard JTier status and health endpoints.

## Endpoints

### Wallet Endpoint

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/wallets/{walletType}/payload` | Build and return a signed JWT wallet payload for the specified units | Internal network / service mesh |
| POST | `/v1/wallets/{walletType}/callback` | Receive a save-to-wallet callback notification from the partner | Internal network / service mesh |

### Service / Diagnostic Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Hello-world liveness probe | None |
| GET | `/{name}` | Named hello (diagnostic) | None |
| GET | `/random` | Generate a random HTTP status code (diagnostic) | None |
| POST | `/post/multipart` | Multipart form upload (diagnostic) | None |
| GET | `/grpn/status` | Service status / version endpoint | None |

## Request/Response Patterns

### POST `/v1/wallets/{walletType}/payload`

**Path parameter**: `walletType` — enum `GOOGLE` or `APPLE`.

**Request body** (`spog.wallet.request.PayloadRequest`):

```json
{
  "units": [
    {
      "id": "<uuid>",
      "isId": "vis"
    }
  ]
}
```

- `units`: required array of unit ID / inventory service ID pairs
- `isId`: inventory service identifier (e.g. `"vis"` for Voucher Inventory Service)

**Response**: A signed JWT string (Google Wallet payload) on success.

### POST `/v1/wallets/{walletType}/callback`

**Path parameter**: `walletType` — enum `GOOGLE` or `APPLE`.

**Request body** (`spog.wallet.request.SaveToWalletCallbackRequest`):

```json
{
  "success": true,
  "message": "...",
  "units": [
    { "id": "<uuid>", "isId": "vis" }
  ],
  "wallets": [
    { "id": "<wallet-id>" }
  ]
}
```

### Common headers

- `Content-Type: application/json` — required for POST endpoints
- `Accept: application/json` — response format

### Error format

Standard JTier/Dropwizard error response. HTTP status codes reflect the error condition. No custom error envelope is defined in the Swagger specification beyond default responses.

### Pagination

> Not applicable — payload and callback endpoints operate on request-scoped unit lists, not paginated collections.

## Rate Limits

> No rate limiting configured. Traffic from Google Pay is mediated by the service mesh / Hybrid Boundary layer.

## Versioning

URL path versioning: all business endpoints are under `/v1/`. The `walletType` path parameter scopes the operation to a specific partner wallet integration.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`

Swagger config: `doc/swagger/config.yml`
