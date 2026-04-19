---
service: "invoice_management"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumInvoiceManagementPostgres"
    type: "postgresql"
    purpose: "Primary store for invoices, payments, receivers, POs, and cron tracking"
  - id: "awsS3RemittanceReports"
    type: "s3"
    purpose: "Object storage for generated remittance report files"
---

# Data Stores

## Overview

invoice_management uses two data stores: a PostgreSQL database as its primary operational store (invoices, payments, receivers, purchase orders, and scheduled job state), and AWS S3 for storing generated remittance report files. The service owns its PostgreSQL schema and manages it directly. S3 is used as a write-once archive for remittance Excel files that are shared with vendors.

## Stores

### Invoice Management PostgreSQL (`continuumInvoiceManagementPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumInvoiceManagementPostgres` |
| Purpose | Primary operational database: stores all invoices, payments, receivers, purchase orders, and Quartz cron job tracking data |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. Migration tooling not confirmed in inventory. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `invoices` | Core invoice records created from PO and GMO events | invoice_id, uuid, status, vendor_id, amount, created_at, netsuite_id |
| `payments` | Payment records fetched from NetSuite; linked to invoices | payment_id, invoice_id, amount, status, netsuite_payment_id, received_at |
| `receivers` | Vendor receiver records created from Receiver events | receiver_id, vendor_id, order_id, status, created_at |
| `purchase_orders` | PO records consumed from Message Bus events | po_id, vendor_id, status, amount, event_received_at |
| `cron_tracking` | Quartz scheduler job execution history and state | job_name, last_run, next_run, status |
| `shipment_status` | Shipment tracking state linked to invoices/POs | shipment_id, invoice_id, status, updated_at |

#### Access Patterns

- **Read**: Invoice listing queries filtered by vendor, status, and date range; payment reconciliation lookups by invoice ID; receiver and PO queries by vendor
- **Write**: Event consumers write new invoice, receiver, PO, and shipment records on message receipt; payment fetch jobs update payment status records; NetSuite callback updates invoice payment state
- **Indexes**: > No evidence found in codebase. Indexes on invoice_id, uuid, vendor_id, and status fields assumed for performance.

### AWS S3 Remittance Reports (`awsS3RemittanceReports`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | > No dedicated Structurizr container ID in inventory. |
| Purpose | Stores generated Excel remittance reports for vendor payment reconciliation |
| Ownership | shared (Goods platform S3 bucket) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Remittance report objects | Excel files (generated via Apache POI) containing payment details per vendor | Bucket key pattern: `remittance/{vendor_id}/{report_date}.xlsx` (assumed) |

#### Access Patterns

- **Read**: > No evidence found in codebase. Likely read by vendors or finance tooling via pre-signed S3 URLs.
- **Write**: Remittance Report Generator component uploads new Excel files after generation
- **Indexes**: S3 key prefix-based lookup

## Caches

> No evidence found in codebase. No explicit caching layer identified for invoice_management. Ebean ORM may use first-level entity cache internally.

## Data Flows

PO and GMO Message Bus events are consumed by `goodsInvoiceAggregator` and immediately persisted to `continuumInvoiceManagementPostgres` as invoice records. Quartz scheduled jobs periodically fetch payment data from NetSuite and update payment records in PostgreSQL. When a remittance run completes, the Remittance Report Generator creates an Excel file using Apache POI and uploads it to AWS S3. The NetSuite callback (`/ns_callback`) writes payment status updates directly to the PostgreSQL payments table.
