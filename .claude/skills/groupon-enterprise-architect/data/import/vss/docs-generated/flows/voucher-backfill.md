---
service: "vss"
title: "Voucher Backfill"
generated: "2026-03-03"
type: flow
flow_name: "voucher-backfill"
flow_type: scheduled
trigger: "Quartz scheduler job (VoucherBackfillScheduler) executing on a periodic schedule"
participants:
  - "continuumVssService"
  - "voucherBackfillScheduler"
  - "voucherUserDataService"
  - "voucherUsersDataDbi"
  - "continuumVssMySql"
  - "continuumVoucherInventoryService"
  - "continuumUsersService"
architecture_ref: "components-vss-searchService-components"
---

# Voucher Backfill

## Summary

The voucher backfill flow re-indexes voucher-user records in VSS MySQL by fetching raw inventory unit data from VIS (v1 or v2) and enriching it with user details from the Users Service. It runs as a Quartz-scheduled background job and serves two purposes: populating the store on initial setup and recovering from any gaps caused by missed JMS events. Backfill can also be triggered manually via the `POST /v1/backfill/units` API endpoint for specific date ranges or unit UUID lists.

## Trigger

- **Type**: schedule (Quartz) or manual api-call
- **Source**: `voucherBackfillScheduler` Quartz job running within `continuumVssService`; also triggerable via `POST /v1/backfill/units`
- **Frequency**: Periodic (configured via Quartz schedule in YAML config); on-demand when triggered via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| VoucherBackfillScheduler | Initiates the backfill cycle; reads unit UUIDs from backfill staging table | `voucherBackfillScheduler` |
| VoucherUserDataService | Orchestrates data read/write during backfill | `voucherUserDataService` |
| VoucherUsersDataDbi | JDBI DAO — reads backfill queue and writes complete records | `voucherUsersDataDbi` |
| VSS MySQL | Backfill staging table (unit UUID queue) and final voucher-user records | `continuumVssMySql` |
| VIS / VIS 2.0 | Provides inventory unit details (UUID, merchant, updatedAt) | `continuumVoucherInventoryService` / VIS 2.0 |
| Users Service | Provides purchaser and consumer account details | `continuumUsersService` |

## Steps

1. **Scheduler fires**: `voucherBackfillScheduler` (Quartz job named `BackfillScheduler`) wakes on schedule. Emits `BackfillScheduler` event metric.
   - From: Quartz scheduler
   - To: `voucherBackfillScheduler`
   - Protocol: scheduled

2. **Reads backfill queue**: `voucherBackfillScheduler` calls `voucherUserDataService` to read a batch of unit UUIDs from the backfill staging table in MySQL. Batch size is controlled by `voucherUnitsBatchSize` config.
   - From: `voucherBackfillScheduler`
   - To: `voucherUserDataService` → `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

3. **Fetches inventory unit details**: For each unit UUID in the batch, VSS calls the appropriate inventory service (VIS v1 or VIS 2.0, determined by `inventoryServiceId`) to retrieve full unit data.
   - From: `voucherUserDataService`
   - To: `continuumVoucherInventoryService` (VIS v1) or VIS 2.0 client
   - Protocol: HTTP/REST (Retrofit2)

4. **Fetches user account details**: For each unit, VSS calls the Users Service to retrieve purchaser and consumer account data (name, email) by account ID.
   - From: `voucherUserDataService`
   - To: `continuumUsersService` — `GET /users/v1/accounts?id={accountId}`
   - Protocol: HTTP/REST (Retrofit2)

5. **Writes complete record**: `voucherUserDataService` calls `voucherUsersDataDbi` to upsert the complete voucher-user record (unit data + user data) into VSS MySQL. Emits `BackfillUnits_Insert_to_DB` event metric.
   - From: `voucherUserDataService`
   - To: `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

6. **Repeats for remaining batches**: Backfill continues processing until the staging queue is exhausted. Concurrency is controlled by `numberOfThreadsForBackfill` config using an `ExecutorServiceManager`.
   - From: `voucherBackfillScheduler`
   - To: next batch iteration
   - Protocol: Java thread pool

## Manual Backfill Trigger (via API)

When `POST /v1/backfill/units` is called with `startDate`/`endDate` query parameters, VSS fetches units updated within that range from the inventory service and inserts them into the backfill staging table for the scheduler to process. Alternatively, explicit unit UUIDs can be submitted in the request body.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS / VIS 2.0 call fails for a unit | Unit skipped for this backfill cycle; retried in next cycle | Metric incremented; no partial write for the failed unit |
| Users Service call fails for a unit | Unit skipped or written without user data depending on implementation | Backfill proceeds for remaining units |
| MySQL write failure | Exception logged; unit may be retried in next scheduler cycle | `BackfillUnits_Insert_to_DB` metric may reflect failure |
| Quartz job disabled (`quartzJobEnable=false`) | Scheduler does not execute | No automated backfill; manual API trigger still available |
| Empty backfill queue | Scheduler completes immediately with no-op | Normal state when real-time events are keeping up |

## Sequence Diagram

```
VoucherBackfillScheduler -> VoucherUserDataService: getBackfillBatch(batchSize)
VoucherUserDataService -> VoucherUsersDataDbi: readBackfillQueue(batchSize)
VoucherUsersDataDbi -> VSSMySQL: SELECT unit_uuids FROM backfill_queue LIMIT N
VSSMySQL --> VoucherUsersDataDbi: [unitUuid, inventoryServiceId]
VoucherUsersDataDbi --> VoucherUserDataService: List<BackfillUnit>

loop for each unit in batch (parallel, numberOfThreadsForBackfill):
  VoucherUserDataService -> VIS/VIS2.0: GET /inventory/v1/units/{uuid}
  VIS/VIS2.0 --> VoucherUserDataService: unit detail (merchantId, updatedAt, ...)
  VoucherUserDataService -> UsersService: GET /users/v1/accounts?id={accountId}
  UsersService --> VoucherUserDataService: user detail (name, email)
  VoucherUserDataService -> VoucherUsersDataDbi: upsert(unit + user data)
  VoucherUsersDataDbi -> VSSMySQL: INSERT ... ON DUPLICATE KEY UPDATE ...
  VSSMySQL --> VoucherUsersDataDbi: OK
end
```

## Related

- Architecture dynamic view: `components-vss-searchService-components`
- Related flows: [Inventory Unit Ingestion](inventory-unit-ingestion.md), [Voucher Search](voucher-search.md)
- API endpoint: `POST /v1/backfill/units` — documented in [API Surface](../api-surface.md)
- Configuration: `voucherUnitsBatchSize`, `numberOfThreadsForBackfill`, `quartzJobEnable` — documented in [Configuration](../configuration.md)
