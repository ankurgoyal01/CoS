---
service: "maris"
title: "Scheduled Cancellation Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "scheduled-cancellation-processing"
flow_type: scheduled
trigger: "Quartz scheduler — periodic batch execution"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "unknown_expediarapidapi_12b321ae"
  - "continuumOrdersService"
  - "messageBus"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Scheduled Cancellation Processing

## Summary

This scheduled batch job processes hotel reservation cancellations that could not be completed synchronously — for example, when an `Orders.StatusChanged` cancellation event was received but the Expedia Rapid API was temporarily unavailable. The job identifies reservations in a pending-cancellation state, cancels the corresponding Expedia itineraries, initiates payment reversals with the Orders Service, and updates unit state in `marisMySql`.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`jtier-quartz-bundle`) running within the MARIS service process
- **Frequency**: Periodic (exact cron schedule defined in service configuration; not discoverable from architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Triggers job execution on schedule | Internal to `continuumTravelInventoryService` |
| MARIS Service | Executes batch cancellation logic | `continuumTravelInventoryService` |
| MARIS MySQL | Source of pending-cancellation records; target for state updates | `marisMySql` |
| Expedia Rapid API | Receives itinerary cancellation requests | `unknown_expediarapidapi_12b321ae` (stub) |
| Orders Service | Instructed to reverse payment for cancelled reservations | `continuumOrdersService` |
| MBus | Receives unit update events after cancellation completion | `messageBus` |

## Steps

1. **Scheduler fires job**: Quartz scheduler triggers the cancellation processing job at the configured interval
   - From: Quartz Scheduler (internal)
   - To: `continuumTravelInventoryService` (Core Orchestration)
   - Protocol: Internal JVM invocation

2. **Queries `marisMySql` for pending-cancellation records**: Identifies reservation and unit records in a cancellation-pending or cancellation-retry state
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

3. **Cancels itinerary with Expedia Rapid API** (per record): Sends cancellation request to Expedia Rapid for the pending itinerary
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Expedia Rapid API (`unknown_expediarapidapi_12b321ae`)
   - Protocol: HTTPS REST

4. **Initiates payment reversal with Orders Service** (per record): Calls Orders Service to reverse the payment authorization or capture for the cancelled unit
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: `continuumOrdersService`
   - Protocol: HTTP/JSON

5. **Updates unit and reservation state in `marisMySql`**: Updates unit status to cancelled, updates reservation record, and appends status log entry
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

6. **Publishes unit update event**: Publishes `InventoryUnits.Updated.Mrgetaways` for each completed cancellation to notify downstream consumers
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Expedia Rapid API unavailable | Skip record for this run; retry on next scheduled execution | Cancellation deferred to next cycle; record remains in pending state |
| Expedia rejects cancellation (e.g., non-cancellable rate) | Log error; mark record for manual review | Cancellation not completed; requires manual escalation |
| Orders Service unavailable for reversal | Skip record; retry on next scheduled execution | Payment reversal deferred; record remains in pending state |
| `marisMySql` write failure after successful cancellation | Log error; record may be reprocessed on next run | Possible duplicate cancellation attempt; Expedia and Orders Service should handle idempotently |
| Batch job fails to start | Quartz will retry on next scheduled trigger | Batch skipped for this cycle; pending records remain in queue |

## Sequence Diagram

```
QuartzScheduler -> MARIS: Trigger cancellation processing job
MARIS -> marisMySql: SELECT pending-cancellation units/reservations (JDBC)
marisMySql --> MARIS: Pending records list
loop for each pending record
  MARIS -> ExpediaRapidAPI: DELETE/cancel itinerary (HTTPS)
  ExpediaRapidAPI --> MARIS: Cancellation confirmation
  MARIS -> OrdersService: POST reverse payment (HTTP/JSON)
  OrdersService --> MARIS: Reversal confirmation
  MARIS -> marisMySql: UPDATE unit status = cancelled, INSERT status_log (JDBC)
  MARIS -> MBus: PUBLISH InventoryUnits.Updated.Mrgetaways (JMS)
end
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Unit Status Change Processing](unit-status-change-processing.md), [Scheduled Refund Sync](scheduled-refund-sync.md), [Hotel Reservation Booking](hotel-reservation-booking.md)
