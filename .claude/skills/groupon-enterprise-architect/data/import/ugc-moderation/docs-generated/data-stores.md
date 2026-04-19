---
service: "ugc-moderation"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "memcachedCache"
    type: "memcached"
    purpose: "Taxonomy/business data caching"
---

# Data Stores

## Overview

UGC Moderation does not own a primary database. All UGC data is owned and persisted by the `continuumUgcService` backend. The service uses a shared Memcached instance for short-term caching of taxonomy and business data to reduce upstream API call volume.

## Stores

### Memcached Cache (`memcachedCache`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `memcachedCache` (stub — external to federated model) |
| Purpose | Caches taxonomy/business data to reduce repeated upstream calls |
| Ownership | shared / external (not owned by this service) |
| Migrations path | Not applicable |

#### Key Entities

| Cache Key Pattern | Purpose | Key Fields |
|-------------------|---------|-----------|
| `taxonomy:business` | Business/taxonomy classification data | Configured namespace `taxonomy:business` |

#### Access Patterns

- **Read**: Taxonomy/business cache reads per request as needed by the UI rendering layer.
- **Write**: Cache population on cache miss.
- **TTL**: `expire: 2592000` (30 days), `freshFor: 864000` (10 days) — configured in `config/base.cson`.

#### Connection Configuration (from `config/base.cson`)

| Parameter | Value |
|-----------|-------|
| `memcached.hosts` | `localhost:11211` (development default) |
| `memcached.poolSize` | 100 |
| `memcached.reconnect` | 300000 ms |
| `memcached.retry` | 1000 ms |
| `memcached.timeout` | 100 ms |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `taxonomy:business` | memcached | Caches business taxonomy data | 30 days (expire), 10 days (freshFor) |

## Data Flows

UGC Moderation reads data from `continuumUgcService` on demand (per user request) and passes results directly to the HTML/JSON response. No ETL, CDC, or data replication pipelines exist. The Memcached cache is populated on cache miss and serves as a read-through cache for taxonomy data only.
