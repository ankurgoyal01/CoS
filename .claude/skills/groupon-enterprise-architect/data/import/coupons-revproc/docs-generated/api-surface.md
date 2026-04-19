---
service: "coupons-revproc"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

The coupons-revproc service exposes a REST API built on Dropwizard (JAX-RS). The API has two resource groups: `transactions` (read queries for processed transactions) and `unprocessed_transactions` (manual ingestion triggers for AffJet). Authentication uses the JTier client-ID mechanism — callers must supply a valid `client_id` query parameter that is verified against the MySQL `client_ids` / `client_id_roles` tables. The primary traffic pattern is internal: the ingestion endpoints are triggered manually or by Quartz cron jobs, and the query endpoint is consumed by internal Groupon services. Normal request rate is approximately 100 RPM.

## Endpoints

### Transactions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/transactions` | Retrieve processed transactions filtered by click IDs, user IDs, date, and/or country | client-id |

### Unprocessed Transactions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/unprocessed_transactions/trigger_affjet_ingestion` | Manually trigger standard AffJet ingestion for a given country | client-id |
| POST | `/unprocessed_transactions/trigger_targeted_affjet_ingestion` | Trigger a targeted AffJet ingestion with custom date ranges, network ID, and transaction type filters | client-id |

## Request/Response Patterns

### GET /transactions — query parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `user_ids` | string | no | — | Comma-separated user IDs (PII class 3) |
| `click_ids` | string | no | — | Comma-separated click IDs |
| `since` | string (datetime) | no | — | Return transactions updated after this timestamp |
| `limit` | integer | no | 50 | Page size |
| `offset` | integer | no | 0 | Page offset |
| `country_code` | string | no | `US` | ISO country code filter |

### GET /transactions — response schema

```json
{
  "pagination": { "limit": 50, "offset": 0 },
  "processedTransactionList": [
    {
      "transactionId": "string",
      "clickId": "string",
      "userId": "string",
      "attributionId": "uuid",
      "bcookie": "string",
      "clickMessageUuid": "uuid",
      "couponUUID": "uuid",
      "dealUUID": "uuid",
      "primaryDealServiceId": "uuid",
      "adId": "string",
      "network": "string",
      "source": "string",
      "merchantSlug": "string",
      "programId": "string",
      "eventId": "string",
      "orderId": "string",
      "offerId": "integer",
      "amount": "double",
      "roundedAmount": "double",
      "totalSale": "double",
      "currencyCode": "string",
      "countryCode": "string",
      "transactionType": "string",
      "transactionFlag": "integer",
      "transactionTime": "date-time",
      "processTime": "date-time",
      "coreCouponTransaction": "boolean",
      "voucherCloudDomainId": "integer"
    }
  ]
}
```

### POST /unprocessed_transactions/trigger_affjet_ingestion — query parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `countryCode` | string | yes | ISO country code to query (e.g., `US`, `GB`) |

### POST /unprocessed_transactions/trigger_targeted_affjet_ingestion — query parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `countryCode` | string | yes | ISO country code to query |
| `lastUpdateFrom` | string (yyyyMMddHHmmss) | no | Earliest last-update timestamp |
| `lastUpdateTo` | string (yyyyMMddHHmmss) | no | Latest last-update timestamp |
| `dateFrom` | string (yyyyMMddHHmmss) | no | Earliest transaction date |
| `dateTo` | string (yyyyMMddHHmmss) | no | Latest transaction date |
| `affiliateNetworkId` | string | no | AffJet affiliate network ID |
| `uniqueId` | string | no | Specific transaction unique ID |
| `type` | string | no | Transaction type filter |

### Common headers

> No evidence found in codebase for custom required headers beyond standard HTTP content negotiation. Responses are `application/json`.

### Error format

> No evidence found in codebase for a custom error response envelope. Dropwizard defaults apply (standard HTTP status codes with JSON body).

### Pagination

The `GET /transactions` response includes a `pagination` object with `limit` (default 50) and `offset` (default 0) fields. Callers advance pages by incrementing `offset`.

## Rate Limits

> No rate limiting configured. The service targets ~100 RPM for transaction submission per the SLA documentation.

## Versioning

No URL versioning scheme is in use. The API version is tracked via the Maven artifact version (`1.36.x`) exposed in the Swagger info block but not in URL paths.

## OpenAPI / Schema References

- Swagger YAML: `doc/swagger/swagger.yaml`
- Swagger JSON: `doc/swagger/swagger.json`
- Service discovery descriptor: `doc/service_discovery/resources.json`
- Swagger UI (local): `http://localhost:9000/swagger/?url=http://localhost:9000/swagger.json`
