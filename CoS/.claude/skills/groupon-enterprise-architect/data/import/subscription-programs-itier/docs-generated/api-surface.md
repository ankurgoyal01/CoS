---
service: "subscription-programs-itier"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, cookie]
---

# API Surface

## Overview

subscription-programs-itier exposes an HTTP interface consumed by browser clients and Groupon mobile app webviews navigating the Groupon Select subscription enrollment and membership management experience. The API serves full-page HTML responses for navigation steps, handles a form POST for subscription enrollment, and provides a JSON polling endpoint for enrollment status checks.

## Endpoints

### Landing and Offer Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/programs/select` | Renders the Groupon Select subscription landing page | Required (itier-user-auth) |
| GET | `/programs/select/purchg1` | Renders Select purchase variant 1 offer page | Required (itier-user-auth) |
| GET | `/programs/select/purchgg` | Renders Select purchase variant 2 offer page | Required (itier-user-auth) |
| GET | `/programs/select/purchge` | Renders Select purchase variant 3 offer page | Required (itier-user-auth) |

### Membership Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/programs/select/benefits` | Renders the Select member benefits page for current members | Required (itier-user-auth) |
| POST | `/programs/select/subscribe` | Initiates a Groupon Select subscription enrollment | Required (itier-user-auth) |
| GET | `/programs/select/subscribe/addcard` | Renders the add-payment-card step of the enrollment flow | Required (itier-user-auth) |
| GET | `/programs/select/confirmation` | Renders the post-enrollment success confirmation page | Required (itier-user-auth) |
| GET | `/programs/select/poll` | Polls and returns current enrollment/membership status as JSON | Required (itier-user-auth) |

## Request/Response Patterns

### Common headers
- `Accept-Language` — used by `itier-divisions` to determine locale/division
- `X-Forwarded-For` / `X-Real-IP` — used for geo-resolution via GeoDetails API
- Standard session cookies managed by `itier-user-auth`
- `User-Agent` — used to detect webview context for embedded mobile flow

### Error format
> No evidence found in codebase. I-Tier framework typically returns HTTP status codes with HTML error pages for browser-facing routes and JSON error objects for AJAX/polling routes.

### Pagination
> Not applicable. The enrollment flow is a sequential step-by-step process; there is no paginated data endpoint beyond `/programs/select/poll`.

## Rate Limits

> No rate limiting configured.

## Versioning

No explicit API versioning. All routes are under the `/programs/select` path prefix with no version segment. The service is consumed directly by browser navigation, AJAX polling, and mobile webview.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema detected in the service inventory.
