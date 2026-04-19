---
service: "accounting-service"
title: "API Vendor Transaction Query"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "api-vendor-transaction-query"
flow_type: synchronous
trigger: "HTTP GET request from an internal consumer querying vendor financial data"
participants:
  - "continuumAccountingService"
  - "acctSvc_apiEndpoints"
  - "continuumAccountingMysql"
  - "continuumAccountingRedis"
architecture_ref: "components-continuum-accounting-service"
---

# API Vendor Transaction Query

## Summary

The API Vendor Transaction Query flow handles synchronous read requests from internal Groupon services and operational tooling that need to retrieve financial data for a specific vendor or merchant. The flow covers queries for contracts, invoices, transactions, statements, payments, and merchant earnings. Requests are served by the Rails API layer, which reads from `continuumAccountingMysql` with optional caching via `continuumAccountingRedis`. Responses are serialized using `rabl` templates.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service or operational tooling making an HTTP GET request
- **Frequency**: On demand, per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal Consumer | Initiates the HTTP GET request to retrieve vendor financial data | External caller |
| API Endpoints | Receives request, validates parameters, queries data store, serializes response | `acctSvc_apiEndpoints` |
| Accounting MySQL | Source of truth for all vendor financial records | `continuumAccountingMysql` |
| Accounting Redis | Optional cache for frequently queried reference data | `continuumAccountingRedis` |

## Steps

1. **Receives HTTP GET request**: API Endpoints (`acctSvc_apiEndpoints`) receives the request on one of the vendor query paths
   - From: Internal consumer
   - To: `acctSvc_apiEndpoints`
   - Protocol: REST / HTTP

2. **Validates request parameters**: Rails controller validates the vendor or merchant ID path parameter and any filter query parameters (date range, status, pagination)
   - From: `acctSvc_apiEndpoints`
   - To: `acctSvc_apiEndpoints` (internal validation)
   - Protocol: Direct

3. **Checks application cache** (optional): For frequently queried reference data, checks `continuumAccountingRedis` for a cached response before querying MySQL
   - From: `acctSvc_apiEndpoints`
   - To: `continuumAccountingRedis`
   - Protocol: Redis

4. **Queries accounting database**: ActiveRecord queries `continuumAccountingMysql` for the requested entity (contracts, invoices, transactions, statements, or payments) scoped to the vendor or merchant ID
   - From: `acctSvc_apiEndpoints`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

5. **Serializes response**: `rabl` template serializes the ActiveRecord result set to JSON
   - From: `acctSvc_apiEndpoints`
   - To: `acctSvc_apiEndpoints` (internal serialization)
   - Protocol: Direct

6. **Returns HTTP response**: Serialized JSON response returned to the internal consumer with appropriate HTTP status
   - From: `acctSvc_apiEndpoints`
   - To: Internal consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Vendor/merchant ID not found | ActiveRecord returns empty result or raises RecordNotFound | HTTP 404 returned to consumer |
| Invalid query parameters | Rails parameter validation raises error | HTTP 400 or 422 returned with error description |
| MySQL unavailable | ActiveRecord raises connection error | HTTP 500 returned; `/api/v3/health` reflects database unavailability |
| Cache miss | Query falls through to MySQL; cache populated on result | Slightly higher latency; transparent to consumer |
| Unauthorized request | Auth middleware rejects request | HTTP 401 or 403 returned |

## Sequence Diagram

```
Internal Consumer -> acctSvc_apiEndpoints: GET /api/v3/vendors/{id}/transactions
acctSvc_apiEndpoints -> continuumAccountingRedis: Check cache (optional)
continuumAccountingRedis --> acctSvc_apiEndpoints: Cache miss
acctSvc_apiEndpoints -> continuumAccountingMysql: SELECT transactions WHERE vendor_id = {id}
continuumAccountingMysql --> acctSvc_apiEndpoints: Transaction records
acctSvc_apiEndpoints -> acctSvc_apiEndpoints: Serialize via rabl template
acctSvc_apiEndpoints --> Internal Consumer: 200 OK { transactions: [...] }
```

> The same pattern applies for contracts (`GET /api/v3/vendors/{id}/contracts`), invoices (`GET /api/v3/vendors/{id}/invoices`), statements (`GET /api/v3/vendors/{id}/statements`), payments (`GET /api/v3/vendors/{id}/payments`), and merchant earnings (`GET /api/v2/merchants/{id}/earnings`).

## Related

- Architecture dynamic view: not yet defined — see `components-continuum-accounting-service`
- Related flows: [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md)
- See [API Surface](../api-surface.md) for full endpoint reference
- See [Data Stores](../data-stores.md) for MySQL entity and access pattern details
