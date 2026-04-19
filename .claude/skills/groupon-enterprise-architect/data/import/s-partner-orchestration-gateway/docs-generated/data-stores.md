---
service: "s-partner-orchestration-gateway"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSpogPostgres"
    type: "postgresql"
    purpose: "Primary datastore for wallet units, partners, offers, resource locks, and attribution data"
---

# Data Stores

## Overview

S-POG owns a single PostgreSQL database provisioned via Groupon's DaaS (Database-as-a-Service) layer. This database stores all persistent state required for wallet integrations: the mapping between Groupon inventory units and Google Wallet offer objects, resource locks for concurrent update prevention, and supplementary data (supplied offers, partners, locations, attribution records). Schema migrations are managed using Flyway via the `jtier-migrations` bundle.

## Stores

### SPOG Postgres (`continuumSpogPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumSpogPostgres` |
| Purpose | Primary datastore for wallet units, partners, offers, resource locks, and attribution data |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `wallet_units` | Maps Groupon inventory units to Google Wallet partner objects | `inventory_unit_id` (UUID, unique with `partner_id`), `inventory_product_id`, `inventory_service_id`, `partner_unit_id`, `partner_id`, `created_at` |
| `resource_locks` | Distributed resource locking (advisory lock coordination) | `resource_id` (UUID, unique index), `resource_name`, `created_at`; uses `pg_try_advisory_lock` / `pg_advisory_unlock` |
| `supplied_offers` | Tracks offers supplied/surfaced to partners | `inventory_product_id`, `permalink`, and offer-related fields |
| `partners` | Partner configuration and identity | Partner ID, UTM source, partner-specific metadata |
| `merchants` | Merchant data for partner offer display | Merchant display name and related fields |
| `locations` | Merchant/offer location data | Place ID, Google place ID, location details |
| `metrics` | Service-level metrics records | Offer/unit processing metrics |
| `cached_offers` | Cached offer data for performance | Offer details cached to reduce downstream calls |
| `order_attribution` (renamed) | Order attribution tracking | Attribution records linking orders to partner sources |

#### Access Patterns

- **Read**: Look up wallet unit by `inventory_unit_id` + `partner_id` (indexed); look up resource locks by `resource_id` + `resource_name`; query offered/cached data for wallet payload generation
- **Write**: Insert new wallet unit records on first save-to-wallet; update wallet unit fields on re-save; insert/delete resource lock records; insert attribution records
- **Indexes**: `idx_wallet_units_by_uuid_and_partner_id` — unique composite index on `(inventory_unit_id, partner_id)`; `idx_resource_lock_id` — unique index on `resource_locks(resource_id)`

## Caches

> No evidence found in codebase. No dedicated caching layer (Redis, Memcached) is used. The `cached_offers` table represents an application-level DB cache, not an in-memory or external cache.

## Data Flows

Inventory unit IDs arrive via the MessageBus or the wallet payload API. S-POG looks up whether a matching `wallet_units` record exists before performing any Google Wallet API operations. New unit-to-wallet mappings are written on successful save-to-wallet flows. The database is not replicated or synced to any external analytics store from within this service.
