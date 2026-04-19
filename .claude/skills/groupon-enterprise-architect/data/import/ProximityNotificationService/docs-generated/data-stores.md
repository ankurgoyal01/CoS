---
service: "proximity-notification-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumProximityNotificationPostgres"
    type: "postgresql"
    purpose: "Primary relational store for hotzone deals, campaigns, and send logs"
  - id: "continuumProximityNotificationRedis"
    type: "redis"
    purpose: "Short-lived user location and rate-limit state cache"
---

# Data Stores

## Overview

The service owns two data stores: a GDS-managed PostgreSQL database as the primary relational store for all persistent domain data, and a Redis cache for low-latency transient state. PostgreSQL is accessed via JDBI DAOs with schema migrations managed by `jtier-migrations`. Redis is accessed via the Jedis 2.9.0 client through a connection pool abstraction (`JedisPoolClient`).

## Stores

### Proximity Notification Postgres (`continuumProximityNotificationPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumProximityNotificationPostgres` |
| Purpose | Stores hotzone deals, category campaigns, and per-user send logs |
| Ownership | owned |
| Migrations path | Managed by `jtier-migrations` (standard JTier migration runner) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Hotzone deals | Stores active hotzone POI deal records with geolocation and campaign bindings | `id` (UUID), `hotZoneId` (UUID), `geoPoint`, `radius`, `expires`, `dealType`, `audienceId`, `audienceType`, `brand` |
| Hotzone category campaigns | Campaign configurations that drive hotzone generation | `id`, `cat` (UUID), `countryCode`, `radius`, `startDate`, `dealType`, `audienceId`, `isAuto`, `active` |
| Send logs | Per-user notification send history for rate-limit enforcement | `bcookie`, `hotZoneId`, `dealType`, `sendType`, send timestamp |
| UI users | Proximity UI user access records | `consumer_id` (UUID) |

#### Access Patterns

- **Read**: Send log lookup by `bcookie` with duration window filter (used before every geofence response); hotzone deal lookup by geographic proximity query; campaign read for hotzone generation jobs
- **Write**: Insert send log records after successful push notification dispatch; upsert hotzone deals during batch generation; CRUD for campaigns via hotzone management API
- **Indexes**: Hotzone deals are queried spatially; send logs are queried by `bcookie` and time window

### Proximity Notification Redis (`continuumProximityNotificationRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumProximityNotificationRedis` |
| Purpose | Caches recent user location and travel state for rate-limit and travel guard logic |
| Ownership | owned |
| Migrations path | Not applicable (schema-free) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| User location state | Stores most recent reported location per device for travel detection | Keyed by `bcookie` |
| Travel state | Tracks whether a device is in "travel" mode and last travel update time | Keyed by `bcookie` |
| Rate limit counters | Transient send counts per device per time window | Keyed by `bcookie` + deal type |

#### Access Patterns

- **Read**: Fetched at start of each geofence request to check rate-limit and travel state
- **Write**: Updated after each geofence event with new location and travel status

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumProximityNotificationRedis` | redis | User location history, travel state, and transient rate-limit counters | Configured per-entry via pool settings; `maxWait` 800ms, connection `timeout` 1000ms |

## Data Flows

1. On each geofence POST, the Geofence Workflow reads the send log from PostgreSQL and the user's travel/location state from Redis.
2. If a notification is sent, the Geofence Workflow writes a send log record to PostgreSQL and updates the Redis state.
3. The Hotzone Job Scheduler writes new hotzone deal records to PostgreSQL during batch generation runs.
4. The hotzone management API reads and writes hotzone and campaign records in PostgreSQL.
5. PostgreSQL replication: data is written to a read-write primary and replicated to a read-only replica (managed by GDS team). Backups are performed by the GDS team.
