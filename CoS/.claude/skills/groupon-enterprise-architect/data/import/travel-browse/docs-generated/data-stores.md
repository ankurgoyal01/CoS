---
service: "travel-browse"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "memcacheCluster"
    type: "memcached"
    purpose: "Session and page-level API response cache"
---

# Data Stores

## Overview

travel-browse is largely stateless — it does not own a primary relational or document database. Its only data store is a shared Memcached cluster used for session context and caching API responses from downstream services. All persistent data (deal details, hotel inventory, geo metadata, user subscriptions) is owned by upstream APIs and fetched on demand.

## Stores

### Memcache Cluster (`memcacheCluster`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `memcacheCluster` |
| Purpose | Session state and cached API responses from RAPI, LPAPI, Getaways API, and Geodetails |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Session data | Stores user session context between requests | Session ID, user identity token |
| API response cache | Caches responses from RAPI, LPAPI, Getaways API, and Geodetails | Cache key (URL + params hash), serialised response payload, TTL |

#### Access Patterns

- **Read**: `travelBrowse_cacheAccess` and `apiClients` components check the cache before making downstream API calls; cache key is derived from request parameters.
- **Write**: Successful downstream API responses are stored in Memcache with a TTL to reduce repeated upstream calls.
- **Indexes**: Not applicable (key-value store; lookup by cache key only).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `memcacheCluster` | memcached | API response and session caching | Per-entry TTL set at write time; specific values managed at application layer |

## Data Flows

All persistent Getaways data originates in upstream APIs (RAPI, Getaways API, Maris API, Geodetails). travel-browse reads from these APIs, optionally caches responses in `memcacheCluster` via the `travelBrowse_cacheAccess` component, and renders HTML. No CDC, ETL, or replication patterns are used — data flows are request-scoped and ephemeral.
