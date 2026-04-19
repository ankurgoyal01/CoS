---
service: "etorch"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for eTorch (Extranet Travel ORCHestrator).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotel Data Management](hotel-data-management.md) | synchronous | Merchant HTTP request | Merchant updates hotel contacts or retrieves inventory auto-updates via the extranet API |
| [Deal Update Batch Job](deal-update-batch-job.md) | batch | API call (`POST /v1/getaways/extranet/jobs/deal_update`) | Internal job trigger pushes deal updates to Deal Management API via eTorch Worker |
| [Accounting Report Generation](accounting-report-generation.md) | scheduled | Quartz scheduler (`continuumEtorchWorker`) | Periodic job retrieves accounting statements and payments from Accounting Service |
| [Low Inventory Batch Reporting](low-inventory-batch-reporting.md) | scheduled | Quartz scheduler (`continuumEtorchWorker`) | Periodic job detects low hotel inventory and dispatches alert notifications |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

All four flows span multiple services. Key cross-service interactions:

- **Hotel Data Management** — `continuumEtorchApp` calls Getaways Inventory (`getawaysInventoryExternal_b51b`) and Notification Service (`notificationServiceExternal_5b7e`). See [Hotel Data Management](hotel-data-management.md).
- **Deal Update Batch Job** — `continuumEtorchApp` and `continuumEtorchWorker` coordinate to push updates to `continuumDealManagementApi`. See [Deal Update Batch Job](deal-update-batch-job.md).
- **Accounting Report Generation** — `continuumEtorchWorker` calls `continuumAccountingService` and `continuumEtorchApp` surfaces results via REST. See [Accounting Report Generation](accounting-report-generation.md).
- **Low Inventory Batch Reporting** — `continuumEtorchWorker` calls Getaways Inventory (`getawaysInventoryExternal_b51b`) and Notification Service (`notificationServiceExternal_5b7e`). See [Low Inventory Batch Reporting](low-inventory-batch-reporting.md).
