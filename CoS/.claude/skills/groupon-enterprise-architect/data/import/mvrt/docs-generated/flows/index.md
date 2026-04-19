---
service: "mvrt"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Multi-Voucher Redemption Tool (MVRT).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Online Voucher Search](online-voucher-search.md) | synchronous | `POST /bulkSearch` or `POST /unitSearch` HTTP request | User submits voucher codes (by any code type) and receives search results in real time |
| [Online Voucher Redemption](online-voucher-redemption.md) | synchronous | `POST /redeemVouchers` HTTP request | User selects redeemable vouchers and triggers batch redemption against Voucher Inventory Service |
| [Offline Search Job Submission](offline-job-submission.md) | synchronous | `POST /createCodesList` + `POST /createJsonFile` sequence | User submits a large code set (up to 300,000) for asynchronous background processing |
| [Offline Search Batch Processing](offline-batch-processing.md) | scheduled | Cron every 1 minute (`node-schedule`) | Background scheduler picks up queued JSON job files, executes voucher search, generates XLSX/CSV report, uploads to S3, and sends email |
| [Offline Report Download](offline-report-download.md) | synchronous | `GET /downloadFile` HTTP request | User downloads a completed offline search/redemption report from AWS S3 |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Online Search and Redeem**: spans `continuumMvrt` → `apiProxy` → `continuumVoucherInventoryService`, `continuumDealCatalogService`, `continuumM3MerchantService`. See architecture dynamic view: `dynamic-search_and_redeem_flow`.
- **Offline Export**: spans `continuumMvrt` → AWS S3 (file storage) → `continuumVoucherInventoryService` / `continuumDealCatalogService` / `continuumM3MerchantService` (batch search) → AWS S3 (report upload) → Rocketman (email). The dynamic view `dynamic-offline_export_flow` is disabled in the architecture model due to stubs not in workspace.
