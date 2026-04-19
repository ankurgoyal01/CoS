---
service: "control-center-ui"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, oauth2]
---

# API Surface

## Overview

Control Center UI is a client-side Ember.js SPA and does not expose its own server-side API. It defines client-side routes for internal tool navigation and communicates with backend services exclusively via Nginx-proxied REST endpoints. The proxy paths below are the only network-facing API surface of this application. Authentication for all routes is enforced by Doorman SSO.

## Endpoints

### Client-Side Routes (Browser Navigation)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/manual-sale/*` | Sale Builder: create and edit manual sale events | Doorman SSO session |
| GET | `/sale/*` | Sale browsing and management: view, edit, publish existing sales | Doorman SSO session |
| GET | `/sale-uploader/*` | Bulk sale upload: upload CSV files for batch sale creation | Doorman SSO session |
| GET | `/search/*` | Deal and division search: find deals to assign to sales | Doorman SSO session |

### Nginx-Proxied Backend Endpoints (Called by SPA)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| ANY | `/__/proxies/dpcc-service/v1.0/sales` | DPCC Service: sale and pricing CRUD operations | Session token (forwarded via proxy) |
| ANY | `/__/proxies/pccjt-service` | Pricing Control Center Jtier: deal search, scheduling, division management | Session token (forwarded via proxy) |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific header conventions. Standard AJAX requests via jQuery / Ember Data adapters; session credentials forwarded through Nginx proxy layer.

### Error format

> No evidence found in codebase for a standardized error envelope. Error handling is managed by Ember Data model error states and jQuery AJAX error callbacks.

### Pagination

> No evidence found in codebase for a specific pagination contract. Pagination behavior is determined by the DPCC Service and PCCJT Service backends.

## Rate Limits

> No rate limiting configured at the SPA/Nginx layer. Rate limiting is enforced by upstream backend services.

## Versioning

The DPCC Service proxy path includes a version segment: `/__/proxies/dpcc-service/v1.0/sales`. The PCCJT Service proxy path does not include a version. API versioning is owned by the respective backend services.

## OpenAPI / Schema References

> No evidence found in codebase. Schema contracts are owned by the DPCC Service and Pricing Control Center Jtier Service.
