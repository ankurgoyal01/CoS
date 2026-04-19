---
service: "online_booking_3rd_party"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOnlineBooking3rdPartyApi, continuumOnlineBooking3rdPartyWorkers, continuumOnlineBooking3rdPartyMysql, continuumOnlineBooking3rdPartyRedis]
---

# Architecture Context

## System Context

`online_booking_3rd_party` is a Continuum platform service sitting at the boundary between Groupon's internal Booking Engine ecosystem and external third-party scheduling providers. It acts as a two-way adapter: inbound REST calls from Booking Engine services trigger mapping and reservation workflows, while outbound polling and event consumption drives synchronization with provider APIs. It participates in the Message Bus event fabric by both consuming topics from the Appointment Engine and Booking Tool and publishing normalized events to the Booking Engine 3rd-party topic.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Online Booking 3rd Party API | `continuumOnlineBooking3rdPartyApi` | API | Ruby on Rails | 5.0.7 | REST API handling merchant mapping, availability, booking, and webhook endpoints |
| Online Booking 3rd Party Workers | `continuumOnlineBooking3rdPartyWorkers` | Worker | Ruby / Resque | — | Resque workers and scheduled jobs for polling, event consumption, and synchronization |
| Online Booking 3rd Party MySQL | `continuumOnlineBooking3rdPartyMysql` | Database | MySQL | — | Primary relational datastore for providers, merchant places, service mappings, reservations, and API tokens |
| Online Booking 3rd Party Redis | `continuumOnlineBooking3rdPartyRedis` | Cache / Queue | Redis | — | Resque queue backend and transient cache / health dependency |

## Components by Container

### Online Booking 3rd Party API (`continuumOnlineBooking3rdPartyApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiPublicEndpoints` | Rails controllers exposing V3 merchant/place/service, booking, availability, and webhook endpoints | Rails Controllers |
| `apiMappingDomain` | Domain logic for merchant place, service mapping, authorization, and reservation state transitions | Ruby Services + ActiveRecord Models |
| `apiExternalClients` | ApiClients and resource adapters for appointments, availability, users, catalog, DMAPI, calendars, and providers | ApiClients / GrouponPlatform Clients |
| `apiAsyncDispatch` | Enqueues background jobs for polling, synchronization, and outbound event publication | ActiveJob + Resque |

### Online Booking 3rd Party Workers (`continuumOnlineBooking3rdPartyWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `workerEventConsumers` | Workers consuming Appointment Engine and Booking Tool topics to trigger synchronization | Messagebus Workers |
| `workerPollingOrchestrator` | Scheduled jobs that detect pollable mappings/places and trigger provider synchronization | Resque Scheduler Jobs |
| `workerProviderSync` | Provider-specific sync and replication logic for bookings, services, and availability | Ruby Services |
| `workerEventPublisher` | Publishes normalized 3rd-party domain events to Booking Engine topics | Messagebus Producer |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOnlineBooking3rdPartyApi` | `continuumOnlineBooking3rdPartyMysql` | Reads and writes domain entities (providers, places, mappings, reservations, tokens) | ActiveRecord/MySQL |
| `continuumOnlineBooking3rdPartyWorkers` | `continuumOnlineBooking3rdPartyMysql` | Reads and writes synchronization state, mappings, reservations, and retries | ActiveRecord/MySQL |
| `continuumOnlineBooking3rdPartyApi` | `continuumOnlineBooking3rdPartyRedis` | Uses Redis for Resque integration and dependency health checks | Redis |
| `continuumOnlineBooking3rdPartyWorkers` | `continuumOnlineBooking3rdPartyRedis` | Uses Redis for Resque queues, schedules, and worker coordination | Redis |
| `continuumOnlineBooking3rdPartyApi` | `continuumAppointmentsEngine` | Creates and updates reservations, reservation requests, and option flags | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumAvailabilityEngine` | Reads and updates places/services and ingests availability snapshots | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumUsersService` | Fetches user/account data for booking workflows | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumDealCatalogService` | Fetches and updates deal product metadata | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumDealManagementApi` | Reads and updates inventory product details | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumCalendarService` | Uses legacy calendar/place/service APIs for compatibility paths | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `emeaBtos` | Calls provider APIs for service availability and booking lifecycle actions | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumVoucherInventoryApi` | Validates and redeems voucher inventory units | HTTP/JSON |
| `continuumOnlineBooking3rdPartyApi` | `continuumOrdersService` | Reads order context for voucher-linked reservation flows | HTTP/JSON |
| `continuumOnlineBooking3rdPartyWorkers` | `continuumAppointmentsEngine` | Applies reservation and place/service updates driven by async flows | HTTP/JSON |
| `continuumOnlineBooking3rdPartyWorkers` | `continuumAvailabilityEngine` | Pushes synchronized availability and service state | HTTP/JSON |
| `continuumOnlineBooking3rdPartyWorkers` | `emeaBtos` | Polls and synchronizes provider bookings and availability | HTTP/JSON |
| `continuumOnlineBooking3rdPartyWorkers` | `messageBus` | Consumes BookingTool/AppointmentEngine topics and publishes BookingEngine.3rdParty events | STOMP/JMS |

## Architecture Diagram References

- Component (API): `components-continuum-online-booking-3rd-party-api`
- Component (Workers): `components-continuum-online-booking-3rd-party-workers`
- Dynamic view (merchant mapping): `dynamic-merchant-mapping-request-flow`
- Dynamic view (provider sync): `dynamic-provider-workerProviderSync-from-inbound-event-flow`
