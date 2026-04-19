---
service: "appointment_engine"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAppointmentEngineMySql"
    type: "mysql"
    purpose: "Primary persistent store for all reservation and appointment data"
  - id: "continuumAppointmentEngineRedis"
    type: "redis"
    purpose: "Resque background job queue"
  - id: "continuumAppointmentEngineMemcached"
    type: "memcached"
    purpose: "API response caching"
---

# Data Stores

## Overview

The appointment engine uses three data stores: MySQL as the primary relational database (owned), Redis as the Resque job queue backing store (owned), and Memcached for API response caching (owned). All three are dedicated to the appointment engine service — none are shared with other services.

## Stores

### MySQL (`continuumAppointmentEngineMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAppointmentEngineMySql` |
| Purpose | Primary persistent store for all reservation requests, reservations, appointments, and related entities |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `reservations` | Stores confirmed appointment reservations | id, deal_id, consumer_id, merchant_id, scheduled_at, state, voucher_id |
| `reservation_requests` | Stores pending reservation requests before confirmation | id, deal_id, consumer_id, requested_at, state, option_id |
| `additional_attributes` | Stores flexible key-value attributes for reservations | id, reservation_id, key, value |
| `option_flags` | Stores per-appointment option flags | id, reservation_id, flag_name, flag_value |
| `places` | Stores merchant/location data for appointment context | id, name, address, lat, lng, external_id |
| `contact_attempts` | Tracks consumer/merchant contact attempt records | id, reservation_id, attempted_at, method, outcome |

#### Access Patterns

- **Read**: Lookups by reservation ID, consumer ID, merchant ID, deal ID, and state; paginated list queries via kaminari
- **Write**: State transitions on reservations (confirm, decline, reschedule, attend, miss); creation of reservation requests; GDPR erasure updates
- **Indexes**: > No evidence found in codebase for specific index definitions.

---

### Redis (`continuumAppointmentEngineRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumAppointmentEngineRedis` |
| Purpose | Resque background job queue — stores pending jobs for the Utility worker |
| Ownership | owned |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Stores serialized background job payloads | queue name, job class, args |
| Resque failed queue | Stores failed job records for inspection/retry | job payload, error, backtrace |

#### Access Patterns

- **Read**: Resque workers (`continuumAppointmentEngineUtility`) dequeue jobs for processing
- **Write**: `continuumAppointmentEngineApi` enqueues background jobs (notifications, GDPR erasure, cleanup)
- **Indexes**: N/A (Redis key-based access)

---

### Memcached (`continuumAppointmentEngineMemcached`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `continuumAppointmentEngineMemcached` |
| Purpose | API response caching to reduce load on MySQL and downstream API calls |
| Ownership | owned |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| API response cache entries | Cached JSON responses for read-heavy API endpoints | cache key (endpoint + params), serialized response |

#### Access Patterns

- **Read**: API controllers check Memcached before querying MySQL or calling downstream services
- **Write**: Cache-aside pattern — populate on miss; invalidate on state change
- **Indexes**: N/A (key-based access via dalli 2.7.8)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumAppointmentEngineMemcached` | memcached | API response cache for appointment engine endpoints | > No evidence found in codebase. |

## Data Flows

- The API layer (`continuumAppointmentEngineApi`) reads and writes appointment/reservation data to MySQL via ActiveRecord.
- On state transitions, the API layer enqueues Resque jobs to Redis for async processing by `continuumAppointmentEngineUtility`.
- `continuumAppointmentEngineUtility` reads jobs from Redis, processes them (notifications, cleanup, GDPR erasure), and may write back to MySQL.
- API read responses may be served from Memcached cache on cache-hit; on miss, MySQL is queried and the result is cached.
- No CDC, ETL, or replication flows are evidenced.
