---
service: "reporting-service"
title: "Report Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "report-generation"
flow_type: synchronous
trigger: "API call — POST /reports/v1/reports"
participants:
  - "reportingService_apiControllers"
  - "reportGenerationService"
  - "reportingService_persistenceDaos"
  - "reportingService_externalApiClients"
  - "reportingService_s3Client"
  - "continuumReportingDb"
  - "continuumFilesDb"
  - "continuumVouchersDb"
  - "continuumEuVoucherDb"
  - "reportingS3Bucket"
  - "continuumPricingApi"
architecture_ref: "Reporting-API-Components"
---

# Report Generation

## Summary

A merchant or internal tool submits a report generation request via `POST /reports/v1/reports`. The `reportingService_apiControllers` component receives the request, persists it, and delegates to `reportGenerationService`, which fetches deal, merchant, voucher, and pricing data from multiple sources, renders the report in the requested format (Excel, CSV, or PDF), uploads the artifact to S3, and records the file metadata. The caller can then download the completed report via `GET /reports/v1/reports/{id}`.

## Trigger

- **Type**: api-call
- **Source**: Merchant portal or internal client calling `POST /reports/v1/reports`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives HTTP request, validates input, persists report request, delegates to generation | `reportingService_apiControllers` |
| Report Generation | Orchestrates data fetch, rendering, and artifact storage | `reportGenerationService` |
| Persistence Layer | Reads voucher/reporting data; writes report status and file metadata | `reportingService_persistenceDaos` |
| External API Clients | Fetches merchant, deal, pricing, taxonomy, and inventory data | `reportingService_externalApiClients` |
| S3 Client | Uploads rendered report artifact | `reportingService_s3Client` |
| Reporting Database | Stores report request and status | `continuumReportingDb` |
| Files Database | Stores file metadata (S3 key, MIME type) after upload | `continuumFilesDb` |
| Vouchers Database | Source of voucher redemption data for report calculations | `continuumVouchersDb` |
| EU Voucher Database | Source of EU-specific voucher data | `continuumEuVoucherDb` |
| Report S3 Bucket | Persists the rendered report file | `reportingS3Bucket` |
| Continuum Pricing API | Provides pricing data for deal value calculations | `continuumPricingApi` |

## Steps

1. **Receive report request**: Client sends `POST /reports/v1/reports` with report type, merchant ID, and date range.
   - From: `external client`
   - To: `reportingService_apiControllers`
   - Protocol: REST

2. **Persist report request**: Controllers write a new report record with status `PENDING` to the reporting database.
   - From: `reportingService_apiControllers`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

3. **Delegate to report generation**: Controllers submit the generation request to the Report Generation component.
   - From: `reportingService_apiControllers`
   - To: `reportGenerationService`
   - Protocol: direct

4. **Fetch voucher data**: Report Generation reads voucher redemption records from the voucher and EU voucher databases.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumVouchersDb`, `continuumEuVoucherDb`
   - Protocol: direct / JDBC

5. **Fetch external enrichment data**: Report Generation calls external API clients to retrieve deal metadata, merchant info, pricing, orders, taxonomy, UGC reviews, and other enrichment data.
   - From: `reportGenerationService`
   - To: `reportingService_externalApiClients` → `continuumPricingApi`, `dcApi`, `m3Api`, `giaApi`, `ordersApi`, `ugcApi`, `taxonomyApi`, `visApi`, `rrApi`, `geoplacesApi`, `localizeApi`, `bookingToolApi`, `fedApi`
   - Protocol: REST (HTTP/JSON)

6. **Render report**: Report Generation uses Apache POI (Excel), SuperCSV (CSV), or Flying Saucer + FreeMarker (PDF) to render the report file in the requested format.
   - From: `reportGenerationService`
   - To: internal rendering libraries
   - Protocol: direct

7. **Upload artifact to S3**: Report Generation uploads the rendered file to the S3 bucket via the S3 Client.
   - From: `reportGenerationService`
   - To: `reportingService_s3Client` → `reportingS3Bucket`
   - Protocol: AWS SDK

8. **Persist file metadata**: Report Generation writes the S3 key, MIME type, and file size to the Files Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumFilesDb`
   - Protocol: direct / JDBC

9. **Update report status**: Report Generation updates the report record status to `COMPLETE` in the Reporting Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

10. **Download report**: Client calls `GET /reports/v1/reports/{id}`; Controllers look up file metadata and stream the S3 artifact back.
    - From: `external client`
    - To: `reportingService_apiControllers` → `reportingService_s3Client` → `reportingS3Bucket`
    - Protocol: REST / AWS SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| External API unavailable | No circuit breaker evidence; request likely fails with exception | Report status set to `FAILED`; client must retry |
| S3 upload failure | S3 Client throws exception; generation pipeline aborts | Report status set to `FAILED`; file metadata not written |
| Database write failure | Hibernate exception propagates | Report request persisted but status may remain `PENDING`; cleanup flow handles stale records |
| Rendering error (corrupt data) | Exception from POI/SuperCSV/Flying Saucer | Report status set to `FAILED`; no artifact uploaded |

## Sequence Diagram

```
Client -> reportingService_apiControllers: POST /reports/v1/reports
reportingService_apiControllers -> continuumReportingDb: INSERT report record (status=PENDING)
reportingService_apiControllers -> reportGenerationService: generateReport(reportRequest)
reportGenerationService -> continuumVouchersDb: SELECT voucher data
reportGenerationService -> continuumEuVoucherDb: SELECT EU voucher data
reportGenerationService -> reportingService_externalApiClients: fetch deal, merchant, pricing data
reportingService_externalApiClients -> continuumPricingApi: GET pricing data
reportGenerationService -> reportingService_s3Client: upload rendered file
reportingService_s3Client -> reportingS3Bucket: PUT report artifact
reportGenerationService -> continuumFilesDb: INSERT file metadata (S3 key)
reportGenerationService -> continuumReportingDb: UPDATE report status=COMPLETE
reportGenerationService --> reportingService_apiControllers: report ID
reportingService_apiControllers --> Client: 200 OK { reportId }

Client -> reportingService_apiControllers: GET /reports/v1/reports/{id}
reportingService_apiControllers -> continuumFilesDb: SELECT file metadata by report ID
reportingService_apiControllers -> reportingService_s3Client: download artifact
reportingService_s3Client -> reportingS3Bucket: GET report artifact
reportingService_s3Client --> reportingService_apiControllers: file bytes
reportingService_apiControllers --> Client: 200 OK [file download]
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Bulk Redemption Processing](bulk-redemption-processing.md), [Report Retry Cleanup](report-retry-cleanup.md), [Weekly Campaign Summary](weekly-campaign-summary.md)
