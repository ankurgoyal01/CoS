---
service: "getaways-payment-reconciliation"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGetawaysPaymentReconciliationDb"
    type: "mysql"
    purpose: "Stores invoices, reservations, reconciliation status, and reconciliation outputs"
---

# Data Stores

## Overview

The service owns a single MySQL database, accessed via the JTier DaaS MySQL module and JDBI DAOs. The database holds all state for the reconciliation process: raw EAN invoice data bulk-loaded from CSV/Excel, reservation records sourced from MBus events, invoice import run status, and merchant invoice payment records. No caching layer is used.

## Stores

### Getaways Payment Reconciliation DB (`continuumGetawaysPaymentReconciliationDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGetawaysPaymentReconciliationDb` |
| Purpose | Stores invoices, reservations, reconciliation status, and reconciliation outputs |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (migration files location not exposed in repository) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `travel_ean_invoice` | Stores raw EAN invoice line items bulk-loaded from CSV/Excel attachments | `affiliate_id`, `itinerary_id`, `confirmation_number`, `amount`, `currency_code`, `amount_us`, `invoice_number`, `invoice_date`, `travel_product_id`, `hotel_name`, `use_date_begin`, `use_date_end`, `created_at` |
| `invoice_importer_status` | Tracks the status of each invoice import run (per invoice date) | `invoice_date` (unique key), `status` (SUCCESS / FAILURE) |
| Merchant Invoice table | Stores merchant invoice records created through the payment API | `merchantInvoiceId`, `merchantInvoiceNumber`, `invoiceDate`, `totalAmount`, `currency`, `statusId`, `paymentGroupId`, `paymentUuid`, `merchantId`, `memo` |
| Reservation table | Stores Getaways reservation records sourced from MBus events | Populated by `messageBusProcessor` via `jdbiDaos`; exact schema not exposed in repository |

#### Access Patterns

- **Read**: `invoicePaymentsService` reads invoice and reservation data to validate totals; `reconciliationWorker` reads pending reconciliation records; `webResources` reads merchant invoices for the listing API
- **Write**: `invoiceImporterScript` bulk-loads `travel_ean_invoice` rows via MySQL `LOAD DATA LOCAL INFILE`; `messageBusProcessor` inserts reservation records; `webResources` writes payment records via `jdbiDaos`; `invoiceImporterScript` upserts `invoice_importer_status`
- **Indexes**: No evidence found of explicit index definitions in repository; primary keys and the `invoice_date` unique constraint on `invoice_importer_status` are referenced in code

## Caches

> No evidence found in codebase of any caching layer.

## Data Flows

Invoice data flows from Gmail (email attachment) → Python script bulk load → `travel_ean_invoice` table. Reservation data flows from MBus topic → Message Bus Processor → reservation table. Reconciliation logic in `invoicePaymentsService` joins invoice and reservation data from MySQL. Payment records are written back to MySQL after creation in the Accounting Service.
