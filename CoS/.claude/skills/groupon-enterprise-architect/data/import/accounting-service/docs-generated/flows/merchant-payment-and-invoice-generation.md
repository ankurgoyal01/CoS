---
service: "accounting-service"
title: "Merchant Payment and Invoice Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-payment-and-invoice-generation"
flow_type: event-driven
trigger: "Voucher/order events normalized by ingestion workers, or API-triggered invoice workflow commands"
participants:
  - "continuumAccountingService"
  - "acctSvc_apiEndpoints"
  - "acctSvc_ingestion"
  - "acctSvc_paymentAndInvoicing"
  - "acctSvc_reportingExports"
  - "continuumOrdersService"
  - "continuumVoucherInventoryService"
  - "messageBus"
  - "continuumAccountingMysql"
  - "continuumAccountingRedis"
architecture_ref: "components-continuum-accounting-service"
---

# Merchant Payment and Invoice Generation

## Summary

The Merchant Payment and Invoice Generation flow drives the full financial settlement lifecycle for Groupon merchants. It begins when normalized accounting events arrive from the ingestion layer (populated by voucher and order events) and progresses through transaction creation, statement generation, invoice production, and merchant payment runs. Invoice state transitions (approve, reject, resubmit) can also be triggered via the v1 API. Completed payments are published to the Message Bus to notify downstream systems.

## Trigger

- **Type**: event or api-call
- **Source**: Normalized accounting events published by `acctSvc_ingestion`; invoice workflow commands via `POST /api/v1/invoices/approve`, `/reject`, `/resubmit`; payment run schedule
- **Frequency**: Event-driven (on ingestion completion); on-demand (invoice approval); scheduled (payment run cadence)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Endpoints | Receives invoice workflow commands (approve, reject, resubmit) | `acctSvc_apiEndpoints` |
| Voucher/Inventory Ingestion | Publishes normalized accounting events that trigger transaction creation | `acctSvc_ingestion` |
| Payment and Invoicing Engine | Core business logic for transaction creation, invoice generation, and payment processing | `acctSvc_paymentAndInvoicing` |
| Reporting and Export Jobs | Receives finalized payment and invoice data for statement and export generation | `acctSvc_reportingExports` |
| Orders Service (TPS) | Provides order and refund data for transaction calculation | `continuumOrdersService` |
| Voucher Inventory Service | Provides voucher state for earnings calculation | `continuumVoucherInventoryService` |
| Message Bus | Receives merchant payment completion events | `messageBus` |
| Accounting MySQL | Stores transactions, invoices, payments, and statements | `continuumAccountingMysql` |
| Accounting Redis | Queues payment and invoicing jobs; holds distributed locks during payment runs | `continuumAccountingRedis` |

## Steps

1. **Receives normalized accounting event**: Payment and Invoicing Engine receives a normalized event from `acctSvc_ingestion` indicating new transaction-eligible activity
   - From: `acctSvc_ingestion`
   - To: `acctSvc_paymentAndInvoicing`
   - Protocol: Direct

2. **Fetches order and refund data**: Payment engine queries Orders Service to retrieve order and refund records needed for transaction amount calculation
   - From: `acctSvc_paymentAndInvoicing`
   - To: `continuumOrdersService`
   - Protocol: REST

3. **Fetches voucher state**: Payment engine queries Voucher Inventory Service to validate voucher state relevant to the earning period
   - From: `acctSvc_paymentAndInvoicing`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

4. **Creates transaction records**: Payment engine writes transaction entries to `continuumAccountingMysql` based on the calculated amounts and contract payment terms
   - From: `acctSvc_paymentAndInvoicing`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

5. **Generates invoice**: Payment engine aggregates transactions for the billing period and writes an invoice record to `continuumAccountingMysql` with status `pending`
   - From: `acctSvc_paymentAndInvoicing`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

6. **Approves or rejects invoice**: An internal consumer calls `POST /api/v1/invoices/approve` or `POST /api/v1/invoices/reject`; API Endpoints delegates to the payment engine to update invoice status
   - From: `acctSvc_apiEndpoints`
   - To: `acctSvc_paymentAndInvoicing`
   - Protocol: Direct

7. **Processes payment run**: Payment engine aggregates approved invoices and executes the merchant payment run; acquires a distributed lock in `continuumAccountingRedis` to prevent concurrent runs
   - From: `acctSvc_paymentAndInvoicing`
   - To: `continuumAccountingRedis` (lock) and `continuumAccountingMysql` (write)
   - Protocol: Redis (lock), ActiveRecord / SQL (write)

8. **Publishes payment completion event**: Service publishes Merchant Payment Completion event to `messageBus`
   - From: `continuumAccountingService`
   - To: `messageBus`
   - Protocol: Message Bus

9. **Triggers reporting exports**: Reporting and Export Jobs reads finalized payment and invoice data to generate statements and outbound exports
   - From: `acctSvc_paymentAndInvoicing`
   - To: `acctSvc_reportingExports`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders Service unavailable | Resque job fails; retry via backoff | Transaction calculation blocked; retry until service recovers |
| Voucher Inventory Service unavailable | Resque job fails; retry via backoff | Voucher validation blocked; retry until service recovers |
| Invoice rejected | Invoice status set to `rejected` via API; resubmission required via `/api/v1/invoices/resubmit` | Merchant payment withheld until invoice is resolved |
| Concurrent payment run attempt | Distributed lock in `continuumAccountingRedis` prevents second run | Second job waits or fails; lock released after first run completes |
| MySQL write failure on payment record | ActiveRecord raises error; Resque job retries | Payment not committed; merchant payment deferred until database recovers |
| Message Bus publish failure | Publish attempt fails; dependent on Message Bus client retry behavior | Downstream systems may not receive payment event; investigate and re-publish if needed |

## Sequence Diagram

```
acctSvc_ingestion -> acctSvc_paymentAndInvoicing: Normalized accounting event
acctSvc_paymentAndInvoicing -> continuumOrdersService: Fetch order and refund data (REST)
continuumOrdersService --> acctSvc_paymentAndInvoicing: Order records
acctSvc_paymentAndInvoicing -> continuumVoucherInventoryService: Fetch voucher state (REST)
continuumVoucherInventoryService --> acctSvc_paymentAndInvoicing: Voucher state
acctSvc_paymentAndInvoicing -> continuumAccountingMysql: Write transaction records (SQL)
acctSvc_paymentAndInvoicing -> continuumAccountingMysql: Write invoice record (SQL)
Internal Consumer -> acctSvc_apiEndpoints: POST /api/v1/invoices/approve
acctSvc_apiEndpoints -> acctSvc_paymentAndInvoicing: Update invoice status
acctSvc_paymentAndInvoicing -> continuumAccountingRedis: Acquire payment run lock
acctSvc_paymentAndInvoicing -> continuumAccountingMysql: Write payment record (SQL)
acctSvc_paymentAndInvoicing -> messageBus: Publish Merchant Payment Completion event
acctSvc_paymentAndInvoicing -> acctSvc_reportingExports: Trigger statement and export generation
```

## Related

- Architecture dynamic view: not yet defined — see `components-continuum-accounting-service`
- Related flows: [Deal Contract Import](deal-contract-import.md), [Voucher and Inventory Ingestion](voucher-inventory-ingestion.md), [Scheduled Reporting and Reconciliation](scheduled-reporting-and-reconciliation.md)
- See [Events](../events.md) for Merchant Payment Completion and Invoice Lifecycle event details
- See [API Surface](../api-surface.md) for invoice workflow endpoint details
