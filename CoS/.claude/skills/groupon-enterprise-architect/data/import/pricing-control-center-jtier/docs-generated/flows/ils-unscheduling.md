---
service: "pricing-control-center-jtier"
title: "ILS Unscheduling"
generated: "2026-03-03"
type: flow
flow_name: "ils-unscheduling"
flow_type: asynchronous
trigger: "Sale status set to UNSCHEDULING_PENDING via POST /sales/{id}/unschedule or by CheckForPendingSalesJob"
participants:
  - "salesRep"
  - "continuumPricingControlCenterJtierService"
  - "continuumPricingControlCenterJtierPostgres"
  - "continuumPricingService"
  - "messagingSaaS"
architecture_ref: "dynamic-ils-scheduling-flow"
---

# ILS Unscheduling

## Summary

The ILS Unscheduling flow removes active pricing programs from the Pricing Service when a sale is cancelled, expired, or manually removed. It mirrors the scheduling flow: a user action (or `CheckForPendingSalesJob` detection) transitions the sale to `UNSCHEDULING_PENDING`, the `ILSUnschedulingJob` batches the scheduled products and calls the Pricing Service bulk delete API, and then updates statuses accordingly. It also cleans up analytics log raw records for the cancelled sale.

## Trigger

- **Type**: user-action (via `POST /sales/{id}/unschedule`) + schedule (via `CheckForPendingSalesJob`)
- **Source**: An IMTL or SUPER user unschedules a sale in the Control Center UI, or the 15-minute polling job detects a sale in `UNSCHEDULING_PENDING` status
- **Frequency**: On-demand (user-triggered) or every 15 minutes (job-triggered for pending/retry cases)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative / IMTL | Initiates unschedule action via UI | `salesRep` |
| Pricing Control Center JTier Service | Runs `ILSUnschedulingJob` to call Pricing Service delete API | `continuumPricingControlCenterJtierService` |
| Pricing Control Center PostgreSQL | Persists sale and product status transitions | `continuumPricingControlCenterJtierPostgres` |
| Pricing Service | Receives bulk program deletion requests | `continuumPricingService` |
| Messaging SaaS (SMTP) | Receives failure notification emails | `messagingSaaS` |

## Steps

1. **User requests unschedule**: IMTL or SUPER user calls `POST /sales/{id}/unschedule` with `user-email` header.
   - From: `salesRep`
   - To: `continuumPricingControlCenterJtierService`
   - Protocol: REST

2. **Validate and set status**: Service validates sale is in `SALE_SETUP_COMPLETE`, `UNSCHEDULING_PAUSED`, or `SCHEDULING_FAILED` status; checks unschedule cutoff window (sale cannot be unscheduled within 4 hours of start time unless user is SUPER); sets sale status to `UNSCHEDULING_PENDING`.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

3. **CheckForPendingSalesJob detects pending unschedule**: Polling job queries PostgreSQL for sales in `UNSCHEDULING_PENDING` status and triggers `ILSUnschedulingJob`.
   - From: `continuumPricingControlCenterJtierService` (Quartz scheduler)
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

4. **ILSUnschedulingJob initializes**: Transitions sale from `UNSCHEDULING_PENDING` to `UNSCHEDULING_STARTED`; retrieves all products with `SCHEDULED` status and valid quote IDs.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

5. **Partition products into batches**: Divides scheduled products into batches of 50 for bulk deletion.
   - From: `continuumPricingControlCenterJtierService`
   - To: (in-process)
   - Protocol: in-process

6. **Call Pricing Service bulk delete**: For each batch, calls the Pricing Service bulk delete API with quote IDs.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingService`
   - Protocol: REST (Retrofit)

7. **Update product statuses**: For each product, sets status to `UNSCHEDULED` on success or `UNSCHEDULING_FAILED` on error.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

8. **Delete analytics records**: For channels with log raw enabled, deletes product records from internal and external (Teradata) log raw tables; updates analytics status.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres` (internal log raw) + Teradata (external log raw)
   - Protocol: JDBC

9. **Finalize sale status**: Sets sale status to `UNSCHEDULING_ENDED` on success or `UNSCHEDULING_FAILED` on error.
   - From: `continuumPricingControlCenterJtierService`
   - To: `continuumPricingControlCenterJtierPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unschedule requested within 4-hour cutoff window | Rejected at API layer (unless SUPER role) | `400 Bad Request`; sale status unchanged |
| Sale not in unschedulable status | Rejected at API layer | `400 Bad Request`; sale status unchanged |
| Pricing Service delete fails for some products | Products set to `UNSCHEDULING_FAILED`; sale set to `UNSCHEDULING_FAILED` | `CheckForPendingSalesJob` retries |
| Analytics deletion fails | Analytics status updated to track failure; `AnalyticsUploadJob` handles deletion retry | Sale unschedule completes; analytics cleaned up asynchronously |
| Sale stuck in `UNSCHEDULING_STARTED` | `CheckForPendingSalesJob` invokes `manageStuckSale` retry logic | Status reset; re-queued |

## Sequence Diagram

```
salesRep -> continuumPricingControlCenterJtierService: POST /sales/{id}/unschedule
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Validate and set UNSCHEDULING_PENDING
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: CheckForPendingSalesJob queries pending unschedules
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set UNSCHEDULING_STARTED; load SCHEDULED products
continuumPricingControlCenterJtierService -> continuumPricingService: Bulk delete pricing programs (batches of 50)
continuumPricingService --> continuumPricingControlCenterJtierService: Delete results
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Update product statuses (UNSCHEDULED / UNSCHEDULING_FAILED)
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Delete analytics log raw records
continuumPricingControlCenterJtierService -> continuumPricingControlCenterJtierPostgres: Set UNSCHEDULING_ENDED
```

## Related

- Architecture dynamic view: `dynamic-ils-scheduling-flow`
- Related flows: [ILS Scheduling](ils-scheduling.md), [Analytics Upload](analytics-upload.md)
