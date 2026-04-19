---
service: "ad-inventory"
title: "DFP Report Ingestion Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "dfp-report-ingestion-pipeline"
flow_type: batch
trigger: "Quartz scheduler cron — triggers ReportGeneratorJob for each configured DFP report definition"
participants:
  - "continuumAdInventoryService_schedulerApi"
  - "continuumAdInventoryService_dfpReportDownloaderTask"
  - "continuumAdInventoryService_reportValidationTask"
  - "continuumAdInventoryService_hiveReportTableCreatorTask"
  - "continuumAdInventoryService_reportsRepository"
  - "continuumAdInventoryService_gcpClient"
  - "continuumAdInventoryGcs"
  - "continuumAdInventoryHive"
  - "continuumAdInventoryMySQL"
architecture_ref: "dynamic-ad-inventory-reporting-ingestion-flow"
---

# DFP Report Ingestion Pipeline

## Summary

The DFP Report Ingestion Pipeline is a multi-stage Quartz-scheduled batch process that downloads ad performance reports from Google Ad Manager (DFP), validates and stages them via GCS, and loads them into Hive tables for analytics consumption. Each configured report definition (`SourceType.DFP`) triggers `ReportGeneratorJob` on its cron schedule. The pipeline supports partial-failure recovery by resuming from the last known running stage, and sends email notifications for report lifecycle events. Rokt and LiveIntent ingestion pipelines follow the same structural pattern with source-specific tasks (`S3FileDownloaderTask`, `LiveIntentReportTask`).

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`@DisallowConcurrentExecution ReportGeneratorJob`)
- **Frequency**: Per-report cron schedule configured in the report definition stored in MySQL; defaults to daily (date range: yesterday's data; first run uses report's configured start date)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduler API | Triggers Quartz jobs for each report definition | `continuumAdInventoryService_schedulerApi` |
| DFP Report Downloader Task | Polls Google Ad Manager and downloads completed report CSVs | `continuumAdInventoryService_dfpReportDownloaderTask` |
| Report Validation Task | Validates CSV schema and promotes to validated GCS path | `continuumAdInventoryService_reportValidationTask` |
| Hive Report Table Creator Task | Creates Hive tables and loads validated CSVs | `continuumAdInventoryService_hiveReportTableCreatorTask` |
| Reports Repository (JDBI) | Manages report instance state and run metadata | `continuumAdInventoryService_reportsRepository` |
| GCP Client | Uploads, downloads, and manages files in GCS | `continuumAdInventoryService_gcpClient` |
| Ad Inventory GCS Bucket | Intermediate staging for downloaded and validated CSVs | `continuumAdInventoryGcs` |
| Ad Inventory Hive Warehouse | Final destination for validated ad performance data | `continuumAdInventoryHive` |
| Ad Inventory MySQL | Stores report definitions, instances, and run history | `continuumAdInventoryMySQL` |
| Google Ad Manager (DFP) | Source of ad performance report data | External: `googleAdManager` |
| Emailer | Sends lifecycle notifications | `continuumAdInventoryService_emailer` |

## Steps

1. **Quartz triggers report job**: `SchedulerApi` fires `ReportGeneratorJob` for a report ID based on the configured cron expression.
   - From: `continuumAdInventoryService_schedulerApi`
   - To: `continuumAdInventoryService_dfpReportDownloaderTask` (via `ReportFlowMediator`)
   - Protocol: Quartz in-process trigger

2. **Load report definition and evaluate run window**: `ReportGeneratorJob` loads the `Report` definition from MySQL. Determines start date (yesterday for recurring runs; configured start date for first run) and end date (yesterday). For DFP source, applies `refreshWindowSize` to ensure a rolling re-ingestion window.
   - From: `continuumAdInventoryService_schedulerApi`
   - To: `continuumAdInventoryService_reportsRepository`
   - Protocol: JDBI / SQL

3. **Create report instance (QUEUED status)**: A new `ReportInstance` is created in MySQL with status `QUEUED` and the calculated date range.
   - From: `continuumAdInventoryService_reportsRepository`
   - To: `continuumAdInventoryMySQL`
   - Protocol: JDBI / SQL

4. **Check for partial failure**: If the previous instance is in a non-terminal state, `isPartialFailureLogicNeeded()` returns true and the pipeline resumes from `lastRunningStage` using saved context attributes.
   - From: `continuumAdInventoryService_schedulerApi`
   - To: `continuumAdInventoryService_reportsRepository`
   - Protocol: JDBI / SQL

5. **Trigger DFP report download**: `DFPReportDownloaderTask` submits a report request to Google Ad Manager using the DFP Axis API client (service account OAuth2 auth) and polls until the report is complete.
   - From: `continuumAdInventoryService_dfpReportDownloaderTask`
   - To: Google Ad Manager (DFP)
   - Protocol: HTTP/SOAP (dfp-axis 4.19.0)

