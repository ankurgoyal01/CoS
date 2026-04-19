---
service: "pricing-control-center-jtier"
title: "Analytics Upload"
generated: "2026-03-03"
type: flow
flow_name: "analytics-upload"
flow_type: scheduled
trigger: "AnalyticsUploadJob Quartz cron: every hour (0 0 0/1 * * ?)"
participants:
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# Analytics Upload

## Summary

The Analytics Upload flow ensures that scheduled product data is propagated to analytics systems (internal log raw tables in PostgreSQL and external Teradata log raw tables) after a sale completes scheduling. It also handles deletion of analytics records for sales that have been unscheduled. The job processes one sale per execution cycle (oldest first) to avoid overwhelming external analytics systems, and only handles sales within the last 15 days.

## Trigger

- **Type**: schedule
- **Source**: Quartz cron trigger `AnalyticsUploadJobTrigger`
- **Frequency**: Every hour (`0 0 0/1 * * ?`)
- **Scope**: Only processes channels with log raw insertion enabled (`ChannelUtil.isLogRawInsertionEnabled`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pricing Control Center JTier Service | Runs `AnalyticsUploadJob`; performs log raw inserts and deletes | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Source of scheduled product records; destination for internal log raw data | `continuumPricingControlCenterJtierPostgres` |

Note: External Teradata analytics tables are also a destination but are accessed via the `LogRawUploader` component; Teradata is not modeled as a separate architecture container in the DSL.

## Steps

### Insertion Path (for newly scheduled sales)

1. **Find sales pending analytics upload**: Queries PostgreSQL for sales in `SALE_SETUP_COMPLETE` status with analytics status `UPLOADING_PENDING` or `UPLOADING_FAILED`; selects the oldest one; limits to sales from the last 15 days.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

2. **Check channel eligibility**: Skips the sale if its channel does not have log raw insertion enabled per `ChannelUtil`.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

3. **Retrieve scheduled products**: Loads all product records with `SCHEDULED` status and valid quote IDs for the selected sale.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

4. **Insert into internal log raw table**: For products not already present, inserts records into the internal log raw table (`log_raw_internal`) in PostgreSQL.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

5. **Insert into external log raw table (Teradata)**: For products not already present in Teradata, inserts records into the external log raw table via `LogRawUploader`.
   - From: `continuumPricingControlCenterJtierService`
   - To: Teradata (external analytics store, accessed via `LogRawUploader`)
   - Protocol: JDBC (Teradata driver)

6. **Update analytics status**: Sets sale analytics status to `UPLOADING_SUCCESS` on completion.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

### Deletion Path (for unscheduled sales)

1. **Find unscheduled sales with pending analytics deletion**: Queries PostgreSQL for sales in `UNSCHEDULING_ENDED` status with analytics status `UPLOADING_FAILED`.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

2. **Delete from internal log raw**: Removes product records from `log_raw_internal` for the unscheduled sale.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **Delete from external log raw (Teradata)**: Removes product records from the Teradata external log raw table.
   - From: `continuumPricingControlCenterJtierService`
   - To: Teradata (via `LogRawUploader`)
   - Protocol: JDBC (Teradata driver)

4. **Update analytics status**: Sets sale analytics status to `UPLOADING_SUCCESS` after successful deletion.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata insert fails | Analytics status remains `UPLOADING_FAILED`; retried on next hourly execution | Data eventually consistent once Teradata recovers |
| Sale older than 15 days | Skipped | No analytics upload attempted for old sales |
| Channel not eligible for log raw | Skipped | No analytics data written for that channel |
| Deletion from Teradata fails | Analytics status remains `UPLOADING_FAILED`; retried by next execution | Stale Teradata records until deletion succeeds |

## Sequence Diagram

```
# Insertion path
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Find SALE_SETUP_COMPLETE sale with UPLOADING_PENDING analytics status
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Load SCHEDULED products with quote IDs
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Insert into log_raw_internal (missing records)
continuumPricingControlCenterJtierService -> Teradata: Insert into external log raw (missing records)
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set analytics_status = UPLOADING_SUCCESS

# Deletion path
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Find UNSCHEDULING_ENDED sale with UPLOADING_FAILED analytics status
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Delete from log_raw_internal
continuumPricingControlCenterJtierService -> Teradata: Delete from external log raw
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set analytics_status = UPLOADING_SUCCESS
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Scheduling](ils-scheduling.md), [ILS Unscheduling](ils-unscheduling.md)
