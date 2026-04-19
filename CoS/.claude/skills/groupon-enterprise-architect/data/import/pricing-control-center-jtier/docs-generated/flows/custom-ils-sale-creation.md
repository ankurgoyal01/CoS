---
service: "pricing-control-center-jtier"
title: "Custom ILS Sale Creation"
generated: "2026-03-03"
type: flow
flow_name: "custom-ils-sale-creation"
flow_type: asynchronous
trigger: "POST /custom-sales API call (sync intake), followed by CustomILSFetchDealOptionsJob (hourly scheduled, async)"
participants:
  - "salesRep"
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
  - "hiveWarehouse"
  - "continuumPricingService"
  - "messagingSaaS"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# Custom ILS Sale Creation

## Summary

The Custom ILS Sale Creation flow enables data-driven Item Level Sales driven by ML flux model outputs. A user creates a Custom ILS sale via API (providing a name and time window), and the service asynchronously fetches deal options (inventory product IDs and pricing) from Hive-stored model outputs. Once deal options are fetched, validated, and inserted into the database, the sale status transitions to `SCHEDULING_PENDING` and the standard ILS Scheduling flow takes over. For the `LOCAL_ILS` channel, the `CustomILSGoLiveJob` is scheduled to fire at sale start time to send a go-live email notification.

## Trigger

- **Type**: user-action (API call) + schedule (hourly job)
- **Source**: IM, IMTL, or SUPER user calls `POST /custom-sales`; `CustomILSFluxModelSyncJob` and `CustomILSFetchDealOptionsJob` run every hour at :15
- **Frequency**: On-demand (sale creation); hourly (deal options fetch and model sync)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Inventory Manager / IMTL | Creates Custom ILS sale via Control Center UI | `salesRep` |
| Pricing Control Center JTier Service | Handles intake, runs model sync and deal option fetch jobs | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Stores sale, flux run associations, deal options, and division records | `continuumPricingControlCenterJtierPostgres` |
| Hive Warehouse | Provides flux model schedule, model location, and ML model output data | `hiveWarehouse` |
| Pricing Service | Provides product validation data during deal option processing | `continuumPricingService` |
| Messaging SaaS (SMTP) | Receives error notifications and go-live notifications | `messagingSaaS` |

## Steps

1. **User creates Custom ILS sale**: Calls `POST /custom-sales` with sale name, start/end times, and timezone.
   - From: `salesRep`
   - To: `continuumPricingControlCenterJtierService`
   - Protocol: REST

2. **Validate and persist sale**: Service validates sale parameters (lead time: 8 hours; min duration: 24 hours; max duration: 1488 hours); creates sale record with status `NEW` and associated `SaleFluxRun` records linking the sale to model IDs selected by the user.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **CustomILSFluxModelSyncJob syncs model schedule from Hive**: Runs hourly; queries `grp_gdoop_local_ds_db.ils_flux_model_schedule_view` in Hive; compares with `custom_ils_flux_model` PostgreSQL table; truncates and repopulates to ensure consistency.
   - From: `continuumPricingControlCenterJtierService` (Quartz scheduler)
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

4. **CustomILSFetchDealOptionsJob picks up sale**: Hourly job finds sales in `NEW` or `FETCHING_DEAL_OPTIONS` status starting within the next 5 days; updates status to `FETCHING_DEAL_OPTIONS`.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

5. **Find target date and run ID for each model**: For each model ID linked to the sale, queries Hive to find the `target_ils_start_date` closest to (and ≤) the sale start date, then finds the most recent run ID (`max(score_timestamp_in_utc)`) for that target date.
   - From: `continuumPricingControlCenterJtierService`
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

6. **Fetch deal options from model output**: Downloads all deal option rows (inventory product IDs, pricing) for the resolved run ID and target date from the Hive model output table.
   - From: `continuumPricingControlCenterJtierService`
   - To: `hiveWarehouse`
   - Protocol: Hive JDBC

7. **Validate and deduplicate deal options**: Checks for duplicate inventory product IDs and deal permalinks within the fetched set; validates products against Pricing Service as needed.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingService`
   - Protocol: REST (Retrofit)

8. **Persist deal options and divisions**: Inserts valid deal options into `SaleProductFromCsv` table; creates `SaleDivision` records for each unique division; calculates and stores unschedule cutoff time (4 hours before earliest division start time).
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

9. **Transition to scheduling**: Updates sale status to `SCHEDULING_PENDING`; standard `ILSSchedulingJob` flow takes over.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

10. **CustomILSGoLiveJob fires at sale start**: After scheduling completes, `ILSSchedulingJob` schedules `CustomILSGoLiveJob` to fire at sale start time; the job sends a go-live email with sale details, algorithm splits, deal counts, and flux run dates.
    - From: `continuumPricingControlCenterJtierService`
    - To: `messagingSaaS`
    - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive read timeout (model schedule sync) | Up to 7 retry attempts (5-minute intervals); OpsGenie alert after 4-hour failure window | Model schedule data may be stale; manual verification recommended |
| No target date found in Hive for model | Logs `targetStartDate could not be computed`; job marks error | Sale status remains `FETCHING_DEAL_OPTIONS`; reset to `NEW` via API to retry |
| Duplicate deal options detected | Duplicates removed; unique set retained | Sale proceeds with de-duplicated products |
| Deal option validation failure | Error logged; email notification sent to `confirmerEmailId` | Sale status set to error; manual intervention required |
| CustomILSGoLiveJob finds sale not `SALE_SETUP_COMPLETE` | Job exits without sending email | No go-live notification sent |

## Sequence Diagram

```
salesRep -> continuumPricingControlCenterJtierService: POST /custom-sales (name, startTime, endTime)
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Create Sale (NEW) + SaleFluxRun records
continuumPricingControlCenterJtierService -> hiveWarehouse: Sync ils_flux_model_schedule_view (hourly)
hiveWarehouse --> continuumPricingControlCenterJtierService: Model schedule rows
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Update custom_ils_flux_model table
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set sale FETCHING_DEAL_OPTIONS
continuumPricingControlCenterJtierService -> hiveWarehouse: Query target date + run ID for each model
continuumPricingControlCenterJtierService -> hiveWarehouse: Fetch deal options for run ID
hiveWarehouse --> continuumPricingControlCenterJtierService: Deal option rows
continuumPricingControlCenterJtierService -> continuumPricingService: Validate products
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Insert SaleProductFromCsv + SaleDivision
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set SCHEDULING_PENDING
continuumPricingControlCenterJtierService -> messagingSaaS: Send go-live email (at sale start time)
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Scheduling](ils-scheduling.md)
