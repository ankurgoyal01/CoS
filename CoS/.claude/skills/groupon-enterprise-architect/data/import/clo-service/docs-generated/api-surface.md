---
service: "clo-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, soap]
auth_mechanisms: [api-key, session, oauth2]
---

# API Surface

## Overview

CLO Service exposes three distinct API surface areas: a versioned consumer/internal API (`/clo/api/v2`), card network callback endpoints (`/clo/api/v1`), a lighter internal API (`/api/v1`), and an ActiveAdmin management UI (`/admin`). The v2 consumer API is used by internal Continuum services to read user claim and enrollment state. Card network endpoints (`/clo/api/v1/visa` and `/clo/api/v1/mastercard`) receive inbound transaction callbacks from Visa and Mastercard. The `/api/v1` surface covers offer management, merchant ingestion, and card interaction flows.

## Endpoints

### Consumer / Internal API (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clo/api/v2/users/{id}/claims` | Retrieve claims for a specific user | api-key / session |
| GET/POST | `/clo/api/v2/users/{id}/card_enrollments` | Read or create card enrollments for a user | api-key / session |
| GET | `/clo/api/v2/users/{id}/statement_credits` | Retrieve statement credit records for a user | api-key / session |
| GET | `/clo/api/v2/users/{id}/rewards_network` | Read Rewards Network status for a user | api-key / session |

### Card Network Callbacks (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/clo/api/v1/visa` | Receive transaction and enrollment callbacks from Visa | Visa-signed request |
| POST | `/clo/api/v1/mastercard` | Receive transaction and enrollment callbacks from Mastercard | Mastercard-signed request |

### Offer and Merchant API (internal)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/api/v1/offers` | Read or create CLO offer records | api-key |
| GET | `/api/v1/users/claims` | Read claim records across users | api-key |
| POST | `/api/v1/merchant/ingestion` | Ingest merchant offer data | api-key |
| POST | `/api/v1/card_interaction` | Record card interaction events | api-key |

### Admin UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/admin` | ActiveAdmin management interface for operators | session (Pundit) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all JSON API requests
- `Accept: application/json` — expected by versioned API consumers
- Card network callbacks may use XML or custom content types per network specification

### Error format

> No evidence found in the architecture inventory. Standard Rails JSON error responses are expected for API endpoints.

### Pagination

> No evidence found in the architecture inventory.

## Rate Limits

> No rate limiting configured. Rate limiting is not evidenced in the architecture model.

## Versioning

The API uses URL path versioning. The primary consumer/internal API is at `/clo/api/v2/`. Card network callbacks are at `/clo/api/v1/`. The internal offer/merchant API is at `/api/v1/`. Version segments are embedded in the path prefix.

## OpenAPI / Schema References

> No evidence found. No OpenAPI spec, proto files, or GraphQL schema are present in the architecture inventory.
