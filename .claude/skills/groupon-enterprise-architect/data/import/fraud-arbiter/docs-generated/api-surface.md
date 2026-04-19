---
service: "fraud-arbiter"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [api-key, hmac-signature]
---

# API Surface

## Overview

Fraud Arbiter exposes two categories of API surface: inbound webhook receivers that accept fraud-decision notifications from Signifyd and Riskified, and internal REST endpoints that allow other Continuum services to query order fraud review status. Webhook payloads are validated by provider-specific signature mechanisms before processing begins.

## Endpoints

### Fraud Provider Webhooks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/webhooks/signifyd` | Receives fraud decision, fulfillment, and return update notifications from Signifyd | HMAC signature validation |
| POST | `/webhooks/riskified` | Receives fraud decision, fulfillment, refund, and cancellation notifications from Riskified | HMAC signature validation |

### Internal Fraud Review API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/fraud_reviews/:order_id` | Returns current fraud review status for an order | Internal API key / service token |
| GET | `/fraud_reviews/:order_id/events` | Returns the audit event log for an order's fraud review | Internal API key / service token |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests
- `X-Signifyd-Sec-Hmac-Sha256` — HMAC signature header for Signifyd webhook validation
- `X-RISKIFIED-HMAC-SHA256` — HMAC signature header for Riskified webhook validation

### Error format

> No evidence found in codebase. Standard Rails JSON error responses are expected (`{ "error": "...", "details": [...] }`).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

> No evidence found in codebase. Endpoints do not use a versioned URL path prefix based on the inventory.

## OpenAPI / Schema References

> No evidence found in codebase.
