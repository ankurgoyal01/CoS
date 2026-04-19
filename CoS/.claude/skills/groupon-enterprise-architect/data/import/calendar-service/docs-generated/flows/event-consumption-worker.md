---
service: "calendar-service"
title: "Event Consumption Worker"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "event-consumption-worker"
flow_type: event-driven
trigger: "MBus message arrives on availabilityEngineEventsBus"
participants:
  - "continuumCalendarServiceCalSer"
  - "continuumCalendarPostgres"
  - "continuumCalendarMySql"
  - "continuumCalendarRedis"
architecture_ref: "calendarServiceComponents"
---

# Event Consumption Worker

## Summary

Calendar Service's `messageBusAdapters` component runs as a long-lived MBus consumer connected to `availabilityEngineEventsBus`. It handles three event types: `AvailabilityRecordChanged` (triggers internal availability state reconciliation), `ProductAvailabilitySegments` (reconciles product segment records), and `AppointmentEvents` (updates booking state for appointment-backed bookings and triggers downstream sync if needed). All processing runs within the `continuumCalendarServiceCalSer` API hosts.

## Trigger

- **Type**: event
- **Source**: Messages published to `availabilityEngineEventsBus` by other Continuum services or by Calendar Service itself
- **Frequency**: Continuous; triggered per-message as events arrive on the bus

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service API Hosts | Hosts the MBus consumer | `continuumCalendarServiceCalSer` |
| Message Bus Adapters | Receives, deserializes, and routes inbound MBus events | `messageBusAdapters` |
| Availability Core | Reconciles availability state on `AvailabilityRecordChanged` and `ProductAvailabilitySegments` events | `availabilityCore` |
| Booking Orchestration Services | Updates booking state on `AppointmentEvents` | `bookingOrchestration` |
| Persistence Layer | Reads and writes availability and booking records | `dataAccessCalSer` |
| Availability Engine MySQL DaaS | Stores reconciled availability records | `continuumCalendarMySql` |
| Calendar Service Postgres DaaS | Stores updated booking state | `continuumCalendarPostgres` |
| Calendar Service Redis Cache | Cache entries invalidated after state changes | `continuumCalendarRedis` |

## Steps

### AvailabilityRecordChanged handling

1. **Receive event**: `messageBusAdapters` receives an `AvailabilityRecordChanged` message from `availabilityEngineEventsBus`.
   - From: `availabilityEngineEventsBus`
   - To: `messageBusAdapters`
   - Protocol: MBus

2. **Route to Availability Core**: `messageBusAdapters` dispatches the event to `availabilityCore` for processing.
   - From: `messageBusAdapters`
   - To: `availabilityCore`
   - Protocol: direct

3. **Reconcile availability records**: `availabilityCore` via `dataAccessCalSer` upserts the changed availability record in `continuumCalendarMySql`.
   - From: `availabilityCore` → `dataAccessCalSer`
   - To: `continuumCalendarMySql`
   - Protocol: JDBC / MySQL

4. **Invalidate Redis cache**: `availabilityCore` deletes the affected cache keys from `continuumCalendarRedis`.
   - From: `availabilityCore`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

5. **Acknowledge message**: `messageBusAdapters` acknowledges the event to MBus to advance the consumer offset.
   - From: `messageBusAdapters`
   - To: `availabilityEngineEventsBus`
   - Protocol: MBus

### ProductAvailabilitySegments handling

1. **Receive event**: `messageBusAdapters` receives a `ProductAvailabilitySegments` message from `availabilityEngineEventsBus`.
   - From: `availabilityEngineEventsBus`
   - To: `messageBusAdapters`
   - Protocol: MBus

2. **Route to Availability Core**: `messageBusAdapters` dispatches the event to `availabilityCore`.
   - From: `messageBusAdapters`
   - To: `availabilityCore`
   - Protocol: direct

3. **Reconcile product segments**: `availabilityCore` via `dataAccessCalSer` upserts product segment records in `continuumCalendarPostgres`.
   - From: `availabilityCore` → `dataAccessCalSer`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Invalidate cache and acknowledge**: Cache invalidated; MBus message acknowledged.
   - From: `availabilityCore` → `continuumCalendarRedis`; `messageBusAdapters` → `availabilityEngineEventsBus`
   - Protocol: Redis protocol / MBus

### AppointmentEvents handling

1. **Receive event**: `messageBusAdapters` receives an `AppointmentEvents` message from `availabilityEngineEventsBus`.
   - From: `availabilityEngineEventsBus`
   - To: `messageBusAdapters`
   - Protocol: MBus

2. **Route to Booking Orchestration**: `messageBusAdapters` dispatches the event to `bookingOrchestration`.
   - From: `messageBusAdapters`
   - To: `bookingOrchestration`
   - Protocol: direct

3. **Update booking state**: `bookingOrchestration` via `dataAccessCalSer` updates the appointment-backed booking record in `continuumCalendarPostgres`.
   - From: `bookingOrchestration` → `dataAccessCalSer`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Optionally schedule EPODS sync**: If the appointment event requires it, `bookingOrchestration` schedules a Quartz sync job via `calendarService_schedulerJobs`.
   - From: `bookingOrchestration`
   - To: `calendarService_schedulerJobs`
   - Protocol: direct

5. **Acknowledge message**: `messageBusAdapters` acknowledges the event.
   - From: `messageBusAdapters`
   - To: `availabilityEngineEventsBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL / Postgres write failure | MBus message not acknowledged; MBus retries delivery | Event is reprocessed; upsert semantics prevent duplicate records |
| Redis invalidation failure | Logged; stale cache expires on TTL | Temporary stale data; corrects naturally |
| Unknown event type | Logged and skipped; message acknowledged | No state change; monitoring alert on unknown type counts |
| Consumer crashes | MBus redelivers unacknowledged messages to next consumer instance | At-least-once processing; idempotency prevents duplicate state changes |

## Sequence Diagram

```
availabilityEngineEventsBus -> messageBusAdapters: AvailabilityRecordChanged { serviceId, window }
messageBusAdapters -> availabilityCore: handleAvailabilityChanged(event)
availabilityCore -> dataAccessCalSer: upsertAvailabilityRecord(serviceId, window)
dataAccessCalSer -> continuumCalendarMySql: UPSERT availability_records
availabilityCore -> continuumCalendarRedis: DEL cache key(serviceId)
messageBusAdapters -> availabilityEngineEventsBus: ACK

availabilityEngineEventsBus -> messageBusAdapters: AppointmentEvents { bookingId, appointmentStatus }
messageBusAdapters -> bookingOrchestration: handleAppointmentEvent(event)
bookingOrchestration -> dataAccessCalSer: updateBookingState(bookingId, status)
dataAccessCalSer -> continuumCalendarPostgres: UPDATE bookings SET status=...
messageBusAdapters -> availabilityEngineEventsBus: ACK
```

## Related

- Architecture dynamic view: `calendarServiceComponents`
- Related flows: [Availability Query and Caching](availability-query-caching.md), [Booking Creation and EPODS Sync](booking-creation-epods-sync.md), [Background Scheduler Jobs](background-scheduler-jobs.md)
