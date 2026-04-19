---
service: "sponsored-campaign-itier"
title: API Surface
generated: "2026-03-02"
type: api-surface
protocols: [rest]
auth_mechanisms: [session-cookie]
---

# API Surface

## Overview

The service exposes two categories of HTTP endpoints under the `/merchant/center/sponsored/` base path. UI routes return server-side-rendered HTML pages (React/Preact SPA shell) for the Merchant Center. API proxy routes accept and return JSON; they validate the merchant session, then forward the request to UMAPI or Groupon V2 and relay the response back to the browser. All endpoints require a valid `authToken` cookie (session) and `mc_mid` cookie (merchant ID). The OpenAPI specification is located at `doc/openapi.yml`.

## Endpoints

### UI Routes (HTML — Server-Side Rendered)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant/center/sponsored/campaign/homepage` | Renders the sponsored campaign homepage/dashboard | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/*` | Wildcard catch-all for campaign section pages | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/performance/*` | Renders campaign performance analytics pages | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/billing/*` | Renders billing and payment management pages | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/resume/*` | Renders campaign resume flow pages | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/update/*` | Renders campaign update/edit flow pages | authToken cookie |
| GET | `/merchant/center/sponsored/campaign/update/locations/*` | Renders location targeting update pages | authToken cookie |

### API Proxy Routes (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant/center/sponsored/api/proxy/get_billing_records/{userId}` | Retrieves billing records for a merchant user | authToken + mc_mid cookies |
| POST | `/merchant/center/sponsored/api/proxy/create_billing_record/{userId}` | Creates a new billing record (payment method) for a user | authToken + mc_mid cookies |
| PUT | `/merchant/center/sponsored/api/proxy/update_billing_record/{userId}` | Updates an existing billing record | authToken + mc_mid cookies |
| DELETE | `/merchant/center/sponsored/api/proxy/delete_billing_record/{userId}` | Deletes a billing record | authToken + mc_mid cookies |
| PUT | `/merchant/center/sponsored/api/proxy/update_campaign/{campaignId}` | Updates campaign details (budget, dates, targeting) | authToken + mc_mid cookies |
| DELETE | `/merchant/center/sponsored/api/proxy/campaign/{campaignId}` | Deletes an active campaign | authToken + mc_mid cookies |
| DELETE | `/merchant/center/sponsored/api/proxy/campaign/delete_draft` | Deletes a draft campaign | authToken + mc_mid cookies |
| POST | `/merchant/center/sponsored/api/proxy/campaign/{campaignId}/update_status/{status}` | Pauses or resumes a campaign by toggling its status | authToken + mc_mid cookies |
| POST | `/merchant/center/sponsored/api/proxy/top_up_wallet/{merchantId}` | Adds funds to a merchant's sponsored campaign wallet | authToken + mc_mid cookies |
| POST | `/merchant/center/sponsored/api/proxy/refund_wallet/{merchantId}` | Issues a refund to a merchant's wallet | authToken + mc_mid cookies |

## Request/Response Patterns

### Common headers

- `Cookie: authToken=<session-token>` — required on all requests; validated by `itier-user-auth` middleware
- `Cookie: mc_mid=<merchant-id>` — merchant identity, extracted from cookie on proxy routes
- `Content-Type: application/json` — required for POST/PUT proxy routes

### Error format

> No evidence found — error response shape is defined in `doc/openapi.yml` and enforced by itier-server defaults.

### Pagination

> No evidence found — billing record and campaign lists are returned as complete arrays in the proxy response. UMAPI may apply server-side pagination; this service relays whatever UMAPI returns.

## Rate Limits

> No rate limiting configured.

## Versioning

The service does not apply versioning to its own routes. Upstream UMAPI endpoints use a `/v2/` path prefix (e.g., `/v2/merchants/{permalink}/sponsored/campaigns/`), but this versioning is internal to the proxy implementation and not exposed to Merchant Center UI consumers.

## OpenAPI / Schema References

- OpenAPI specification: `doc/openapi.yml` (in the service repository)
