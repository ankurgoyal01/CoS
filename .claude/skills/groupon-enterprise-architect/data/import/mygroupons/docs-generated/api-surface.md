---
service: "mygroupons"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

My Groupons exposes a set of server-rendered HTML endpoints that power the post-purchase customer experience. All routes are consumed directly by end-user browsers. Authentication is enforced via Groupon session middleware (keldor). The service acts as a BFF — it has no public JSON API; all responses are HTML pages rendered server-side using Preact and Mustache.

## Endpoints

### My Groupons Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mygroupons` | Renders the main My Groupons deal list for the authenticated user | Session required |
| GET | `/mygroupons/vouchers/:id` | Renders the voucher detail page for a specific voucher | Session required |
| GET | `/mygroupons/vouchers/:id/pdf` | Generates and streams a PDF voucher for the specified voucher ID | Session required |
| GET | `/mygroupons/returns` | Renders the return request page | Session required |
| GET | `/mygroupons/exchanges` | Renders the voucher exchange page | Session required |
| GET | `/mygroupons/gifting` | Renders the voucher gifting page | Session required |
| GET | `/mygroupons/track-order/:id` | Renders the order shipment tracking page for the specified order | Session required |
| GET | `/mygroupons/my-bucks` | Renders the Groupon Bucks balance and history page | Session required |
| GET | `/mygroupons/account/details` | Renders the account details editing page | Session required |

## Request/Response Patterns

### Common headers

- `Cookie` — carries the Groupon session token; validated by keldor middleware on every request
- `Accept-Language` — used for locale-aware rendering of deal and voucher content
- `X-Forwarded-For` — propagated by API Proxy for downstream geo-aware calls

### Error format

HTML error pages are returned for server-side rendering failures. Downstream service errors are handled by the orchestration layer (`myGroupons_requestOrchestration`) — non-critical failures degrade gracefully (e.g., recommendations section omitted if Relevance API is unavailable). Critical failures (orders data unavailable) result in an error page render.

### Pagination

The main My Groupons list (`/mygroupons`) supports cursor or page-based pagination via query parameters passed through to `continuumOrdersService`. Specific pagination parameters are governed by the orders client contract.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting is enforced upstream by API Proxy and Akamai.

## Versioning

No API versioning strategy. The service exposes a single version of each HTML route. Breaking changes are deployed via coordinated releases.

## OpenAPI / Schema References

> No evidence found. This service renders HTML pages; no OpenAPI or machine-readable schema is maintained in the repository.
