---
service: "calendar-service"
title: "Booking Creation and EPODS Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "booking-creation-epods-sync"
flow_type: synchronous
trigger: "Inbound POST /v1/units/bookings API call"
participants:
  - "continuumCalendarServiceCalSer"
  - "continuumCalendarPostgres"
  - "continuumVoucherInventoryService"
  - "continuumThirdPartyInventoryService"
  - "continuumEpodsService"
  - "continuumCalendarRedis"
architecture_ref: "dynamic-calendarBookingAndSyncFlow"
---

# Booking Creation and EPODS Sync

## Summary

This flow covers the end-to-end lifecycle of creating a new unit booking: from the initial API request through persistence, inventory validation, EPODS reservation creation, and post-booking event emission. The synchronous API path persists the booking and calls EPODS; a Quartz job is then scheduled via `calendarService_schedulerJobs` to handle asynchronous follow-up synchronization and MBus event publication. This flow is the primary source of `AvailabilityRecordChanged` events published to `availabilityEngineEventsBus`.

## Trigger

- **Type**: api-call
- **Source**: Booking surface or checkout orchestration calling `POST /v1/units/bookings`
- **Frequency**: On-demand; triggered on each consumer booking attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service API Hosts | Receives booking creation request and orchestrates the flow | `continuumCalendarServiceCalSer` |
| API Resources | Routes POST request to booking orchestration | `apiResourcesCalSer` |
| Booking Orchestration Services | Coordinates the booking lifecycle across persistence, inventory, and EPODS | `bookingOrchestration` |
| Persistence Layer | Writes booking and unit state to Postgres | `dataAccessCalSer` |
| External Client Adapters | Calls inventory services and EPODS | `calendarService_externalClients` |
| Schedulers and Background Jobs | Schedules post-booking EPODS sync job | `calendarService_schedulerJobs` |
| Message Bus Adapters | Publishes booking lifecycle events to MBus | `messageBusAdapters` |
| Calendar Service Postgres DaaS | Stores booking and unit records | `continuumCalendarPostgres` |
| Voucher Inventory Service | Validates voucher inventory for the booked product | `continuumVoucherInventoryService` |
| Third-Party Inventory Service | Validates third-party inventory if applicable | `continuumThirdPartyInventoryService` |
| EPODS Service | Creates or updates the external partner booking reservation | `continuumEpodsService` |
| Calendar Service Redis Cache | Cache entries for the booked unit are invalidated | `continuumCalendarRedis` |

## Steps

1. **Receive booking creation request**: Caller sends `POST /v1/units/bookings` with unit ID, service ID, time slot, and consumer details.
   - From: upstream caller
   - To: `apiResourcesCalSer`
   - Protocol: REST

2. **Invoke Booking Orchestration**: `apiResourcesCalSer` passes the booking request to `bookingOrchestration`.
   - From: `apiResourcesCalSer`
   - To: `bookingOrchestration`
   - Protocol: direct

3. **Validate and reserve inventory**: `bookingOrchestration` calls `calendarService_externalClients` to validate voucher inventory and, if applicable, third-party inventory availability.
   - From: `bookingOrchestration`
   - To: `calendarService_externalClients` → `continuumVoucherInventoryService` and/or `continuumThirdPartyInventoryService`
   - Protocol: REST

4. **Persist booking record**: `bookingOrchestration` instructs `dataAccessCalSer` to write the new booking and update unit state in `continuumCalendarPostgres`.
   - From: `bookingOrchestration`
   - To: `dataAccessCalSer` → `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

5. **Create EPODS booking**: `bookingOrchestration` calls `calendarService_externalClients` to create a booking in `continuumEpodsService`, passing booking reference and time slot.
   - From: `bookingOrchestration`
   - To: `calendarService_externalClients` → `continuumEpodsService`
   - Protocol: REST

6. **Invalidate availability cache**: `bookingOrchestration` triggers a cache invalidation for the booked unit's availability keys in `continuumCalendarRedis`.
   - From: `bookingOrchestration`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

7. **Schedule post-booking sync job**: `bookingOrchestration` registers a Quartz sync job via `calendarService_schedulerJobs` for deferred EPODS status confirmation and event publication.
   - From: `bookingOrchestration`
   - To: `calendarService_schedulerJobs`
   - Protocol: direct

8. **Return booking response**: `apiResourcesCalSer` returns HTTP 201 with the created booking record to the caller.
   - From: `apiResourcesCalSer`
   - To: caller
   - Protocol: REST

9. **Async: emit booking events**: After the Quartz job fires, `calendarService_schedulerJobs` instructs `messageBusAdapters` to publish `AvailabilityRecordChanged` to `availabilityEngineEventsBus`.
   - From: `calendarService_schedulerJobs`
   - To: `messageBusAdapters` → `availabilityEngineEventsBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory validation fails | `bookingOrchestration` aborts before persisting; returns HTTP 409 or 422 | Booking not created; caller must retry with valid inventory |
| Postgres write failure | Transaction rolled back; HTTP 500 returned | Booking not created; no partial state |
| EPODS creation fails | `calendarService_externalClients` retries per resilience4j config; if circuit is open, HTTP 503 returned | Booking may be persisted locally but EPODS sync is queued for Quartz retry |
| Quartz job scheduling failure | Logged; sync job will be retried on next Quartz polling cycle | Booking exists; EPODS sync and event emission delayed |
| Redis cache invalidation failure | Logged; stale cache entry will expire naturally | Temporary stale availability data; corrects on TTL expiry or next availability ingestion |

## Sequence Diagram

```
Caller -> apiResourcesCalSer: POST /v1/units/bookings { unitId, serviceId, slot, consumer }
apiResourcesCalSer -> bookingOrchestration: createBooking(request)
bookingOrchestration -> calendarService_externalClients: validateInventory(unitId, productId)
calendarService_externalClients -> continuumVoucherInventoryService: GET /inventory/check
continuumVoucherInventoryService --> calendarService_externalClients: inventory valid
calendarService_externalClients --> bookingOrchestration: inventory ok
bookingOrchestration -> dataAccessCalSer: insertBooking(booking)
dataAccessCalSer -> continuumCalendarPostgres: INSERT INTO bookings ...
continuumCalendarPostgres --> dataAccessCalSer: booking persisted
bookingOrchestration -> calendarService_externalClients: createEpodsBooking(bookingRef, slot)
calendarService_externalClients -> continuumEpodsService: POST /bookings
continuumEpodsService --> calendarService_externalClients: EPODS booking created
bookingOrchestration -> continuumCalendarRedis: DEL availability cache key
bookingOrchestration -> calendarService_schedulerJobs: scheduleSync(bookingId)
apiResourcesCalSer --> Caller: HTTP 201 { booking }
calendarService_schedulerJobs -> messageBusAdapters: publishEvent(AvailabilityRecordChanged)
messageBusAdapters -> availabilityEngineEventsBus: publish AvailabilityRecordChanged
```

## Related

- Architecture dynamic view: `dynamic-calendarBookingAndSyncFlow`
- Related flows: [Background Scheduler Jobs](background-scheduler-jobs.md), [Availability Query and Caching](availability-query-caching.md)
