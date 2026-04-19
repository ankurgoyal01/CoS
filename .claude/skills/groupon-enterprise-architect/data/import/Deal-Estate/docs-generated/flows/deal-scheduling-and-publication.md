---
service: "Deal-Estate"
title: "Deal Scheduling and Publication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-scheduling-and-publication"
flow_type: synchronous
trigger: "API call — POST /deals/:id/schedule or POST /api/v1/deals/:id/schedule"
participants:
  - "continuumDealEstateWeb"
  - "continuumDealEstateMysql"
  - "continuumDealEstateRedis"
  - "continuumDealEstateScheduler"
  - "continuumDealEstateWorker"
  - "continuumDealCatalogService"
  - "continuumDealManagementApi"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-deal-scheduling-and-publication"
---

# Deal Scheduling and Publication

## Summary

This flow handles the scheduling of a deal for time-bounded publication. The web layer validates that the deal is in a schedulable state, records the schedule in MySQL, and coordinates with Deal Catalog and Deal Management API to propagate the schedule. The Resque Scheduler ensures that timed publication and unscheduling jobs fire at the correct times. Distribution windows are also managed as part of this flow.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling or Continuum services calling `POST /deals/:id/schedule` or `POST /api/v1/deals/:id/schedule`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Estate Web | Receives schedule request, validates schedulability, persists schedule | `continuumDealEstateWeb` |
| Deal Estate MySQL | Stores schedule state and distribution windows | `continuumDealEstateMysql` |
| Deal Estate Redis | Holds Resque scheduled job definitions | `continuumDealEstateRedis` |
| Deal Estate Scheduler | Enqueues timed publish/unschedule jobs at the correct time | `continuumDealEstateScheduler` |
| Deal Estate Workers | Executes scheduled publish/unschedule jobs | `continuumDealEstateWorker` |
| Deal Catalog Service | Receives schedule propagation to align catalog-side deal state | `continuumDealCatalogService` |
| Deal Management API | Updated with schedule data | `continuumDealManagementApi` |
| Voucher Inventory Service | Confirms or updates inventory for the scheduled deal | `continuumVoucherInventoryService` |

## Steps

1. **Receive schedule request**: Caller submits `POST /deals/:id/schedule` or `POST /api/v1/deals/:id/schedule` with schedule parameters.
   - From: `caller`
   - To: `continuumDealEstateWeb`
   - Protocol: REST

2. **Check schedulability**: Validates deal state via `state_machine` and checks `GET /api/v1/deals/:id/schedulable` conditions (deal must not be already scheduled, archived, or closed).
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateWeb` (internal) + `continuumDealEstateMysql`
   - Protocol: direct / SQL

3. **Persist schedule and distribution windows**: Updates deal record with schedule dates and writes distribution windows to MySQL.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

4. **Propagate schedule to Deal Catalog**: Notifies Deal Catalog of the scheduled deal to align catalog-side state.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealCatalogService`
   - Protocol: REST (service-client)

5. **Update Deal Management API**: Writes schedule data to Deal Management API.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealManagementApi`
   - Protocol: REST (service-client)

6. **Confirm voucher inventory**: Validates inventory availability with Voucher Inventory Service for the scheduled period.
   - From: `continuumDealEstateWeb`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST (service-client)

7. **Enqueue timed publication job**: Scheduler registers a delayed Resque job to trigger deal publication at the scheduled start time.
   - From: `continuumDealEstateScheduler`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

8. **Execute publication job at scheduled time**: Worker dequeues and executes the publication job, transitioning deal state to published.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

9. **Return response to caller**: Returns updated deal record with schedule confirmation.
   - From: `continuumDealEstateWeb`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not in schedulable state | state_machine validation failure | HTTP 422; schedule rejected |
| MySQL write failure | ActiveRecord exception; transaction rolled back | HTTP 500; schedule not persisted |
| Deal Catalog unavailable | service-client timeout/error | HTTP 502 or 500; schedule may not propagate to catalog |
| Deal Management API unavailable | service-client timeout/error | HTTP 502 or 500; schedule may not propagate |
| Voucher Inventory Service unavailable | service-client timeout/error | HTTP 502 or 500; schedule blocked |
| Scheduled job failure at publish time | Resque retry with backoff | Deal may not publish on time; visible in Resque Web UI |

## Sequence Diagram

```
caller -> continuumDealEstateWeb: POST /deals/:id/schedule
continuumDealEstateWeb -> continuumDealEstateMysql: validate deal state + fetch record
continuumDealEstateWeb -> continuumDealEstateMysql: UPDATE schedule + distribution_windows
continuumDealEstateWeb -> continuumDealCatalogService: propagate schedule
continuumDealEstateWeb -> continuumDealManagementApi: update schedule data
continuumDealEstateWeb -> continuumVoucherInventoryService: confirm inventory
continuumDealEstateScheduler -> continuumDealEstateRedis: enqueue timed publish job
continuumDealEstateWeb --> caller: 200 OK / updated deal
--- (at scheduled time) ---
continuumDealEstateWorker -> continuumDealEstateRedis: dequeue publish job
continuumDealEstateWorker -> continuumDealEstateMysql: transition deal state to published
```

## Related

- Architecture dynamic view: `dynamic-deal-scheduling-and-publication`
- Related flows: [Deal Creation and Import](deal-creation-and-import.md), [Deal State Sync from Catalog](deal-state-sync-from-catalog.md)
