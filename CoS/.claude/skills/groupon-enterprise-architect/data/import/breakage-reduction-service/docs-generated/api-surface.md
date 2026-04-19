---
service: "breakage-reduction-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [mtls, session, api-key]
---

# API Surface

## Overview

BRS exposes a REST HTTP API under the I-Tier framework. Consumers call endpoints to retrieve voucher next-actions, schedule/retrieve reminders, and fetch push/in-app message content. All endpoints produce `text/html` (server-rendered) except `/voucher/v1/next_actions` which consumes `application/json`. The service is fronted by Groupon's Hybrid Boundary (HB) proxy, which handles mTLS termination. Two URL prefix variants exist for most routes: a prefixed `/brs/v1/...` form and an unprefixed legacy form.

## Endpoints

### Voucher Next Actions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/voucher/v1/next_actions` | Compute and return the list of applicable next-actions for a given voucher | mTLS (internal) |

### Remind Me Later

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/remind_me_later/v1/users/{user_id}/send_reminder` | Retrieve reminder scheduling status for a user/voucher | mTLS / session |
| POST | `/remind_me_later/v1/users/{user_id}/send_reminder` | Schedule a reminder for a user/voucher at a given time | mTLS / session |
| GET | `/remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders` | List reminders for a specific user voucher | mTLS / session |
| POST | `/remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders` | Create a reminder for a specific user voucher | mTLS / session |
| GET | `/brs/v1/remind_me_later/v1/users/{user_id}/send_reminder` | Prefixed variant — retrieve reminder status | mTLS / session |
| POST | `/brs/v1/remind_me_later/v1/users/{user_id}/send_reminder` | Prefixed variant — schedule reminder | mTLS / session |
| GET | `/brs/v1/remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders` | Prefixed variant — list reminders | mTLS / session |
| POST | `/brs/v1/remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders` | Prefixed variant — create reminder | mTLS / session |

### Message Content

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/message/v1/content` | Render campaign message content for push or in-app notification | mTLS (internal) |
| GET | `/brs/v1/message/v1/content` | Prefixed variant — render campaign message content | mTLS (internal) |

### Health / Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `:8000/status` | Service health check endpoint (I-Tier default) | none |

## Request/Response Patterns

### Common headers

- `x-brand` — brand identifier (used by message content endpoint)
- `x-country` — country code driving localization and eligibility rules
- Standard I-Tier session cookie headers for authenticated consumer requests

### Error format

Standard I-Tier error page response for HTML routes. For internal JSON endpoints, errors propagate via HTTP status codes with JSON error bodies from the I-Tier error middleware (`common/error/middleware.js`).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured. Traffic shaping is managed at the Hybrid Boundary / Routing Service layer.

## Versioning

URL path versioning is used: `/v1/` is embedded in each path segment. The `/brs/v1/` prefix duplicates routes for routing compatibility. No header- or query-param-based versioning is used.

## OpenAPI / Schema References

- OpenAPI 3.0 spec: `doc/openapi.yml`
- Swagger 2.0 schema (auto-generated from I-Tier routes): `doc/schema.yml`
