---
service: "itier-3pip-docs"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "http"]
auth_mechanisms: ["cookie", "oauth-token", "csrf"]
---

# API Surface

## Overview

`itier-3pip-docs` exposes a REST HTTP API consumed by its own frontend bundle (Preact SPA) running in partner browsers. All API endpoints require a valid Groupon partner session (cookie-based OAuth token). CSRF protection is enabled for mutating endpoints. The service also serves server-rendered HTML pages for the Groupon Simulator and API documentation views. The OpenAPI spec is available at runtime via `GET /groupon-simulator/get-open-api-spec`.

Full spec: `doc/openapi.yml` in the repository.

## Endpoints

### Page Routes (HTML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Root — validates session, redirects to `/integration` or Groupon login | Cookie session |
| `GET` | `/integration` | Shows the setup Integration page | Cookie session |
| `GET` | `/launch` | Shows launch page | Cookie session |
| `GET` | `/review-integration` | Shows review integration page | Cookie session |
| `GET` | `/set-up-test-deals` | Shows set-up test deals page | Cookie session |
| `GET` | `/test-integration` | Shows test integration page | Cookie session |
| `GET` | `/uptime` | Shows partner uptime metrics page | Cookie session |
| `GET` | `/logout` | Clears auth cookies (`macaroon`), redirects to login | Cookie session |
| `GET` | `/get-cookies` | Checks whether required auth cookies are set | None |
| `GET` | `/3pip/docs` | Legacy route — renders the Redoc API documentation page | Cookie session (merchant login) |

### Simulator API Routes (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/get-partner-config` | Gets full partner onboarding configuration for a country | Cookie session |
| `GET` | `/api/get-partner-country-codes` | Gets list of country codes available for the authenticated partner | Cookie session |
| `GET` | `/api/get-review-integration-data` | Gets partner onboarding config summary for review integration page | Cookie session |
| `GET` | `/api/get-configure-test-deal-config` | Gets test deal configuration including deal details and acquisition method | Cookie session |
| `GET` | `/api/get-logs` | Gets simulator transaction logs for a time window | Cookie session |
| `GET` | `/api/get-uptime-metrics` | Gets partner API uptime metrics for a date range | Cookie session |
| `GET` | `/api/get-production-secrets` | Gets production API key for certified partners | Cookie session |
| `GET` | `/api/get-purchases/ttd/{configurationId}` | Gets list of TTD (Things To Do) purchases for a configuration | Cookie session |
| `GET` | `/api/get-purchases/hbw/{configurationId}` | Gets list of HBW (Hotels by World) purchases for a configuration | Cookie session |
| `GET` | `/api/onboarding-configurations/{configurationId}/reviews` | Gets configuration review history | Cookie session |
| `GET` | `/api/partners/{acquisitionMethodId}/deals/{dealId}/mappings` | Gets deal mapping schema for a specific deal | Cookie session |
| `POST` | `/api/onboarding-configurations/{configurationId}/review` | Submits a review request for a configuration | Cookie session |
| `POST` | `/api/onboarding-configurations/{configurationId}/update-status` | Updates the onboarding configuration status (triggers state event) | Cookie session |
| `PUT` | `/api/onboarding-configurations/{configurationId}/trigger-availability` | Triggers availability sync for a deal | Cookie session |
| `PUT` | `/api/partners/{acquisitionMethodId}/mappings` | Updates inventory mappings for a partner | Cookie session |
| `GET` | `/api/partners/{acquisitionMethodId}/merchant/{partnerMerchantId}/services` | Gets merchant feed/services data by merchant ID | Cookie session |

### Utility Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/groupon-simulator/get-open-api-spec` | Returns the merged OpenAPI spec as a downloadable `swagger.json`; supports `?operationId=` filtering | None |

## Request/Response Patterns

### Common headers

- `cookie`: Required for all authenticated endpoints — must contain a valid Groupon partner session token
- `Content-Type: application/json`: Required for `POST` and `PUT` requests with a body
- CSRF token: Required for state-mutating requests; token is embedded in page HTML and sent per-request

### Error format

> No standardized error envelope is documented in the OpenAPI spec. Errors are returned with appropriate HTTP status codes (400, 401, 500). The `simulatorApiActions` module returns `{ statusCode, message }` objects for upstream errors forwarded from PAPI GraphQL responses.

### Pagination

> No evidence found in codebase. The API does not implement pagination; all results for a partner are returned in a single response.

## Rate Limits

> No rate limiting configured. The service relies on upstream GraphQL API and Lazlo service rate limits.

## Versioning

The service does not implement URL-based API versioning. The 3PIP OpenAPI specification packages (`@grpn/grpn-3pip-ingestion-docs`, `@grpn/grpn-3pip-transactional-docs`, `@grpn/grpn-3pip-booking-docs`) are pinned to fixed versions in `package.json` to prevent unreviewed spec changes from reaching partners.

## OpenAPI / Schema References

- Runtime spec endpoint: `GET /groupon-simulator/get-open-api-spec`
- Source spec file: `doc/openapi.yml`
- Ingestion spec package: `@grpn/grpn-3pip-ingestion-docs` v2.21.1
- Transactional spec package: `@grpn/grpn-3pip-transactional-docs` v2.19.8
- Booking spec package: `@grpn/grpn-3pip-booking-docs` v1.2.1
