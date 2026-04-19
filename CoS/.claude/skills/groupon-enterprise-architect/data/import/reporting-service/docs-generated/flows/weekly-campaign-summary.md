---
service: "reporting-service"
title: "Weekly Campaign Summary"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "weekly-campaign-summary"
flow_type: scheduled
trigger: "Weekly scheduler — campaignScheduler (Spring Scheduler + ShedLock)"
participants:
  - "campaignScheduler"
  - "reportGenerationService"
  - "reportingService_persistenceDaos"
  - "reportingService_externalApiClients"
  - "reportingService_s3Client"
  - "continuumReportingDb"
  - "continuumFilesDb"
  - "continuumVouchersDb"
  - "reportingS3Bucket"
  - "teradataWarehouse"
  - "notsApi"
architecture_ref: "Reporting-API-Components"
---

# Weekly Campaign Summary

## Summary

The weekly campaign summary flow runs on a recurring weekly schedule via the `campaignScheduler` component. It generates automated campaign performance reports for all active merchants by querying Teradata for campaign-level data, enriching it with voucher and deal information from Continuum databases and APIs, rendering the summary report (Excel or PDF), uploading it to S3, and optionally sending notification alerts via NOTS. The flow uses ShedLock to ensure exactly one instance executes per scheduled run.

## Trigger

- **Type**: schedule
- **Source**: `campaignScheduler` component (Spring Scheduler with ShedLock 1.2.0 distributed lock)
- **Frequency**: Weekly

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Scheduler | Initiates the weekly summary job; holds ShedLock to prevent duplicate runs | `campaignScheduler` |
| Report Generation | Coordinates data aggregation, rendering, and artifact storage | `reportGenerationService` |
| Persistence Layer | Reads voucher and reporting data from Continuum databases | `reportingService_persistenceDaos` |
| External API Clients | Fetches deal, merchant, and pricing data to enrich the summary | `reportingService_externalApiClients` |
| S3 Client | Uploads the rendered weekly summary report | `reportingService_s3Client` |
| Reporting Database | Stores report request records and final status | `continuumReportingDb` |
| Files Database | Stores S3 file metadata for the generated summary | `continuumFilesDb` |
| Vouchers Database | Source of voucher redemption data for the summary period | `continuumVouchersDb` |
| Report S3 Bucket | Persists the rendered weekly summary file | `reportingS3Bucket` |
| Teradata Warehouse | Source of campaign-level analytics data for the summary period | `teradataWarehouse` |
| NOTS API | Sends notification alerts when the summary report is ready | `notsApi` |

## Steps

1. **Acquire distributed lock**: `campaignScheduler` acquires a ShedLock on the weekly campaign summary job.
   - From: `campaignScheduler`
   - To: `continuumReportingDb` (ShedLock table)
   - Protocol: JDBC

2. **Identify active merchants and campaigns**: Scheduler determines the set of merchants and campaigns for the reporting period.
   - From: `campaignScheduler`
   - To: `reportGenerationService`
   - Protocol: direct

3. **Query Teradata for campaign data**: Report Generation queries Teradata warehouse for campaign performance metrics covering the weekly period.
   - From: `reportGenerationService`
   - To: `reportingService_externalApiClients` → `teradataWarehouse`
   - Protocol: JDBC/query

4. **Fetch voucher redemption data**: Report Generation reads voucher records for the period from the Vouchers Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumVouchersDb`
   - Protocol: direct / JDBC

5. **Fetch enrichment data from APIs**: Report Generation calls external API clients to retrieve merchant metadata, deal details, and pricing for the reporting period.
   - From: `reportGenerationService`
   - To: `reportingService_externalApiClients` → `m3Api`, `dcApi`, `continuumPricingApi`, `fedApi`
   - Protocol: REST

6. **Render weekly summary report**: Report Generation aggregates the data and renders the summary using Apache POI (Excel) or Flying Saucer + FreeMarker (PDF).
   - From: `reportGenerationService`
   - To: internal rendering libraries
   - Protocol: direct

7. **Upload report to S3**: S3 Client uploads the rendered summary file to the S3 bucket.
   - From: `reportGenerationService`
   - To: `reportingService_s3Client` → `reportingS3Bucket`
   - Protocol: AWS SDK

8. **Persist file metadata**: Report Generation writes S3 key and file details to the Files Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumFilesDb`
   - Protocol: direct / JDBC

9. **Update report status**: Report Generation updates the report record to `COMPLETE` in the Reporting Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

10. **Send notification**: External API Clients call NOTS to send a notification to relevant merchants or operators that the weekly summary is available.
    - From: `reportingService_externalApiClients`
    - To: `notsApi`
    - Protocol: REST

11. **Release distributed lock**: ShedLock releases the campaign summary job lock.
    - From: `campaignScheduler`
    - To: `continuumReportingDb` (ShedLock table)
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ShedLock already held | Lock not acquired; job skipped | No summary generated for this run; next weekly run will attempt |
| Teradata unavailable | External API Clients exception | Campaign data cannot be fetched; summary generation fails |
| S3 upload failure | S3 Client exception | Rendered report lost; status set to `FAILED` |
| NOTS notification failure | Exception from notsApi call | Report generated and stored; notification not sent; merchants may not be alerted |

## Sequence Diagram

```
campaignScheduler -> continuumReportingDb: ACQUIRE ShedLock
campaignScheduler -> reportGenerationService: generateWeeklyCampaignSummary(period)
reportGenerationService -> teradataWarehouse: QUERY campaign metrics (weekly period)
reportGenerationService -> continuumVouchersDb: SELECT voucher redemption data
reportGenerationService -> reportingService_externalApiClients: fetch merchant, deal, pricing data
reportingService_externalApiClients -> m3Api: GET merchant metadata
reportingService_externalApiClients -> dcApi: GET deal details
reportingService_externalApiClients -> continuumPricingApi: GET pricing data
reportGenerationService -> reportGenerationService: render summary (Excel/PDF)
reportGenerationService -> reportingService_s3Client: upload summary to S3
reportingService_s3Client -> reportingS3Bucket: PUT summary file
reportGenerationService -> continuumFilesDb: INSERT file metadata
reportGenerationService -> continuumReportingDb: UPDATE report status=COMPLETE
reportingService_externalApiClients -> notsApi: POST notification (summary ready)
campaignScheduler -> continuumReportingDb: RELEASE ShedLock
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [Deal Cap Enforcement](deal-cap-enforcement.md), [Report Retry Cleanup](report-retry-cleanup.md)
