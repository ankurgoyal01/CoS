---
service: "api-lazlo-sox"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumApiLazloRedisCache"
    type: "redis"
    purpose: "Distributed cache for taxonomy, localization, feature flags, and transient state"
---

# Data Stores

## Overview

API Lazlo and API Lazlo SOX are stateless gateway services. They do not own any relational databases or persistent storage. The only data store is a shared Redis cache cluster used for taxonomy lookups, localization data, feature flags, and other transient or session-like state. All persistent data is owned by the downstream domain services that API Lazlo aggregates.

## Stores

### API Lazlo Redis Cache (`continuumApiLazloRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumApiLazloRedisCache` |
| Purpose | Distributed cache for taxonomy, localization, feature flags, and transient state |
| Ownership | Owned (shared between API Lazlo and API Lazlo SOX) |
| Managed service | GCP MemoryStore (managed Redis cluster) |

#### Key Entities

| Key Pattern | Purpose | Key Fields |
|-------------|---------|-----------|
| `taxonomy:*` | Cached taxonomy category trees and mappings | Category ID, hierarchy, labels |
| `localization:*` | Cached localization strings by locale and market | Locale, key, translated value |
| `feature-flag:*` | Feature flag state for per-request feature gating | Flag name, enabled/disabled, variant |
| `session:*` | Transient session-like state (where applicable) | Session ID, user context |
| `geo:*` | Cached geo/division lookup results | Division ID, coordinates, market |

#### Access Patterns

- **Read**: High-throughput reads for taxonomy, localization, and feature flags on every inbound request. Read-through caching pattern where cache misses trigger downstream service calls and populate the cache.
- **Write**: Cache population on miss from downstream service responses. TTL-based expiration for all keys. Feature flag updates may be pushed or refreshed on a schedule.
- **TTL**: Varies by key pattern; taxonomy and localization data may have longer TTLs (minutes to hours), while feature flags and session data use shorter TTLs (seconds to minutes).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Taxonomy cache | Redis (`continuumApiLazloRedisCache`) | Pre-computed taxonomy category trees for mobile display | Minutes to hours |
| Localization cache | Redis (`continuumApiLazloRedisCache`) | Translated strings per locale to avoid per-request lookups | Minutes to hours |
| Feature flags | Redis (`continuumApiLazloRedisCache`) | Runtime feature flag state for request-level gating | Seconds to minutes |
| Transient state | Redis (`continuumApiLazloRedisCache`) | Ephemeral session-like and cart-related state | Seconds to minutes |

## Data Flows

API Lazlo does not perform CDC, ETL, or data replication. The Redis cache is populated via read-through caching: on cache miss, the relevant BLS module calls the downstream domain service, and the response is cached in Redis with a TTL before being returned to the client. Cache invalidation is primarily TTL-based.

### Cache Access by Component

| Component | Container | Cache Operations |
|-----------|-----------|-----------------|
| `continuumApiLazloService_redisAccess` | API Lazlo Service | Primary Redis access layer for all BLS modules |
| `continuumApiLazloSoxService_redisAccess` | API Lazlo SOX Service | Redis access layer for SOX BLS modules |
| `continuumApiLazloService_usersBlsModule` | API Lazlo Service | Caches user-related and session-like data |
| `continuumApiLazloService_dealsBlsModule` | API Lazlo Service | Caches deal and taxonomy-related computations |
| `continuumApiLazloService_ordersBlsModule` | API Lazlo Service | Caches cart and order-related ephemeral state |
| `continuumApiLazloSoxService_sharedBlsModules` | API Lazlo SOX Service | Caches configuration and transient state for SOX flows |
