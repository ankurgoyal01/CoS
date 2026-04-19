---
service: "user_sessions"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session-cookie, oauth2]
---

# API Surface

## Overview

user_sessions exposes a small set of browser-facing HTTP endpoints that render authentication pages and accept form submissions. All endpoints produce server-rendered HTML responses for GET requests and perform redirect responses after POST processing. The API is not a JSON/REST API for machine consumption — it is an I-Tier page service for web browsers. Session state is communicated via HTTP cookies set on successful authentication.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/login` | Render the login page | None (public) |
| POST | `/login` | Accept email/password credentials; validate via GAPI; set session cookie; redirect | None (public) |
| GET | `/signup` | Render the registration page | None (public) |
| POST | `/signup` | Accept registration form; create account via GAPI; set session cookie; redirect | None (public) |

### Password Reset

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users/password_reset/:token` | Render password reset form for a given reset token | None (public) |
| GET | `/passwordreset/:token` | Alternate password reset route (legacy path alias) | None (public) |
| GET | `/users/reset_password/:userId/:token` | Render password reset form using userId and token parameters | None (public) |

## Request/Response Patterns

### Common headers

- `Cookie` — carries the session cookie for authenticated requests
- `Content-Type: application/x-www-form-urlencoded` — used for login and signup POST submissions
- `Set-Cookie` — returned on successful authentication to establish the session

### Error format

Errors are communicated via server-rendered HTML pages. Form validation errors are rendered inline on the respective page (login, signup, password reset). Upstream GAPI errors result in re-rendered forms with appropriate user-facing error messaging.

### Pagination

> Not applicable — this service renders single-page HTML responses; there are no paginated resources.

## Rate Limits

> No evidence found in codebase. Rate limiting is expected to be enforced at the load balancer or Akamai CDN layer upstream of this service.

## Versioning

No API versioning is used. This is a browser-facing page service; URL paths are stable and do not carry version prefixes. The `/users/reset_password/:userId/:token` and `/passwordreset/:token` paths exist as legacy aliases alongside the canonical `/users/password_reset/:token` path.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto file, or GraphQL schema is published by this service.
