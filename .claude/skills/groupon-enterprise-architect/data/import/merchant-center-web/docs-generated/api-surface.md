---
service: "merchant-center-web"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, oauth2]
---

# API Surface

## Overview

Merchant Center Web is a client-side SPA and does not expose a server-side API. It defines client-side routes for browser navigation and consumes backend APIs through proxied REST endpoints. The routes below describe the in-browser navigation surface available to merchants.

## Endpoints

### Client-Side Routes (Browser Navigation)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Dashboard / home for authenticated merchants | Doorman SSO session |
| GET | `/login` | SSO login entry point; redirects to Doorman | None |
| GET | `/onboarding/*` | Multi-step merchant onboarding wizard | Doorman SSO session |
| GET | `/messages` | Merchant messaging / notifications inbox | Doorman SSO session |
| GET | `/account/*` | Account settings and profile management | Doorman SSO session |

### Proxied Backend API Paths (Called by SPA)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| ANY | Proxied UMAPI endpoints | All merchant backend operations (deals, orders, inventory, account) | Session token (proxied) |
| ANY | Proxied AIDG endpoints | Analytics and reporting data queries | Session token (proxied) |
| ANY | Proxied AIaaS endpoints | Image classification for deal asset uploads | Session token (proxied) |
| ANY | Proxied Bynder endpoints | Digital asset library access | Session token (proxied) |
| ANY | Proxied Salesforce endpoints | CRM context for merchant | Session token (proxied) |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific header conventions. Standard browser-initiated HTTPS requests; session credentials forwarded via cookie or Authorization header through proxy layer.

### Error format

> No evidence found in codebase for a standardized client-visible error envelope. Error handling is delegated to @tanstack/react-query error boundaries and form-level validation via zod.

### Pagination

> No evidence found in codebase for a specific pagination contract. Pagination behavior is determined by the upstream UMAPI and AIDG services.

## Rate Limits

> No rate limiting configured at the SPA layer. Rate limiting is enforced by upstream backend services (UMAPI, AIDG).

## Versioning

The SPA itself has no API versioning; versioning is managed by the upstream backend services it calls. The application is deployed as immutable static assets; new versions are published via CI/CD and served from GCS/Akamai CDN.

## OpenAPI / Schema References

> No evidence found in codebase. Schema contracts are owned by the upstream UMAPI and AIDG services. Runtime input validation uses zod schemas co-located with forms.
