---
service: "accounting-service"
title: "Deal Contract Import"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-contract-import"
flow_type: asynchronous
trigger: "Salesforce contract data available or API-triggered import command"
participants:
  - "continuumAccountingService"
  - "acctSvc_apiEndpoints"
  - "acctSvc_contractImport"
  - "acctSvc_ingestion"
  - "salesForce"
  - "continuumDealCatalogService"
  - "continuumAccountingMysql"
  - "continuumAccountingRedis"
architecture_ref: "components-continuum-accounting-service"
---

# Deal Contract Import

## Summary

The Deal Contract Import flow pulls merchant contract data from Salesforce into the Accounting Service, normalizes it against deal and option metadata from the Deal Catalog Service, and persists the resulting accounting contract models to MySQL. The flow can be triggered by a scheduled import job, an API command, or a webhook notification. It is the foundation for all downstream invoicing and payment processing, as contracts define the payment terms applied when calculating merchant earnings.

## Trigger

- **Type**: api-call or schedule
- **Source**: API command via `POST /api/v3/vendors/{id}/contracts` or internal import job enqueued to `continuumAccountingRedis`
- **Frequency**: Periodic (scheduled import cadence) plus on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Endpoints | Receives import command and enqueues background job | `acctSvc_apiEndpoints` |
| Contract Import Pipeline | Executes the import logic against Salesforce and persists results | `acctSvc_contractImport` |
| Voucher/Inventory Ingestion | Resolves inventory lineage and data-source mappings during import | `acctSvc_ingestion` |
| Salesforce | Source of contract and merchant/account metadata | `salesForce` |
| Deal Catalog Service | Provides deal and option metadata for contract line item resolution | `continuumDealCatalogService` |
| Accounting MySQL | Persists normalized contract records | `continuumAccountingMysql` |
| Accounting Redis | Queues import jobs for background processing | `continuumAccountingRedis` |

## Steps

1. **Receives import command**: API endpoint (`acctSvc_apiEndpoints`) receives a contract import request via `POST /api/v3/vendors/{id}/contracts` or a scheduled trigger fires
   - From: `acctSvc_apiEndpoints` or internal scheduler
   - To: `continuumAccountingRedis`
   - Protocol: Resque job enqueue

2. **Dequeues import job**: Resque worker picks up the contract import job from `continuumAccountingRedis`
   - From: `continuumAccountingRedis`
   - To: `acctSvc_contractImport`
   - Protocol: Redis / Resque

3. **Fetches contract data from Salesforce**: Contract Import Pipeline authenticates and queries Salesforce for contract and merchant/account metadata for the target vendor
   - From: `acctSvc_contractImport`
   - To: `salesForce`
   - Protocol: REST

4. **Fetches deal and option metadata**: Contract Import Pipeline queries the Deal Catalog Service to resolve deal and option identifiers referenced in the Salesforce contract
   - From: `acctSvc_contractImport`
   - To: `continuumDealCatalogService`
   - Protocol: REST

5. **Resolves inventory lineage**: Contract Import delegates to the Ingestion component to resolve inventory product and voucher lineage for the contract's deal lines
   - From: `acctSvc_contractImport`
   - To: `acctSvc_ingestion`
   - Protocol: Direct

6. **Persists normalized contract models**: Contract Import Pipeline writes the normalized contract, payment terms, and associated line items to `continuumAccountingMysql`; Papertrail creates audit version records
   - From: `acctSvc_contractImport`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

7. **Publishes contract imported event**: Service publishes a Contract Imported event to `messageBus` to notify downstream consumers
   - From: `continuumAccountingService`
   - To: `messageBus`
   - Protocol: Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | Resque job fails; automatic retry with backoff | Job moves to failed queue after max retries; import halted until Salesforce is reachable |
| Deal Catalog Service unavailable | Resque job fails on deal lookup; retry | Deal metadata unresolved; contract import incomplete until service recovers |
| Duplicate contract import | Existing record detected via contract identifier lookup; update applied | Idempotent upsert; existing contract updated with latest Salesforce data |
| Malformed Salesforce payload | Validation error raised in import pipeline | Job fails and moves to Resque failed queue; alert for manual investigation |
| MySQL write failure | ActiveRecord raises error; job fails and retries | Contract not persisted; retry until database recovers |

## Sequence Diagram

```
API / Scheduler -> continuumAccountingRedis: Enqueue contract import job
continuumAccountingRedis -> acctSvc_contractImport: Dequeue job
acctSvc_contractImport -> salesForce: Fetch contract and merchant metadata (REST)
salesForce --> acctSvc_contractImport: Contract payload
acctSvc_contractImport -> continuumDealCatalogService: Fetch deal/option metadata (REST)
continuumDealCatalogService --> acctSvc_contractImport: Deal metadata
acctSvc_contractImport -> acctSvc_ingestion: Resolve inventory lineage
acctSvc_ingestion --> acctSvc_contractImport: Resolved mappings
acctSvc_contractImport -> continuumAccountingMysql: Persist contract models (SQL)
continuumAccountingMysql --> acctSvc_contractImport: Confirmation
acctSvc_contractImport -> messageBus: Publish Contract Imported event
```

## Related

- Architecture dynamic view: not yet defined — see `components-continuum-accounting-service`
- Related flows: [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md), [Voucher and Inventory Ingestion](voucher-inventory-ingestion.md)
- See [Events](../events.md) for Contract Imported event details
- See [Integrations](../integrations.md) for Salesforce and Deal Catalog Service details
