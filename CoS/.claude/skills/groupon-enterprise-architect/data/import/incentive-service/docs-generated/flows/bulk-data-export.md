---
service: "incentive-service"
title: "Bulk Data Export"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bulk-data-export"
flow_type: batch
trigger: "API call — POST /bulk-export/start"
participants:
  - "continuumIncentiveService"
  - "incentiveApi"
  - "incentiveBackgroundJobs"
  - "incentiveDataAccess"
  - "continuumIncentivePostgres"
  - "continuumIncentiveCassandra"
architecture_ref: "dynamic-incentive-request-flow"
---

# Bulk Data Export

## Summary

The bulk data export flow generates a CSV file containing all redemption and qualification records for a specified date range. An HTTP request enqueues an Akka job that reads from both Cassandra and PostgreSQL, assembles the export dataset, writes it to shared storage, and tracks job progress in PostgreSQL. The caller polls a status endpoint to determine when the export is ready. This flow is only active when `SERVICE_MODE=bulk`.

## Trigger

- **Type**: api-call
- **Source**: Data team, analytics consumers, or reporting systems
- **Frequency**: On-demand; typically daily or weekly batch exports

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Data / Analytics Caller | Requests the export and polls for completion | — |
| Incentive Service (API) | Receives export request and enqueues the job | `incentiveApi` |
| Background Jobs | Akka actor that executes the CSV generation job | `incentiveBackgroundJobs` |
| Incentive Data Access | Queries Cassandra for redemption and qualification records; queries PostgreSQL for incentive metadata and job state | `incentiveDataAccess` |
| Incentive Cassandra / Keyspaces | Source of redemption and qualification records | `continuumIncentiveCassandra` |
| Incentive PostgreSQL | Holds incentive metadata for enrichment; tracks export job state | `continuumIncentivePostgres` |

## Steps

1. **Receive export request**: Caller calls `POST /bulk-export/start` with a date range and optionally a filter (e.g., campaign ID, export type).
   - From: Data / Analytics Caller
   - To: `incentiveApi`
   - Protocol: REST/HTTP

2. **Create export job record**: `incentiveApi` creates a job record in PostgreSQL with status `pending` and returns a `jobId` to the caller.
   - From: `incentiveApi`
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

3. **Enqueue Akka bulk export job**: `incentiveApi` submits the export job to `incentiveBackgroundJobs`, passing the job ID and export parameters.
   - From: `incentiveApi`
   - To: `incentiveBackgroundJobs`
   - Protocol: in-process (Akka message)

4. **Update job status to in-progress**: The Akka actor updates the job record in PostgreSQL to `in-progress` before beginning data access.
   - From: `incentiveBackgroundJobs`
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

5. **Query Cassandra for redemption records**: `incentiveDataAccess` reads all redemption records within the requested date range from Cassandra (or Keyspaces).
   - From: `incentiveBackgroundJobs` (via `incentiveDataAccess`)
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

6. **Query Cassandra for qualification records**: `incentiveDataAccess` reads all qualification results within the date range.
   - From: `incentiveBackgroundJobs` (via `incentiveDataAccess`)
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

7. **Query PostgreSQL for incentive metadata**: `incentiveDataAccess` fetches incentive definitions to enrich the export rows (e.g., campaign name, discount type).
   - From: `incentiveBackgroundJobs` (via `incentiveDataAccess`)
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

8. **Generate CSV**: The Akka actor assembles the combined dataset and generates a CSV file. The feature flag `incentive.bulkExportV2` controls which CSV format is used.
   - From: `incentiveBackgroundJobs`
   - To: internal
   - Protocol: in-process

9. **Write CSV to shared storage**: The generated CSV is written to the configured shared storage location (path details managed externally).
   - From: `incentiveBackgroundJobs`
   - To: shared storage
   - Protocol: > No evidence found in codebase.

10. **Update job status to complete**: The Akka actor updates the job record in PostgreSQL to `complete` with the storage path and record count.
    - From: `incentiveBackgroundJobs`
    - To: `continuumIncentivePostgres`
    - Protocol: JDBC/PostgreSQL

11. **Poll for completion** (repeated): Caller polls `GET /bulk-export/:jobId/status` until the status is `complete` or `failed`.
    - From: Data / Analytics Caller
    - To: `incentiveApi`
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cassandra read timeout on large date range | Retry with backoff; consider narrowing date range | Job fails if all retries exhausted; caller resubmits with smaller range |
| PostgreSQL unavailable | Job fails immediately; status updated to `failed` | Caller must resubmit once PostgreSQL recovers |
| Akka actor failure | Actor restarts per supervision strategy; job status reflects `failed` | Caller must resubmit via `POST /bulk-export/start` |
| CSV write to storage fails | Retry write; job status updated to `failed` if unrecoverable | No partial export delivered; caller resubmits |
| `incentive.bulkExportV2` flag | Selects new CSV format when enabled | Different output schema; callers must be prepared for both formats during rollout |

## Sequence Diagram

```
DataCaller -> incentiveApi: POST /bulk-export/start { dateFrom: D1, dateTo: D2 }
incentiveApi -> continuumIncentivePostgres: INSERT INTO export_jobs (status: "pending")
continuumIncentivePostgres --> incentiveApi: jobId: J
incentiveApi --> DataCaller: 202 Accepted { jobId: J }
incentiveApi -> incentiveBackgroundJobs: enqueue BulkExportJob(J, D1, D2)
incentiveBackgroundJobs -> continuumIncentivePostgres: UPDATE export_jobs SET status = "in-progress" WHERE id = J
incentiveBackgroundJobs -> continuumIncentiveCassandra: SELECT redemptions WHERE redeemed_at BETWEEN D1 AND D2
continuumIncentiveCassandra --> incentiveBackgroundJobs: redemption records
incentiveBackgroundJobs -> continuumIncentiveCassandra: SELECT qualification_results WHERE evaluated_at BETWEEN D1 AND D2
continuumIncentiveCassandra --> incentiveBackgroundJobs: qualification records
incentiveBackgroundJobs -> continuumIncentivePostgres: SELECT incentive metadata
continuumIncentivePostgres --> incentiveBackgroundJobs: incentive definitions
incentiveBackgroundJobs -> incentiveBackgroundJobs: generate CSV
incentiveBackgroundJobs -> sharedStorage: write export-J.csv
incentiveBackgroundJobs -> continuumIncentivePostgres: UPDATE export_jobs SET status = "complete", path = "export-J.csv"
DataCaller -> incentiveApi: GET /bulk-export/J/status
incentiveApi --> DataCaller: { status: "complete", path: "export-J.csv", rowCount: N }
```

## Related

- Architecture dynamic view: `dynamic-incentive-request-flow`
- Related flows: [Audience Qualification](audience-qualification.md)
