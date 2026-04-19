---
service: "mx-reservations-app"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, token]
---

# API Surface

## Overview

MX Reservations App exposes SPA-served routes to merchant browsers and proxies backend data requests through `/reservations/api/v2/*` to the API Proxy. All routes are merchant-authenticated via itier-user-auth session handling. The app itself does not publish a standalone API for third-party consumption; its API surface is the set of browser-accessible SPA routes plus the backend proxy path.

## Endpoints

### SPA Application Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reservations` | Root SPA entrypoint; renders merchant reservations dashboard | itier session |
| GET | `/reservations/booking` | Booking workflow SPA route | itier session |
| GET | `/reservations/calendar` | Calendar management SPA route | itier session |
| GET | `/reservations/workshops` | Workshop scheduling SPA route | itier session |
| GET | `/reservations/redemption` | Redemption and check-in SPA route | itier session |

### Backend API Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/reservations/api/v2/*` | Proxied requests to API Proxy for all reservation data operations | itier session + token |

## Request/Response Patterns

### Common headers

- `Cookie` / `Authorization`: itier-user-auth session token passed on all proxied API requests
- `Content-Type: application/json`: used for all JSON API requests
- `Accept: application/json`: expected response format for API proxy calls

### Error format

> No evidence found in the architecture inventory for a specific error schema. Errors from the API Proxy are passed through to the browser client. The SPA renders error states based on HTTP status codes returned from `/reservations/api/v2/*`.

### Pagination

> No evidence found in the architecture inventory for a specific pagination scheme. Pagination behavior is determined by the downstream API Proxy and Marketing Deal Service responses.

## Rate Limits

> No rate limiting configured at the MX Reservations App layer. Rate limiting, if any, is enforced by the API Proxy downstream.

## Versioning

API proxy calls use URL path versioning: all backend requests are routed through `/reservations/api/v2/*`. The SPA application routes are unversioned.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or GraphQL schema in the repository inventory. Backend API contracts are owned by the API Proxy and Marketing Deal Service.
