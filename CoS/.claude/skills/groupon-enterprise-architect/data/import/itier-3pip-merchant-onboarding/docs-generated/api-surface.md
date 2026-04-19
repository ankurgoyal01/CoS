---
service: "itier-3pip-merchant-onboarding"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt, oauth2, session]
---

# API Surface

## Overview

The 3PIP Merchant Onboarding service exposes HTTP endpoints consumed by merchant browsers during the onboarding lifecycle. Endpoints fall into four groups: OAuth install redirects, OAuth callback handling, MSS onboarding form submission, and SSO token decoding. Each partner (Square, Mindbody, Shopify) has its own module under `modules/*/open-api.js` with partner-specific route definitions. The service does not expose a public REST API; all routes are merchant-browser-facing.

## Endpoints

### OAuth Install and Redirect

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/install` | Initiates the OAuth install flow; redirects merchant to the partner OAuth authorization page | Okta JWT / session |
| GET | `/oauth-redirect` | Receives the OAuth callback from the partner platform; exchanges authorization code and updates onboarding state | OAuth2 callback |

### Onboarding Submission

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/mss-onboarding` | Submits MSS (Merchant Self-Service) onboarding data to Partner Service; completes partner activation | Okta JWT / session |

### Identity Verification

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/decode-sso-token` | Decodes and validates an Okta-signed SSO token; returns verified merchant identity claims | Okta JWT |

### Partner-Specific Modules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/square/*` | Square-specific onboarding and connection management UI pages | Okta JWT / session |
| GET | `/mindbody/*` | Mindbody-specific onboarding and connection management UI pages | Okta JWT / session |
| GET | `/shopify/*` | Shopify-specific onboarding and connection management UI pages | Okta JWT / session |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <okta-jwt>` — required for authenticated routes
- `Content-Type: application/json` — for POST endpoints

### Error format

> No evidence found in the DSL model for a standardized error response schema. Error handling follows standard iTier-server conventions.

### Pagination

> Not applicable — all endpoints return single-resource or redirect responses.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning. The service follows the iTier deployment model — a single active version is deployed per environment.

## OpenAPI / Schema References

Route declarations are defined in partner-module files under `modules/*/open-api.js`. No standalone OpenAPI specification file was identified in the inventory.
