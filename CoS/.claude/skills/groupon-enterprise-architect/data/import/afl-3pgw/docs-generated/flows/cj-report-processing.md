---
service: "afl-3pgw"
title: "CJ Report and Commission Processing"
generated: "2026-03-03"
type: flow
flow_name: "cj-report-processing"
flow_type: scheduled
trigger: "Quartz scheduler — daily jobs (CjReportProcessingJob, CjCommissionsJob)"
participants:
  - "continuumAfl3pgwService"
  - "continuumAfl3pgwDatabase"
  - "cjAffiliate"
architecture_ref: "components-afl3pgw-service"
---

# CJ Report and Commission Processing

## Summary

AFL-3PGW runs daily Quartz jobs that fetch performance reports and commission data from Commission Junction. `CjReportProcessingJob` retrieves the previous day's CJ transaction report (via GraphQL or CSV) and persists the line items into the `network_report` tables. `CjCommissionsJob` fetches advertiser commission data for audit and reconciliation purposes. Both jobs write to the service-owned MySQL database and are monitored by Wavefront alerts that fire if either job fails to run within a 24-hour window.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (MySQL-backed, clustered); configured in service YAML `quartz` block
- **Frequency**: Daily — each job targets the previous calendar day's data

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFL 3PGW Service (Job Orchestration) | Executes `CjReportProcessingJob` and `CjCommissionsJob` | `continuumAfl3pgwService` (`jobOrchestrationComponent`) |
| AFL 3PGW MySQL | Stores fetched report and commission data; tracks job execution state | `continuumAfl3pgwDatabase` |
| Commission Junction | Source of report data (GraphQL API and/or CSV download) | `cjAffiliate` |

## Steps

1. **CjReportProcessingJob triggers**: Quartz fires `CjReportProcessingJob` on its configured daily schedule.
   - From: Quartz scheduler
   - To: `continuumAfl3pgwService` (`jobOrchestrationComponent`)
   - Protocol: in-process

2. **Determine report date**: The job reads the last-run timestamp from the `jobs` table to determine the reporting date (previous day).
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

3. **Fetch CJ report**: The job calls the CJ GraphQL API (via `CJGraphQLHttpClient`) or downloads a CSV report (stored locally at `cjCsvLocalFolderPath`) for the target date.
   - From: `continuumAfl3pgwService` (`affiliateNetworkGatewayComponent`)
   - To: `cjAffiliate` (CJ GraphQL endpoint)
   - Protocol: GraphQL over HTTP (Retrofit `cjGraphQlClient`) or CSV file

4. **Parse and persist report**: Report line items are parsed (using `jackson-dataformat-csv` for CSV, or GraphQL response unmarshalling) and written to the `network_report` table and `cj_report`-related tables.
   - From: `continuumAfl3pgwService` (`persistenceComponent`)
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

5. **Update job checkpoint**: After successful persistence, the job updates its last-run timestamp in the `jobs` table.
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

6. **CjCommissionsJob triggers**: Quartz fires `CjCommissionsJob` on its configured daily schedule.
   - From: Quartz scheduler
   - To: `continuumAfl3pgwService`

7. **Fetch commission data**: The job calls the CJ API to retrieve advertiser commission records for the previous day and writes them to the `cj_commission` tables.
   - From: `continuumAfl3pgwService` (`affiliateNetworkGatewayComponent`)
   - To: `cjAffiliate`
   - Protocol: REST/HTTP or GraphQL (Retrofit `cjGraphQlClient`)

8. **Persist commission data and update checkpoint**: Commission records are written to the database, and the job checkpoint is updated.
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CJ API unavailable or returns error | Failsafe retry up to configured retry limit | Job marked as failed; `AFL-3pGW CJ Report Processing Job Failed` or `CjCommissionsJob Job Not run in last 24 hrs` alert fires |
| All retries exhausted | Exception logged to ELK; job checkpoint NOT updated | Next run will reattempt the same date; if backfilling is required, disable alerts before backfill |
| Report data parsing error | Exception logged; job may partially commit rows before failure | Investigate ELK logs; may require manual backfill of `cj_report` or `cj_commission` tables |

## Sequence Diagram

```
Quartz                -> CjReportProcessingJob:    Trigger (daily)
CjReportProcessingJob -> afl-3pgwDatabase:          READ last-run checkpoint from jobs table
afl-3pgwDatabase      --> CjReportProcessingJob:    Last-run date
CjReportProcessingJob -> cjAffiliate:               GraphQL query or CSV download (previous day report)
cjAffiliate           --> CjReportProcessingJob:    Report data (JSON/CSV)
CjReportProcessingJob -> afl-3pgwDatabase:          INSERT report line items into network_report / cj_report
CjReportProcessingJob -> afl-3pgwDatabase:          UPDATE jobs checkpoint
Quartz                -> CjCommissionsJob:          Trigger (daily)
CjCommissionsJob      -> afl-3pgwDatabase:          READ last-run checkpoint
CjCommissionsJob      -> cjAffiliate:               Fetch commission data
cjAffiliate           --> CjCommissionsJob:         Commission records
CjCommissionsJob      -> afl-3pgwDatabase:          INSERT commission data; UPDATE checkpoint
```

## Related

- Related flows: [CJ Reconciliation and Correction Submission](cj-reconciliation-correction.md)
- Architecture component view: `components-afl3pgw-service`
