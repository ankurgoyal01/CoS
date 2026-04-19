---
service: "accounting-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Accounting Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Contract Import](deal-contract-import.md) | asynchronous | Salesforce contract data available or API-triggered import | Pulls merchant contracts from Salesforce and persists normalized accounting models |
| [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md) | event-driven | Voucher/order events or scheduled payment run | Generates invoices and processes merchant payment runs based on transaction data |
| [Voucher and Inventory Ingestion](voucher-inventory-ingestion.md) | event-driven | Message Bus events from Deal Catalog and Voucher Inventory services | Consumes upstream events and normalizes voucher and inventory product data into accounting records |
| [API Vendor Transaction Query](api-vendor-transaction-query.md) | synchronous | HTTP GET request from an internal consumer | Returns contracts, transactions, invoices, statements, or payments for a given vendor via REST API |
| [Scheduled Reporting and Reconciliation](scheduled-reporting-and-reconciliation.md) | scheduled | Cron or Delayed Job schedule | Runs periodic financial reconciliation and produces reporting exports |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Deal Contract Import](deal-contract-import.md) flow spans `continuumAccountingService` and `salesForce`, with secondary lookups to `continuumDealCatalogService`
- The [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md) flow spans `continuumAccountingService`, `continuumOrdersService`, `continuumVoucherInventoryService`, and `messageBus`
- The [Voucher and Inventory Ingestion](voucher-inventory-ingestion.md) flow spans `messageBus`, `continuumDealCatalogService`, `continuumVoucherInventoryService`, and `continuumAccountingService`

> Dynamic views for these flows are not yet defined in Structurizr. See the `components-continuum-accounting-service` component diagram for static component relationships.
