---
service: "sub_center"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "memcached_ext_0c5e"
    type: "memcached"
    purpose: "Caches division and channel metadata"
---

# Data Stores

## Overview

sub_center does not own a primary database. It is a stateful-read, stateless-write application: subscription state is owned and persisted by downstream services (Groupon V2 API, Subscriptions Service). The service uses a shared Memcached instance to cache division and channel metadata, reducing repeated upstream calls for frequently-accessed reference data.

## Stores

> sub_center does not own any persistent data stores. All subscription state is managed by downstream services.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `memcached_ext_0c5e` | memcached | Caches division and channel metadata for subscription center pages | Not specified in architecture model |

### Cache Access Details

- **Component**: `subCenter_cacheAccess` (Cache Access component within `continuumSubCenterWebApp`)
- **Data cached**: Division listings and subscription channel metadata
- **Pattern**: Read-through; populated on cache miss by querying downstream services via External API Clients
- **Architecture ref**: `memcached_ext_0c5e` (stub only — not yet in federated model)

## Data Flows

Subscription data follows this read path:

1. Request arrives at the Controller Layer
2. Subscription Handlers invoke Subscription Data Getter
3. Cache Access checks Memcached for division/channel metadata
4. On cache miss, External API Clients fetch data from Subscriptions Service or Groupon V2 API
5. Results are passed to Subscription Presenters to build the view model
6. Page Renderer produces the HTML response

Write path (preference updates / unsubscribe):

1. Controller Layer receives POST request
2. Subscription Handlers call External API Clients to POST updated preferences to Groupon V2 API or Subscriptions Service
3. No local write occurs; state is owned by the downstream service
