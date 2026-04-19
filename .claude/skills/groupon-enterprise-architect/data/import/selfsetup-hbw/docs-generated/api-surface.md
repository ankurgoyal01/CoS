---
service: "selfsetup-hbw"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session, none]
---

# API Surface

## Overview

selfsetup-hbw exposes a set of HTTP endpoints served by the PHP/Zend/Apache stack (`continuumSsuWebApp`). The surface is primarily designed for browser-based merchant interaction (HTML forms and page navigation) with a small number of JSON-returning endpoints for AJAX lookups. There is no public API contract; all endpoints are consumed by the merchant's browser during the self-setup wizard flow. A liveness endpoint (`/heartbeat.txt`) is consumed by infrastructure health checks.

## Endpoints

### Merchant Setup Wizard

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the wizard home / landing page | None (URL contains Salesforce token) |
| GET/POST | `/front` | Renders and processes the main merchant profile setup form | Session |
| GET/POST | `/week` | Renders and processes the merchant availability schedule | Session |
| GET/POST | `/capping` | Renders and processes the capacity capping configuration | Session |
| POST | `/sf` | Pushes finalised setup configuration to Salesforce and BookingTool | Session |

### Lookup / Data Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/opportunity` | Resolves Salesforce opportunity details by token/ID for the current merchant session | Session |

### Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat.txt` | Liveness probe — returns a static OK response for load balancer and EKS health checks | None |

## Request/Response Patterns

### Common headers

- Standard browser `Content-Type: text/html` for form-based pages
- `Content-Type: application/json` for the `/api/opportunity` AJAX endpoint
- Session cookie maintained across wizard steps

### Error format

> No evidence found of a standardised JSON error envelope. Error states are rendered as HTML error pages by Zend MVC exception handlers. The `/api/opportunity` endpoint is expected to return HTTP 4xx/5xx with a plain or JSON body on failure.

### Pagination

> Not applicable — no paginated endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy is in use. The service is a single-version internal application. URL paths do not include version segments.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or schema registry entry for this service.
