---
service: "getaways-accounting-service"
title: "Daily CSV Generation and Upload"
generated: "2026-03-03"
type: flow
flow_name: "csv-generation-and-upload"
flow_type: scheduled
trigger: "Kubernetes cron-job at 00:20 UTC daily (schedule: 20 0 * * *)"
participants:
  - "continuumGetawaysAccountingService"
  - "tisPostgres_bf2737"
  - "contentServiceApi_abaf55"
  - "accountingSftpServer_14db43"
architecture_ref: "dynamic-getaways-accounting-csv"
---

# Daily CSV Generation and Upload

## Summary

Each day at 00:20 UTC, a Kubernetes cron-job triggers the `createcsv` admin task on the Getaways Accounting Service. The task queries the TIS PostgreSQL database for all committed and cancelled reservation transactions for the previous day, builds two CSV files (a detail report and a summary report enriched with hotel metadata from the Content Service), generates MD5 checksums, uploads all files to the accounting SFTP server, and validates the upload by re-downloading and comparing checksums.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes cron-job component (`cron-job`) executes `POST /tasks/createcsv` on the app pod
- **Frequency**: Daily at 00:20 UTC (`20 0 * * *` in production)
- **Task name**: `createcsv` (Dropwizard admin task on port 8081)
- **Parameters**: `type=all`, `date={yesterday}`, `upload=true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAS Cron-Job Pod | Invokes the admin task | `continuumGetawaysAccountingService` |
| CSV Generation Task | Orchestrates the entire CSV build, upload, and validation | `continuumGetawaysAccountingService` |
| Reservation Repository / DAO | Queries reservation transactions from TIS PostgreSQL | `continuumGetawaysAccountingService` |
| TIS PostgreSQL | Source of reservation and transaction records | `tisPostgres_bf2737` |
| Summary CSV Builder | Builds summary CSV lines with hotel metadata | `continuumGetawaysAccountingService` |
| Content Service | Provides hotel name and address for summary lines | `contentServiceApi_abaf55` |
| Detail CSV Builder | Builds per-reservation detail CSV lines | `continuumGetawaysAccountingService` |
| CSV Builder | Serialises lines to CSV files on local pod storage | `continuumGetawaysAccountingService` |
| Md5 Builder | Generates MD5 checksum file for each CSV | `continuumGetawaysAccountingService` |
| File Uploader | Uploads CSV and MD5 files via SFTP | `continuumGetawaysAccountingService` |
| SFTP Channel | Executes SFTP upload and download via JSch | `continuumGetawaysAccountingService` |
| CSV Validator | Re-downloads uploaded file and verifies MD5 | `continuumGetawaysAccountingService` |
| Accounting SFTP Server | Receives and stores CSV and checksum files | `accountingSftpServer_14db43` |

## Steps

1. **Receive task invocation**: Kubernetes cron-job posts to `POST /tasks/createcsv?type=all&date={date}&upload=true` on the Dropwizard admin port (8081).
   - From: `cron-job pod`
   - To: `CSV Generation Task` (admin interface)
   - Protocol: HTTP (internal pod)

2. **Check active host**: The task compares the current pod hostname against `csvJobScheduler.activeHost` (set to `${HOSTNAME}` in production). Proceeds only if they match, preventing duplicate execution across replicas.
   - From: `CSV Generation Task`
   - To: JVM `InetAddress.getLocalHost()`
   - Protocol: direct

3. **Query reservation transactions**: Calls `ReservationRepository.findTransactionsByDate(generationDate)`, which executes a SQL UNION query returning COMMITTED reservations (by `commitupdatedat`) and CANCELLED reservations (by `cancelledat`) for the given date.
   - From: `CSV Generation Task`
   - To: `TIS PostgreSQL` via Reservation DAO
   - Protocol: PostgreSQL / JDBI

4. **Build detail CSV**: The Detail CSV Builder generates a `DetailLine` per reservation. Each line is validated to confirm the `Inventory_Product_UUID` field is present in the `customData` column. The CSV Builder writes `getaways_booking_detail_-{date}.csv` to `/var/groupon/jtier/csv/`.
   - From: `Detail CSV Builder`
   - To: local filesystem
   - Protocol: direct

5. **Validate detail CSV (async)**: A background thread reads the written CSV file and logs any lines missing `Inventory_Product_UUID` in the Custom Data column.
   - From: `CSV Generation Task`
   - To: local filesystem (background thread)
   - Protocol: direct (async)

6. **Build summary CSV**: The Summary CSV Builder generates one `SummaryLine` per hotel. For each hotel UUID, it calls the Content Service API to fetch hotel name and address metadata, then writes `getaways_booking_summary_-{date}.csv`.
   - From: `Summary CSV Builder`
   - To: `Content Service API` via Retrofit HTTPS
   - Protocol: HTTPS

7. **Generate MD5 checksums**: The Md5 Builder computes an MD5 hash for each CSV file and writes a corresponding `.md5` file in the same local folder.
   - From: `Md5 Builder`
   - To: local filesystem
   - Protocol: direct

8. **Upload files via SFTP**: The File Uploader iterates over all configured SFTP servers and uploads both the CSV file and its MD5 file.
   - From: `File Uploader` via `SFTP Channel` (JSch)
   - To: `Accounting SFTP Server`
   - Protocol: SFTP

9. **Validate upload integrity**: The CSV Validator downloads the uploaded CSV from the SFTP remote path and verifies it matches the locally generated file (size / content check). Throws `FileIntegrityException` if mismatch is detected.
   - From: `CSV Validator` via `SFTP Channel`
   - To: `Accounting SFTP Server`
   - Protocol: SFTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `csvJobScheduler.activeHost` mismatch | Task logs a message and exits without processing | No CSV generated; no side effects |
| TIS PostgreSQL unavailable | JDBI throws connection exception | Task fails; exception propagates; cron-job pod exits non-zero; alert fires |
| Content Service returns 404 for hotel | `HotelNotFound` exception thrown | Summary CSV generation fails; task aborts |
| SFTP upload failure | JSch exception propagates from `FileUploader` | Task fails; files remain locally staged; alert fires |
| CSV integrity mismatch after upload | `FileIntegrityException` thrown by `CsvValidator` | Task fails with exception; must be re-triggered manually |
| `Inventory_Product_UUID` missing from detail line | Logged at ERROR level; async validation logs summary | Warning only; CSV is still generated and uploaded |
| Duplicate pod execution | `isActiveHost()` check returns false for non-active pods | Silently skipped — no duplicate processing |

## Sequence Diagram

```
CronJob -> CsvGenerationTask: POST /tasks/createcsv?type=all&date=YYYY-MM-DD&upload=true
CsvGenerationTask -> CsvGenerationTask: isActiveHost() check
CsvGenerationTask -> ReservationDAO: findTransactionsByDate(date)
ReservationDAO -> TISPostgres: SQL UNION query (COMMITTED + CANCELLED)
TISPostgres --> ReservationDAO: List<ReservationDBO>
ReservationDAO --> CsvGenerationTask: List<Reservation>
CsvGenerationTask -> DetailCsvBuilder: generateDetailLineList(reservations)
DetailCsvBuilder --> CsvGenerationTask: List<DetailLine>
CsvGenerationTask -> CsvBuilder: generateCsvFile(detail.csv, detailLines)
CsvGenerationTask -> SummaryCsvBuilder: generateSummaryLineList(reservations)
SummaryCsvBuilder -> ContentServiceClient: GET /hotels/{hotelUuid} (per hotel)
ContentServiceClient -> ContentServiceAPI: HTTPS request
ContentServiceAPI --> ContentServiceClient: HotelResponse (name, address)
SummaryCsvBuilder --> CsvGenerationTask: List<SummaryLine>
CsvGenerationTask -> CsvBuilder: generateCsvFile(summary.csv, summaryLines)
CsvGenerationTask -> Md5Builder: generateMd5File(detail.csv)
CsvGenerationTask -> Md5Builder: generateMd5File(summary.csv)
CsvGenerationTask -> FileUploader: uploadFiles([detail.csv, detail.md5])
FileUploader -> SftpChannel: upload to SFTP remote
SftpChannel -> AccountingSftpServer: SFTP PUT
CsvGenerationTask -> FileUploader: uploadFiles([summary.csv, summary.md5])
FileUploader -> SftpChannel: upload to SFTP remote
SftpChannel -> AccountingSftpServer: SFTP PUT
CsvGenerationTask -> CsvValidator: validateReport(detail.csv)
CsvValidator -> SftpChannel: download from SFTP remote
SftpChannel -> AccountingSftpServer: SFTP GET
CsvValidator --> CsvGenerationTask: integrity OK / FileIntegrityException
CsvGenerationTask -> CsvValidator: validateReport(summary.csv)
```

## Related

- Architecture dynamic view: `dynamic-getaways-accounting-csv`
- Related flows: [CSV Upload Validation](csv-upload-validation.md), [Finance Lookup](finance-lookup.md)
