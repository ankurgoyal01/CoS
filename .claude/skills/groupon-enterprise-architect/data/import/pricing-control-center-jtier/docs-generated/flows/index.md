---
service: "pricing-control-center-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Pricing Control Center JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [ILS Scheduling](ils-scheduling.md) | asynchronous | `POST /sales/{id}/schedule` or `CheckForPendingSalesJob` detecting `SCHEDULING_PENDING` | Orchestrates multi-batch scheduling of sale products into the Pricing Service |
| [ILS Unscheduling](ils-unscheduling.md) | asynchronous | `POST /sales/{id}/unschedule` or `CheckForPendingSalesJob` detecting `UNSCHEDULING_PENDING` | Removes pricing programs from the Pricing Service for a cancelled or expired sale |
| [Custom ILS Sale Creation](custom-ils-sale-creation.md) | mixed | `POST /custom-sales` (sync intake) + scheduled hourly job (async fetch) | Creates a Custom ILS sale using ML flux model outputs fetched from Hive |
| [Sellout Program Creation](sellout-program-creation.md) | scheduled | `SelloutProgramCreatorJob` every 3 hours | Automatically creates and schedules sales for the Sellout channel from Gdoop flux output files |
| [RPO Program Creation](rpo-program-creation.md) | scheduled | `RetailPriceOptimizationJob` every 3 hours | Automatically creates and schedules sales for the RPO channel from GCS extract files |
| [Analytics Upload](analytics-upload.md) | scheduled | `AnalyticsUploadJob` every hour | Uploads scheduled product data to internal and external (Teradata) analytics log raw tables |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven / job-triggered) | 2 |
| Batch / Scheduled | 3 |
| Mixed (sync intake + async processing) | 1 |

## Cross-Service Flows

- **ILS Scheduling** spans `continuumPricingControlCenterJtierService`, `continuumPricingControlCenterJtierPostgres`, `continuumVoucherInventoryService`, `continuumPricingService`, and `messagingSaaS`. Architecture dynamic view: `dynamic-ils-scheduling-flow`.
- **Custom ILS Sale Creation** additionally involves `hiveWarehouse` for ML model output retrieval.
- **Sellout Program Creation** involves `hdfsStorage` (Gdoop) for flux file access.
- **RPO Program Creation** involves `gcpDynamicPricingBucket` for extract file download.
