---
service: "vss"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, client-id]
---

# API Surface

## Overview

VSS exposes a REST API under the `/v1` path prefix, consumed primarily by Merchant Centre. The API provides voucher search, user obfuscation (GDPR), and data backfill management endpoints. All responses return JSON. Search endpoints require a `clientId` to identify the calling consumer. The obfuscation endpoint requires an `X-API-KEY` header for authorization.

## Endpoints

### Voucher Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/vouchers/search` | Search vouchers by query string (first name, last name, Groupon code, security code, gifted email, user email) | `clientId` query param |
| `POST` | `/v1/vouchers/search` | Search vouchers using request body (same fields as GET) | `clientId` in body |

### Admin / Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/backfill/units` | Trigger backfill of voucher units for a date range or list of unit UUIDs | None (internal use) |
| `GET` | `/v1/vouchers/updateRedemptionStatus` | Update redemption status for vouchers between `startId` and `endId` | None (internal use) |

### GDPR / Compliance

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/obfuscate/users` | Obfuscate user names and email addresses for given purchaser/consumer IDs | `X-API-KEY` header (required) |

### Health / Platform

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | JTier health/status check — returns deployed version and heartbeat state | None |

## Request/Response Patterns

### Common headers

- `X-API-KEY` — Required for `POST /v1/obfuscate/users`. Validated server-side against `deleteUserSecretKey` config value.
- `x-request-id` — Forwarded on outbound calls to Users Service for tracing correlation.

### Error format

- HTTP 401 returned by `/v1/obfuscate/users` when `X-API-KEY` is missing or invalid.
- Standard JTier/Dropwizard error envelope used for all other error responses (JSON with `code` and `message` fields).

### Pagination

> No evidence found in codebase. Search results return all matching vouchers in a single response.

## Rate Limits

> No rate limiting configured at the VSS service level. Downstream limits apply at the load balancer or edge proxy.

## Versioning

All endpoints use URL path versioning under the `/v1` prefix. The current API version is `v1`; the service version is `2.0.x`.

## OpenAPI / Schema References

- OpenAPI 2.0 spec: `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`
- Service discovery resource descriptor: `doc/service_discovery/resources.json`
- Base URL (staging): `http://vss-staging.snc1`
- Base URL (production): `http://vss.snc1` / `http://vss.sac1`

## Key Query Parameters — `GET /v1/vouchers/search`

| Parameter | Required | Data Class | Description |
|-----------|----------|-----------|-------------|
| `merchantId` | yes | unclassified | Merchant ID scoping the search |
| `clientId` | yes | unclassified | Identifies the calling client application |
| `query` | yes | class2 (PII) | Free-text search string across voucher and user fields |

## Key Query Parameters — `POST /v1/backfill/units`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `startDate` | no | Start of date range for unit `updated_at` filter |
| `endDate` | no | End of date range for unit `updated_at` filter |
| `inventoryServiceId` | no | Filter by inventory source (`vis` or `voucher`); defaults to `vis` |
| Body: `units` | no | Explicit list of unit UUIDs to backfill |
