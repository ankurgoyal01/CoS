---
service: "voucher-archive-backend"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [bearer-token, session-token]
---

# API Surface

## Overview

The voucher-archive-backend exposes a versioned REST API under the `/ls-voucher-archive/api/v1/` path prefix. The API serves four distinct caller audiences — consumers, merchants, CSRs, and deal/checkout clients — each with separate route namespaces. All endpoints require caller authentication via token validation delegated to upstream auth services.

## Endpoints

### Consumer Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/consumers/:id/vouchers` | List vouchers owned by a consumer | Consumer bearer token |
| GET | `/ls-voucher-archive/api/v1/consumers/:id/vouchers/:voucher_id` | Retrieve a single voucher for a consumer | Consumer bearer token |

### Voucher Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/vouchers/:id` | Retrieve voucher details | Bearer token |
| GET | `/ls-voucher-archive/api/v1/vouchers/:id/pdf` | Generate and return PDF for a voucher | Bearer token |
| GET | `/ls-voucher-archive/api/v1/vouchers/:id/qr_code` | Generate and return QR code for a voucher | Bearer token |
| PUT | `/ls-voucher-archive/api/v1/vouchers/:id/redeem` | Mark a voucher as redeemed | Merchant token |
| PUT | `/ls-voucher-archive/api/v1/vouchers/:id/refund` | Initiate a refund on a voucher | CSR token |

### Merchant Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/merchants/:id/vouchers` | List vouchers redeemable at a merchant | Merchant token |
| POST | `/ls-voucher-archive/api/v1/merchants/:id/vouchers/bulk_redeem` | Batch redeem multiple vouchers | Merchant token |

### CSR Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/csrs/vouchers/:id` | Retrieve voucher details for a CSR | CSR session token |
| POST | `/ls-voucher-archive/api/v1/csrs/vouchers/:id/refund` | Process a refund for a voucher | CSR session token |
| GET | `/ls-voucher-archive/api/v1/csrs/consumers/:id/vouchers` | List all vouchers for a consumer | CSR session token |

### Deal Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/deals/:id` | Retrieve deal with options and images | Bearer token |
| GET | `/ls-voucher-archive/api/v1/deals/:id/redemption_instructions` | Retrieve redemption instructions for a deal | Bearer token |

### Checkout Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/api/v1/checkout/:id` | Retrieve checkout/order details | Bearer token |

### Health Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ls-voucher-archive/health` | Liveness check | None |
| GET | `/ls-voucher-archive/health/db` | Database connectivity check | None |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <token>` — required on all authenticated endpoints
- `Content-Type: application/json` — required for POST/PUT requests
- `Accept: application/json` — expected on all endpoints except `/pdf` and `/qr_code`

### Error format

> No evidence found in codebase. Standard Rails JSON error responses are expected (`{ "error": "message" }`).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning. All endpoints are prefixed with `/ls-voucher-archive/api/v1/`, indicating a single active version (v1). No multi-version routing evidence found.

## OpenAPI / Schema References

> No evidence found in codebase.
