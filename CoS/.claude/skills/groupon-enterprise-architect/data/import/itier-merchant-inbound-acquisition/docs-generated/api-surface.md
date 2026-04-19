---
service: "itier-merchant-inbound-acquisition"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, html]
auth_mechanisms: [session, itier-user-auth]
---

# API Surface

## Overview

The service exposes two categories of HTTP endpoints. Page routes render HTML signup and marketing pages for browsers. BFF API routes (`/merchant/inbound/api/*`) are called by the client-side React signup form to perform geocoding, field validation, configuration loading, and lead submission. All endpoints are served via `itier-server`. The OpenAPI specification is located at `doc/openapi.yml`.

Production base URL: `https://merchant-inbound-acquisition.production.service`
Staging base URL: `https://merchant-inbound-acquisition.staging.service`

## Endpoints

### Page Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Root page (redirects to signup) | None |
| `GET` | `/merchant/signup` | Main merchant signup page; accepts UTM and incentive query params | None |
| `GET` | `/merchant/signup/marketing` | Marketing landing page variant | None |
| `GET` | `/merchant/signup/marketing/form` | Signup form page (marketing variant) | None |
| `GET` | `/merchant/signup/marketing/form/assets` | Static assets for marketing form | None |
| `GET` | `/merchant/signup/marketing/form/test` | Test variant of marketing form | None |
| `GET` | `/merchant/signup/marketing/form/widget` | Embeddable widget form variant | None |
| `GET` | `/merchant/signup/marketing/success/inbound` | Post-submission success page (marketing, inbound path) | None |
| `GET` | `/merchant/signup/marketing/success/user-signup` | Post-submission success page (marketing, user-signup path) | None |
| `GET` | `/merchant/signup/success/inbound` | Post-submission success page (inbound path) | None |
| `GET` | `/merchant/signup/success/user-return` | Success page for returning users | None |
| `GET` | `/merchant/signup/success/user-signup` | Success page for new user account creation | None |

### BFF API Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/merchant/inbound/api/geo` | Returns address autocomplete suggestions from Groupon V2 / Lazlo | None |
| `GET` | `/merchant/inbound/api/place` | Returns place details for a given `placeid` (Google Places-style) | None |
| `POST` | `/merchant/inbound/api/lead` | Creates a merchant lead; routes to Metro draft service or Salesforce | None |
| `GET` | `/merchant/inbound/api/loadconfig` | Loads locale-specific merchant configuration from Metro | None |
| `GET` | `/merchant/inbound/api/pds` | Returns product/deal-service category taxonomy from Metro | None |
| `POST` | `/merchant/inbound/api/validatefieldbyname` | Validates a single form field for deduplication against the draft service | None |

## Request/Response Patterns

### Common headers

- `Referer` — inspected on `POST /merchant/inbound/api/lead` and success page GET requests to determine account-creation routing (feature flag `enableHeaderParam`)
- `itier_merchant_center_acquasition_country_code` — query parameter parsed from the `Referer` URL to trigger account-creation mode

### Query parameters for `/merchant/signup`

| Parameter | Purpose |
|-----------|---------|
| `utm_source` | Marketing attribution — UTM source |
| `utm_campaign` | Marketing attribution — UTM campaign |
| `utm_medium` | Marketing attribution — UTM medium |
| `itier_merchant_center_acquasition_country_code` | Country code override for account-creation routing |
| `bWt0bmdfaW5jZW50aXZpc2Vk` | Incentivised merchant flag (base64-encoded) |
| `incentiveChannel` | Incentive channel identifier |

### Error format

Errors from BFF API routes are returned as JSON: `{ "message": "<error string>" }`. The HTTP status code mirrors the upstream response or defaults to 200 with an error body when upstream exceptions are caught.

### Pagination

> Not applicable — BFF API endpoints return single-result responses.

## Rate Limits

> No rate limiting configured at this service layer. Upstream services (Metro, Salesforce) may apply their own limits.

## Versioning

No URL versioning is applied. The API is internally versioned via the `metro-client` and `jsforce` SDK versions. The `createDraftMerchantV2` Metro endpoint is selected at runtime based on a `treatment` flag in the lead payload.

## OpenAPI / Schema References

OpenAPI 3.0 specification: `doc/openapi.yml` (relative to repository root).
Service Portal: https://service-portal.groupondev.com/services/merchant-inbound-acquisition
