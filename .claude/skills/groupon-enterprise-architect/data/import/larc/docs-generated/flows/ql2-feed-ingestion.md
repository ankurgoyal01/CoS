---
service: "larc"
title: "QL2 Feed Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "ql2-feed-ingestion"
flow_type: scheduled
trigger: "FTPMonitorWorkerManager scheduler fires on ftpMonitorIntervalInSec interval"
participants:
  - "continuumTravelLarcService"
  - "thirdPartyInventory"
  - "continuumTravelLarcDatabase"
architecture_ref: "dynamic-larc-rate-update-flow"
---

# QL2 Feed Ingestion

## Summary

LARC monitors a QL2-operated FTP/SFTP server for new hotel pricing CSV files. When new files are detected (via MD5 checksum comparison), the worker downloads them to local disk, validates their integrity, and bulk-loads the nightly rate rows into the `NightlyLar` table in the LARC MySQL database. This flow is the entry point for all market pricing data that LARC subsequently uses for LAR computation.

## Trigger

- **Type**: schedule
- **Source**: `FTPMonitorWorkerManager` scheduled worker (starts on `ftpMonitorStartTime`, repeats every `ftpMonitorIntervalInSec` seconds); `FtpDownloadWorker` runs in its own thread on `ftpDownloadIntervalInSec` interval
- **Frequency**: Continuous polling on configured interval (default: 1 second if not overridden in `workerConfig`); production intervals set in the environment YAML config

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LARC Service (Worker Schedulers) | Orchestrates FTP monitoring and file download scheduling | `continuumTravelLarcService` / `larcWorkerSchedulers` |
| LARC Service (External Clients) | Connects to QL2 FTP/SFTP server, downloads CSV files | `continuumTravelLarcService` / `larcExternalClients` |
| QL2 FTP Server | Provides partner hotel pricing CSV feed files | `thirdPartyInventory` |
| LARC Service (Persistence Layer) | Writes ingestion job records and NightlyLar rows | `continuumTravelLarcService` / `larcDataAccess` |
| LARC Database | Stores ingestion job lifecycle and raw nightly LAR data | `continuumTravelLarcDatabase` |

## Steps

1. **Monitor FTP for new files**: `FTPMonitorWorkerManager` scheduler wakes on interval and calls the FTP monitor to list files available on the QL2 FTP/SFTP server.
   - From: `larcWorkerSchedulers`
   - To: `thirdPartyInventory` (QL2 FTP)
   - Protocol: FTP (Apache Commons Net) or SFTP (JSch)

2. **Detect new files via MD5 checksum**: LARC compares the MD5 checksum file (extension from `ftpGlobalConfiguration.md5Extension`, default `_out.csv`) against previously seen checksums to identify new or updated pricing files.
   - From: `larcExternalClients`
   - To: `thirdPartyInventory` (QL2 FTP)
   - Protocol: FTP/SFTP

3. **Create ingestion job record**: For each new file detected, an `IngestionJob` record is created in the LARC database with `stage=QL2_DATA_DOWNLOAD` and `status=DONE`, recording the file path and timestamp.
   - From: `larcRateComputation`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

4. **Download CSV file**: `FtpDownloadWorker` downloads the CSV file from the QL2 FTP server to the local directory (default `/tmp/`). File size download is bounded by `downloadThreshold` configuration.
   - From: `larcExternalClients`
   - To: `thirdPartyInventory` (QL2 FTP)
   - Protocol: FTP/SFTP (binary transfer)

5. **Parse and load CSV rows**: `LoadCsv` parses the downloaded CSV file row by row and bulk-inserts nightly rate records into the `NightlyLar` table, keyed by `roomTypeUuid` and `night`, with the `ql2Timestamp` and `amount` from the feed.
   - From: `larcRateComputation`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL (batch insert)

6. **Update ingestion job status**: The ingestion job record is updated to reflect completion or failure of the load operation.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| QL2 FTP unreachable | FTPMonitorWorker catches exception; no new jobs created | Retried on next scheduler interval; no data gap created for current cycle |
| FTP credential failure | Exception logged; monitor retries on next interval | Stale data until credentials are refreshed in k8s-secrets and pod is restarted |
| CSV parse error | Exception logged as ingestion job failure | Affected rows skipped; partial data may be loaded; job marked failed |
| MD5 mismatch | File treated as corrupt or incomplete | File skipped; retried on next FTP poll when a valid file is available |
| Database write failure | `SQLException` caught; logged as `DB_ERROR` event | Ingestion job fails; no NightlyLar rows written for that file |
| `downloadThreshold` exceeded | Download loop exits early | Remaining files deferred to next worker cycle |

## Sequence Diagram

```
FTPMonitorWorker -> QL2 FTP Server: List files + fetch MD5 checksums
QL2 FTP Server --> FTPMonitorWorker: File listing + MD5 files
FTPMonitorWorker -> LARC Database: Create IngestionJob (QL2_DATA_DOWNLOAD, DONE)
FtpDownloadWorker -> QL2 FTP Server: Download CSV file (binary)
QL2 FTP Server --> FtpDownloadWorker: CSV file bytes
FtpDownloadWorker -> LoadCsv: Parse CSV rows
LoadCsv -> LARC Database: Bulk insert NightlyLar rows
LARC Database --> LoadCsv: Insert confirmation
LoadCsv -> LARC Database: Update IngestionJob status
```

## Related

- Architecture dynamic view: `dynamic-larc-rate-update-flow`
- Related flows: [LAR Computation and Rate Update](lar-computation-rate-update.md)
