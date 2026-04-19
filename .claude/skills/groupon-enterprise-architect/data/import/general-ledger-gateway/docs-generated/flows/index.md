---
service: "general-ledger-gateway"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for General Ledger Gateway.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Send Invoice to NetSuite](send-invoice-to-netsuite.md) | synchronous | `PUT /v1/invoices/{ledger}/send` API call | Receives a ledger invoice from Accounting Service and forwards it as a vendor bill to the specified NetSuite instance |
| [Invoice Lookup](invoice-lookup.md) | synchronous | `GET /v1/invoices/{invoiceUUID}` API call | Looks up a stored invoice record by UUID and returns its details |
| [Ledger Entry Lookup](ledger-entry-lookup.md) | synchronous | `GET /v1/ledger-entries/...` API call | Returns the ledger payment status (PAID/UNPAID/VOIDED) for an invoice UUID or ledger-specific ID |
| [Import Applied Invoices Job](import-applied-invoices.md) | batch | `POST /v1/{ledger}/jobs/import-applied-invoices` or Quartz schedule | Downloads applied invoice credits from NetSuite saved searches and applies them in Accounting Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The Import Applied Invoices flow spans GLG, NetSuite ERP, and Accounting Service. It is documented in the architecture dynamic view `ImportAppliedInvoices` within the `continuumGeneralLedgerGatewayApi` container model. See [Import Applied Invoices Job](import-applied-invoices.md) for the detailed step sequence.
