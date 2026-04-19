---
service: "pricing-control-center-jtier"
title: "Sellout Program Creation"
generated: "2026-03-03"
type: flow
flow_name: "sellout-program-creation"
flow_type: scheduled
trigger: "SelloutProgramCreatorJob Quartz cron: every 3 hours starting at 4:30 PM UTC (0 30 16/3 1/1 * ? *)"
participants:
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
  - "hdfsStorage"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# Sellout Program Creation

## Summary

The Sellout Program Creation flow automatically creates and schedules ILS sales for the SELLOUT channel by processing flux output files produced by the Data Science team and stored in Gdoop (HDFS). The job runs every 3 hours, checks for new unprocessed files, and — when a new file is available — creates sale and product records in PostgreSQL, then sets the sale status to `SCHEDULING_PENDING` to hand off to the standard ILS Scheduling flow.

## Trigger

- **Type**: schedule
- **Source**: Quartz cron trigger `SelloutProgramCreatorJobTrigger`
- **Frequency**: Every 3 hours starting at 4:30 PM UTC (`0 30 16/3 1/1 * ? *`)
- **Prerequisite**: `jobConfiguration.sellout.enabled` must be `true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pricing Control Center JTier Service | Runs `SelloutProgramCreatorJob`; creates sale/product records | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Stores `SelloutVersion`, sale, and product records | `continuumPricingControlCenterJtierPostgres` |
| HDFS / Gdoop | Provides flux output files listing sellout-eligible products with pricing | `hdfsStorage` |

## Steps

1. **Check job enabled**: Job verifies `jobConfiguration.sellout.enabled` is true; exits early if disabled.
   - From: `continuumPricingControlCenterJtierService` (Quartz scheduler)
   - To: (in-process configuration)
   - Protocol: in-process

2. **Retrieve last processed file**: Queries `SelloutVersion` table in PostgreSQL to find the filename of the last successfully processed flux output file.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **Fetch file list from Gdoop**: Calls Gdoop API to list available flux output files for the sellout model.
   - From: `continuumPricingControlCenterJtierService`
   - To: `hdfsStorage`
   - Protocol: HTTP (Gdoop WebHDFS API)

4. **Check for new file**: Compares latest file in Gdoop against the last processed file name. If no new file, job exits.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

5. **Create SelloutVersion record**: Inserts a new `SelloutVersion` record for the new file to track processing state.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

6. **Download flux output file**: Downloads the new flux output file from Gdoop.
   - From: `continuumPricingControlCenterJtierService`
   - To: `hdfsStorage`
   - Protocol: HTTP (Gdoop WebHDFS API)

7. **Parse flux output**: Parses the file to extract sellout-eligible product records with pricing parameters.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process, opencsv)
   - Protocol: in-process

8. **Group by sale window**: Groups records by unique combination of `start_date` and `end_date` to form distinct sale windows.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

9. **Create Sale and product records**: For each sale window, creates a `Sale` record (channel: `SELLOUT`) and inserts product rows via `SaleProductDAO`.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

10. **Validate sales**: Applies channel-specific validator for SELLOUT channel (lead time: 1 hour).
    - From: `continuumPricingControlCenterJtierService`
    - To: (in-process, ValidatorProvider)
    - Protocol: in-process

11. **Schedule sales**: Sets each valid sale status to `SCHEDULING_PENDING` to hand off to the `ILSSchedulingJob`.
    - From: `continuumPricingControlCenterJtierService`
    - To: `continuumPricingControlCenterJtierPostgres`
    - Protocol: JDBC

12. **Update version status**: Updates `SelloutVersion` record status to `JOB_SUCCESSFULLY_SCHEDULED` on success or an error status on failure.
    - From: `continuumPricingControlCenterJtierService`
    - To: `continuumPricingControlCenterJtierPostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Job disabled | Immediate exit | No processing; no error |
| No new file available | Immediate exit | No processing; current version remains |
| File already processed (duplicate) | Skipped based on version record check | No duplicate sales created |
| Flux output parse error | `SelloutVersion` status set to parse error code | No sales created for that file; next run picks up the same file if it persists |
| Validation failure for a sale | Sale skipped or rejected by validator | Only valid sales scheduled |

## Sequence Diagram

```
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Query last processed file (SelloutVersion)
continuumPricingControlCenterJtierService -> hdfsStorage: List Gdoop flux output files
hdfsStorage --> continuumPricingControlCenterJtierService: File list
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Create SelloutVersion record
continuumPricingControlCenterJtierService -> hdfsStorage: Download flux output file
hdfsStorage --> continuumPricingControlCenterJtierService: File contents
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Insert Sale + SaleProduct records
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set sales to SCHEDULING_PENDING
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Update SelloutVersion to JOB_SUCCESSFULLY_SCHEDULED
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Scheduling](ils-scheduling.md), [RPO Program Creation](rpo-program-creation.md)
