---
service: "calendar-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Calendar Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Availability Query and Caching](availability-query-caching.md) | synchronous | API call to `/v1/services/availability` | Serves compiled availability windows from Redis cache or MySQL fallback; returns time-range slots to the caller |
| [Booking Creation and EPODS Sync](booking-creation-epods-sync.md) | synchronous | API call to `POST /v1/units/bookings` | Creates a unit booking, persists state to Postgres, calls inventory and EPODS, then schedules asynchronous sync jobs |
| [Availability Ingestion and Compilation](availability-ingestion-compilation.md) | asynchronous | API call to `POST /v1/services/{id}/ingest_availability` + utility worker | Ingests raw availability data, stores it in MySQL, and triggers background compilation into queryable availability windows |
| [Event Consumption Worker](event-consumption-worker.md) | event-driven | MBus events on `availabilityEngineEventsBus` | Consumes `AvailabilityRecordChanged`, `ProductAvailabilitySegments`, and `AppointmentEvents`; updates internal state and invalidates cache |
| [Background Scheduler Jobs](background-scheduler-jobs.md) | scheduled | Quartz scheduler in `continuumCalendarUtility` | Executes periodic EPODS sync, booking cleanup, and redemption reconciliation jobs |
| [Place Service Config Sync](place-service-config-sync.md) | synchronous | API call to `POST /v1/merchants/{id}/places/{id}/sync` | Fetches place metadata and open hours from M3 Place and persists updated configuration for availability compilation |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Booking Creation and EPODS Sync** spans `continuumCalendarServiceCalSer`, `continuumEpodsService`, `continuumVoucherInventoryService`, and `continuumThirdPartyInventoryService`. See architecture dynamic view `calendarBookingAndSyncFlow`.
- **Event Consumption Worker** spans `continuumCalendarServiceCalSer` and `availabilityEngineEventsBus` (MBus). Event producers include Appointments Service and other Continuum availability services.
- **Background Scheduler Jobs** spans `continuumCalendarUtility` and `continuumEpodsService`; utility workers independently synchronize EPODS booking state without going through the API hosts.
