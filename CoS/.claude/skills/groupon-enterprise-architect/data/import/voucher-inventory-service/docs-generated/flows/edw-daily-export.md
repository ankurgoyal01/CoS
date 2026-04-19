---
service: "voucher-inventory-service"
title: "EDW Daily Export"
generated: "2026-03-03"
type: flow
flow_name: "edw-daily-export"
flow_type: batch
trigger: "Scheduled daily ETL job"
participants:
  - "continuumVoucherInventoryApi"
  - "continuumVoucherInventoryApi_edwExporter"
  - "continuumVoucherInventoryDb"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumEdw"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# EDW Daily Export

## Summary

The EDW daily export flow builds analytical snapshots of voucher inventory data and uploads them to S3 for ingestion into the Enterprise Data Warehouse (EDW). The EDW Exporter component queries both the product and units databases, assembles export files, and uploads them to a designated S3 bucket. This batch process runs daily and provides downstream analytics, reporting, and business intelligence teams with up-to-date inventory data.

## Trigger

- **Type**: schedule
- **Source**: Daily scheduled rake task or cron job
- **Frequency**: daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory API | Hosts the EDW Exporter component | `continuumVoucherInventoryApi` |
| EDW Exporter | Builds and uploads analytical snapshots | `continuumVoucherInventoryApi_edwExporter` |
| Voucher Inventory DB | Source for product-level data | `continuumVoucherInventoryDb` |
| Voucher Inventory Units DB | Source for unit-level data | `continuumVoucherInventoryUnitsDb` |
| Enterprise Data Warehouse | Target for exported snapshots | `continuumEdw` |

## Steps

1. **Trigger export job**: The scheduled rake task or cron job triggers the EDW Exporter.
   - From: Scheduler
   - To: `continuumVoucherInventoryApi_edwExporter`
   - Protocol: Rake task / cron

2. **Query product data**: The exporter queries the product database for inventory product snapshots.
   - From: `continuumVoucherInventoryApi_edwExporter`
   - To: `continuumVoucherInventoryDb`
   - Protocol: MySQL (read-only queries)

3. **Query units data**: The exporter queries the units database for unit-level snapshots and aggregates.
   - From: `continuumVoucherInventoryApi_edwExporter`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL (read-only queries)

4. **Build export files**: Assemble the queried data into export files (CSV or structured format).
   - From: `continuumVoucherInventoryApi_edwExporter`
   - To: (internal processing)
   - Protocol: File I/O

5. **Upload to S3/EDW**: Upload the export files to S3 for EDW ingestion.
   - From: `continuumVoucherInventoryApi_edwExporter`
   - To: `continuumEdw`
   - Protocol: Batch ETL/S3

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database query timeout | Retry with smaller batch size | Export delayed but eventually completes |
| S3 upload failure | Retry upload with exponential backoff | Export files preserved locally until upload succeeds |
| Partial data export | Log warning, continue with available data | Partial snapshot available; full retry on next run |

## Sequence Diagram

```
Scheduler -> EDW Exporter: triggerDailyExport()
EDW Exporter -> Voucher Inventory DB: SELECT product snapshots
Voucher Inventory DB --> EDW Exporter: productData[]
EDW Exporter -> Units DB: SELECT unit snapshots and aggregates
Units DB --> EDW Exporter: unitData[]
EDW Exporter -> EDW Exporter: buildExportFiles(productData, unitData)
EDW Exporter -> EDW (S3): uploadExportFiles()
EDW --> EDW Exporter: uploadConfirmation
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Reconciliation](reconciliation.md)
