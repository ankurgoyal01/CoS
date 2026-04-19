---
service: "appointment_engine"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumAppointmentEngineApi, continuumAppointmentEngineUtility, continuumAppointmentEngineMySql, continuumAppointmentEngineRedis, continuumAppointmentEngineMemcached]
---

# Architecture Context

## System Context

The appointment engine sits within the Groupon **Continuum** platform in the Booking / Services domain. It is the authoritative service for appointment state — consumers book appointments through the Groupon deal page, which calls into the appointment engine API. Merchants interact via booking management tooling. The service listens to events from the Availability Engine and Orders Service on the Groupon Message Bus, and emits appointment lifecycle events that downstream services (e.g., notification systems) consume. A Resque-based worker container handles all asynchronous and scheduled background processing.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Appointment Engine API | `continuumAppointmentEngineApi` | Backend | Ruby on Rails / Puma | 5.0.7 / 3.12.6 | REST API for reservation and appointment management (V2 and V3) |
| Appointment Engine Utility | `continuumAppointmentEngineUtility` | Backend | Ruby / Resque + resque-scheduler | — | Background worker for async job processing and scheduled cleanup tasks |
| Appointment Engine MySQL | `continuumAppointmentEngineMySql` | Database | MySQL | — | Primary persistent store for reservations, appointments, and related entities |
| Appointment Engine Redis | `continuumAppointmentEngineRedis` | Cache | Redis | — | Resque job queue backing store |
| Appointment Engine Memcached | `continuumAppointmentEngineMemcached` | Cache | Memcached (dalli 2.7.8) | — | API response cache |

## Components by Container

### Appointment Engine API (`continuumAppointmentEngineApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| V2 Reservation Requests Controller | CRUD for reservation requests | Rails controller |
| V2 Reservations Controller | Read access to confirmed reservations | Rails controller |
| V2 Appointments Parameters Controller | Exposes appointment options/configuration | Rails controller |
| V3 Reservations Controller | Full CRUD + confirm/decline/reschedule/attend/miss transitions | Rails controller |
| V3 Voucher Status Controller | Returns voucher redemption status for an appointment | Rails controller |
| V3 Option Flags Controller | Manages per-appointment option flags | Rails controller |
| V3 Contact Attempts Controller | Tracks consumer/merchant contact attempt records | Rails controller |
| V3 Tickets Controller | Manages appointment ticket entities | Rails controller |
| Smoke Test Controller | Health check / smoke test endpoints | Rails controller |
| Appointment State Machine | Manages valid state transitions (state_machine 1.2.0) | Ruby / state_machine gem |
| Message Bus Publisher | Publishes appointment lifecycle events to JMS topics | messagebus 0.5.2 |
| Message Bus Consumer | Subscribes to and processes incoming JMS events | messagebus 0.5.2 |
| API Response Cache | Caches API responses in Memcached | dalli 2.7.8 |

### Appointment Engine Utility (`continuumAppointmentEngineUtility`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Resque Worker | Processes background jobs from Redis queue | resque |
| Scheduler | Triggers periodic data cleanup and notification jobs | resque-scheduler / active_scheduler |
| GDPR Erasure Job | Deletes personal data in response to `gdpr.account.v1.erased` events | Resque job |
| Notification Job | Dispatches appointment notifications via Online Booking Notifications | Resque job |
| Data Cleanup Job | Runs periodic cleanup of stale reservation and appointment records | Resque scheduled job |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAppointmentEngineApi` | `continuumAppointmentEngineMySql` | Reads and writes all reservation/appointment data | MySQL (ActiveRecord) |
| `continuumAppointmentEngineApi` | `continuumAppointmentEngineMemcached` | Caches API responses | Memcached (dalli) |
| `continuumAppointmentEngineUtility` | `continuumAppointmentEngineRedis` | Reads and writes Resque job queue | Redis |
| `continuumAppointmentEngineUtility` | `continuumAppointmentEngineMySql` | Reads/writes appointment data for background jobs | MySQL (ActiveRecord) |
| `continuumAppointmentEngineApi` | Message Bus | Publishes appointment lifecycle events | JMS / messagebus |
| `continuumAppointmentEngineApi` | Message Bus | Consumes availability and order status events | JMS / messagebus |
| `continuumAppointmentEngineApi` | Availability Engine | Queries availability for reservation coordination | REST/HTTP |
| `continuumAppointmentEngineApi` | Online Booking Notifications | Triggers consumer/merchant notifications | REST/HTTP |
| `continuumAppointmentEngineApi` | Deal Catalog | Fetches deal/option metadata | REST/HTTP |
| `continuumAppointmentEngineApi` | Orders Service | Reads order/voucher state | REST/HTTP |
| `continuumAppointmentEngineApi` | Users Service | Resolves consumer identity | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Dynamic view: `appointment-lifecycle`
