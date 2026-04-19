---
service: "merchant-booking-tool"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, oauth2]
---

# API Surface

## Overview

The Merchant Booking Tool exposes an I-tier web application API surface over HTTPS. It serves server-rendered merchant booking pages and provides passthrough proxy endpoints to the upstream booking service. Routes are defined via OpenAPI within the I-tier framework. The primary consumers are merchant browser clients (web and mobile web). Two categories of endpoints exist: page-rendering routes that produce Preact-rendered HTML, and proxy endpoints that forward JSON API requests to the `continuumUniversalMerchantApi`.

## Endpoints

### Reservation and Booking Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reservations/mbt/*` | Serves merchant booking tool web pages (reservation management, calendars, accounts, campaigns, workshops, staff profiles) | Session |

### Proxy Passthrough

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/reservations/mbt/proxy/*` | Forwards API requests to the upstream booking service with request/response normalization | Session |

### Support Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | Support auth bootstrap endpoint (Inbenta) | Builds and returns Inbenta support authentication tokens for embedded support flows | Session |

> Specific sub-paths and full OpenAPI route definitions are defined within the I-tier route configuration. The architecture DSL confirms the proxy pattern under `/reservations/mbt/proxy/*` and the booking domain scope covering reservations, calendars, accounts, campaigns, workshops, and staff profiles.

## Request/Response Patterns

### Common headers

- Standard I-tier session headers for merchant authentication
- `Content-Type: application/json` for proxy API calls
- `Accept: application/json` for upstream booking service requests

### Error format

> No evidence found in codebase. Error format follows I-tier platform conventions.

### Pagination

> No evidence found in codebase. Pagination behavior delegated to upstream `continuumUniversalMerchantApi` responses passed through the proxy.

## Rate Limits

> No rate limiting configured at the Merchant Booking Tool layer. Rate limiting, if applied, is enforced by the upstream `continuumUniversalMerchantApi`.

## Versioning

The service does not expose a versioned API surface of its own. The I-tier application serves pages under a consistent path namespace (`/reservations/mbt/`). Versioning of booking data APIs is managed by the upstream `continuumUniversalMerchantApi`.

## OpenAPI / Schema References

> No evidence found in codebase. The I-tier framework uses OpenAPI route definitions internally. Refer to the service repository's route configuration files for the full route schema.
