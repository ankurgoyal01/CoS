---
service: "badges-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBadgesRedis"
    type: "redis"
    purpose: "Primary badge state cache — stores per-item badge assignments, per-user-item badge entries, and Janus deal-stats results"
---

# Data Stores

## Overview

The Badges Service uses Redis (provisioned via STaaS) as its sole persistent data store. Redis serves both as the primary write-through badge state store (item badges, user-item badges) and as a read-through cache layer for downstream dependency results (Janus deal-stats, recently-viewed data). There is no relational database.

## Stores

### Badges Redis (`continuumBadgesRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumBadgesRedis` |
| Purpose | Caches badge data, user-item badge data, and Janus deal-stats responses |
| Ownership | owned (provisioned via STaaS) |
| Migrations path | Not applicable — schema-less key/value store |

#### Key Entities

| Key Pattern | Purpose | Key Fields / Notes |
|-------------|---------|-------------------|
| Per-item badge entries | Stores badge type assignments for a deal UUID | Keyed by deal UUID; written by `BadgesController.setItemBadgesInCache`; TTL set to 21,600 seconds (6 hours) by `MerchandisingBadgeJob` |
| Per-user-item badge entries | Stores badge assignments scoped to a specific consumer or visitor + deal UUID | Keyed by consumer/visitor ID + deal UUID |
| `Last24Hours_DealStats_<dealId>_v7` | Caches Janus last-24-hour deal view/purchase stats | Written by `DealStatsClientJanusImpl`; TTL configured via `janusConfig.last24hoursCacheTtl` |
| `Last7Days_Purchases_<dealId>_v7` | Caches Janus last-7-day purchase counts per deal | Written by `DealStatsClientJanusImpl`; TTL configured via `janusConfig.last7daysCacheTtl` |
| `LastPurchase_Time_<dealId>_v7` | Caches Janus last purchase timestamp per deal | Written by `DealStatsClientJanusImpl`; TTL configured via `janusConfig.lptCacheTtl` |
| `Last5Min_Views_<dealId>_v7` | Caches Janus last-5-minute view counts per deal | Written by `DealStatsClientJanusImpl`; TTL configured via `janusConfig.last5minCacheTtl` |

#### Access Patterns

- **Read**: High-frequency synchronous reads on every badge lookup request; cache-hit path uses both Lettuce (async cluster) and Jedis (sync) clients
- **Write**: Badge state is written during `POST /badges/v1/itemBadges`, `POST /badges/v1/setUserItemBadges`, and by `MerchandisingBadgeJob` (scheduled batch); Janus stats results are written inline during async HTTP response handling
- **Indexes**: Not applicable — Redis key-based lookup only

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumBadgesRedis` (badge state) | Redis | Per-item and per-user-item badge assignments | 21,600 s (6 hours) for merchandising badges; configurable per badge type |
| `continuumBadgesRedis` (Janus last-24h stats) | Redis | Deal view + purchase counts over 24 hours | Configured via `janusConfig.last24hoursCacheTtl` |
| `continuumBadgesRedis` (Janus last-7d purchases) | Redis | Cumulative purchase count over 7 days | Configured via `janusConfig.last7daysCacheTtl` |
| `continuumBadgesRedis` (Janus last purchase time) | Redis | Timestamp of most recent purchase | Configured via `janusConfig.lptCacheTtl` |
| `continuumBadgesRedis` (Janus last-5min views) | Redis | View count in last 5 minutes | Configured via `janusConfig.last5minCacheTtl` |
| In-memory localization cache | In-memory | Localized badge strings fetched from Localization API | Refreshed on schedule by `LocalizationJob` |

## Data Flows

- On every inbound badge lookup request, the `feedService` reads badge state from Redis and enriches it with recently-viewed data from Watson KV.
- On every inbound badge lookup request, the `badgeEngine` fetches Janus deal stats through the `externalClientGateway`, which first checks the Redis cache (stale-while-revalidate pattern with a 5-minute async refresh for 24-hour stats).
- The `MerchandisingBadgeJob` (Quartz scheduled) polls the Deal Catalog Service for deals associated with merchandising taxonomy tags and writes the resulting badge-item entries to Redis with a 6-hour expiry.
- The `LocalizationJob` (Quartz scheduled) fetches localized string packages from the Localization API and populates an in-memory cache used by the badge decoration step.
