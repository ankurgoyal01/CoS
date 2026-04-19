---
service: "merchant-page"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "in-process-merchant-cache"
    type: "in-memory"
    purpose: "Short-lived merchant page data cache"
---

# Data Stores

## Overview

The merchant-page service is stateless and does not own any persistent data stores (no database, no Redis instance, no S3 bucket). All merchant, deal, review, and map data is fetched synchronously from downstream services on each request. The service applies an in-process response cache (`itier-cached`) to reduce upstream call frequency for merchant data.

## Stores

> No persistent data stores are owned by this service.

This service is stateless and does not own any data stores. All data is sourced from upstream services at request time.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `merchant` | in-memory (`itier-cached`) | Caches merchant/place data responses to reduce calls to `continuumUniversalMerchantApi` | 60 seconds (base / staging); 3600 seconds (production) |

### Cache Configuration Details

The cache TTL is environment-specific, configured via CSON config files:

- **Base/staging default**: `cache.merchant.freshFor = 60` (seconds) — `config/base.cson`
- **Production override**: `cache.merchant.freshFor = 3600` (seconds) — `config/stage/production.cson`
- **Global cache timeout**: `cache.globalDefaults.timeout = 100` (ms) — `config/base.cson`

## Data Flows

All data flows are inbound-only (read) from external services:

- Merchant/place data flows from `continuumUniversalMerchantApi` → MPP Client Adapter → Merchant Route Handler → page render.
- Deal card data flows from `continuumRelevanceApi` → RAPI Client Adapter → card rendering → page or fragment response.
- Review data flows from `continuumUgcService` → UGC Client Adapter → page or fragment response.
- Map signing flows as a URL redirect from `gims` via the Map Signing Adapter.

No data is written or stored by this service.