6. **Stage downloaded CSV to GCS**: `DFPReportDownloaderTask` calls `GCPClient` to upload the downloaded report CSV to the staging path in the GCS bucket.
   - From: `continuumAdInventoryService_dfpReportDownloaderTask`
   - To: `continuumAdInventoryService_gcpClient`
   - Protocol: in-process call

7. **Upload staged CSV to GCS**: `GCPClient` writes the CSV to `adsgcpclientconfig.bucketName` under the staging prefix.
   - From: `continuumAdInventoryService_gcpClient`
   - To: `continuumAdInventoryGcs`
   - Protocol: GCS SDK

8. **Trigger report validation**: `SchedulerApi` / `ReportFlowMediator` triggers `ReportValidationTask`. The task reads the staged CSV from GCS, validates row count and schema against expected structure using OpenCSV.
   - From: `continuumAdInventoryService_schedulerApi`
   - To: `continuumAdInventoryService_reportValidationTask`
   - Protocol: Quartz / in-process

9. **Upload validated CSV to GCS**: On successful validation, `ReportValidationTask` calls `GCPClient` to move/copy the file to the validated GCS prefix and cleans up the staging artifact.
   - From: `continuumAdInventoryService_reportValidationTask`
   - To: `continuumAdInventoryService_gcpClient`
   - Protocol: in-process call

10. **Trigger Hive table load**: `SchedulerApi` / `ReportFlowMediator` triggers `HiveReportTableCreatorTask`. The task reads the validated CSV from GCS and issues `CREATE TABLE IF NOT EXISTS` and `LOAD DATA` statements against Hive.
    - From: `continuumAdInventoryService_schedulerApi`
    - To: `continuumAdInventoryService_hiveReportTableCreatorTask`
    - Protocol: Quartz / in-process

11. **Load data into Hive**: `HiveReportTableCreatorTask` executes Hive SQL to create the report table (named `{source}_{name}_{id}_v{ver}`) and loads data from GCS.
    - From: `continuumAdInventoryService_hiveReportTableCreatorTask`
    - To: `continuumAdInventoryHive`
    - Protocol: Hive JDBC (jtier-hive)

12. **Persist run metadata**: `HiveReportTableCreatorTask` updates the `ReportInstance` in MySQL with final status (`COMPLETED`), row counts, and verification outcomes.
    - From: `continuumAdInventoryService_hiveReportTableCreatorTask`
    - To: `continuumAdInventoryService_reportsRepository`
    - Protocol: JDBI / SQL

13. **Send notification email**: `Emailer` sends a lifecycle notification (completion or failure) via SMTP.
    - From: `continuumAdInventoryService_emailer`
    - To: SMTP / `continuumEmailService`
    - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DFP API unavailable / timeout | Logged; report instance stays in `RUNNING` or returns to `QUEUED`; `ReportMonitoringJob` detects stall and sends alert | Next Quartz run will attempt resume via partial-failure logic |
| Validation failure (schema mismatch) | `ReportValidationTask` marks instance as failed; alert email sent | Hive load skipped; data not loaded; requires manual intervention |
| GCS upload failure | Exception propagated; report instance marked failed | Pipeline halted at staging stage; next run will retry from last stage |
| Hive load failure | Exception logged; instance marked failed | Report data not available in Hive; alert email sent |
| `@DisallowConcurrentExecution` | Quartz prevents overlapping runs for the same report | Ensures no duplicate data loads; may cause a run skip if previous run is still running |

## Sequence Diagram

```
QuartzScheduler -> ReportGeneratorJob: trigger(reportId)
ReportGeneratorJob -> MySQL: getReport(reportId), createReportInstance(QUEUED)
ReportGeneratorJob -> DFPReportDownloaderTask: execute(context)
DFPReportDownloaderTask -> GoogleAdManager: submit and poll report (HTTP/SOAP)
GoogleAdManager --> DFPReportDownloaderTask: report CSV download URL
DFPReportDownloaderTask -> GCPClient: upload staged CSV
GCPClient -> GCS: PUT staged/report.csv
ReportGeneratorJob -> ReportValidationTask: execute(context)
ReportValidationTask -> GCS: GET staged/report.csv
ReportValidationTask -> ReportValidationTask: validate schema
ReportValidationTask -> GCPClient: upload validated CSV, delete staged
GCPClient -> GCS: PUT validated/report.csv
ReportGeneratorJob -> HiveReportTableCreatorTask: execute(context)
HiveReportTableCreatorTask -> GCS: GET validated/report.csv
HiveReportTableCreatorTask -> Hive: CREATE TABLE, LOAD DATA (Hive JDBC)
HiveReportTableCreatorTask -> MySQL: UPDATE report_instance (COMPLETED)
Emailer -> SMTP: send completion notification
```

## Related

- Architecture dynamic view: `dynamic-ad-inventory-reporting-ingestion-flow`
- Related flows: [Audience Cache Warm-Up](audience-cache-warm-up.md)
