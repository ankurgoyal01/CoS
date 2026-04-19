---
service: "pricing-control-center-jtier"
title: "ILS Scheduling"
generated: "2026-03-03"
type: flow
flow_name: "ils-scheduling"
flow_type: asynchronous
trigger: "Sale status set to SCHEDULING_PENDING via POST /sales/{id}/schedule or by CheckForPendingSalesJob"
participants:
  - "salesRep"
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
  - "continuumVoucherInventoryService"
  - "continuumPricingService"
  - "messagingSaaS"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# ILS Scheduling

## Summary

The ILS Scheduling flow is the core operational process of the Control Center. It takes a sale from `SCHEDULING_PENDING` status and creates active pricing programs for all included products in the Pricing Service. The flow is split into an orchestrator job (`ILSSchedulingJob`) that partitions products into batches, and multiple parallel sub-jobs (`ILSSchedulingSubJob`) that call the Pricing Service bulk API per batch. Once all sub-jobs complete, the orchestrator marks the sale as `SALE_SETUP_COMPLETE` or `SCHEDULING_FAILED`.

## Trigger

- **Type**: user-action (via `POST /sales/{id}/schedule`) + schedule (via `CheckForPendingSalesJob`)
- **Source**: An IMTL or SUPER user schedules a sale in the Control Center UI, or the 15-minute polling job detects a sale in `SCHEDULING_PENDING` status
- **Frequency**: On-demand (user-triggered) or every 15 minutes (job-triggered for pending/retry cases)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative / IMTL | Initiates scheduling action via UI | `salesRep` |
| Pricing Control Center JTier Service | Orchestrates scheduling; runs `ILSSchedulingJob` and `ILSSchedulingSubJob` | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Persists sale/product status; provides Quartz job store | `continuumPricingControlCenterJtierPostgres` |
| Voucher Inventory Service | Supplies min-per-pledge constraints for local-channel products | `continuumVoucherInventoryService` |
| Pricing Service | Receives bulk program creation requests; returns quote IDs | `continuumPricingService` |
| Messaging SaaS (SMTP) | Receives failure notification emails | `messagingSaaS` |

## Steps

1. **User schedules sale**: Sales rep calls `POST /sales/{id}/schedule` with `user-email` header.
   - From: `salesRep`
   - To: `continuumPricingControlCenterJtierService`
   - Protocol: REST

2. **Validate and set status**: Service validates sale is in `NEW` or `SCHEDULING_PAUSED` status and start time is in the future; updates sale status to `SCHEDULING_PENDING` in PostgreSQL.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **CheckForPendingSalesJob detects pending sale**: The Quartz job running every 15 minutes queries PostgreSQL for sales in `SCHEDULING_PENDING` status and triggers `ILSSchedulingJob`.
   - From: `continuumPricingControlCenterJtierService` (Quartz scheduler)
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

4. **ILSSchedulingJob initializes**: Transitions sale from `SCHEDULING_PENDING` to `SCHEDULING_STARTED`; calculates unschedule cutoff time; loads all sale products from PostgreSQL.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

5. **Partition products into sub-job batches**: Divides products into chunks of 10; creates and queues one `ILSSchedulingSubJob` per chunk with staggered start times (gap configurable via `ilsSchedulingSubJobTrigger.gapBetweenEachTriggerStartTime`).
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres` (Quartz job store)
   - Protocol: JDBC

6. **Sub-job validates products**: For each product in the batch, applies channel-specific validation rules. For `LOCAL_ILS` / local channels, fetches min-per-pledge from VIS.
   - From: `continuumPricingControlCenterJtierService` (ILSSchedulingSubJob)
   - To: `continuumVoucherInventoryService`
   - Protocol: REST (Retrofit)

7. **Sub-job calls Pricing Service bulk create**: Assembles pricing program payloads (display params, program labels, timer labels) and calls the Pricing Service bulk create API.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingService`
   - Protocol: REST (Retrofit)

8. **Sub-job records results**: Updates each product status to `SCHEDULED` (with quote ID and marginal cost) or `SCHEDULING_FAILED` (with exclusion reason) in PostgreSQL.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

9. **Orchestrator waits for all sub-jobs**: `ILSSchedulingJob` polls `TaskStatusCache` until all sub-jobs complete or a timeout elapses.
   - From: `continuumPricingControlCenterJtierService` (orchestrator)
   - To: `continuumPricingControlCenterJtierService` (TaskStatusCache in-process)
   - Protocol: in-process

10. **Finalize sale status**: Orchestrator sets sale status to `SALE_SETUP_COMPLETE` (if all products processed) or `SCHEDULING_FAILED` (on orchestrator-level error). For `LOCAL_ILS` channel, schedules `CustomILSGoLiveJob` to fire at sale start time.
    - From: `continuumPricingControlCenterJtierService`
    - To: `continuumPricingControlCenterJtierPostgres`
    - Protocol: JDBC

11. **Send failure notification (on error)**: If the job fails, an email is sent via SMTP relay to `dp-engg@groupon.com`.
    - From: `continuumPricingControlCenterJtierService`
    - To: `messagingSaaS`
    - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Sale start time is in the past | Rejected at API layer | `400 Bad Request`; sale status unchanged |
| Sale not in schedulable status | Rejected at API layer | `400 Bad Request`; sale status unchanged |
| VIS call fails for a product | Product excluded with `SCHEDULING_FAILED` status and exclusion reason | Sale may partially succeed |
| Pricing Service rejects a product | Product set to `SCHEDULING_FAILED` with exclusion reason from Pricing Service response | Sale may partially succeed |
| Pricing Service returns overlapping program (duplicate quote ID) | Existing quote ID reused; product treated as `SCHEDULED` | Sale continues |
| Orchestrator-level exception | Sale set to `SCHEDULING_FAILED`; email alert sent | `CheckForPendingSalesJob` retries after cooldown |
| Sale stuck in `SCHEDULING_STARTED` | `CheckForPendingSalesJob` invokes `manageStuckSale` retry logic after threshold | Status reset; re-queued |

## Sequence Diagram

```
salesRep -> continuumPricingControlCenterJtierService: POST /sales/{id}/schedule
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Validate and set SCHEDULING_PENDING
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: CheckForPendingSalesJob queries for pending sales
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set SCHEDULING_STARTED; load products
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Persist sub-job triggers (Quartz)
continuumPricingControlCenterJtierService -> continuumVoucherInventoryService: Fetch min-per-pledge (local channel)
continuumPricingControlCenterJtierService -> continuumPricingService: Bulk create pricing programs
continuumPricingService --> continuumPricingControlCenterJtierService: Quote IDs / error responses
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Update product statuses (SCHEDULED / SCHEDULING_FAILED)
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set SALE_SETUP_COMPLETE
continuumPricingControlCenterJtierService -> messagingSaaS: Send failure email (on error only)
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Unscheduling](ils-unscheduling.md), [Analytics Upload](analytics-upload.md)
