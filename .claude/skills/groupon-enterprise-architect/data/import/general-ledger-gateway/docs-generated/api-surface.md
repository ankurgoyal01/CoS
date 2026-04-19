---
service: "general-ledger-gateway"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-token]
---

# API Surface

## Overview

GLG exposes a REST API intended exclusively for internal consumers — primarily Accounting Service. The API operates over HTTP on port 8080, with an admin port on 8081. All endpoints are versioned under `/v1`. The `{ledger}` path parameter selects the target NetSuite instance.

## Endpoints

### Invoice Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/invoices/{invoiceUUID}` | Retrieve an invoice record by UUID | Internal |
| `PUT` | `/v1/invoices/{ledger}/send` | Send a ledger invoice to the specified NetSuite instance | Internal |

### Ledger Entry Map Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/ledger-entries/{invoiceUUID}` | Look up ledger entry status by invoice UUID | Internal |
| `GET` | `/v1/ledger-entries/{ledger}/{ledgerID}` | Look up ledger entry status by ledger type and NetSuite ledger ID | Internal |

### Job Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/{ledger}/jobs/import-applied-invoices` | Trigger the Import Applied Invoices job for a specific ledger | Internal |

### Ledger Values

The `{ledger}` path parameter accepts:

| Value | NetSuite Instance |
|-------|-----------------|
| `GOODS_NETSUITE` | North America Goods NetSuite (realm 3579761) |
| `NETSUITE` | International NetSuite (realm 1202613) |
| `NORTH_AMERICA_LOCAL_NETSUITE` | North America Local NetSuite (realm 4004600) |

## Request/Response Patterns

### Send Invoice Request Body (`PUT /v1/invoices/{ledger}/send`)

Key fields from `LedgerInvoice` model:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Invoice identifier |
| `merchantID` | UUID | Merchant identifier |
| `amount` | double | Invoice amount |
| `currency` | Currency object | Currency details |
| `brand` | enum (`groupon`, `livingsocial`) | Brand |
| `documentDate` | datetime | Document date |
| `dueDate` | datetime | Payment due date |
| `invoiceClassification` | enum | Classification (e.g., `GETAWAYS`, `MARKET_RATE_INVOICE`) |
| `reasonCode` | enum | Reason code (e.g., `REFUNDS`, `PREPAID`, `FRAUD`) |
| `setOfBooks` | enum | ISO country code or special value identifying the accounting book |

### Invoice Show Response (`GET /v1/invoices/{invoiceUUID}`)

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | UUID | Invoice identifier |
| `vendorUUID` | UUID | Associated vendor identifier |
| `dueDate` | date | Payment due date |
| `setOfBooks` | enum | Accounting book identifier |

### Ledger Entry Show Response (`GET /v1/ledger-entries/...`)

| Field | Type | Description |
|-------|------|-------------|
| `invoiceUUID` | UUID | Invoice identifier |
| `ledgerStatus` | enum (`PAID`, `UNPAID`, `VOIDED`) | Current ledger status in NetSuite |

### Error format

All error responses return a JSON object:

```json
{ "error": "<error message string>" }
```

HTTP 404 is returned when an invoice or ledger entry is not found.

### Pagination

> No evidence found in codebase. The NetSuite client uses internal `PaginationParameters` for paging NetSuite saved searches, but pagination is not exposed through the REST API.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are versioned by URL path prefix `/v1`.

## OpenAPI / Schema References

The Swagger 2.0 specification is available at `doc/swagger/swagger.yaml` in the source repository. The Swagger UI configuration is at `doc/swagger/config.yml`.
