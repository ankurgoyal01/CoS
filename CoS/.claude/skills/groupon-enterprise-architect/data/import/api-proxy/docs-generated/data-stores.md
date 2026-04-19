---
service: "api-proxy"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumApiProxyRedis"
    type: "redis"
    purpose: "Distributed rate-limit counters and throttling state"
---

# Data Stores

## Overview

API Proxy uses a single external data store: a dedicated Redis instance (`continuumApiProxyRedis`) that holds shared rate-limit counters and throttling state. The proxy itself is otherwise stateless — route configuration and client identity data are loaded from external services and held in process memory, not persisted locally.

## Stores

### API Proxy Redis (`continuumApiProxyRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumApiProxyRedis` |
| Purpose | Distributed store for rate-limit counters and per-client throttling state shared across proxy instances |
| Ownership | owned |
| Migrations path | Not applicable (schema-free key/value store) |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| Rate-limit counter keys | Track request counts per client/route within a sliding or fixed window | client ID, route identifier, time window |
| Throttling state flags | Indicate whether a given client is currently throttled | client ID, throttle expiry TTL |

#### Access Patterns

- **Read**: `apiProxy_rateLimiter` reads current counter values during each request to determine whether the request exceeds the configured threshold
- **Write**: `apiProxy_rateLimiter` increments counters atomically on each allowed request; sets throttle state flags when limits are breached
- **Indexes**: Redis key namespace conventions enforced by the Rate Limiter component; no secondary indexes

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumApiProxyRedis` | redis | Shared rate-limit counter and throttling state store | Configured per rate-limit window |
| In-process route config | in-memory | Holds resolved route definitions loaded by `apiProxy_routeConfigLoader`; refreshed on config reload | Per reload cycle |
| In-process client ID cache | in-memory | Holds client identity and policy overrides loaded by `apiProxy_clientIdLoader` | Per reload cycle |

## Data Flows

Route configuration and BEMOD data flow into the in-process cache via periodic refresh calls to external services (`continuumClientIdService` for client identity; BASS for BEMOD overlays). Rate-limit counters flow out on every proxied request and back in as read operations; counter data is never replicated or exported to other stores. No CDC, ETL, or replication patterns are used.
