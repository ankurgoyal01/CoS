---
service: "epods"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumEpodsPostgres"
    type: "postgresql"
    purpose: "Primary persistent store for mappings, bookings, products, merchants, and units"
  - id: "continuumEpodsRedis"
    type: "redis"
    purpose: "Caching and distributed locks"
---

# Data Stores

## Overview

EPODS uses two data stores: a PostgreSQL database as the primary persistent store for all entity mappings and booking records, and a Redis instance for availability caching and distributed locking. The service owns both stores exclusively — they are not shared with other Continuum services.

## Stores

### EPODS Postgres (`continuumEpodsPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumEpodsPostgres` |
| Purpose | Stores EPODS data such as mappings, bookings, products, merchants, and units |
| Ownership | owned |
| Migrations path | > No evidence found — refer to service repository for migration scripts |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `bookings` | Records of partner-backed bookings created through EPODS | bookingId, partnerId, dealId, status, createdAt, updatedAt |
| `mappings` | Bi-directional ID mappings between Groupon entities and partner-system identifiers | grouponId, partnerEntityId, entityType, partnerId |
| `products` | Partner-translated product records linked to Groupon deals | productId, partnerId, grouponDealId, partnerProductId |
| `merchants` | Partner-translated merchant records | merchantId, partnerId, grouponMerchantId, partnerMerchantId |
| `units` | Partner-translated purchasable unit records | unitId, partnerId, grouponUnitId, partnerUnitId |
| `segments` | Booking category/segment mapping records | segmentId, partnerId, grouponSegmentId, partnerSegmentId |

#### Access Patterns

- **Read**: Lookup by Groupon entity ID or partner entity ID using indexed mapping tables; booking status reads by bookingId
- **Write**: Insert on booking creation; update on booking status change or mapping refresh; upsert patterns for sync operations
- **Indexes**: Expected indexes on `grouponId`, `partnerEntityId`, `bookingId`, and composite `(partnerId, entityType)` — exact schema in service repository

### EPODS Redis (`continuumEpodsRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumEpodsRedis` |
| Purpose | Caching and distributed locks |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

> No evidence found of specific Redis key schemas in the architecture model. Refer to the service repository for cache key naming conventions.

#### Access Patterns

- **Read**: Cache-aside pattern for availability data; lock acquisition checks before sync operations
- **Write**: Cache population after partner availability poll; lock acquisition and release around concurrent sync jobs
- **Indexes**: Not applicable (Redis key-value)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumEpodsRedis` | redis | Availability data caching; distributed locks to prevent concurrent partner sync conflicts | > No evidence found — TTL configured in service properties |

## Data Flows

- Availability data is fetched from partner APIs by the sync job and written to `continuumEpodsRedis` for fast read access by the `/v1/availability` endpoint.
- Booking records are persisted to `continuumEpodsPostgres` on creation and updated on status change events received from partners via webhooks or polling.
- Entity mappings are loaded from `continuumEpodsPostgres` on each inbound request to translate between Groupon and partner-system identifiers.
- No ETL, CDC, or replication to external analytics stores was found in the architecture model.
