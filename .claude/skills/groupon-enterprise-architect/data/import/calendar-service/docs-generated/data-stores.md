---
service: "calendar-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCalendarPostgres"
    type: "postgresql"
    purpose: "Primary operational datastore for bookings, jobs, and service state"
  - id: "continuumCalendarMySql"
    type: "mysql"
    purpose: "Availability-engine and legacy availability datastore"
  - id: "continuumCalendarRedis"
    type: "redis"
    purpose: "In-memory cache for hot calendar and availability lookups"
---

# Data Stores

## Overview

Calendar Service owns three data stores. PostgreSQL (`continuumCalendarPostgres`) is the primary operational store for booking records, unit state, and scheduler job metadata. MySQL (`continuumCalendarMySql`) powers the availability engine — it holds the legacy availability and compilation data that feeds the `/v1/services/availability` query path. Redis (`continuumCalendarRedis`) provides an in-memory cache layer to serve hot availability and booking lookups without hitting the relational stores on every request. Both the API hosts (`continuumCalendarServiceCalSer`) and utility workers (`continuumCalendarUtility`) access all three stores.

## Stores

### Calendar Service Postgres DaaS (`continuumCalendarPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCalendarPostgres` |
| Purpose | Primary operational datastore for bookings, units, product segments, scheduler job state, and service configuration |
| Ownership | owned |
| Migrations path | > Not applicable — managed via JTier DaaS provisioning; migration path not declared in architecture DSL |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `bookings` | Core booking records created and managed via the bookings API | booking ID, unit ID, service ID, status, created/updated timestamps |
| `units` | Bookable unit definitions and state | unit ID, service ID, capacity, status |
| `product_segments` | Product availability segment records | product ID, segment ID, start/end datetime, capacity |
| `scheduler_jobs` | Quartz job metadata and execution history for EPODS sync and cleanup | job ID, job type, next fire time, status |

#### Access Patterns

- **Read**: `bookingOrchestration` and `availabilityCore` components query bookings, units, and segments by ID, service ID, and date range
- **Write**: `bookingOrchestration` inserts and updates booking and unit records on each booking lifecycle transition; `calendarService_schedulerJobs` updates scheduler job state
- **Indexes**: Not declared in architecture DSL; expected indexes on booking ID, unit ID, service ID, and status fields

---

### Availability Engine MySQL DaaS (`continuumCalendarMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCalendarMySql` |
| Purpose | Availability-engine and legacy availability datastore; stores compiled availability windows used by the availability query and ingest paths |
| Ownership | owned |
| Migrations path | > Not applicable — managed via JTier DaaS provisioning; migration path not declared in architecture DSL |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `availability_records` | Compiled availability windows per service | service ID, start/end datetime, available slots, compiled timestamp |
| `availability_ingestion` | Raw ingested availability data pending compilation | service ID, raw availability payload, ingestion timestamp |

#### Access Patterns

- **Read**: `availabilityCore` queries compiled availability records by service ID and date range to respond to `/v1/services/availability` requests
- **Write**: `continuumCalendarUtility` workers write compiled availability output; `apiResourcesCalSer` writes raw ingestion records via `/v1/services/{id}/ingest_availability`
- **Indexes**: Not declared in architecture DSL; expected indexes on service ID and datetime range columns

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCalendarRedis` | redis | Hot availability and booking lookup cache; reduces read pressure on Postgres and MySQL for frequently queried availability windows and booking states | Not declared in architecture DSL |

### Redis Access Pattern

- **Read**: `continuumCalendarServiceCalSer` checks Redis before querying relational stores for availability and booking data
- **Write**: `continuumCalendarServiceCalSer` and `continuumCalendarUtility` write cache entries after computing or ingesting availability data; entries are invalidated on `AvailabilityRecordChanged` consumption

## Data Flows

- Availability ingestion flow: raw data arrives via `/v1/services/{id}/ingest_availability` and is written to `continuumCalendarMySql`; `continuumCalendarUtility` workers compile the raw data and write compiled availability records back to MySQL; compiled records are cached in `continuumCalendarRedis`
- Booking creation flow: booking records are written to `continuumCalendarPostgres`; relevant availability slots are updated in `continuumCalendarMySql`; cache entries in `continuumCalendarRedis` are invalidated or updated
- Scheduler state: Quartz job metadata lives in `continuumCalendarPostgres` and is managed exclusively by the `calendarService_schedulerJobs` component and `continuumCalendarUtility` hosts
