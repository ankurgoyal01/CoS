---
service: "clo-ita"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

`clo-ita` exposes a REST HTTP API consumed by Groupon web and mobile frontend clients. All endpoints serve CLO-specific experiences: deal claiming, card enrollment, consent management, transaction summaries, and missing cash-back support. User authentication is validated via `itier-user-auth` on routes that require an authenticated session.

## Endpoints

### Claim

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / POST | `/deals/:dealId/claim` | Render or submit a single CLO deal claim for the authenticated user | Session |

### CLO Proxy

Routes prefixed `/clo/proxy/*` forward requests to the CLO Backend API via the shared `apiProxy`. The I-Tier service validates the session and routes accordingly.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/clo/proxy/claim` | Submit a single deal claim to the CLO Backend API | Session |
| POST | `/clo/proxy/bulk_claims` | Submit multiple deal claims in a single request | Session |
| POST / DELETE | `/clo/proxy/card_enrollments` | Enroll or un-enroll a card for CLO | Session |
| POST | `/clo/proxy/consent_sms` | Submit SMS consent for CLO notifications | Session |
| GET | `/clo/proxy/related_deals` | Retrieve deals related to a CLO context | Session |

### Enrollment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / POST | `/clo/enrollment/*` | Render or submit card enrollment and un-enrollment flows | Session |

### User Linked Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users/:userId/linked-deals` | Retrieve all CLO deals linked to a user's account | Session |

### Transaction Summary

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users/:userId/transaction_summary` | Retrieve CLO transaction and cashback summary for a user | Session |

### Missing Cash Back

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / POST | `/clo/missing_cash_back/*` | Render or submit a missing cash-back support request | Session |

### Static / Informational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clo/tutorial` | Serve the CLO product tutorial page | None / Session |
| GET | `/clo/consent_cards` | Serve the consent cards page | Session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — for JSON POST bodies
- Session cookie — used by `itier-user-auth` for user identity

### Error format

> No evidence found in the architecture inventory. Error format is expected to follow itier-server standard error response conventions.

### Pagination

> No evidence found in the architecture inventory for paginated endpoints.

## Rate Limits

> No rate limiting configured at the I-Tier layer. Rate limiting is expected to be enforced upstream by the API gateway or `apiProxy`.

## Versioning

Endpoints are not versioned with a URL path prefix. Versioning is managed by itier-server deployment conventions and the itier release process.

## OpenAPI / Schema References

> No OpenAPI spec or schema file found in the architecture inventory. See the service repository for any generated API contracts.
