---
service: "ai-reporting"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

The AI Reporting service exposes a REST API implemented via Dropwizard Jersey resources. Consumers include the Sponsored Listings merchant dashboard, Salesforce callbacks, and internal Groupon tooling. All endpoints use JSON as the wire format. The API is grouped into four domains: Sponsored Campaigns dashboard, merchant wallet management, ads reporting, and CitrusAd campaign management.

## Endpoints

### Sponsored Listings Dashboard

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sponsored/v1/dashboard` | Retrieve Sponsored Listings dashboard data for a merchant | Session / API key |
| GET | `/campaigns` | List campaigns for the authenticated merchant | Session / API key |
| POST | `/campaigns` | Create a new Sponsored Listing campaign | Session / API key |
| PUT | `/campaigns/{id}` | Update an existing campaign (budget, status, search terms) | Session / API key |
| DELETE | `/campaigns/{id}` | Deactivate or pause a campaign | Session / API key |

### Merchant Wallet

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{id}/wallet` | Retrieve wallet balance and transaction history | Session / API key |
| POST | `/merchants/{id}/wallet` | Initiate a wallet top-up | Session / API key |
| GET | `/freecredits` | List free credit promotions for the merchant | Session / API key |
| POST | `/freecredits` | Issue a free credit to a merchant wallet | Session / API key |

### Ads Reporting

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/reports` | Retrieve aggregated ads performance report (LiveIntent, Rokt, GAM) | Session / API key |

### CitrusAd Campaign Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/citrusad/campaigns` | List CitrusAd campaigns and sync status | Session / API key |
| POST | `/citrusad/campaigns` | Create or sync a CitrusAd campaign | Session / API key |
| PUT | `/citrusad/campaigns/{id}` | Update CitrusAd campaign parameters (CPC, budget, search terms) | Session / API key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Accept: application/json`
- Authentication headers as required by the JTier auth layer (session token or API key)

### Error format

Standard Dropwizard/Jersey error responses use HTTP status codes with a JSON body:

```json
{
  "code": 400,
  "message": "Validation failed: budget must be greater than 0"
}
```

### Pagination

> No evidence found for a standardized pagination scheme from the available DSL inventory. Consumers should verify with the service owner.

## Rate Limits

> No rate limiting configured in the available DSL inventory. Consult service owner for production limits.

## Versioning

URL path versioning is used: `/sponsored/v1/` for the dashboard surface and `/api/v1/` for the reporting surface. CitrusAd management paths do not currently carry an explicit version segment.

## OpenAPI / Schema References

> No OpenAPI spec or proto files were identified in the architecture inventory. Contact ads-eng@groupon.com for schema references.
