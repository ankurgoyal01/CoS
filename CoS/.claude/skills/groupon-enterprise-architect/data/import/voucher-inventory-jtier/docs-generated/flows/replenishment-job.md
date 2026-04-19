---
service: "voucher-inventory-jtier"
title: "Replenishment Job (Ouroboros)"
generated: "2026-03-03"
type: flow
flow_name: "replenishment-job"
flow_type: scheduled
trigger: "Quartz cron schedule (Ouroboros_Jtier job)"
participants:
  - "continuumVoucherInventoryWorker"
  - "continuumVoucherInventoryRwDb"
  - "continuumVoucherInventoryProductDb"
  - "legacyVoucherInventoryService"
architecture_ref: "components-voucherInventoryWorker"
---

# Replenishment Job (Ouroboros)

## Summary

The Ouroboros replenishment job is a scheduled Quartz task that runs in the Worker container on pods where `ENABLE_OUROBOROS=true` (the `ouroboros-jtier` component). It reads replenishment schedule data from the RW MySQL database, fetches updated inventory schedule information from Legacy VIS (VIS 1.0/2.0) via HTTP, and writes the updated schedules back to the RW database. This flow bridges the legacy VIS inventory scheduling system with VIS 3.0, keeping replenishment configuration synchronized.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler inside `continuumVoucherInventoryWorker` (ouroboros-jtier pods)
- **Frequency**: Production (on-prem SNC1): every ~10 minutes (`0 2,12,22,30,48,58 * * * ?`); Production (cloud): hourly or custom cron; Staging: at 9pm, 10pm, 11pm, and 11:59pm UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Replenishment Job (Quartz) | Scheduled entry point; orchestrates the replenishment cycle | `continuumVoucherInventoryWorker` |
| Inventory DAOs (Worker) | Reads replenishment schedules and product data from MySQL | `continuumVoucherInventoryRwDb`, `continuumVoucherInventoryProductDb` |
| Legacy VIS Client | HTTP client for fetching inventory schedule details from Legacy VIS | `legacyVoucherInventoryService` |
| Inventory DAOs (Worker) | Writes updated replenishment schedules to RW DB | `continuumVoucherInventoryRwDb` |

## Steps

1. **Quartz fires Ouroboros_Jtier job**: The Quartz scheduler triggers the Replenishment Job according to the configured cron expression
   - From: Quartz scheduler (in-process)
   - To: Replenishment Job component (in-process)
   - Protocol: direct

2. **Reads replenishment schedules**: Replenishment Job loads current replenishment schedule records from the RW MySQL database via Inventory DAOs
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryRwDb`
   - Protocol: JDBI/MySQL

3. **Reads product data**: Replenishment Job may also load relevant product records from the Product DB to resolve product context
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryProductDb`
   - Protocol: JDBI/MySQL

4. **Fetches legacy inventory details**: Legacy VIS Client calls Legacy VIS endpoints to retrieve the latest replenishment/inventory schedule data (client ID: `ouroboros-jtier`)
   - From: `continuumVoucherInventoryWorker` (Legacy VIS Client)
   - To: `legacyVoucherInventoryService`
   - Protocol: HTTP (OkHttp/Retrofit); connectTimeout: 1,000ms, readTimeout: 5,000ms

5. **Writes updated schedules to RW DB**: Replenishment Job applies the updates from Legacy VIS to the RW MySQL database via Inventory DAOs
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryRwDb`
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Legacy VIS HTTP timeout | No explicit retry documented | Job cycle fails; replenishment schedules not updated until next cycle |
| MySQL RW DB unavailable | No explicit retry documented | Job cycle fails; schedules remain at previous state |
| Quartz mis-fire | Quartz default mis-fire handling | Job may be skipped or retried depending on Quartz policy |
| Pod restarts between cycles | Quartz job resumes on next cron fire | No data loss; schedules updated on next cycle |

## Sequence Diagram

```
QuartzScheduler    -> ReplenishmentJob:     TRIGGER Ouroboros_Jtier (cron)
ReplenishmentJob   -> WorkerInventoryDaos:  LOAD replenishment schedules
WorkerInventoryDaos -> RwDb:               SELECT replenishment_schedules
RwDb               --> WorkerInventoryDaos: schedule records
WorkerInventoryDaos -> ProductDb:           SELECT product context (optional)
ProductDb          --> WorkerInventoryDaos: product records
ReplenishmentJob   -> WorkerVisClient:      GET inventory schedule details
WorkerVisClient    -> LegacyVIS:            HTTP GET /inventory/schedule/...
LegacyVIS          --> WorkerVisClient:     schedule data
ReplenishmentJob   -> WorkerInventoryDaos:  WRITE updated schedules
WorkerInventoryDaos -> RwDb:               INSERT/UPDATE replenishment_schedules
RwDb               --> WorkerInventoryDaos: OK
```

## Related

- Architecture ref: `components-voucherInventoryWorker`
- Configuration: `canEnableReplenishment` (`ENABLE_OUROBOROS` env var); cron in `quartz` config block
- Related flows: [Unit Redeem Job](unit-redeem-job.md)
- Integrations: [Integrations](../integrations.md) (Legacy VIS Client section)
