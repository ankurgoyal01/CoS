---
service: "incentive-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

The Incentive Service exposes a REST HTTP API served by Play Framework on port 9000 (default). The API is active only when `SERVICE_MODE` is set to `checkout`, `admin`, or `bulk`. Checkout systems call the validation and redemption endpoints synchronously during the purchase flow. Administrative users interact with the campaign management endpoints via the admin UI. Bulk export endpoints are available in bulk mode.

## Endpoints

### Promo Code — Checkout

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/incentives/validate` | Validate a promo code for a given user and deal context | session / api-key |
| POST | `/incentives/redeem` | Redeem a promo code for an order | session / api-key |

### Incentive Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/incentives/:id` | Fetch incentive details by ID | session / api-key |
| POST | `/incentives` | Create a new incentive (admin) | admin session |
| PUT | `/incentives/:id` | Update an existing incentive (admin) | admin session |

### Audience Qualification

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/audience/qualify` | Trigger an audience qualification job for a campaign | session / api-key |
| GET | `/audience/:campaignId/status` | Poll the status of an audience qualification job | session / api-key |

### Bulk Export

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/bulk-export/start` | Enqueue a bulk data export job | session / api-key |
| GET | `/bulk-export/:jobId/status` | Poll the progress of a bulk export job | session / api-key |

### Admin UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/campaigns` | List all campaigns (admin UI) | admin session |
| GET | `/admin/campaigns/:id` | View campaign detail (admin UI) | admin session |
| POST | `/admin/campaigns/:id/approve` | Approve a campaign and transition to active state | admin session |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness and readiness health check | none |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT request bodies
- `Accept: application/json` — expected for API consumers; admin UI requests accept `text/html`

### Error format

> No evidence found in codebase. Standard Play Framework JSON error responses are expected, including HTTP status codes and an error message body.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

> No evidence found in codebase. No URL-based or header-based API versioning is present in the inventory.

## OpenAPI / Schema References

> No evidence found in codebase.
