---
service: "PizzaNG"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session, ogwall]
---

# API Surface

## Overview

PizzaNG exposes two BFF API routes on `continuumPizzaNgService` that the React UI and Chrome extension call to retrieve agent support context and initiate order creation. Both routes are GET-based; request parameters specify the support ticket or customer context. Authentication is handled by the `continuumPizzaNgAuthComponent` using OGWall/request-header-based session validation.

## Endpoints

### BFF API Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/bff/pizza` | Returns aggregated CS agent context: customer info, order details, deal data, snippets, and refund eligibility for the current ticket | OGWall session |
| GET | `/api/bff/create-order` | Returns the data needed to initiate an order creation workflow on behalf of the customer | OGWall session |

## Request/Response Patterns

### Common headers

- Session / OGWall authentication headers — managed by `continuumPizzaNgAuthComponent`
- `Content-Type: application/json` — for all API responses

### Error format

> No evidence found in codebase. Error response shape follows I-Tier / Express defaults and is to be confirmed by service owner.

### Pagination

> No evidence found in codebase. BFF responses appear to return complete result sets for the current ticket context.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-based versioning applied. BFF routes are scoped under `/api/bff/` as a path prefix.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or GraphQL schema file detected in the repository.
