---
service: "mls-yang"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none-documented]
---

# API Surface

## Overview

mls-yang exposes a small internal REST API over HTTP (port 8080) built on Dropwizard JAX-RS. The API is an operational/internal interface used by sibling MLS services and debugging tooling — it is not a public-facing consumer API. Endpoints provide read and write access to CLO transactions, merchant accounts, merchant facts, and voucher counts that have been projected from Kafka commands into the Yang read databases.

The OpenAPI specification is available at `doc/swagger/swagger.yaml` (version 1.14.0-SNAPSHOT) and `doc/swagger/swagger.json`.

## Endpoints

### CLO Transactions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/clo_transaction` | Retrieve CLO transactions by `group_id` (optionally filtered to recent only) | None documented |
| `POST` | `/clo_transaction` | Insert a CLO transaction record | None documented |
| `GET` | `/clo_transaction/search` | Search CLO transactions by `deal_ids`, `start_date`, and `end_date` | None documented |
| `GET` | `/clo_transaction/{transaction_uuid}` | Retrieve a single CLO transaction by UUID | None documented |

### Merchant Account

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/merchant_account` | Upsert a merchant account record | None documented |
| `GET` | `/merchant_account/{merchant_uuid}` | Retrieve merchant account by UUID | None documented |

### Merchant Facts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/merchantfact` | Insert a merchant fact | None documented |
| `GET` | `/merchantfact/{merchant_id}` | Retrieve all merchant facts for a merchant UUID | None documented |

### Voucher Counts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/voucherredeemed` | Insert a voucher-redeemed count record | None documented |
| `GET` | `/voucherredeemed/{merchant_id}` | Retrieve voucher-redeemed count for a merchant | None documented |
| `POST` | `/vouchersold` | Insert a voucher-sold count record | None documented |
| `GET` | `/vouchersold/{merchant_id}` | Retrieve voucher-sold count for a merchant | None documented |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | Health/status check endpoint (port 8080) | None |
| `GET` | `/quartz` | Quartz scheduler admin endpoint | None documented |

## Request/Response Patterns

### Common headers

No custom headers documented. Standard `Content-Type: application/json` and `Accept: application/json` apply.

### Error format

> No evidence found in codebase for a documented standard error response shape beyond default Dropwizard error responses.

### Pagination

> No evidence found in codebase of pagination — all list endpoints return full result sets.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-based or header-based API versioning is implemented. The Kafka command payload types use versioned class namespaces (`v_1`, `v_2`) but the REST API itself has no explicit versioning strategy.

## OpenAPI / Schema References

- `doc/swagger/swagger.yaml` — Swagger 2.0 spec (version 1.14.0-SNAPSHOT)
- `doc/swagger/swagger.json` — JSON variant (referenced from `.service.yml`)
- Resource package: `com.groupon.mls.yang.resources`
