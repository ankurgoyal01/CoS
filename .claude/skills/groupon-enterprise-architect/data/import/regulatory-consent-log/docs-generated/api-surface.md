---
service: "regulatory-consent-log"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, jwt]
---

# API Surface

## Overview

The Regulatory Consent Log exposes a REST API over HTTP/JSON. Consumers use it to record user consents, retrieve existing consent records, look up erased-user cookie mappings, initiate account erasure, check erasure status, and handle Transcend privacy webhook callbacks. All endpoints are secured by an API key passed in the `X-API-KEY` header. The Transcend webhook endpoint additionally validates a JWT signature.

The OpenAPI 2.0 specification is located at `docs/openapi.yml` in the repository.

## Endpoints

### Consents

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/consents` | Record one or more user consent log entries | `X-API-KEY` |
| `GET` | `/v1/consents` | Retrieve consent records for a given `identifierValue`, optionally filtered by `workflowType` | `X-API-KEY` |

### Cookie Lookup

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/cookie` | Return erased-user info for a given b-cookie UUID; returns 204 if cookie belongs to no erased user | `X-API-KEY` |

### User Erasure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/erasure` | Initiate account erasure for a given user UUID | `X-API-KEY` |
| `GET` | `/v1/users/{user_id}/erasureStatus` | Return current erasure status and days remaining for a user | `X-API-KEY` |

### Transcend Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | (Transcend webhook path) | Receive and process Transcend access/erasure event notifications | JWT (verified by `Transcend Users Event Service`) |

## Request/Response Patterns

### Common headers

| Header | Required | Description |
|--------|----------|-------------|
| `X-API-KEY` | Yes (all endpoints) | API key for service authentication |
| `X-Country-Code` | Yes (`POST /v1/consents`) | ISO country code where consent was captured |
| `X-Locale` | Yes (`POST /v1/consents`) | Locale string (e.g. `en_US`) |
| `X-Remote-User-Agent` | No (`POST /v1/consents`) | User-agent string of the originating client |
| `X-Client-Roles` | No (`POST /v1/consents`) | Role context (e.g. `web`, `mobile`) |

### POST /v1/consents — key body fields

| Field | Type | Required | Values / Notes |
|-------|------|----------|---------------|
| `legalConsents` | array | Yes | Array of `CreateConsentItem` objects |
| `identifierType` | enum | Yes | `user_id`, `b_cookie`, `device_id` |
| `identifierValue` | string | Yes | UUID of the user identifier |
| `workflowType` | enum | Yes | `registration`, `checkout`, `email_subscription`, `billing_record`, `cookies`, `user_delete`, `order_update`, `start_tradein`, `groupon_redeem`, `order_return`, `dnsmi`, `vas`, `social_submodal` |
| `eventType` | enum | Yes | `accept`, `revoke`, `forget`, `true`, `false` |
| `logType` | enum | Yes | `consent`, `notice` |
| `termsType` | enum | No | `privacy_policy`, `terms_of_service`, `email_subscription_disclosure`, `terms_of_sale`, `billing_record_disclosure`, `cookie_policy`, `doNotSell` |
| `termsTypeVersion` | string | No | Version of the terms document |
| `workflowTypeOrigin` | enum | No | `subcenter`, `cyclops`, `submodal`, `user_registration`, `display_marketing`, `backfill`, `user_merge`, `coupons`, `beautynow`, `legacy_app`, `dnsmi_modal`, `pizza`, `social_submodal`, `checkout` |
| `metadata` | object | No | Key/value pairs; allowed keys: `billingRecordId`, `parentOrderId` |

### Query parameters

| Parameter | Endpoint | Type | Required | Description |
|-----------|----------|------|----------|-------------|
| `identifierValue` | `GET /v1/consents` | string | Yes | User identifier (user_id or b_cookie value) |
| `workflowType` | `GET /v1/consents` | string | No | Filter results by workflow type |
| `isConsumerId` | `POST /v1/consents`, `GET /v1/consents` | boolean | No | When true, allows `user_id` identifier type |
| `b_cookie` | `GET /v1/cookie` | string | Yes | B-cookie UUID to look up |
| `user_id` | `GET /v1/users/{user_id}/erasureStatus` | string (path) | Yes | User UUID |

### Error format

All error responses follow the standard shape:

```json
{
  "code": 400,
  "message": "Bad Request"
}
```

HTTP status codes used: `200`, `204`, `400`, `401`, `404`, `500`.

### Pagination

> No evidence found in codebase. The `GET /v1/consents` endpoint returns all matching records without pagination.

## Rate Limits

> No rate limiting configured. SLA targets from runbook: `POST /v1/consents` — 1,000 RPM, p99 50ms; `GET /v1/cookie` — 15,000 RPM in US datacenters, 10,000 RPM in EMEA, p99 10ms.

## Versioning

All endpoints are versioned under the `/v1/` path prefix. The OpenAPI spec version is `0.1.0`.

## OpenAPI / Schema References

- OpenAPI 2.0 specification: `docs/openapi.yml`
- Generated server SDK: `com.groupon.api:regconsentlog-server:1.4` (from `regulatory-consent-log-sdk` repository)
- Generated client SDK: `com.groupon.api:regconsentlog-client:1.4` (test scope)
