---
service: "mls-sentinel"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

MLS Sentinel exposes two categories of HTTP endpoints under a Dropwizard (JTier) server on port 8080. The `trigger` group provides operational controls: manual event replay, backfill initiation, DLQ retry, CLO transaction injection, and update requests for specific entity types. The `history` group provides the Merchant History Service write API. All endpoints use POST and accept/return JSON. Authentication is enforced via the JTier Client-ID mechanism configured in `clientIdAuth`.

## Endpoints

### Trigger — Backfill and Update

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/trigger/backfillRequest/{type}` | Trigger a backfill of deal or inventory_product data within a time window, optionally filtered by inventory service IDs | Client-ID |
| `POST` | `/trigger/updateRequest/{type}` | Submit a list of UUIDs (merchant, deal, inventory_product, inventory_unit) for immediate update processing | Client-ID |
| `POST` | `/trigger/updateRequest/{type}/bulk` | Submit a structured list of update requests with optional entity discovery | Client-ID |

**Path parameter `type` values:**
- `backfillRequest`: `deal`, `inventory_product`
- `updateRequest`: `merchant`, `deal`, `inventory_product`, `inventory_unit`

**Query parameters — `backfillRequest`:**
- `earliest` (required, date-time): Start of the backfill window
- `latest` (required, date-time): End of the backfill window
- `isids` (optional, array): Inventory service IDs to filter — `candler`, `cdis`, `clo`, `coupons`, `getaways`, `glive`, `goods`, `gtg`, `legacy_getaways`, `localbook`, `mrgetaways`, `stores`, `tpis`, `vis`, `voucher`

### Trigger — CLO Transactions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/trigger/clo_auth_transaction` | Inject a CLO authorization transaction event | Client-ID |
| `POST` | `/trigger/clo_clear_transaction` | Inject a CLO clearing transaction event | Client-ID |
| `POST` | `/trigger/clo_reward_transaction` | Inject a CLO reward transaction event | Client-ID |

**Body schema (all CLO trigger endpoints):**
```json
{
  "preClaim": true
}
```

### Trigger — Voucher and Salesforce

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/trigger/voucher_sold` | Manually trigger VoucherSold processing for a list of voucher UUIDs | Client-ID |
| `POST` | `/trigger/voucher_redeemed` | Manually trigger VoucherRedeemed processing for a list of voucher UUIDs | Client-ID |
| `POST` | `/trigger/salesforce_account_update` | Manually trigger a Salesforce account update by Salesforce ID | Client-ID |
| `POST` | `/trigger/retryDLQs/{database}` | Retry failed messages from a named database's DLQ within a time window | Client-ID |

**Query parameters — `voucher_sold` / `voucher_redeemed`:**
- `inventory_service_id` (optional): Filter to a specific inventory service

**Query parameters — `salesforce_account_update`:**
- `salesforce_id` (optional): Target Salesforce account ID

**Query parameters — `retryDLQs`:**
- `earliest` (required, date-time): Retry window start
- `latest` (required, date-time): Retry window end

### History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/history` | Register a new merchant history event | Client-ID |

**Body schema — `/v1/history`:**
```json
{
  "historyId": "<uuid>",
  "merchantId": "<uuid>",
  "dealId": "<uuid>",
  "userId": "<uuid>",
  "deviceId": "<uuid>",
  "clientId": "<string>",
  "eventDate": "<date-time>",
  "eventType": "<string>",
  "eventTypeId": "<uuid>",
  "userType": "<string>",
  "historyData": {}
}
```

### Platform / Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Liveness check — returns `OK` | None |
| `GET` | `/grpn/status` | Status summary including build information | None |

Admin endpoints are available on port 8081.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for endpoints accepting a request body
- `X-Request-Id` — propagated through the entire MLS request chain for log correlation; in Sentinel this is tied to MBus message IDs

### Error format

> No standardized error response shape documented in the OpenAPI spec. JTier/Dropwizard default error responses apply (HTTP status + JSON body with `code` and `message` fields).

### Pagination

> Not applicable — all trigger endpoints are fire-and-acknowledge with no paginated response.

## Rate Limits

> No rate limiting configured.

## Versioning

The history API uses a URL path version prefix (`/v1/history`). Trigger endpoints are unversioned. The API version maps to the service version (`1.14.0-SNAPSHOT` at the time of inventory).

## OpenAPI / Schema References

- Swagger JSON: `doc/swagger/swagger.json`
- Swagger YAML: `doc/swagger/swagger.yaml`
- Swagger config: `doc/swagger/config.yml`
