---
service: "larc"
title: "LAR Computation and Rate Update"
generated: "2026-03-03"
type: flow
flow_name: "lar-computation-rate-update"
flow_type: scheduled
trigger: "LivePricingWorkerManager scheduler processes queued LivePricingJobs after QL2 ingestion"
participants:
  - "continuumTravelLarcService"
  - "continuumTravelLarcDatabase"
  - "continuumDealCatalogService"
  - "continuumTravelInventoryService"
architecture_ref: "dynamic-larc-rate-update-flow"
---

# LAR Computation and Rate Update

## Summary

After QL2 pricing data has been ingested into the `NightlyLar` table, the live pricing worker processes the queue of `LivePricingJob` records. For each job, `RoomTypeLarCalculator` retrieves active rate plans from the Inventory Service, determines the valid travel window (start/end date range), queries `NightlyLar` for the cheapest rate per night within that window, and publishes the computed QL2 price updates to the Travel Inventory Service. This flow is the core value-add of LARC: converting raw partner pricing data into actionable deal rate updates.

## Trigger

- **Type**: schedule
- **Source**: `LivePricingWorkerManager` scheduler; also triggered indirectly by completed QL2 ingestion jobs creating `LivePricingJob` records
- **Frequency**: Continuous processing on configured interval (`livePricingAlertingEmailIntervalInSec` / `livePricingAlertingEmailStartTime` in `workerConfig`); processing count bounded by `larUpdateThreshold`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LARC Service (Worker Schedulers) | Drives the LAR computation loop | `continuumTravelLarcService` / `larcWorkerSchedulers` |
| LARC Service (Rate Computation) | Executes RoomTypeLarCalculator and LarSender business logic | `continuumTravelLarcService` / `larcRateComputation` |
| LARC Service (Persistence Layer) | Reads NightlyLar records; reads/writes LivePricingJob records | `continuumTravelLarcService` / `larcDataAccess` |
| LARC Database | Stores NightlyLar data and LivePricingJob state | `continuumTravelLarcDatabase` |
| Deal Catalog / Content Service | Provides product set status and rate-plan metadata | `continuumDealCatalogService` |
| Travel Inventory Service | Provides rate-plan details; receives computed LAR updates | `continuumTravelInventoryService` |

## Steps

1. **Dequeue LivePricingJobs**: `LivePricingWorkerManager` reads pending `LivePricingJob` records from the LARC database (bounded by `larUpdateThreshold`).
   - From: `larcWorkerSchedulers`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

2. **Fetch active rate plans from Inventory Service**: For each `LivePricingJob` (keyed by `productSetUuid`), `RoomTypeLarCalculator` calls the Inventory Service to retrieve all rate plans for the room type, or a specific rate plan if `ratePlanUuid` is set.
   - From: `larcExternalClients`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTP/JSON (Retrofit)

3. **Check product set status**: For each active rate plan with a `productSetUuid`, LARC queries the Inventory Service for the product set's status (`finished`, `disabled`, or other valid states). Only rate plans with a valid product set status produce LAR updates.
   - From: `larcExternalClients`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTP/JSON (Retrofit)

4. **Determine travel window**: LARC computes the union date range (`min` start date, `max` end date) across all viable rate plans. Past nights are excluded — the effective start is `max(minDate, today)`.
   - From: `larcRateComputation`
   - To: (internal computation, no external call)
   - Protocol: —

5. **Query NightlyLar for cheapest rate per night**: `NightlyLarConnector.getNightlyLarsWithRoomStartEnd()` retrieves all `NightlyLar` records for the room type within the computed date range. For each night, the record with the latest `ql2Timestamp` is selected; if timestamps are equal, the lower `amount` wins.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

6. **Build rate update payload**: For each viable rate plan, LARC maps the per-night minimum rates into an `InventoryServiceRates` structure, assigning each night's LAR amount as a `ql2Price`.
   - From: `larcRateComputation`
   - To: (internal computation)
   - Protocol: —

7. **Publish QL2 price updates to Inventory Service**: `InventoryServiceClient.updateQl2Prices()` sends the computed nightly rates to `continuumTravelInventoryService` for the hotel/room-type/rate-plan combination.
   - From: `larcExternalClients`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTP/JSON (Retrofit PUT)

8. **Update LivePricingJob status**: The `LivePricingJob` record is marked as processed in the LARC database.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate plan not found in Inventory Service | `LarcException` thrown with HTTP 404 | Job fails; logged; retried on next scheduler cycle |
| Inventory Service timeout (SocketTimeoutException) | Caught; `UPDATE_LAR_TIMED_OUT` event logged | Current rate plan update aborted; other rate plans in same job may still succeed |
| Inventory Service connection error (ConnectException) | Caught; `UPDATE_LAR_FAILURE` event logged | Update skipped; retried on next cycle |
| Product set status is `finished` or `disabled` | `LivePricingUtilities.isValidStatus()` returns false | No `LivePricingJob` created for that product set; no LAR update sent |
| SQL error reading NightlyLar | `SQLException` caught; `DB_ERROR` logged | `LarcException` thrown with HTTP 500; job fails |
| No NightlyLar data for a night | Night is omitted from `InventoryServiceRates` | Only nights with data are sent to Inventory; gaps not backfilled |
| `larUpdateThreshold` exceeded | Processing loop exits early | Remaining jobs deferred to next worker cycle |

## Sequence Diagram

```
LivePricingWorkerManager -> LARC Database: Fetch pending LivePricingJobs
LARC Database --> LivePricingWorkerManager: LivePricingJob records
LivePricingWorkerManager -> Travel Inventory Service: GET rate plans for room type
Travel Inventory Service --> LivePricingWorkerManager: Rate plan list (active, with productSetUuid)
LivePricingWorkerManager -> Travel Inventory Service: GET product set status
Travel Inventory Service --> LivePricingWorkerManager: Product set status (finished/live/etc.)
LivePricingWorkerManager -> LARC Database: Query NightlyLar by roomTypeUuid + date range
LARC Database --> LivePricingWorkerManager: NightlyLar records (night, amount, ql2Timestamp)
LivePricingWorkerManager -> Travel Inventory Service: PUT ql2Prices (computed LAR per night)
Travel Inventory Service --> LivePricingWorkerManager: 200 OK
LivePricingWorkerManager -> LARC Database: Update LivePricingJob status
```

## Related

- Architecture dynamic view: `dynamic-larc-rate-update-flow`
- Related flows: [QL2 Feed Ingestion](ql2-feed-ingestion.md), [On-Demand LAR Send](on-demand-lar-send.md)
