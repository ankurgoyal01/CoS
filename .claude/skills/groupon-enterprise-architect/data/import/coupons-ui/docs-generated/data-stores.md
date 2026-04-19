---
service: "coupons-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCouponsRedis"
    type: "redis"
    purpose: "Read-through cache for merchant page payloads and site-wide coupon data"
  - id: "continuumCouponsMemoryCache"
    type: "in-memory"
    purpose: "Process-local buffer for site-wide coupon data to reduce Redis reads"
---

# Data Stores

## Overview

Coupons UI is a read-only consumer of two caches. It does not own a primary database and does not write any application data. A Redis instance holds pre-populated merchant page payloads and site-wide coupon data written by an upstream worker. A process-local NodeCache instance buffers frequently accessed site-wide data to reduce Redis round-trips within the same Node.js process lifetime.

## Stores

### Coupons Redis Cache (`continuumCouponsRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumCouponsRedis` |
| Purpose | Read-through cache of merchant coupon page payloads and site-wide coupon data |
| Ownership | shared (populated by upstream coupon worker; consumed read-only by this service) |
| Migrations path | Not applicable — schema-less key/value store |

#### Key Entities

| Redis Key Pattern | Purpose | Key Fields |
|-------------------|---------|-----------|
| `cf:MerchantPageData:{countryCode}_19_{merchantPermalink}` | Merchant page payload including offers, SEO metadata, and related merchants | Country code, domain ID (19), merchant permalink |
| `cf:SiteWideData:{countryCode}_19` | Site-wide coupon data for navigation and trending sections | Country code, domain ID (19) |

#### Access Patterns

- **Read**: `VoucherCloudClient.getMerchantDataByPermalink()` performs a single key `GET` per SSR page request using the pattern `cf:MerchantPageData:{countryCode}_19_{merchantPermalink}`. `VoucherCloudClient.getSiteWideData()` performs a key `GET` for `cf:SiteWideData:{countryCode}_19`, wrapped by in-memory cache to avoid repeated Redis lookups.
- **Write**: This service does not write to Redis. Keys are populated externally by the upstream coupon worker.
- **Indexes**: Not applicable — direct key lookup only.

#### Connection Configuration

| Parameter | Base default | Production (US) | Production (EU) | Staging (US) |
|-----------|-------------|-----------------|-----------------|--------------|
| Host | `localhost` | `coupon-worker-memorystore.us-central1.caches.prod.gcp.groupondev.com` | `coupon-worker-memorystore.europe-west1.caches.prod.gcp.groupondev.com` | `coupons-ui-memorystore.us-central1.caches.stable.gcp.groupondev.com` |
| Port | `6379` | `6379` | `6379` | `6379` |
| TTL | `3600` s | inherited | inherited | inherited |
| Max retries | `3` | `5` | `5` | `5` |

---

### Coupons Memory Cache (`continuumCouponsMemoryCache`)

| Property | Value |
|----------|-------|
| Type | In-memory (NodeCache) |
| Architecture ref | `continuumCouponsMemoryCache` |
| Purpose | Process-local buffer for site-wide coupon data; reduces Redis reads within a single Node.js process |
| Ownership | owned (ephemeral, process-scoped) |
| Migrations path | Not applicable |

#### Key Entities

| Cache Key | Purpose |
|-----------|---------|
| `cf:SiteWideData:{countryCode}_19` | Mirrors the Redis key for site-wide data; avoids repeated Redis reads during the TTL window |

#### Access Patterns

- **Read**: `getOrElse()` helper checks the in-memory cache before falling back to Redis. Returns cached value if present and not expired.
- **Write**: Populated on cache miss by the Redis read result. TTL is set to `3600` seconds (constant `SITE_WIDE_DATA_TTL`).
- **Max size**: Configured via `cache.maxSize` in `config/base.yml`; default `1073741824` bytes (1 GiB).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCouponsRedis` | Redis | Merchant page payloads and site-wide data | 3600 s (set by upstream writer) |
| `continuumCouponsMemoryCache` | In-memory (NodeCache) | Site-wide data buffer per Node.js process | 3600 s |

## Data Flows

Upstream coupon worker populates Redis keys (`cf:MerchantPageData:*`, `cf:SiteWideData:*`). On each page request, the Astro middleware initializes a Redis client and a VoucherCloud Cache Client. The Merchant Page Renderer calls the VoucherCloud Cache Client, which checks the in-memory NodeCache first; on a miss it reads from Redis and populates the NodeCache. Redis data flows one-way into this service — no write-back or CDC occurs.
