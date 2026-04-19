---
service: "occasions-itier"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumOccasionsMemcached"
    type: "memcached"
    purpose: "Cache for campaign configs and deal API responses"
  - id: "in-process-memory"
    type: "in-memory"
    purpose: "Division configs, occasion themes, and card permalink maps"
---

# Data Stores

## Overview

occasions-itier uses two tiers of caching to reduce upstream API load. Memcached (`continuumOccasionsMemcached`) stores serialized campaign and deal API responses. Node.js in-process memory holds hot-path data structures — division configurations, merchandising themes, and card permalink maps — that are refreshed by the background Campaign Service poller. The service owns no persistent relational or document database.

## Stores

### Occasions Memcached (`continuumOccasionsMemcached`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `continuumOccasionsMemcached` |
| Purpose | Cache serialized campaign configuration and deal API response payloads |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Campaign config cache entry | Stores Campaign Service (ArrowHead) response for a given occasion/division | occasion slug, division ID, serialized config, TTL |
| Deal response cache entry | Stores Groupon V2 API deal results for occasion + geo + offset combinations | occasion slug, geo key, offset, serialized deal list, TTL |

#### Access Patterns

- **Read**: On every page render and AJAX deal request, the service checks Memcached before calling upstream APIs. A cache hit returns the stored payload directly.
- **Write**: The Campaign Service poller writes refreshed configs every 1800 seconds. Deal responses are written on first fetch per cache key combination. Manual `POST /cachecontrol` invalidates entries.
- **Indexes**: Not applicable (Memcached key-value store).

### Node In-Process Memory (`in-process-memory`)

| Property | Value |
|----------|-------|
| Type | in-memory |
| Architecture ref | `continuumOccasionsItier` |
| Purpose | Hot-path storage for division data, occasion themes, and card permalink maps |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Division map | Maps division IDs to locale/currency/region config; managed by `itier-divisions` | division ID, locale, currency, region |
| Occasion theme map | Maps occasion slugs to visual theme configs (colors, copy, imagery) | occasion slug, theme config |
| Card permalink map | Maps card identifiers to resolved permalink paths | card ID, permalink |

#### Access Patterns

- **Read**: Synchronous in-process lookup on every page render; zero network latency.
- **Write**: Refreshed on startup and on each Campaign Service poll cycle (every 1800 seconds).
- **Indexes**: Not applicable (in-process JavaScript Map/Object).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumOccasionsMemcached` | memcached | Campaign config and deal API response caching | Managed by `itier-cached`; configurable per entry type |
| In-process division/theme store | in-memory | Division configs, themes, and card permalink maps | Refreshed every 1800s via Campaign Service poll |

## Data Flows

On startup, the Campaign Service poller fetches occasion configs from Campaign Service (ArrowHead) and populates both the in-process memory maps and Memcached entries. Every 1800 seconds the poller re-runs, writing fresh values to both tiers. On each HTTP request, the service reads from in-process memory first (for division/theme data) and from Memcached second (for deal/campaign payloads). A cache miss triggers a live upstream API call; the result is then written back to Memcached. Operators can flush Memcached entries on demand via `POST /cachecontrol`.
