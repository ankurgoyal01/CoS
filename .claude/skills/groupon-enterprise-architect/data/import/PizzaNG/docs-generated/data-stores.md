---
service: "PizzaNG"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "ticketFields-cache"
    type: "in-memory"
    purpose: "Caches ticket field metadata to reduce repeated downstream calls"
---

# Data Stores

## Overview

PizzaNG owns one in-process in-memory cache (`ticketFields`) for ticket field metadata. It does not own any persistent databases. All customer, order, deal, refund, and snippet data is fetched on demand from downstream services and held only for the lifetime of the cache TTL or the process.

## Stores

> This service is stateless with respect to persistent data and does not own any databases.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `ticketFields` | in-memory | Caches Zendesk ticket field metadata to avoid repeated downstream lookups per request | 2 hours |

### ticketFields Cache

- **Location**: In-process memory within `continuumPizzaNgService`
- **Populated by**: Downstream call to Zendesk (via `continuumPizzaNgZendeskIntegration`) on first access or after TTL expiry
- **Invalidation**: Time-based — entries expire after 2 hours of freshness
- **Impact if lost**: On process restart or expiry, the cache is repopulated from Zendesk on the next request; no data loss

## Data Flows

Ticket field metadata flows from Zendesk into the `ticketFields` in-memory cache on first access. Subsequent requests within the 2-hour window are served from cache. All other data (customer, order, deal, refund, snippet) is fetched live from CAAP, Cyclops, Deal Catalog, CFS, and API Proxy on each BFF request.
