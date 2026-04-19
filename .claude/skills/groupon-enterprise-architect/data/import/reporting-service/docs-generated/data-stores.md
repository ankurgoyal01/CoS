---
service: "reporting-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumReportingDb"
    type: "postgresql"
    purpose: "Core reporting data store"
  - id: "continuumDealCapDb"
    type: "postgresql"
    purpose: "Deal cap data store for risk and caps"
  - id: "continuumFilesDb"
    type: "postgresql"
    purpose: "Metadata store for reporting files"
  - id: "continuumVouchersDb"
    type: "postgresql"
    purpose: "Voucher reporting data store"
  - id: "continuumVatDb"
    type: "postgresql"
    purpose: "VAT reporting data store"
  - id: "continuumEuVoucherDb"
    type: "postgresql"
    purpose: "EU voucher reporting data store"
  - id: "reportingS3Bucket"
    type: "s3"
    purpose: "Report artifact storage"
---

# Data Stores

## Overview

The reporting service owns or accesses six PostgreSQL databases covering distinct reporting domains (core reporting, deal caps, file metadata, vouchers, VAT, and EU vouchers) plus an AWS S3 bucket for report artifact storage. All relational access is via Hibernate 3.6.10 with the PostgreSQL JDBC 42.7.3 driver. S3 access uses the AWS SDK. In-process caching via EhCache 2.10.1 reduces repeated reference data lookups across databases.

## Stores

### Reporting Database (`continuumReportingDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumReportingDb` |
| Purpose | Core reporting data store; holds merchant deal performance records and report metadata |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Report records | Track generated report requests and status | Report ID, merchant ID, status, created timestamp |
| Payment event data | Persisted from PaymentNotification MBus messages | Payment ID, deal ID, amount, event timestamp |

#### Access Patterns

- **Read**: Report status lookups by ID; merchant report history queries
- **Write**: Report request creation; payment event persistence from MBus consumer
- **Indexes**: No evidence found; to be confirmed from service source

---

### Deal Cap Database (`continuumDealCapDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumDealCapDb` |
| Purpose | Deal cap data store for risk and caps |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal cap records | Track per-deal cap limits and current usage | Deal ID, cap limit, redemption count, updated timestamp |
| Audit log entries | Audit trail for deal cap enforcement actions | Deal ID, action type, actor, timestamp |

#### Access Patterns

- **Read**: Audit trail queries via `GET /dealcap/v1/audit`; cap status checks by deal ID
- **Write**: Cap state updates from `dealCapScheduler` and enforcement events
- **Indexes**: No evidence found

---

### Files Database (`continuumFilesDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumFilesDb` |
| Purpose | Metadata store for reporting files |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| File metadata | Records for each report file stored in S3 | File ID, S3 key, MIME type, size, created timestamp, report ID |

#### Access Patterns

- **Read**: File lookup by report ID to resolve S3 key for download
- **Write**: File metadata insertion when report artifact is uploaded to S3
- **Indexes**: No evidence found

---

### Vouchers Database (`continuumVouchersDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumVouchersDb` |
| Purpose | Voucher reporting data store |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Voucher records | Voucher state for reporting calculations | Voucher ID, deal ID, status, redemption date |

#### Access Patterns

- **Read**: Voucher data reads for deal performance and redemption reporting
- **Write**: No write evidence found; primarily read-only for reporting queries
- **Indexes**: No evidence found

---

### VAT Database (`continuumVatDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumVatDb` |
| Purpose | VAT reporting data store |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| VAT invoices | VAT invoice records for merchants | Invoice ID, merchant ID, period, amount, status |

#### Access Patterns

- **Read**: Invoice listing via `GET /vat/v1/invoices`
- **Write**: Invoice creation via `POST /vat/v1/invoices` and from `VatInvoicing` MBus events
- **Indexes**: No evidence found

---

### EU Voucher Database (`continuumEuVoucherDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumEuVoucherDb` |
| Purpose | EU voucher reporting data store |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| EU voucher records | EU-specific voucher data for regional reporting compliance | Voucher ID, country code, deal ID, status |

#### Access Patterns

- **Read**: EU voucher data reads for EU-specific reporting and compliance reports
- **Write**: No write evidence found; primarily read-only
- **Indexes**: No evidence found

---

### Report Artifact Storage (`reportingS3Bucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `reportingS3Bucket` |
| Purpose | Stores completed report files (Excel, CSV, PDF) for merchant download |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Report objects | Report files uploaded after generation | S3 key (by report ID), MIME type, content |

#### Access Patterns

- **Read**: Report artifact download triggered by `GET /reports/v1/reports/{id}` via `reportingService_s3Client`
- **Write**: Report artifact upload by `reportGenerationService` via `reportingService_s3Client` after rendering
- **Indexes**: Not applicable (object storage)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| EhCache (in-process) | in-memory | Caches reference data such as deal metadata and merchant records to reduce repeated API and DB calls during report generation | No evidence found for TTL; to be confirmed |

## Data Flows

- Report generation reads from `continuumReportingDb`, `continuumVouchersDb`, and `continuumEuVoucherDb`, enriches with data from external APIs, renders the report file, stores the artifact in `reportingS3Bucket`, and writes file metadata to `continuumFilesDb`.
- Payment events received from MBus are persisted to `continuumReportingDb` and may trigger report generation.
- Deal cap enforcement reads from `continuumDealCapDb`, updates cap state from the scheduler, and queries external APIs for current deal/merchant status.
- VAT invoicing reads and writes to `continuumVatDb`; EU voucher data is sourced from `continuumEuVoucherDb`.
