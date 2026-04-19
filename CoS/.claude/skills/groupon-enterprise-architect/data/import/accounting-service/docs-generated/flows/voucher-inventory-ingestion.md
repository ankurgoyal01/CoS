---
service: "accounting-service"
title: "Voucher and Inventory Ingestion"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "voucher-inventory-ingestion"
flow_type: event-driven
trigger: "Message Bus events published by Deal Catalog Service, Voucher Inventory Service, or Orders Service"
participants:
  - "continuumAccountingService"
  - "acctSvc_ingestion"
  - "acctSvc_paymentAndInvoicing"
  - "messageBus"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumOrdersService"
  - "continuumAccountingMysql"
  - "continuumAccountingRedis"
architecture_ref: "components-continuum-accounting-service"
---

# Voucher and Inventory Ingestion

## Summary

The Voucher and Inventory Ingestion flow receives upstream events from the Groupon Message Bus — including deal catalog distributions, inventory product voucher updates, post-live deal events, and payment status updates — and normalizes them into the Accounting Service's domain models. Resque workers dequeue incoming events and transform the raw data into accounting records and transaction entries. Normalized events are then forwarded to the Payment and Invoicing Engine for downstream processing.

## Trigger

- **Type**: event
- **Source**: `messageBus` — topics `DealCatalogDistribution`, `inventory-product-voucher-updates`, `post-live-events`, and `payment-status-events`
- **Frequency**: Continuous; events arrive as upstream services publish them

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers upstream events to the ingestion workers | `messageBus` |
| Voucher/Inventory Ingestion | Dequeues and processes events; normalizes data into accounting models | `acctSvc_ingestion` |
| Payment and Invoicing Engine | Receives normalized accounting events to trigger transaction creation | `acctSvc_paymentAndInvoicing` |
| Deal Catalog Service | Source of `DealCatalogDistribution` events; also queried directly for deal metadata | `continuumDealCatalogService` |
| Voucher Inventory Service | Source of `inventory-product-voucher-updates` events | `continuumVoucherInventoryService` |
| Orders Service | Source context for post-live and payment-status events | `continuumOrdersService` |
| Accounting MySQL | Stores normalized accounting records, voucher state, and transaction entries | `continuumAccountingMysql` |
| Accounting Redis | Resque queue that holds pending ingestion jobs | `continuumAccountingRedis` |

## Steps

1. **Receives upstream event**: Message Bus client receives an event on a subscribed topic (`DealCatalogDistribution`, `inventory-product-voucher-updates`, `post-live-events`, or `payment-status-events`)
   - From: `messageBus`
   - To: `continuumAccountingService` (Message Bus consumer)
   - Protocol: Message Bus

2. **Enqueues ingestion job**: The Message Bus consumer serializes the event payload and enqueues a Resque job in `continuumAccountingRedis`
   - From: `continuumAccountingService`
   - To: `continuumAccountingRedis`
   - Protocol: Redis / Resque

3. **Dequeues and routes job**: Resque worker picks up the job and routes it to the appropriate ingestion handler based on event type
   - From: `continuumAccountingRedis`
   - To: `acctSvc_ingestion`
   - Protocol: Resque

4. **Normalizes deal catalog event** (DealCatalogDistribution): Ingestion handler extracts deal and option metadata and upserts accounting contract line items; resolves inventory lineage mappings
   - From: `acctSvc_ingestion`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

5. **Normalizes voucher inventory event** (inventory-product-voucher-updates): Ingestion handler updates voucher and inventory product state in accounting records, associating vouchers with their accounting contract context
   - From: `acctSvc_ingestion`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

6. **Normalizes post-live event** (post-live-events): Ingestion handler processes the post-live signal for a deal and creates the initial accounting entries that enable merchant earning calculations
   - From: `acctSvc_ingestion`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

7. **Normalizes payment status event** (payment-status-events): Ingestion handler routes payment status updates to the Payment and Invoicing Engine to update payment records
   - From: `acctSvc_ingestion`
   - To: `acctSvc_paymentAndInvoicing`
   - Protocol: Direct

8. **Publishes normalized accounting event**: Ingestion component signals the Payment and Invoicing Engine with the normalized accounting event, enabling downstream transaction and invoice generation
   - From: `acctSvc_ingestion`
   - To: `acctSvc_paymentAndInvoicing`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed event payload | Ingestion handler raises validation error; Resque job fails | Job moves to failed queue; no partial writes; manual investigation required |
| Duplicate event received | Ingestion handler deduplicates by event key (deal, voucher, or payment identifier) | Idempotent upsert; no duplicate records created |
| MySQL write failure | ActiveRecord error; Resque job retries | Normalized record not persisted; job retried until database recovers |
| Unknown event type | Handler logs unrecognized event type; job completes without side effects | Event ignored; logged for monitoring |
| Message Bus consumer disconnects | Message Bus client reconnects per client library behavior | Events may be delayed; no data loss if Message Bus provides at-least-once delivery |

## Sequence Diagram

```
messageBus -> continuumAccountingService: DealCatalogDistribution event
continuumAccountingService -> continuumAccountingRedis: Enqueue ingestion job
continuumAccountingRedis -> acctSvc_ingestion: Dequeue job
acctSvc_ingestion -> continuumAccountingMysql: Upsert contract line items / voucher state (SQL)
acctSvc_ingestion -> acctSvc_paymentAndInvoicing: Publish normalized accounting event

messageBus -> continuumAccountingService: inventory-product-voucher-updates event
continuumAccountingService -> continuumAccountingRedis: Enqueue ingestion job
continuumAccountingRedis -> acctSvc_ingestion: Dequeue job
acctSvc_ingestion -> continuumAccountingMysql: Update voucher/inventory state (SQL)

messageBus -> continuumAccountingService: post-live-events event
continuumAccountingService -> continuumAccountingRedis: Enqueue ingestion job
continuumAccountingRedis -> acctSvc_ingestion: Dequeue job
acctSvc_ingestion -> continuumAccountingMysql: Create initial accounting entries (SQL)
acctSvc_ingestion -> acctSvc_paymentAndInvoicing: Publish normalized accounting event

messageBus -> continuumAccountingService: payment-status-events event
continuumAccountingService -> continuumAccountingRedis: Enqueue ingestion job
continuumAccountingRedis -> acctSvc_ingestion: Dequeue job
acctSvc_ingestion -> acctSvc_paymentAndInvoicing: Update payment status
```

## Related

- Architecture dynamic view: not yet defined — see `components-continuum-accounting-service`
- Related flows: [Deal Contract Import](deal-contract-import.md), [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md)
- See [Events](../events.md) for all consumed event topic details
- See [Integrations](../integrations.md) for Deal Catalog Service and Voucher Inventory Service details
