---
service: "itier-tpp"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, html]
auth_mechanisms: [macaroon, csrf]
---

# API Surface

## Overview

I-Tier TPP exposes both server-rendered HTML pages (for the portal UI) and JSON API endpoints (for client-side interactions). All routes are protected by Doorman macaroon authentication. CSRF protection is applied to all mutating requests via the `csurf` middleware. The service is accessible internally via Hybrid Boundary at `itier-tpp.production.service` and externally at `tpp.groupondev.com`. The full OpenAPI 3.0 spec is available at `doc/openapi.yml`.

## Endpoints

### Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/partner-config` | Render partner configuration page | macaroon |
| GET | `/admin/partner-config-review` | Render partner configuration review page | macaroon |

### Partner Configurations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/partner_configurations` | Retrieve partner configurations; supports `taxonomy` and `acquisitionMethodId` query params | macaroon |
| POST | `/api/partner_configurations` | Create a new partner configuration | macaroon + CSRF |
| PUT | `/api/partner_configurations/{acquisitionMethodId}` | Replace a partner configuration by acquisition method ID | macaroon + CSRF |
| PATCH | `/api/partner_configurations/{acquisitionMethodId}` | Partially update a partner configuration | macaroon + CSRF |
| POST | `/partner_configurations/{configId}/review` | Submit a review decision (approve/reject) for a partner configuration | macaroon + CSRF |
| GET | `/partner_configurations/{configId}/reviews` | Fetch review history for a partner configuration | macaroon |

### Onboarding Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/onboarding_configuration` | Retrieve onboarding configuration; supports `taxonomy` and `acquisitionMethodId` query params | macaroon |
| POST | `/onboarding_configuration` | Create a new onboarding configuration | macaroon + CSRF |
| GET | `/onboarding_configuration/{configId}` | Retrieve a specific onboarding configuration | macaroon |
| PUT | `/onboarding_configuration/{configId}` | Create or replace an onboarding configuration | macaroon + CSRF |
| PATCH | `/onboarding_configuration/{configId}` | Partially update an onboarding configuration | macaroon + CSRF |
| POST | `/onboarding_configuration/{configId}/users` | Register a user email against an onboarding configuration | macaroon + CSRF |

### Merchants (HBW)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{partnerId}` | Render merchants management page for a partner | macaroon |
| GET | `/merchants/{partnerId}/{merchantId}` | Render merchant deal listings | macaroon |
| GET | `/merchants/{partnerId}/{merchantId}/{dealId}/{inventoryProductUuid}` | Render deal option detail page | macaroon |
| GET | `/merchants/{partnerId}/{merchantId}/{dealId}/{inventoryProductUuid}/{serviceId}` | Render merchant service detail page | macaroon |

### Partner Booking (Booker)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/partnerbooking` | Render partner booking landing page | macaroon |
| GET | `/partnerbooking/deal-config` | Render deal configuration page | macaroon |
| GET | `/partnerbooking/deal-offboard` | Render deal offboarding page | macaroon |
| GET | `/partnerbooking/deal/{dealId}` | Get deal details | macaroon |
| GET | `/partnerbooking/merchant/{merchantId}` | View merchant details | macaroon |
| PUT | `/partnerbooking/api/merchant_configuration/{partnerName}` | Update merchant configuration for a partner | macaroon + CSRF |
| GET | `/partnerbooking/api/partner/{partnerId}/mapping/deal/{dealId}` | Retrieve deal mapping schema | macaroon |
| PUT | `/partnerbooking/api/partner/{partnerId}/mappings` | Update partner deal mappings | macaroon + CSRF |
| PUT | `/partnerbooking/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}` | Update a deal (activate, deactivate, sync); requires `actionType` query param | macaroon + CSRF |

### TTD Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ttd/{partnerAcmid}` | Render TTD partner landing page | macaroon |
| GET | `/ttd/{partnerAcmid}/merchant/{merchantId}` | View TTD merchant details | macaroon |
| GET | `/ttd/{partnerAcmid}/{merchantId}/deal-config/{dealUuid}` | Render TTD deal configuration | macaroon |
| GET | `/ttd/deal/{dealId}` | Get TTD deal details | macaroon |
| GET | `/ttd/api/partner/{partnerId}/mapping/deal/{dealId}` | Retrieve TTD deal mapping schema | macaroon |
| PUT | `/ttd/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}` | Update a TTD deal; requires `actionType` query param | macaroon + CSRF |

### Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/metrics/merchants` | Render 3PIP merchant metrics dashboard | macaroon |
| GET | `/metrics/uptime` | Render 3PIP uptime metrics dashboard | macaroon |

### Redirects

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/goto/{partnerName}` | Redirect to a partner's portal page | macaroon |
| GET | `/goto/{partnerName}/{partnerProductId}` | Redirect to a partner's product page | macaroon |

## Request/Response Patterns

### Common headers

- `Cookie: macaroon=<token>` — Doorman authentication token, required on all requests
- `X-CSRF-Token` — CSRF token required on all state-mutating requests (POST, PUT, PATCH)
- `Content-Type: application/json` — required on JSON API endpoints

### Error format

Standard HTTP status codes are returned. HTML pages render error pages via `itier-error-page`. API endpoints return JSON error bodies. The service monitors error rates via Nagios alerts (`tpp_api_response_code errors increase`, `tpp_response_code errors increase`).

### Pagination

> No evidence found of pagination support in the current OpenAPI spec. Results are returned in full.

## Rate Limits

> No rate limiting configured. The service is expected to handle a maximum of ~100 RPM based on SLA documentation.

## Versioning

No URL path versioning. The API is versioned implicitly through the service deployment version. The OpenAPI spec version maps to a commit hash rather than a semantic version.

## OpenAPI / Schema References

Full OpenAPI 3.0 specification: `doc/openapi.yml`

Servers defined in the spec:
- Production: `https://itier-tpp.production.service` (Hybrid Boundary)
- Preprod/Staging: `https://itier-tpp.staging.service` (Hybrid Boundary)
