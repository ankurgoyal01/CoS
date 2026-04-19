---
service: "pricing-control-center-jtier"
title: "RPO Program Creation"
generated: "2026-03-03"
type: flow
flow_name: "rpo-program-creation"
flow_type: scheduled
trigger: "RetailPriceOptimizationJob Quartz cron: every 3 hours starting at 4:30 PM UTC (0 30 16/3 1/1 * ? *)"
participants:
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
  - "gcpDynamicPricingBucket"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# RPO Program Creation

## Summary

The Retail Price Optimization (RPO) Program Creation flow automatically creates and schedules indefinite ILS sales for the RPO channel by processing extract files stored in a GCS bucket. The job runs every 3 hours, expects a date-stamped file for the next calendar day (`extract-{nextDayDate}.out`), and — when a new file is present — creates sale and product records and transitions the sale to `SCHEDULING_PENDING`. RPO sales have an indefinite end time (year 2037) and start at 6:30 AM UTC the next day.

## Trigger

- **Type**: schedule
- **Source**: Quartz cron trigger `RetailPriceOptimizationJobTrigger`
- **Frequency**: Every 3 hours starting at 4:30 PM UTC (`0 30 16/3 1/1 * ? *`)
- **Prerequisite**: `jobConfiguration.rpo.enabled` must be `true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pricing Control Center JTier Service | Runs `RetailPriceOptimizationJob`; creates sale/product records | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Stores `RPOVersion`, sale, and product records | `continuumPricingControlCenterJtierPostgres` |
| Dynamic Pricing GCS Bucket | Stores RPO model extract CSV files | `gcpDynamicPricingBucket` |

## Steps

1. **Check job enabled**: Job verifies `jobConfiguration.rpo.enabled` is true; exits early if disabled.
   - From: `continuumPricingControlCenterJtierService` (Quartz scheduler)
   - To: (in-process configuration)
   - Protocol: in-process

2. **Retrieve last processed file**: Queries `RPOVersion` table in PostgreSQL to find the filename of the last successfully processed extract file.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **Compute expected file name**: Constructs the expected filename for the next day: `extract-{nextDayDate}.out`. Validates that the target date matches the next calendar day.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

4. **Check if file is new**: Compares expected filename against the last processed file. If already processed or target date mismatch, job exits.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

5. **Create RPOVersion record**: Inserts a new `RPOVersion` record to track processing state.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

6. **Download extract file from GCS**: Downloads the RPO extract CSV from the configured GCS bucket (`gcpConfiguration.gcpBucket`) using the GCP SDK.
   - From: `continuumPricingControlCenterJtierService`
   - To: `gcpDynamicPricingBucket`
   - Protocol: GCP SDK (google-cloud-storage)

7. **Parse CSV extract**: Parses the CSV file using `CSVFileParser` to extract RPO product records.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process, opencsv)
   - Protocol: in-process

8. **Create Sale record**: Creates a single `Sale` record with:
   - Channel: `RPO`
   - Start time: Next day at 6:30 AM UTC (390 minutes after midnight)
   - End time: Year 2037 (indefinite)
   - Program ID: Configured RPO program ID
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

9. **Insert product records**: Inserts RPO product rows from the parsed CSV into `SaleProduct` (via `SaleProductDAO`).
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

10. **Schedule sale**: Sets sale status to `SCHEDULING_PENDING` to hand off to `ILSSchedulingJob`.
    - From: `continuumPricingControlCenterJtierService`
    - To: `continuumPricingControlCenterJtierPostgres`
    - Protocol: JDBC

11. **Update version status**: Updates `RPOVersion` record to `JOB_SUCCESSFULLY_SCHEDULED` on success or an error status on parse/processing failure.
    - From: `continuumPricingControlCenterJtierService`
    - To: `continuumPricingControlCenterJtierPostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Job disabled | Immediate exit | No processing |
| File already processed | Skipped based on version record check | No duplicate sales created |
| Target date does not match next day | Job exits without processing | Waits for next execution cycle |
| GCS download failure | `RPOVersion` status set to error | No sales created; retried on next job execution |
| CSV parse error | `RPOVersion` status set to parse error | No sales created for that file |

## Sequence Diagram

```
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Query last processed file (RPOVersion)
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Create RPOVersion record
continuumPricingControlCenterJtierService -> gcpDynamicPricingBucket: Download extract-{nextDayDate}.out
gcpDynamicPricingBucket --> continuumPricingControlCenterJtierService: CSV file contents
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Insert Sale (RPO channel, indefinite end) + SaleProduct records
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set sale to SCHEDULING_PENDING
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Update RPOVersion to JOB_SUCCESSFULLY_SCHEDULED
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Scheduling](ils-scheduling.md), [Sellout Program Creation](sellout-program-creation.md)
