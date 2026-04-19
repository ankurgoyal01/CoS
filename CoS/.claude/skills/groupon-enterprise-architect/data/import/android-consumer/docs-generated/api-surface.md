---
service: "android-consumer"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, oidc]
---

# API Surface

## Overview

The Android Consumer App is a pure API consumer — it does not expose its own network-facing API. It calls Groupon backend services via `apiProxy` using Retrofit over HTTPS. All requests are authenticated via OAuth 2.0 / OpenID Connect tokens issued by Okta. The app targets the following API path groups across its feature modules.

## Endpoints

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/*` | Browse and retrieve deal listings | OAuth 2.0 Bearer |

### Cart

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cart/*` | Retrieve current cart state | OAuth 2.0 Bearer |
| POST | `/cart/*` | Add item to cart | OAuth 2.0 Bearer |
| PATCH | `/cart/*` | Update cart item quantity or options | OAuth 2.0 Bearer |
| DELETE | `/cart/*` | Remove item from cart | OAuth 2.0 Bearer |

### Checkout

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/checkout/*` | Initiate and submit payment | OAuth 2.0 Bearer |
| GET | `/checkout/*` | Retrieve checkout session state | OAuth 2.0 Bearer |

### Account

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/account/*` | Retrieve user profile and settings | OAuth 2.0 Bearer |
| PUT | `/account/*` | Replace user profile fields | OAuth 2.0 Bearer |
| PATCH | `/account/*` | Update partial user profile | OAuth 2.0 Bearer |
| DELETE | `/account/*` | Delete account or account data | OAuth 2.0 Bearer |

### Identity

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/identity/*` | Initiate OAuth login, token exchange | Public / OAuth 2.0 |
| GET | `/identity/*` | Retrieve identity session information | OAuth 2.0 Bearer |

### Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/search/*` | Search deals by keyword, location, or category | OAuth 2.0 Bearer |

### Collections

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/collections/*` | Retrieve user wishlists | OAuth 2.0 Bearer |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <oauth_token>` — present on all authenticated requests
- `Content-Type: application/json` — standard for POST/PATCH/PUT bodies
- OkHttp interceptors handle token attachment, retry, and timeout logic

### Error format

> No evidence found in codebase. Error format is defined by the `apiProxy` backend; the app handles HTTP error codes via Retrofit response callbacks and OkHttp interceptors.

### Pagination

> No evidence found in codebase. Pagination parameters are defined by the backend API contract.

## Rate Limits

> No rate limiting configured on the client side. Server-side rate limiting is enforced by `apiProxy`.

## Versioning

> No evidence found in codebase. API versioning strategy is owned by the `apiProxy` backend services. The app targets the API version baked into its build configuration.

## OpenAPI / Schema References

> No evidence found in codebase. OpenAPI specifications are maintained in the respective backend service repositories.
