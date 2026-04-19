---
service: "getaways-payment-reconciliation"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Getaways Payment Reconciliation.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [EAN Invoice Email Import](ean-invoice-email-import.md) | scheduled | Email reader worker timer | Downloads EAN invoice CSV/Excel from Gmail, bulk-loads into MySQL, updates import status |
| [Inventory Reservation Ingestion](inventory-reservation-ingestion.md) | event-driven | MBus inventory-units-updated message | Consumes MBus event, fetches unit details from Maris, persists reservation record to MySQL |
| [Invoice Reconciliation and Payment](invoice-reconciliation-and-payment.md) | synchronous | Internal user POST /products/{product}/invoices | Validates invoice total against reservations, creates vendor invoice in Accounting Service, records payment |
| [Scheduled Reconciliation Worker](scheduled-reconciliation-worker.md) | scheduled | Periodic timer (reconciliationWorkerPeriod) | Runs automated reconciliation over all pending invoices and sends notification |
| [Invoice Listing](invoice-listing.md) | synchronous | Internal user GET /products/{product}/invoices | Retrieves and returns filtered list of merchant invoices from MySQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Invoice Email Import** spans: Gmail (IMAP), Python Invoice Importer Script, MySQL — see [EAN Invoice Email Import](ean-invoice-email-import.md)
- **Inventory Reservation Ingestion** spans: MBus topic, Message Bus Processor, Maris API, MySQL — see [Inventory Reservation Ingestion](inventory-reservation-ingestion.md)
- **Invoice Reconciliation and Payment** spans: REST API, Invoice Payments Service, Accounting Service API, MySQL — see [Invoice Reconciliation and Payment](invoice-reconciliation-and-payment.md)
