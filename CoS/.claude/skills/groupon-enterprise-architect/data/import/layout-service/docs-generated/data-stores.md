---
service: "layout-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumLayoutTemplateCache"
    type: "redis"
    purpose: "In-memory cache for rendered Mustache templates and layout fragments"
---

# Data Stores

## Overview

Layout Service has a single data dependency: a Redis cache used to store compiled Mustache templates and rendered layout fragments. The service does not own a relational or document database. All durable state (template source files, brand assets) lives in the deployed artifact and CDN, not in a database.

## Stores

### Layout Template Cache (`continuumLayoutTemplateCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumLayoutTemplateCache` |
| Purpose | In-memory cache for rendered templates and fragments used by Layout Service |
| Ownership | owned |
| Migrations path | Not applicable — schema-free key/value cache |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|----------------------|---------|-----------|
| Compiled template entries | Store pre-compiled Mustache/Hogan template bytecode to avoid re-compilation on each request | Template identifier, locale/market variant |
| Rendered fragment entries | Cache fully rendered layout fragments (header, footer) for repeated identical context combinations | Request context hash (locale, market, feature flags) |

#### Access Patterns

- **Read**: `layoutSvc_templateCacheClient` performs a cache lookup before rendering; a cache hit returns the compiled template or pre-rendered fragment directly, bypassing the Mustache render step.
- **Write**: `layoutSvc_templateCacheClient` writes newly compiled templates and freshly rendered fragments to cache after a cache miss, using a TTL to ensure eventual refresh.
- **Indexes**: Not applicable — Redis key-value access by deterministic key derived from template identity and context.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumLayoutTemplateCache` | redis | Stores compiled Mustache templates and rendered layout fragments to reduce per-request rendering overhead | Managed by service configuration; specific TTL values not evidenced in architecture inventory |

## Data Flows

On each layout request, `layoutSvc_templateRenderer` asks `layoutSvc_templateCacheClient` for a cached compiled template. On a miss, the renderer compiles the template from source, delegates asset URL injection to `layoutSvc_assetResolver`, renders the final fragment, and writes the result back to `continuumLayoutTemplateCache`. No CDC, ETL, or cross-store replication exists — the cache is the only store.
