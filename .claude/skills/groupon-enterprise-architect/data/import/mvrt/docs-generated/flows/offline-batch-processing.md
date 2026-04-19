---
service: "mvrt"
title: "Offline Search Batch Processing"
generated: "2026-03-03"
type: flow
flow_name: "offline-batch-processing"
flow_type: scheduled
trigger: "node-schedule cron: '0/1 * * * *' (every 1 minute)"
participants:
  - "offlineProcessing"
  - "voucherSearch"
  - "mvrt_fileExport"
  - "apiProxy"
  - "continuumVoucherInventoryService"
  - "continuumDealCatalogService"
  - "continuumM3MerchantService"
  - "aws-s3"
  - "rocketman"
architecture_ref: "dynamic-search_and_redeem_flow"
---

# Offline Search Batch Processing

## Summary

Every minute, the Offline Job Scheduler (`offlineProcessing`) polls the local filesystem directory `CodesForOfflineSearch/Json_Files/` for pending job files. When a job file is found, the scheduler acquires a lock file to prevent concurrent processing, reads the job descriptor, deduplicates codes, and invokes the Voucher Search Engine to process all codes against the downstream Continuum services. Once all voucher records are retrieved and enriched, the scheduler generates an XLSX or CSV report, uploads it to AWS S3, and dispatches a notification email via Rocketman containing the download link. Failed jobs are retried up to 3 times before being dropped, with an error email sent to the originating user.

## Trigger

- **Type**: schedule
- **Source**: `node-schedule` cron expression `'0/1 * * * *'` — fires every minute on the running MVRT application instance
- **Frequency**: Every 1 minute; one job file processed per cycle (lock-serialized)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Offline Job Scheduler (`offlineProcessing`) | Polls filesystem, manages lock, coordinates the full processing pipeline | `offlineProcessing` |
| Voucher Search Engine (`voucherSearch`) | Executes voucher search across downstream services for the batch codes | `voucherSearch` |
| File Export and Report Builder (`mvrt_fileExport`) | Generates XLSX/CSV report from search results | `mvrt_fileExport` |
| API Proxy | Routes all outbound service-client calls | `apiProxy` |
| Voucher Inventory Service | Provides voucher unit data for batch codes | `continuumVoucherInventoryService` |
| Deal Catalog Service | Provides deal/product metadata for enrichment | `continuumDealCatalogService` |
| M3 Merchant Service | Provides merchant name for enrichment | `continuumM3MerchantService` |
| AWS S3 | Receives uploaded XLSX/CSV report for durable storage | `unknown_awss3bucket_da58205c` (stub) |
| Rocketman | Delivers notification email with S3 download link to the originating user | `unknown_rocketman_a99a3cab` (stub) |

## Steps

1. **Poll for job files**: Scheduler fires every minute; reads `CodesForOfflineSearch/Json_Files/` directory; identifies the oldest `.json` file (FIFO ordering, excludes already-`completed`-suffix files).
   - From: `offlineProcessing` (cron trigger)
   - To: Local filesystem
   - Protocol: Filesystem read

2. **Acquire lock**: Acquires `CodesForOfflineSearch/sample.lock` with a 4-hour stale timeout. If locked, skips this cycle and logs `[JOB-INFO] One Job already in progress`.
   - From: `offlineProcessing` (internal)
   - Protocol: `lockfile` library

3. **Parse job descriptor**: Reads and parses the oldest JSON file; extracts `user_email`, `user_name`, `user_firstname`, `user_lastname`, `user_groups`, `Code.codes`, `Code.codetype`, `Code.fileType`, `i18n_country`, `host_name`, `all_countries_reqd`.
   - From: `offlineProcessing` (internal)
   - Protocol: Filesystem read + JSON.parse

4. **Deduplicate codes**: Identifies and removes duplicate code entries from the codes array before processing; records duplicate count for inclusion in the result email.
   - From: `offlineProcessing` (internal)
   - Protocol: Direct (in-process, using lodash `_.countBy`)

5. **Execute voucher search**: Invokes `searchVouchers.getAllVouchers` with the full code list, code type, chunk sizes, country config, and all downstream service clients. Search is chunked per code type (same logic as online search).
   - From: `offlineProcessing` → `voucherSearch`
   - To: `apiProxy` → `continuumVoucherInventoryService`, `continuumDealCatalogService`, `continuumM3MerchantService`
   - Protocol: REST via service clients

