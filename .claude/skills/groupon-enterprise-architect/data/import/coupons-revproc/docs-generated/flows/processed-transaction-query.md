---
service: "coupons-revproc"
title: "Processed Transaction Query"
generated: "2026-03-03"
type: flow
flow_name: "processed-transaction-query"
flow_type: synchronous
trigger: "HTTP GET by internal Groupon services querying processed transaction data"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_apiResources"
  - "revproc_transactionDao"
  - "continuumCouponsRevprocDatabase"
architecture_ref: "dynamic-coupons-revproc-transaction-query"
---

# Processed Transaction Query

## Summary

The Processed Transaction Query flow is the primary read path for coupons-revproc. Internal Groupon services (attribution, finance, and reporting consumers) call `GET /transactions` to retrieve processed transaction records filtered by click IDs, user IDs, country code, and date. The endpoint is authenticated via the JTier client-ID mechanism. Results are paginated using `limit` (default 50) and `offset` (default 0) parameters, and the response includes a `pagination` envelope alongside a `processedTransactionList` array.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service or operator with a valid `client_id`
- **Frequency**: On-demand; up to ~100 RPM at steady state

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal consumer | Sends GET request with filter parameters and client_id | External |
| HTTP Resources (`revproc_apiResources`) | Validates auth, parses query params, delegates to DAO | `revproc_apiResources` |
| Transaction DAOs (`revproc_transactionDao`) | Executes parameterized JDBI3 query against MySQL | `revproc_transactionDao` |
| MySQL | Stores and serves processed transaction records | `continuumCouponsRevprocDatabase` |

## Steps

1. **Receive GET request**: The JAX-RS `GET /transactions` resource handler receives the request. Auth is validated against MySQL `client_ids` / `client_id_roles` via the JTier auth bundle.
   - From: Internal consumer
   - To: `revproc_apiResources`
   - Protocol: HTTPS (REST)

2. **Parse query parameters**: The handler extracts `user_ids`, `click_ids`, `since`, `limit` (default 50), `offset` (default 0), and `country_code` (default `"US"`) from the query string.
   - From: `revproc_apiResources`
   - To: Internal
   - Protocol: Direct

3. **Query processed transactions**: `ProcessedTransactionDAO` executes a parameterized JDBI3 SELECT against `processed_transactions`, applying the supplied filters. At least one of `user_ids` or `click_ids` is typically provided; `since` and `country_code` further constrain the result set. Pagination is applied via SQL LIMIT and OFFSET.
   - From: `revproc_transactionDao`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

4. **Build response**: The result set is mapped to a list of `ProcessedTransaction` model objects and wrapped in a `ProcessedTransactionResults` envelope containing the `pagination` object.
   - From: `revproc_apiResources`
   - To: Internal
   - Protocol: Direct

5. **Return HTTP 200 with JSON body**: The JAX-RS resource serializes the response to JSON (`application/json`) and returns HTTP 200.
   - From: `revproc_apiResources`
   - To: Internal consumer
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid / missing `client_id` | JTier auth bundle rejects the request | HTTP 401 / 403 returned |
| MySQL query failure | JDBI3 exception propagates | HTTP 500 with Dropwizard error body |
| No matching transactions | Empty `processedTransactionList` returned | HTTP 200 with empty list and pagination |

## Sequence Diagram

```
InternalConsumer -> HTTP Resource: GET /transactions?click_ids=X&country_code=US&limit=50 HTTPS
HTTP Resource -> MySQL: validateClientId JDBC
MySQL --> HTTP Resource: authorized
HTTP Resource -> ProcessedTransactionDAO: findByFilters(clickIds, userIds, since, countryCode, limit, offset) JDBI3
ProcessedTransactionDAO -> MySQL: SELECT * FROM processed_transactions WHERE ... LIMIT 50 OFFSET 0
MySQL --> ProcessedTransactionDAO: ResultSet
ProcessedTransactionDAO --> HTTP Resource: List<ProcessedTransaction>
HTTP Resource --> InternalConsumer: HTTP 200 application/json { pagination, processedTransactionList }
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-transaction-query`
- Related flows: [Transaction Processing and Finalization](transaction-processing-finalization.md)
- API reference: [API Surface](../api-surface.md)
