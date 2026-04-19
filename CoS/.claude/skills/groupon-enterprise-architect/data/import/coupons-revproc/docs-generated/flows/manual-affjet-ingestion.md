---
service: "coupons-revproc"
title: "Manual AffJet Ingestion Trigger"
generated: "2026-03-03"
type: flow
flow_name: "manual-affjet-ingestion"
flow_type: synchronous
trigger: "HTTP POST by operator or internal service to trigger_affjet_ingestion or trigger_targeted_affjet_ingestion"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_apiResources"
  - "revproc_affJetIngestion"
  - "continuumCouponsRevprocDatabase"
architecture_ref: "dynamic-coupons-revproc-manual-ingestion"
---

# Manual AffJet Ingestion Trigger

## Summary

This flow allows operators or internal Groupon services to manually trigger AffJet transaction ingestion outside of the normal Quartz schedule. There are two variants: a standard trigger that uses the same default 30-day window as the scheduled jobs, and a targeted trigger that accepts explicit date ranges, affiliate network IDs, and transaction type filters. Both endpoints delegate to `AffJetAdapter.ingestTransactions`, which pages through the AffJet API and writes unprocessed transactions to MySQL for subsequent processing.

## Trigger

- **Type**: api-call
- **Source**: Operator curl or internal service calling the HTTP API with a valid `client_id`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (operator / internal service) | Initiates the ingestion request | External |
| HTTP Resources (`revproc_apiResources`) | Receives the POST request, validates auth, delegates to ingestion | `revproc_apiResources` |
| AffJet Adapter (`revproc_affJetIngestion`) | Executes the ingestion against the AffJet API | `revproc_affJetIngestion` |
| AffJet API | External source of affiliate transaction data | External |
| MySQL | Receives written unprocessed transactions | `continuumCouponsRevprocDatabase` |

## Steps

### Variant A: Standard Trigger (`POST /unprocessed_transactions/trigger_affjet_ingestion`)

1. **Receive POST request**: The JAX-RS resource receives the request. Auth is validated against the MySQL `client_ids` / `client_id_roles` tables. Required query parameter: `countryCode`.
   - From: Caller
   - To: `revproc_apiResources`
   - Protocol: HTTPS (REST)

2. **Delegate to AffJetAdapter.process()**: The resource calls `AffJetAdapter.process()`, which builds the default date range (2 days ago to 30 days ago) and iterates over dates.
   - From: `revproc_apiResources`
   - To: `revproc_affJetIngestion`
   - Protocol: Direct

3. **Page AffJet API and ingest**: Same paging and ingestion steps as [AffJet Scheduled Ingestion](affjet-scheduled-ingestion.md) steps 4–6.
   - From: `revproc_affJetIngestion`
   - To: AffJet API
   - Protocol: HTTPS

4. **Write unprocessed transactions**: `AffJetIngestionService.ingest` writes raw transactions to MySQL.
   - From: `revproc_affJetIngestion`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

5. **Return response**: The endpoint returns HTTP 200 on success (empty response body per Swagger schema).
   - From: `revproc_apiResources`
   - To: Caller
   - Protocol: HTTPS

### Variant B: Targeted Trigger (`POST /unprocessed_transactions/trigger_targeted_affjet_ingestion`)

1. **Receive POST request**: The JAX-RS resource receives the request with optional parameters: `lastUpdateFrom`, `lastUpdateTo`, `dateFrom`, `dateTo`, `uniqueId`, `affiliateNetworkId`, `type`, and required `countryCode`.
   - From: Caller
   - To: `revproc_apiResources`
   - Protocol: HTTPS (REST)

2. **Build custom AffJetRequest**: `AffJetAdapter.ingestAffJetTransactions` constructs an `AffJetRequest` from the supplied parameters and calls `ingestTransactions`.
   - From: `revproc_apiResources`
   - To: `revproc_affJetIngestion`
   - Protocol: Direct

3. **Page AffJet API with filters**: Same paging loop, but constrained to the supplied date range and optionally filtered by `affiliateNetworkId` and `type`.
   - From: `revproc_affJetIngestion`
   - To: AffJet API
   - Protocol: HTTPS

4. **Write unprocessed transactions**: Same as variant A step 4.
   - From: `revproc_affJetIngestion`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

5. **Return response**: The endpoint returns HTTP 200 with a plain-text body (per Swagger schema `text/plain`).
   - From: `revproc_apiResources`
   - To: Caller
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid / missing `client_id` | Auth rejected by JTier auth bundle | HTTP 401/403 returned to caller |
| Missing required `countryCode` | JAX-RS validation failure | HTTP 400 returned |
| AffJet API error during ingestion | Logged; partial ingestion may have occurred | HTTP 200 still returned if the endpoint itself doesn't propagate the exception |
| MySQL write error | Exception propagates; logged | Partial data may be written |

## Sequence Diagram

```
Caller -> HTTP Resource: POST /unprocessed_transactions/trigger_affjet_ingestion?countryCode=US HTTPS
HTTP Resource -> MySQL: validateClientId JDBC
MySQL --> HTTP Resource: authorized
HTTP Resource -> AffJetAdapter: process() or ingestAffJetTransactions(...)
AffJetAdapter -> AffJetAPI: GET transactions (paged) HTTPS
AffJetAPI --> AffJetAdapter: List<AffJetTransaction>
AffJetAdapter -> AffJetIngestionService: ingest(transactions, countryCode)
AffJetIngestionService -> MySQL: INSERT unprocessed_transactions JDBC
AffJetAdapter --> HTTP Resource: done
HTTP Resource --> Caller: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-manual-ingestion`
- Related flows: [AffJet Scheduled Ingestion](affjet-scheduled-ingestion.md), [Transaction Processing and Finalization](transaction-processing-finalization.md)
