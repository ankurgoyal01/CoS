---
service: "orders-rails3"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

The Orders Service exposes a versioned REST API under the `/orders/v1/` prefix. Consumers include storefront clients, mobile applications, and internal Continuum services. The API covers the full order lifecycle: creating and retrieving orders and order units, processing payments and transactions, managing merchant tax accounts, and handling account redaction requests for GDPR compliance.

## Endpoints

### Orders

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/orders/v1/orders` | Create a new order | session / api-key |
| GET | `/orders/v1/orders/:id` | Retrieve order by ID | session / api-key |
| PUT | `/orders/v1/orders/:id` | Update order state | session / api-key |

### Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/orders/v1/units` | List order units | session / api-key |
| GET | `/orders/v1/units/:id` | Retrieve a specific unit | session / api-key |
| PUT | `/orders/v1/units/:id` | Update unit state | session / api-key |

### Payments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/orders/v1/payments` | Submit a payment action | session / api-key |
| GET | `/orders/v1/payments/:id` | Retrieve payment record | session / api-key |
| PUT | `/orders/v1/payments/:id` | Update payment record | session / api-key |

### Merchant Tax

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/orders/v1/merchants/tax` | Retrieve merchant tax account data | api-key |
| POST | `/orders/v1/merchants/tax` | Commit merchant tax document | api-key |

### Account Redaction

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/orders/v1/account/redaction` | Initiate account redaction workflow (GDPR) | api-key |
| GET | `/orders/v1/account/redaction/:id` | Check redaction job status | api-key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- `X-Groupon-RequestId` — correlation ID for distributed tracing

### Error format

Standard Rails JSON error responses with HTTP status codes. Error bodies include a `message` field and, where applicable, a `code` field for machine-readable error classification.

### Pagination

> No evidence found of a documented pagination scheme in the architecture model. Assumed cursor or page-based pagination consistent with Continuum API conventions.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting is applied upstream at the API gateway / load balancer layer.

## Versioning

The API uses URL path versioning with the prefix `/orders/v1/`. All endpoints are under this version prefix; no header-based versioning is in use.

## OpenAPI / Schema References

> No OpenAPI spec or schema file is present in the architecture repository for this service. API contracts are defined within the Rails routes and controller code.
