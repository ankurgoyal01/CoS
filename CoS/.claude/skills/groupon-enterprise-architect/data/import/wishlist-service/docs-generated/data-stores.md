---
service: "wishlist-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumWishlistPostgresRw"
    type: "postgresql"
    purpose: "Primary write datastore for wishlist lists, items, and user bucket state"
  - id: "continuumWishlistPostgresRo"
    type: "postgresql"
    purpose: "Read replica for wishlist read-heavy queries"
  - id: "continuumWishlistRedisCluster"
    type: "redis"
    purpose: "Cache and queue backing store for user/list caching and bucket processing"
---

# Data Stores

## Overview

The Wishlist Service uses two PostgreSQL instances (read-write primary and read-only replica) backed by Groupon's DaaS (Database as a Service) infrastructure for persistent wishlist data, and a Redis cluster backed by Groupon's RaaS (Redis as a Service) infrastructure for caching, background processing queues, and price-drop state. PostgreSQL hosts all wishlist lists, items, user records, and user bucket state. Redis provides sub-millisecond access for deal metadata caching, user queue management, and price-drop event caching.

## Stores

### Wishlist Postgres RW (`continuumWishlistPostgresRw`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumWishlistPostgresRw` |
| Purpose | Primary write datastore for wishlist lists, items, and user bucket state |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` bundle (Flyway-style); migration scripts bundled with the service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Lists | Stores user wishlist list metadata | listId (UUID), consumerId (UUID), listName (string), locale (string), isPublic (boolean), created (timestamp), modified (timestamp) |
| Items | Stores individual wishlist item records linked to lists | itemId (UUID), listId (UUID), dealId (UUID), optionId (UUID), channelId (UUID), created (timestamp), expires (timestamp), purchased (timestamp), gifted (timestamp) |
| Users | Tracks registered wishlist users and notification state | userId (UUID), notifyEmail (timestamp — last email sent), notifyPush (timestamp — last push sent) |
| User Buckets | Tracks background processing bucket assignments for user queue partitioning | bucket ID, bucket state (IDLE/QUEUEING), lastUpdated (timestamp) |

#### Access Patterns

- **Read**: All API list/item retrieval queries and background job user enumeration target the read-only replica (`continuumWishlistPostgresRo`) via JDBI3 DAO interfaces. Supports filtering by consumerId, listId, listName, dealId, optionId, channelId, purchased/gifted state, and date ranges with offset/limit pagination.
- **Write**: List creation, item addition, item deletion, bucket state updates, purchased/gifted timestamp updates, and notification state updates target the read-write primary via JDBI3 DAO interfaces.
- **Indexes**: Not directly visible from source code. Standard indexes expected on `consumerId`, `listId`, `dealId`, `optionId` based on query patterns.

### Wishlist Postgres RO (`continuumWishlistPostgresRo`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumWishlistPostgresRo` |
| Purpose | Read replica for wishlist read-heavy API queries and background job user enumeration |
| Ownership | owned (replica) |
| Migrations path | N/A — replica follows primary |

#### Access Patterns

- **Read**: API list/item retrieval queries and background `UserEnqueueJob` user enumeration by bucket.
- **Write**: None — read-only replica.

### Wishlist Redis Cluster (`continuumWishlistRedisCluster`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumWishlistRedisCluster` |
| Purpose | Cache for deal metadata/pricing/inventory responses, user ID queue for background processing, and price-drop state |
| Ownership | owned (RaaS-managed) |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal metadata cache | Caches deal catalog, pricing, and inventory responses to meet 40ms SLA | Keyed by deal/option UUID |
| User bucket queue | Queues user UUID sets for background item processing (enqueue/dequeue pipeline) | User UUID |
| Price-drop state | Caches detected price-drop events per deal for notification deduplication | `priceDrops:<dealId>` (string key) |

#### Access Patterns

- **Read**: Background `UserDequeueJob` (every 2 seconds) pops user IDs from the queue. API and job processors read cached deal metadata on cache hit.
- **Write**: `UserEnqueueJob` (every 5 seconds) pushes user ID sets into the queue after claiming a free bucket. `RedisPriceDropHandler` stores price-drop state under `priceDrops:<dealId>` with `priceDropCacheExpiry` TTL (default 24 hours). Deal cache entries written on cache miss from external service calls.
- **Indexes**: Not applicable (Redis key-value store).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Deal metadata cache (`continuumWishlistRedisCluster`) | Redis | Caches deal catalog, pricing, and inventory API responses to serve wishlist decorations within 40ms | Configured per environment (`listCacheExpiry`, default 24 hours) |
| User cache (`continuumWishlistRedisCluster`) | Redis | Caches user records for fast lookup during background processing | `userCacheExpiry`, default 24 hours |
| Price-drop cache (`continuumWishlistRedisCluster`) | Redis | Stores price-drop events per deal for push notification deduplication | `priceDropCacheExpiry`, default 24 hours |

## Data Flows

- PostgreSQL primary receives all wishlist write operations from the `app` component via JDBI3 DAOs (`ListDao`, `ListItemDao`, `UserDao`, `UserBucketDao`).
- PostgreSQL read replica serves read-heavy API queries and background job user enumeration queries.
- `UserEnqueueJob` (every 5 seconds on worker) claims a free bucket from PostgreSQL, loads user IDs for that bucket, filters inactive users (no wishlist activity in past 12 months), and pushes active user IDs into the Redis queue.
- `UserDequeueJob` (every 2 seconds on worker) pops user ID batches from Redis and fans them out through a pipeline of registered `UserProcessingTask` implementations (`ChannelUpdateTask`, `ExpiryUpdateTask`, `ListItemProcessingTask`, `UpdateBucketNumbersTask`).
- Price-drop events received from MBus are cached in Redis by `RedisPriceDropHandler`; push notification tasks read from this cache when determining which users to notify.
- On DaaS datastore failure and snapshot restoration, Redis should be flushed to clear stale cached data.
