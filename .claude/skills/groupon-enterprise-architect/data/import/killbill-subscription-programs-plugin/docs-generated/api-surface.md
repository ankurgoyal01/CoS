---
service: "killbill-subscription-programs-plugin"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [killbill-api-key, killbill-api-secret, basic-auth, sp-auth-token]
---

# API Surface

## Overview

The plugin exposes HTTP endpoints under the base path `/plugins/sp-plugin/` mounted on the Kill Bill Tomcat container (port 8080). All endpoints require Kill Bill tenant authentication via `X-Killbill-ApiKey` and `X-Killbill-ApiSecret` headers. The API is used by operators and internal systems to manually trigger or refresh subscription orders, manage tokens, and check service health. Standard Kill Bill admin Basic Auth (`admin:password`) is also required for most plugin endpoints.

## Endpoints

### Orders

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/plugins/sp-plugin/orders/v1` | Manually trigger a new order for an existing Kill Bill invoice | Basic Auth + `X-Killbill-ApiKey` + `X-Killbill-ApiSecret` |
| `POST` | `/plugins/sp-plugin/orders/v1/refresh` | Refresh invoice state for an existing Groupon order (by `orderId`/`consumerId` body or `invoiceId` query param) | Basic Auth + `X-Killbill-ApiKey` + `X-Killbill-ApiSecret` |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/plugins/sp-plugin/healthcheck` | Plugin health status (on-prem, checks MBus listener states) | None |
| `GET` | `/plugins/sp-plugin/healthcheck/cloud` | Plugin health status (cloud readiness/liveness probe) | None |

### Tokens

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/plugins/sp-plugin/tokens/v1` | Generate a short-lived authorization token for a given user/subscription | Basic Auth + `X-Killbill-ApiKey` + `X-Killbill-ApiSecret` |

## Request/Response Patterns

### Common headers

- `X-Killbill-ApiKey`: Kill Bill tenant API key (required for all non-health endpoints)
- `X-Killbill-ApiSecret`: Kill Bill tenant API secret (required for all non-health endpoints)
- `X-Killbill-CreatedBy`: Caller identifier (required by Kill Bill for audit)
- `X-Request-Id`: Request correlation identifier (optional; used for tracing through GAPI calls)
- `Content-Type: application/json`: Required for POST request bodies

### Error format

Kill Bill standard error responses are returned as JSON. Plugin-level errors are recorded as custom fields on the Kill Bill invoice object (`ORDER_FAILED` field containing the error detail).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

Endpoints are versioned by URL path segment (`/v1`). The current version for orders and tokens endpoints is `v1`. No content-negotiation or header-based versioning is used.

## OpenAPI / Schema References

An OpenAPI 2.0 (Swagger) specification is present at `doc/swagger/swagger.json`. The spec describes the `getSubscriptions.response` schema with fields: `uuid`, `status`, `billingPeriod`, `billingRecordUuid`, `dealUuid`, `merchandisingProductUuid`, `startDate`, `endDate`, `nextPurchaseDate`, `orders`, and `quantity`. The spec also documents the common request headers `X-Killbill-ApiKey`, `X-Killbill-ApiSecret`, and `X-Request-Id`. Extended API documentation is published on the [Groupon Service Portal for subscription-engine](https://services.groupondev.com/services/subscription-engine#endpoint_documentation).
