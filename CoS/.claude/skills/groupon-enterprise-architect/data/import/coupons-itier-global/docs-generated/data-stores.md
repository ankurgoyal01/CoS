---
service: "coupons-itier-global"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCouponsRedisCache"
    type: "redis"
    purpose: "Shared cache for coupon offers, redirects, and derived render payloads"
---

# Data Stores

## Overview

`coupons-itier-global` uses a single Redis cache as its data store. The service is otherwise stateless — it holds no primary relational or document database. All persistent coupon and merchant data originates from Vouchercloud API and GAPI; Redis provides a caching layer to reduce latency and backend load.

## Stores

### Coupons I-Tier Redis Cache (`continuumCouponsRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumCouponsRedisCache` |
| Purpose | Shared cache for coupon offers, redirects, and derived render payloads |
| Ownership | owned |
| Migrations path | Not applicable (schema-less key-value store) |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| Coupon offer payloads | Cache Vouchercloud offer data to avoid repeated upstream API calls | Offer ID, country/locale |
| Redirect rules | Cache merchant and offer redirect URL mappings for low-latency redirect resolution | Merchant ID, Offer ID |
| Render payloads | Cache server-side rendered page fragments or data payloads | Route key, locale |

#### Access Patterns

- **Read**: `couponsItierGlobal_cacheClient` reads cached offer data, redirect rules, and render payloads on each inbound request before falling back to upstream API calls
- **Write**: `couponsItierGlobal_cacheClient` writes Vouchercloud and GAPI responses into Redis after each upstream fetch; `redirectCacheCron` bulk-writes refreshed redirect rules on schedule
- **Indexes**: Not applicable (Redis key-value access by key pattern)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCouponsRedisCache` | Redis | Caches offer data, redirect rules, and render payloads to reduce Vouchercloud and GAPI load | Not documented in architecture model |

## Data Flows

Upstream data from Vouchercloud API flows into Redis via two paths:

1. **On-demand**: When `itierServer` handles a page or redirect request, `couponsItierGlobal_cacheClient` checks Redis first. On a cache miss it delegates to `couponsItierGlobal_vouchercloudClient`, receives the response, writes it to `continuumCouponsRedisCache`, and returns the result.
2. **Scheduled refresh**: `redirectCacheCron` runs on a defined schedule, fetches all current redirect rules from Vouchercloud via `couponsItierGlobal_vouchercloudClient`, and bulk-writes them into `continuumCouponsRedisCache` via `couponsItierGlobal_cacheClient`.

GAPI-sourced deal and redemption data follows the same on-demand cache-aside pattern.
