---
service: "getaways-accounting-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Getaways Accounting Service (GAS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily CSV Generation and Upload](csv-generation-and-upload.md) | scheduled | Kubernetes cron-job at 00:20 UTC daily | Generates accounting summary and detail CSV files from reservation data, uploads to SFTP with MD5 checksums, and validates upload integrity |
| [Finance Lookup by Record Locator](finance-lookup.md) | synchronous | HTTP GET /v1/finance | Accepts one or more booking record locators and returns finance reservation details from TIS PostgreSQL |
| [Reservations Search by Date Range](reservations-search.md) | synchronous | HTTP GET /v1/reservations/search | Returns paginated reservation records filtered by a date range for audit and accounting reconciliation |
| [CSV Upload Validation](csv-upload-validation.md) | synchronous | Triggered at end of CSV generation task | Re-downloads uploaded CSV from SFTP remote and validates MD5 integrity |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Daily CSV Generation** flow spans `continuumGetawaysAccountingService`, the TIS PostgreSQL database (`tisPostgres_bf2737`), the Content Service API (`contentServiceApi_abaf55`), and the accounting SFTP server (`accountingSftpServer_14db43`).
- The **Finance Lookup** and **Reservations Search** flows span `continuumGetawaysAccountingService` and `tisPostgres_bf2737`, with EDW / FED as external callers.
