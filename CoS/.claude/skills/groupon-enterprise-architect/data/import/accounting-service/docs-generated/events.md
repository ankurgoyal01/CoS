---
service: "accounting-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Accounting Service participates in Groupon's Message Bus (`messageBus`) for both publishing and consuming async events. It publishes events for downstream finance and reporting systems when contract, payment, and invoice milestones occur. It consumes events from Deal Catalog, Voucher Inventory, and Order services to drive ingestion and payment workflows. Background processing is handled by Resque workers backed by `continuumAccountingRedis`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` | Contract Imported | Salesforce contract import completes successfully | contract_id, vendor_id, deal_ids, effective_date |
| `messageBus` | Payment Term Validation | Payment terms validated during contract processing | contract_id, vendor_id, payment_terms |
| `messageBus` | Merchant Payment Completion | Merchant payment run finalized | payment_id, vendor_id, amount, currency, payment_date |
| `messageBus` | Invoice Lifecycle Event | Invoice created, approved, rejected, or resubmitted | invoice_id, vendor_id, status, amount, event_type |

### Contract Imported Detail

- **Topic**: `messageBus`
- **Trigger**: Salesforce contract import pipeline completes and persists a new or updated contract
- **Payload**: contract_id, vendor_id, associated deal_ids, effective_date, contract_status
- **Consumers**: Downstream finance and reporting services
- **Guarantees**: at-least-once

### Payment Term Validation Detail

- **Topic**: `messageBus`
- **Trigger**: Contract import pipeline validates payment terms during contract ingestion
- **Payload**: contract_id, vendor_id, payment_terms structure
- **Consumers**: Downstream contract and payment configuration consumers
- **Guarantees**: at-least-once

### Merchant Payment Completion Detail

- **Topic**: `messageBus`
- **Trigger**: Payment and invoicing engine finalizes a merchant payment run
- **Payload**: payment_id, vendor_id, amount, currency, payment_date, payment_status
- **Consumers**: Merchant notification and ledger services
- **Guarantees**: at-least-once

### Invoice Lifecycle Event Detail

- **Topic**: `messageBus`
- **Trigger**: Invoice state transitions — creation, approval via `/api/v1/invoices/approve`, rejection via `/api/v1/invoices/reject`, or resubmission via `/api/v1/invoices/resubmit`
- **Payload**: invoice_id, vendor_id, status, amount, currency, event_type
- **Consumers**: Finance operations tooling and downstream reporting
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `DealCatalogDistribution` | Deal catalog distribution | `acctSvc_ingestion` (Resque worker) | Normalizes deal/option data into accounting contract models |
| `inventory-product-voucher-updates` | Inventory product voucher update | `acctSvc_ingestion` (Resque worker) | Updates voucher inventory state in accounting records |
| `post-live-events` | Post-live deal event | `acctSvc_ingestion` (Resque worker) | Triggers transaction and accounting entry creation after deal goes live |
| `payment-status-events` | Payment status update | `acctSvc_paymentAndInvoicing` | Updates payment status on accounting payment records |

### DealCatalogDistribution Detail

- **Topic**: `DealCatalogDistribution`
- **Handler**: `acctSvc_ingestion` — Resque worker normalizes deal and option metadata into accounting contract line items
- **Idempotency**: Processing is keyed on deal and option identifiers; duplicate messages result in updates rather than duplicate records
- **Error handling**: Failed jobs are retried via Resque retry mechanism; persistent failures remain in the Resque failed queue for investigation
- **Processing order**: unordered

### inventory-product-voucher-updates Detail

- **Topic**: `inventory-product-voucher-updates`
- **Handler**: `acctSvc_ingestion` — Resque worker updates voucher and inventory product state in accounting records
- **Idempotency**: Updates are applied based on product/voucher identifiers
- **Error handling**: Resque retry with failed queue fallback
- **Processing order**: unordered

### post-live-events Detail

- **Topic**: `post-live-events`
- **Handler**: `acctSvc_ingestion` — Resque worker triggers transaction creation and accounting entries when a deal goes live
- **Idempotency**: Deal-live events are deduplicated by deal identifier
- **Error handling**: Resque retry with failed queue fallback
- **Processing order**: unordered

### payment-status-events Detail

- **Topic**: `payment-status-events`
- **Handler**: `acctSvc_paymentAndInvoicing` — updates payment status fields on accounting payment records
- **Idempotency**: Status updates are applied based on payment identifier
- **Error handling**: Resque retry with failed queue fallback
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Resque failed queue (`continuumAccountingRedis`) | All consumed topics | Until manually cleared | No evidence found of automated alerting configuration |

> Failed Resque jobs accumulate in the Redis-backed failed queue and require manual investigation or re-enqueue by operators. See [Runbook](runbook.md) for operational procedures.