6. **Generate XLSX or CSV report**: If vouchers were found, `excelHelper.exportSearchReport` generates a local XLSX file in `CodesForOfflineSearch/Excel_Files/<fileName>.xlsx` (or `.csv` if `fileType` is CSV).
   - From: `mvrt_fileExport`
   - To: Local filesystem
   - Protocol: Filesystem write (`exceljs` / `fast-csv`)

7. **Upload report to S3**: Uploads the local XLSX/CSV file to the configured S3 bucket using the `aws-sdk` / `s3-client`; constructs download link `http://<hostName>/downloadFile?report=<fileName>`.
   - From: `mvrt_fileExport`
   - To: AWS S3
   - Protocol: AWS SDK (`uploadFile`)

8. **Delete local report file**: After successful S3 upload, deletes the local XLSX/CSV file from `CodesForOfflineSearch/Excel_Files/`.
   - From: `offlineProcessing` (internal)
   - Protocol: Filesystem unlink

9. **Send success email via Rocketman**: Calls `rocketmanClient.sendEmail` with the S3 download link, search summary (submitted codes count, code type, not-found count, duplicate count), and user destination email. Queue: `cs_deal_notice`.
   - From: `offlineProcessing`
   - To: Rocketman (`@grpn/rocketman-client`)
   - Protocol: REST SDK

10. **Clean up job file and release lock**: Deletes the processed JSON file from `CodesForOfflineSearch/Json_Files/`; releases the lock file.
    - From: `offlineProcessing` (internal)
    - Protocol: Filesystem unlink + lockfile.unlock

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Lock file already held | Skip processing this cycle; log `[JOB-INFO]` | Next cycle will retry |
| Error acquiring lock | Log `[JOB-ERROR]`; do not process | Next cycle will retry |
| JSON parse error on job file | `handleJSONFileError` called; file renamed with error suffix (attempt 1-2) | Retried up to `MAX_ATTEMPT_COUNT` (3) times; then file deleted and error email sent |
| Voucher search fails | `handleJSONFileError` called | Same retry-then-error-email strategy |
| XLSX/CSV generation fails | `handleJSONFileError` called | Same retry-then-error-email strategy |
| S3 upload fails | `handleJSONFileError` called; `[FILE-UPLOAD-FAILURE]` logged | Same retry-then-error-email strategy |
| Rocketman email fails | Retried up to `MAX_ATTEMPT_COUNT` (3) times; logged as `[MAIL-NOT-SENT]` | Job file still deleted after first failure; user does not receive notification |
| No vouchers found | Skip report generation; send email with zero-voucher summary | User receives email with summary but no download link |

## Sequence Diagram

```
node-schedule -> offlineProcessing: cron fire (every 1 minute)
offlineProcessing -> filesystem: readdir(Json_Files/)
filesystem --> offlineProcessing: [job files]
offlineProcessing -> filesystem: lock(sample.lock)
offlineProcessing -> filesystem: readFile(oldest .json)
filesystem --> offlineProcessing: job descriptor JSON
offlineProcessing -> offlineProcessing: deduplicate codes
offlineProcessing -> voucherSearch: getAllVouchers(codes, codeType, ...)
voucherSearch -> apiProxy: search VIS, DealCatalog, M3 (chunked)
apiProxy -> continuumVoucherInventoryService: search/redeem
apiProxy -> continuumDealCatalogService: getDeal
apiProxy -> continuumM3MerchantService: getMerchant
voucherSearch --> offlineProcessing: enriched voucher results
offlineProcessing -> mvrt_fileExport: exportSearchReport(vouchers, filePath, fileType)
mvrt_fileExport -> filesystem: write Excel_Files/<name>.xlsx
offlineProcessing -> aws-s3: uploadFile(localReport, bucketName, fileName)
aws-s3 --> offlineProcessing: upload success
offlineProcessing -> filesystem: unlink(local report)
offlineProcessing -> rocketman: sendEmail(to, subject, htmlBody with S3 link)
rocketman --> offlineProcessing: success
offlineProcessing -> filesystem: unlink(job .json) + unlock(sample.lock)
```

## Related

- Architecture dynamic view: `dynamic-search_and_redeem_flow`
- Related flows: [Offline Search Job Submission](offline-job-submission.md), [Offline Report Download](offline-report-download.md)
