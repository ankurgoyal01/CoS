---
service: "maris"
title: "Scheduled Refund Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "scheduled-refund-sync"
flow_type: scheduled
trigger: "Quartz scheduler — periodic batch execution"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "continuumOrdersService"
  - "unknown_expediarapidapi_12b321ae"
  - "messageBus"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Scheduled Refund Sync

## Summary

This scheduled batch job identifies hotel reservations and inventory units that require refund processing — cases where a cancellation or reversal was initiated but refund settlement has not yet been confirmed. For each identified record, MARIS verifies state with Expedia Rapid API and instructs the Orders Service to process the outstanding refund. Unit state and status logs are updated in `marisMySql` upon successful completion.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`jtier-quartz-bundle`) running within the MARIS service process
- **Frequency**: Periodic (exact cron schedule defined in service configuration; not discoverable from architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Triggers job execution on schedule | Internal to `continuumTravelInventoryService` |
| MARIS Service | Executes batch refund sync logic | `continuumTravelInventoryService` |
| MARIS MySQL | Source of records requiring refund processing; target for state updates | `marisMySql` |
| Expedia Rapid API | Consulted to verify itinerary cancellation status | `unknown_expediarapidapi_12b321ae` (stub) |
| Orders Service | Instructed to process outstanding refunds | `continuumOrdersService` |
| MBus | Receives unit update events after refund completion | `messageBus` |

## Steps

1. **Scheduler fires job**: Quartz scheduler triggers the refund sync job at the configured interval
   - From: Quartz Scheduler (internal)
   - To: `continuumTravelInventoryService` (Core Orchestration)
   - Protocol: Internal JVM invocation

2. **Queries `marisMySql` for refund-pending records**: Identifies reservation and unit records in a refund-pending or unresolved cancellation state
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

3. **Verifies itinerary cancellation status with Expedia Rapid API** (per record): Confirms that the Expedia itinerary has been cancelled before processing the refund
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Expedia Rapid API (`unknown_expediarapidapi_12b321ae`)
   - Protocol: HTTPS REST

4. **Instructs Orders Service to process refund** (per verified record): Calls Orders Service to execute the payment reversal or refund for the unit
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: `continuumOrdersService`
   - Protocol: HTTP/JSON

5. **Updates unit and reservation state in `marisMySql`**: Marks unit as refunded, updates reservation status, and appends status log entry
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

6. **Publishes unit update event**: Publishes `InventoryUnits.Updated.Mrgetaways` for each completed refund to notify downstream consumers
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Expedia Rapid API unavailable | Skip record for this run; retry on next scheduled execution | Refund deferred to next cycle |
| Expedia shows itinerary still active | Skip refund for this record; log for investigation | Refund not processed until itinerary is confirmed cancelled |
| Orders Service unavailable | Skip record for this run; retry on next scheduled execution | Refund deferred to next cycle |
| `marisMySql` write failure after refund | Log error; record may be reprocessed on next run (idempotent) | Possible duplicate refund attempt on retry; Orders Service should guard against duplicate refunds |
| Batch job fails to start | Quartz will retry on next scheduled trigger | Batch skipped for this cycle |

## Sequence Diagram

```
QuartzScheduler -> MARIS: Trigger refund sync job
MARIS -> marisMySql: SELECT refund-pending units/reservations (JDBC)
marisMySql --> MARIS: Pending records list
loop for each pending record
  MARIS -> ExpediaRapidAPI: GET itinerary status (HTTPS)
  ExpediaRapidAPI --> MARIS: Itinerary cancelled confirmation
  MARIS -> OrdersService: POST process refund (HTTP/JSON)
  OrdersService --> MARIS: Refund processed confirmation
  MARIS -> marisMySql: UPDATE unit status = refunded, INSERT status_log (JDBC)
  MARIS -> MBus: PUBLISH InventoryUnits.Updated.Mrgetaways (JMS)
end
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Unit Status Change Processing](unit-status-change-processing.md), [Scheduled Cancellation Processing](scheduled-cancellation-processing.md), [Hotel Reservation Booking](hotel-reservation-booking.md)
