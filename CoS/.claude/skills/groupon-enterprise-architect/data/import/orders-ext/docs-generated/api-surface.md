---
service: "orders-ext"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [http-basic, hmac-sha256, none]
---

# API Surface

## Overview

Orders Ext exposes inbound webhook endpoints consumed exclusively by external fraud and payment partners. All endpoints are push-only (POST); there is no consumer-facing query API. Authentication varies per endpoint: Accertify uses HTTP Basic auth, Signifyd uses HMAC-SHA256 signature verification, and PayPal uses its own signature verification flow. KillBill notifications are unauthenticated at the Rails level (trusted internal routing). Health and status endpoints are unauthenticated.

## Endpoints

### Health & Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes liveness probe | None |
| GET | `/status` | Simple application status ping | None |

### Accertify Fraud Resolution

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/accertify_listener/resolve_order` | Receive XML fraud review resolution from Accertify; parse and enqueue async order resolution job | HTTP Basic |

### KillBill / Adyen Payment Notifications

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/killbill/notifications/killbill-:subservice/:region` | Proxy Adyen payment event notification to KillBill by subservice type and region | None (internal trusted partner) |

### PayPal Webhooks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/paypal_webhooks` | Receive PayPal billing agreement events; verify signature with PayPal API; publish cancellation event to message bus | PayPal signature verification |

### Signifyd Webhooks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/signifyd_webhooks` | Receive Signifyd fraud decision review callbacks; verify HMAC-SHA256 signature; forward `ORDER_CHECKPOINT_ACTION_UPDATE` / `SIGNIFYD_REVIEW` events to Fraud Arbiter Service | HMAC-SHA256 (`SIGNIFYD-SEC-HMAC-SHA256` header) |

## Request/Response Patterns

### Common headers

- **Accertify**: `Authorization: Basic <credentials>` (HTTP Basic Auth)
- **Signifyd**: `SIGNIFYD-SEC-HMAC-SHA256` (Base64-encoded HMAC-SHA256 of payload), `SIGNIFYD-TOPIC`, `SIGNIFYD-CHECKPOINT`
- **PayPal**: `Paypal-Transmission-Sig`, `Paypal-Auth-Algo`, `Paypal-Cert-Url`, `Paypal-Transmission-Id`, `Paypal-Transmission-Time`

### Error format

- PayPal and Signifyd endpoints return JSON: `{ "message": "<description>" }` with appropriate HTTP status codes (400, 401, 500)
- Accertify endpoint returns HTTP 400 (no body) on bad request or XML parse failure
- KillBill endpoint passes through the upstream KillBill response code and body unchanged; a zero response code (timeout) is converted to HTTP 504

### Pagination

> Not applicable. All endpoints are single-event push receivers.

## Rate Limits

> No rate limiting configured. The service relies on upstream partners to manage delivery frequency.

## Versioning

No API versioning strategy is applied. Endpoint paths are unversioned. Schema compatibility is managed via the `api_schemas/` JSON descriptor files used by `schema_driven_client`.

## OpenAPI / Schema References

Schema descriptor files (schema_driven_client format) are located at:

- `api_schemas/fraud_arbiter_service.json` — Fraud Arbiter decision review endpoint
- `api_schemas/killbill.json` — KillBill Adyen notification endpoint
- `api_schemas/pay-pal.json` — PayPal verify-webhook-signature endpoint
- `api_schemas/users-service.json` — Users Service account lookup endpoint
