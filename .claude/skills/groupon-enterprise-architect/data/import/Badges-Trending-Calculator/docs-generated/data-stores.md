---
service: "badges-trending-calculator"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBadgesRedisStore"
    type: "redis"
    purpose: "Intermediate deal-count hashes, final weekly badge rankings, and cached geographic division set"
---

# Data Stores

## Overview

The service uses a single Redis data store (`continuumBadgesRedisStore`) for all state: daily rolling deal-count hashes that accumulate purchase quantities per deal, final weekly Top-500 Trending and Top Seller ranked-list hashes used directly by `badges-service`, and the cached set of supported geographic divisions refreshed hourly from Bhuvan. In production the store is a Redis Cluster (Google Memorystore); in staging it operates in standalone mode. The same Redis instance is shared with `badges-service`.

## Stores

### Badges Redis Store (`continuumBadgesRedisStore`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumBadgesRedisStore` |
| Purpose | Intermediate per-day deal-count hashes, final weekly badge rankings (Trending and Top Seller), supported division cache |
| Ownership | shared (with `badges-service`) |
| Migrations path | Not applicable — schema is managed via key naming conventions |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| `{prefix}\|date={date}\|type={channel}\|div={division}` | Daily deal-count hash; field = `{dealUUID}\|{dealPermalink}`, value = purchase count string | prefix, date, channel, division |
| `wfinal\|{prefix}\|{calcType}_deal\|{baseKey}` | Final weekly ranked hash (Top Seller or Trending); used by `badges-service` | prefix, calcType (`trending` / `top_seller`), division, channel |
| `{hashTag}\|{prefix}\|wfinal\|{calcType}_deal\|{dealUUID}` | Per-deal rank-and-count string; cluster-mode uses CRC16 hash tag for slot locality | dealUUID, calcType |
| `Divison_Supported` | Cached comma-separated string of supported division permalinks | — |

#### Access Patterns

- **Read**: `HGETALL` on daily deal-count keys to retrieve persisted counts for the 7-day window; `GET` on `Divison_Supported` to populate the division filter cache per micro-batch.
- **Write**: `HSET` + `EXPIRE` to accumulate/overwrite daily deal-count hashes; `UNLINK` + `HSET` + `EXPIRE` to atomically replace final weekly ranked hashes; `SETEX` to write per-deal rank-and-count strings; `SETEX` with 3600s TTL to refresh `Divison_Supported`.
- **Indexes**: No explicit Redis indexes. Key structure encodes all partition dimensions (prefix, date, channel, division). Cluster mode uses CRC16 hash tags on deal UUID for slot affinity.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `Divison_Supported` | redis (string) | Cached set of supported geographic division permalinks per country | 3600 seconds (1 hour) |
| Daily deal-count hashes | redis (hash) | Per-day rolling purchase counts per deal, used as rolling input to weekly aggregation | 691200 seconds (8 days) |
| Per-deal rank-and-count strings | redis (string) | Final per-deal Trending/Top Seller rank and count | 86400 seconds (1 day) |

## Data Flows

Purchase events arrive per Spark micro-batch. The processor reads 7 days of existing daily hashes from Redis (`HGETALL`), merges in new batch counts, applies daily decay (factor 0.9^day) for Trending, produces Top-500 ranked maps, and writes all updates back to Redis atomically per partition. The `GeoServiceTask` independently refreshes `Divison_Supported` every hour by calling Bhuvan and overwriting the key. The `badges-service` reads the final weekly ranked hashes and per-deal strings in real time to serve deal badges.
