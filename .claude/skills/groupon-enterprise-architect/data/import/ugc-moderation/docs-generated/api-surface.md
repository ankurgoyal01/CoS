---
service: "ugc-moderation"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [okta-username-allowlist, csrf-token]
---

# API Surface

## Overview

UGC Moderation exposes both HTML page routes (browser navigation) and JSON API endpoints (AJAX actions from the UI). All routes are served by a single Node.js/Express process on port 8000. Access to write/destructive endpoints is enforced by the Okta User Middleware, which validates the `x-grpn-username` header against a configured allowlist. There is no public-facing API — this service is exclusively for internal Groupon staff.

## Endpoints

### Page Routes (HTML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the merchant places / tips home page | Okta admin (restricted route + POST/DELETE verbs) |
| GET | `/reported` | Renders the reported (flagged) tips page with last 30 days of data | Okta admin |
| GET | `/user_images` | Renders the user images moderation page | Okta image admin |
| GET | `/user_videos` | Renders the user videos moderation page | Okta image admin |
| GET | `/review_ratings` | Renders the review ratings moderation page | Okta admin |
| GET | `/ugc_lookup` | Renders the merchant UGC lookup page | Okta admin |
| GET | `/merchant_transfer` | Renders the merchant transfer workflow page | Okta admin |

### Tips API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/tips/search` | Searches tips by query parameters | Okta admin (restricted) |
| POST | `/tips/delete` | Deletes a single tip by ID | Okta admin (restricted POST) |
| POST | `/tips/delete-all` | Deletes all tips matching criteria | Okta admin (restricted POST) |
| GET | `/get-name` | Resolves a place name by query | Okta admin |

### Reported Tips API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reported/search` | Searches flagged tips by date range and offset | Okta admin (restricted) |

### Images API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/user_images/search` | Searches user images by merchantId, dealId, userId, status, date range | Okta image admin |
| POST | `/user_images/report` | Rejects an image with a reason code (action: reject) | Okta image admin (restricted POST) |
| POST | `/user_images/accept` | Approves an image (action: approve) | Okta image admin (restricted POST) |
| POST | `/user_images/updateUrl` | Updates the URL of a user image | Okta image admin (restricted POST) |

### Videos API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/user_videos/reject` | Rejects a user video | Okta image admin (restricted POST) |
| POST | `/user_videos/accept` | Accepts a user video | Okta image admin (restricted POST) |

### Ratings API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/review_ratings/update` | Updates a review rating score, reason, and case metadata | Okta admin |

### UGC Lookup API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ugc_lookup/search` | Searches UGC data for a merchant by query | Okta admin |
| POST | `/ugc_lookup/contentOptOut` | Creates a content opt-out for a merchant entity | Okta admin (restricted POST) |

### Merchant Transfer API (JSON)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant_transfer/search` | Looks up and compares UGC data for old and new merchant UUIDs | Okta admin |
| POST | `/merchant_transfer` | Executes UGC transfer from old merchant to new merchant | Okta admin |

## Request/Response Patterns

### Common headers

- `x-grpn-username`: Injected by the Hybrid Boundary / proxy layer; used by Okta User Middleware for authorization. In non-production environments, this header is not enforced.
- `Content-Type: application/json` for JSON POST bodies.
- CSRF token required for all state-mutating POST requests (enforced by `csurf` middleware).

### Error format

JSON error responses follow the pattern:

```json
{ "result": "error", "code": "<error-code>" }
```

Specific codes observed in source: `unable-to-remove`, `unable-to-load`, `unable-to-fetch`, `unable-to-load`, `no-valid-merchant-id`.

Missing required parameters return:

```json
{ "result": "error", "code": "missing-params", "params": ["<param-name>"] }
```

### Pagination

List endpoints (`/tips/search`, `/user_images/search`, `/review_ratings`) support offset-based pagination:

- Query parameters: `offset` (integer, default 0)
- Response fields: `total`, `limit`, `items[]`, plus computed `nextOffset` and `previousOffset`
- The UI renders "Next" / "Previous" controls based on `showNext` and `showPrevious` flags

## Rate Limits

> No rate limiting configured. This is an internal tool with access restricted by Okta username allowlist.

## Versioning

No API versioning strategy. All routes are unversioned. The service is an internal tool not intended for external consumers.

## OpenAPI / Schema References

An OpenAPI schema path is declared in `.service.yml` as `doc/openapi.yml`, but no schema file was found in the repository inventory.
