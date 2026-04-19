---
service: "dynamic_pricing"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumPricingDb"
    type: "mysql"
    purpose: "Primary pricing state, history, rules, schedules, and Quartz metadata"
  - id: "continuumPwaDb"
    type: "mysql"
    purpose: "PWA inventory parity for program price state"
  - id: "continuumRedisCache"
    type: "redis"
    purpose: "Low-latency PriceSummary cache for current price lookups"
---

# Data Stores

## Overview

The Pricing Service uses two MySQL databases for persistent state and one Redis cache for low-latency reads. The primary database (`continuumPricingDb`) is the authoritative store for all pricing data. The secondary database (`continuumPwaDb`) maintains inventory parity with voucher systems. Redis (`continuumRedisCache`) accelerates current price lookups by caching serialized PriceSummary records that are invalidated on every price write.

## Stores

### Pricing Service DB (`continuumPricingDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumPricingDb` |
| Purpose | Stores pricing state, price history, program prices, price rules, schedules, and Quartz job metadata |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| pricing state | Current and future retail prices per product | product_id, price_value, currency, effective_date |
| price_history | Audit trail of price changes over time | product_id, price_value, changed_at, quote_id |
| program_prices | Scheduled and active program price tiers | product_id, program_id, price_value, start_date, end_date |
| price_rules | Configured pricing rules applied to products | rule_id, product_id, rule_type, rule_params |
| quartz_* | Quartz scheduler job and trigger metadata | job_name, trigger_name, next_fire_time |

#### Access Patterns

- **Read**: Bulk reads by product ID for current price lookups; history queries by quote ID; price rule lookups per product; scheduled update polling by the worker
- **Write**: Transactional writes via `continuumPricingService_priceUpdateWorkflow` for all price changes; Quartz metadata updates by the scheduler; VIS consumer writes for unit update signals
- **Indexes**: No evidence found for specific index definitions in the available inventory

### PWA DB (`continuumPwaDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumPwaDb` |
| Purpose | Inventory and program price state used for parity with voucher inventory systems |
| Ownership | shared |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| inventory/program price tables | Program price and inventory parity state synchronized from the pricing service | product_id, inventory_state, parity_flag |

#### Access Patterns

- **Read**: Parity checks during program price validation
- **Write**: Synchronized by `continuumPricingService_priceUpdateWorkflow` via `continuumPricingService_pwaDbRepository` after every price change
- **Indexes**: No evidence found

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumRedisCache` | redis | Caches PriceSummary records for low-latency current price endpoint responses | No evidence found |

### Cache Behavior

- **Population**: Lazily populated or refreshed by `continuumPricingService_redisCacheClient` (Lettuce) after a price write
- **Invalidation**: Explicit expiry triggered by `continuumPricingService_priceUpdateWorkflow` and `continuumPricingService_retailPriceService` on every price update
- **Format**: PriceSummary records serialized as CSV entries; bulk get/set operations used for efficiency

## Data Flows

1. A price update is written transactionally to `continuumPricingDb` by `continuumPricingService_priceUpdateWorkflow`.
2. The same workflow synchronizes the change to `continuumPwaDb` for inventory parity.
3. The workflow expires the relevant PriceSummary entries in `continuumRedisCache`.
4. Subsequent reads for the updated product miss the cache, fetch from `continuumPricingDb`, and repopulate the cache.
5. VIS inventory events consumed from MBus write unit update signals directly into `continuumPricingDb` via `continuumPricingService_mbusConsumers`.
