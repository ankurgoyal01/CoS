---
service: "deal_wizard"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, session]
---

# API Surface

## Overview

Deal Wizard exposes a Rails-based REST API used by its own browser UI and potentially by internal tooling. The API is organized into two namespaces: `/api/v1/` for programmatic deal lifecycle operations, and `/deals/:id/` sub-resources for wizard step data. An `/admin/` namespace provides operational dashboards for error monitoring and Salesforce integration health.

Authentication is via Salesforce OAuth 2.0 (omniauth-salesforce), with session state maintained in Redis.

## Endpoints

### Deal API (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/deals` | List deals | Session (OAuth) |
| POST | `/api/v1/deals` | Create a new deal record | Session (OAuth) |
| GET | `/api/v1/deals/:id` | Retrieve deal by ID | Session (OAuth) |
| PUT | `/api/v1/deals/:id` | Update deal record | Session (OAuth) |
| DELETE | `/api/v1/deals/:id` | Delete deal record | Session (OAuth) |
| POST | `/api/v1/create_salesforce_deal` | Persist a completed wizard deal to Salesforce | Session (OAuth) |
| GET | `/api/v1/approvals` | List deal approvals | Session (OAuth) |
| POST | `/api/v1/approvals` | Submit deal for approval | Session (OAuth) |
| GET | `/api/v1/adoption_rate` | Retrieve deal adoption rate metrics | Session (OAuth) |
| GET | `/api/v1/outstanding_vouchers` | Retrieve outstanding voucher counts | Session (OAuth) |

### Deal Sub-resources (Wizard Steps)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/:id/options` | Retrieve deal option configurations (pricing, discount, quantity) | Session (OAuth) |
| PUT | `/deals/:id/options` | Update deal option configurations | Session (OAuth) |
| GET | `/deals/:id/fine_prints` | Retrieve fine print selections for a deal | Session (OAuth) |
| PUT | `/deals/:id/fine_prints` | Update fine print selections | Session (OAuth) |
| GET | `/deals/:id/payments` | Retrieve payment terms for a deal | Session (OAuth) |
| PUT | `/deals/:id/payments` | Update payment terms | Session (OAuth) |
| GET | `/deals/:id/merchants` | Retrieve merchant associations for a deal | Session (OAuth) |
| PUT | `/deals/:id/merchants` | Update merchant associations | Session (OAuth) |
| GET | `/deals/:id/distributions` | Retrieve distribution channel settings | Session (OAuth) |
| PUT | `/deals/:id/distributions` | Update distribution channel settings | Session (OAuth) |

### Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/dashboard` | Admin dashboard with deal creation metrics | Session (OAuth, admin role) |
| GET | `/admin/salesforce_errors` | View Salesforce integration errors and failures | Session (OAuth, admin role) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT requests
- `Accept: application/json` — required for API consumers expecting JSON responses
- Session cookie (managed by Rails session middleware, backed by Redis)

### Error format

Rails standard JSON error responses; error details surface via New Relic for monitoring. Admin `/admin/salesforce_errors` surfaces structured Salesforce error payloads from the `salesforceClient` component.

### Pagination

> No evidence found for explicit pagination configuration in the inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning: `/api/v1/` prefix on programmatic endpoints. The wizard step sub-resource endpoints (`/deals/:id/`) are unversioned and are consumed directly by the wizard UI.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec or schema file in the inventory.
