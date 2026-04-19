---
service: "voucher-inventory-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumVoucherInventoryProductDb"
    type: "mysql"
    purpose: "Product and inventory data"
  - id: "continuumVoucherInventoryUnitsDb"
    type: "mysql"
    purpose: "Units and voucher barcode data"
  - id: "continuumVoucherInventoryRwDb"
    type: "mysql"
    purpose: "Replenishment schedules, acquisition methods, feature controls"
  - id: "continuumVoucherInventoryRedis"
    type: "redis"
    purpose: "Inventory product and unit sold count cache"
---

# Data Stores

## Overview

Voucher Inventory JTier owns three MySQL databases and one Redis cache. The Product DB holds read-optimized inventory product data. The Units DB holds unit and barcode data from VIS 2.0. The RW DB is the writable store for replenishment schedules, acquisition methods, and feature controls. Redis (RaaS) provides a high-speed cache-behind layer eliminating the need for a Varnish front cache. All MySQL databases use DaaS (Database as a Service) provided by Groupon's infrastructure, with replication between US (SNC1/SAC1) and EU (DUB1) data centers.

## Stores

### Voucher Inventory Product DB (`continuumVoucherInventoryProductDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumVoucherInventoryProductDb` |
| Purpose | Read-optimized store for inventory product data |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` (via `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| inventory products | Core product inventory records | product ID, unit counts, pricing-related fields, template UUID |

#### Access Patterns

- **Read**: API container reads product inventory records by product ID list; Worker container reads products for cache refresh and replenishment job processing
- **Write**: Worker container updates product records in response to MessageBus events
- **Indexes**: Not visible from configuration; managed via Flyway migrations in `jtier-migrations`

#### Production Hosts (examples)

- NA: `voucher-inventory-ro-na-production-db.gds.prod.gcp.groupondev.com` (database: `voucher_inventory_production`)
- EU (DUB1): `gds-dub1-prod-voucherinventory-ro-dns.dub1`
- US (SAC1): `gds-sac1-prod-voucherinventory-ro-dns.sac1`
- US (SNC1): `gds-snc1-prod-voucherinventory-ro-dns.snc1`

---

### Voucher Inventory Units DB (`continuumVoucherInventoryUnitsDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumVoucherInventoryUnitsDb` |
| Purpose | Units and voucher barcode data store (sourced from VIS 2.0) |
| Ownership | shared |
| Migrations path | Managed by VIS 2.0; read-only from this service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| units | Voucher unit and barcode records | unit ID, barcode, sold count, status |

#### Access Patterns

- **Read**: API container reads unit sold counts and barcode data; Worker container reads units for inventory processing
- **Write**: Worker container updates unit records in response to `InventoryUnits.Updated.*` events
- **Indexes**: Not visible from configuration

#### Production Hosts (examples)

- NA: `voucher-inventory-jtier-20-ro-na-production-db.gds.prod.gcp.groupondev.com` (database: `groupon_production`)
- EU (DUB1): `gds-dub1-prod-vis20-ro-dns.dub1`
- US (SAC1): `gds-sac1-prod-vis20-ht-ro-dns.sac1`
- US (SNC1): `gds-snc1-prod-vis20-ht-ro-dns.snc1`

---

### Voucher Inventory RW DB (`continuumVoucherInventoryRwDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumVoucherInventoryRwDb` |
| Purpose | Writable store for replenishment schedules, acquisition methods, and feature controls |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` (via `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| replenishment schedules | Ouroboros/replenishment job schedules | product ID, schedule config, acquisition method |
| acquisition methods | Supported acquisition method registry | acquisition method UUID, client ID |
| feature controls | Feature flag overrides per product | product ID, feature key, enabled flag |

#### Access Patterns

- **Read**: Worker Replenishment Job reads schedules; API reads feature controls when `enableRwDatabase` is true
- **Write**: API creates/updates acquisition methods; Worker writes replenishment schedule data
- **Indexes**: Not visible from configuration

#### Production Host (NA)

- `voucher-inventory-rw-na-production-db.gds.prod.gcp.groupondev.com` (database: `voucher_inventory_production`)

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumVoucherInventoryRedis` | Redis (RaaS/Jedis) | Inventory product data (semi-static) | 10,800 seconds (3 hours) — `inventoryProductTTL` |
| `continuumVoucherInventoryRedis` | Redis (RaaS/Jedis) | Unit sold counts (frequently changing) | 600 seconds (10 minutes) — `unitSoldCountTTL` |

### Redis Endpoints

| Environment | Endpoint |
|-------------|----------|
| Production (NA) | `vis--redis.prod` |
| Staging | `vis--redis.staging` |

**Connection pool configuration (production):**
- `minIdle`: 10
- `maxIdle`: 100
- `maxTotal`: 2,000
- `timeout`: 2,000ms
- `connectTimeout`: 1,000ms
- `queryTimeout`: 1,000ms

**RaaS Wavefront graph clusters:**
- SNC1: `cache.snc1.raas-voucher-inventory-prod.grpn`
- SAC1: `cache.sac1.raas-voucher-inventory-prod.grpn`
- DUB1: `cache.dub1.raas-voucher-inventory-prod.grpn`

## Data Flows

- **Cache-behind pattern**: The API reads from Redis first; on miss, it reads from MySQL Product DB, enriches with Pricing and Calendar data, and writes the result back to Redis with the appropriate TTL.
- **Event-driven cache invalidation**: The Worker consumes MessageBus inventory update events and refreshes the Redis cache entries for affected products and units.
- **Cross-region replication**: MySQL data is replicated between SNC1, SAC1 (US) and DUB1 (EU) via DaaS master replication.
- **PWA DB**: A separate PWA read-only MySQL endpoint (`gds-snc1-prod-pwa-split7-ro-vip.snc1`) is referenced for SNC1 production, indicating a shared read replica for PWA-related queries.
