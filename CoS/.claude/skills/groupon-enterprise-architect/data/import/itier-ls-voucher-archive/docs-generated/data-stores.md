---
service: "itier-ls-voucher-archive"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumLsVoucherArchiveMemcache"
    type: "memcached"
    purpose: "Runtime page cache — caches rendered responses and backend API results to reduce latency"
---

# Data Stores

## Overview

itier-ls-voucher-archive owns one data store: a Memcached instance used as a runtime cache for rendered page fragments and backend API responses. The service does not own any persistent databases. All authoritative voucher data is stored in the Voucher Archive Backend. The Memcached cache reduces repeated API calls to downstream services on frequently accessed voucher pages.

## Stores

> This service is stateless with respect to persistent data. It does not own any databases or object stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumLsVoucherArchiveMemcache` | memcached | Runtime cache for rendered responses and downstream API results; reduces load on Voucher Archive Backend and Groupon v2 API | Configured per cache key category |

### Memcached (`continuumLsVoucherArchiveMemcache`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `continuumLsVoucherArchiveMemcache` |
| Purpose | Runtime page and API response cache for voucher detail, CSR, and merchant views |
| Ownership | owned |
| Migrations path | Not applicable — cache is ephemeral |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Voucher page cache entries | Cached rendered HTML fragments or API response payloads for individual voucher views | voucher_id, locale, user_role |
| Merchant search result cache | Cached merchant voucher search results for repeated queries | merchant_id, search_params |

#### Access Patterns

- **Read**: Interaction tier checks Memcached before making downstream API calls; cache hit returns stored response directly
- **Write**: On cache miss, the downstream API response is written to Memcached after a successful fetch
- **Indexes**: Not applicable — key-value store with composite string keys

## Data Flows

1. Incoming HTTP request hits `continuumLsVoucherArchiveItier`.
2. Middleware checks `continuumLsVoucherArchiveMemcache` for a cached response keyed by voucher ID, locale, and role.
3. On cache hit: cached response is returned to the browser without calling downstream APIs.
4. On cache miss: downstream APIs (Voucher Archive Backend, Lazlo, etc.) are called; response is assembled, written to Memcached, and returned to the browser.
