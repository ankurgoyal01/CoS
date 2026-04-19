---
service: "calendar-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCalendarServiceCalSer, continuumCalendarUtility, continuumCalendarPostgres, continuumCalendarMySql, continuumCalendarRedis]
---

# Architecture Context

## System Context

Calendar Service is a backend component of the **Continuum** commerce platform (`continuumSystem`). It sits at the intersection of booking, availability, and external partner synchronization. Booking surfaces and CX tooling call it synchronously over REST. It interacts asynchronously with `availabilityEngineEventsBus` via MBus to exchange `AvailabilityRecordChanged` and `ProductAvailabilitySegments` events. External partners (EPODS, Third-Party Booking, Appointments Service) are reached via Retrofit HTTP clients managed by the `calendarService_externalClients` component. The service is tagged `ToDecommission`, indicating it is a legacy Continuum service with a planned migration path.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Calendar Service API Hosts | `continuumCalendarServiceCalSer` | Backend API | Java / Dropwizard | JTier 5.15.0 | REST API hosts exposing calendar, availability, and booking endpoints; integrates with persistence, MBus, and external booking systems |
| Calendar Service Utility Hosts | `continuumCalendarUtility` | Background Worker | Java / Quartz | JTier 5.15.0 | Background scheduler and async workers for availability compilation and EPODS booking synchronization |
| Calendar Service Postgres DaaS | `continuumCalendarPostgres` | Database | PostgreSQL | — | Primary operational datastore for bookings, jobs, and service state |
| Availability Engine MySQL DaaS | `continuumCalendarMySql` | Database | MySQL | — | Availability-engine and legacy availability datastore used by calendar workflows |
| Calendar Service Redis Cache | `continuumCalendarRedis` | Cache | Redis | — | In-memory cache for hot calendar and availability lookups |

## Components by Container

### Calendar Service API Hosts (`continuumCalendarServiceCalSer`)

> Note: The federated DSL also defines a logical `continuumCalendarService` container that holds the component decomposition. Components below are defined within that container and deployed on the API hosts.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiResourcesCalSer` — API Resources | REST resources handling inbound requests for availability, reservations, segments, units, and places | Dropwizard JAX-RS |
| `bookingOrchestration` — Booking Orchestration Services | Application services coordinating booking lifecycle, reservation, and product operations | Java |
| `availabilityCore` — Availability Core | Core availability compilation, search, and time-range logic | Java |
| `dataAccessCalSer` — Persistence Layer | JDBI DAOs and datastore abstractions for Postgres and MySQL | JDBI3 |
| `calendarService_externalClients` — External Client Adapters | Retrofit clients for Third Party, Appointments, Inventory, M3, and EPODS | JTier Retrofit |
| `calendarService_schedulerJobs` — Schedulers and Background Jobs | Quartz jobs for cleanup, redemption, and EPODS synchronization | JTier Quartz |
| `messageBusAdapters` — Message Bus Adapters | Message consumer and publisher processing for availability and booking events | JTier MBus |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCalendarServiceCalSer` | `continuumCalendarPostgres` | Reads and writes service data | JDBC / PostgreSQL |
| `continuumCalendarServiceCalSer` | `continuumCalendarMySql` | Reads and writes availability-engine data | JDBC / MySQL |
| `continuumCalendarServiceCalSer` | `continuumCalendarRedis` | Caches availability and booking data | Redis protocol |
| `continuumCalendarUtility` | `continuumCalendarPostgres` | Reads and writes scheduled job and booking state | JDBC / PostgreSQL |
| `continuumCalendarUtility` | `continuumCalendarMySql` | Reads and writes availability compilation data | JDBC / MySQL |
| `continuumCalendarUtility` | `continuumCalendarRedis` | Reads and writes cache data | Redis protocol |
| `continuumCalendarServiceCalSer` | `continuumEpodsService` | Creates, checks, and cancels EPODS bookings | REST |
| `continuumCalendarServiceCalSer` | `continuumVoucherInventoryService` | Calls voucher inventory APIs | REST |
| `continuumCalendarServiceCalSer` | `continuumThirdPartyInventoryService` | Calls third-party inventory APIs | REST |
| `continuumCalendarServiceCalSer` | `continuumM3MerchantService` | Fetches merchant metadata | REST |
| `continuumCalendarUtility` | `continuumEpodsService` | Executes async EPODS synchronization jobs | REST |
| `apiResourcesCalSer` | `bookingOrchestration` | Invokes booking, segment, and availability application services | direct |
| `apiResourcesCalSer` | `availabilityCore` | Invokes availability search and compilation workflows | direct |
| `bookingOrchestration` | `dataAccessCalSer` | Reads and writes booking, unit, and segment persistence models | direct |
| `availabilityCore` | `dataAccessCalSer` | Reads and updates availability and product data | direct |
| `bookingOrchestration` | `calendarService_externalClients` | Calls EPODS, inventory, and appointment adapters | direct |
| `availabilityCore` | `calendarService_externalClients` | Calls M3 and third-party integration adapters | direct |
| `bookingOrchestration` | `calendarService_schedulerJobs` | Schedules EPODS booking synchronization jobs | direct |
| `calendarService_schedulerJobs` | `messageBusAdapters` | Publishes booking and availability events | direct |

## Architecture Diagram References

- Container view: `calendarServiceContainers`
- Component view: `calendarServiceComponents`
- Dynamic flow: `calendarBookingAndSyncFlow`
