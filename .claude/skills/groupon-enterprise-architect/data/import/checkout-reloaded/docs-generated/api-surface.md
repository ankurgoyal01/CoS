---
service: "checkout-reloaded"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session, csrf-token]
---

# API Surface

## Overview

checkout-reloaded exposes an HTTP BFF API consumed directly by Groupon consumer browsers and mobile web views. All page-rendering endpoints return server-side rendered HTML (Preact SSR) with Redux initial state injected for client hydration. Mutation endpoints (POST) accept form data or JSON and redirect on success. The service is not a public machine-to-machine API; it is designed for browser interaction within the Groupon checkout funnel.

## Endpoints

### Checkout

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/checkout` | Renders the checkout page (SSR Preact); fetches cart, deals, and pricing | Session |
| GET | `/checkout/:orderId` | Renders the checkout page for a specific order | Session |
| POST | `/checkout/submit` | Submits checkout form; orchestrates payment authorization and order finalization | Session + CSRF token |

### Cart

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cart` | Renders the cart review page (SSR) | Session |
| POST | `/cart/update` | Updates cart items (quantity adjustment or item removal) | Session + CSRF token |

### Receipt

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/receipt/:orderId` | Renders the order receipt page (SSR) | Session |
| POST | `/receipt/resend-email` | Re-sends the order confirmation email to the consumer | Session + CSRF token |

### Post-Purchase

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/post-purchase` | Renders the post-purchase upsell offers page | Session |
| POST | `/post-purchase/redeem` | Processes a selected post-purchase redemption | Session + CSRF token |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Health check for Kubernetes readiness and liveness probes | None |

## Request/Response Patterns

### Common headers

- `Cookie` — carries the Express session cookie (signed with `SESSION_SECRET`)
- `X-CSRF-Token` — required on all POST mutation endpoints; validated server-side before processing

### Error format

On validation or upstream failure, the BFF re-renders the relevant SSR page with an embedded error state in the Redux initial state payload, allowing Preact to display contextual error messages without a full page redirect. Hard failures (5xx from critical dependencies) result in a redirect to an error page.

### Pagination

> Not applicable — checkout, cart, and receipt pages are single-context views; no paginated data sets are exposed through the BFF.

## Rate Limits

> No rate limiting configured at the BFF layer. Rate limiting is enforced upstream by Akamai CDN / edge layer.

## Versioning

No explicit API versioning is applied. The BFF is a consumer-facing UI layer; breaking changes are managed via feature flags (Keldor) and coordinated frontend/backend deploys rather than versioned URL paths.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are published for this BFF; it is a browser-facing HTML surface, not a machine-to-machine API.
