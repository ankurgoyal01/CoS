---
service: "scs-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumScsJtierWriteMysql"
    type: "mysql"
    purpose: "Primary shopping cart data store"
  - id: "continuumScsJtierReadMysql"
    type: "mysql"
    purpose: "Read replica for shopping cart data"
---

# Data Stores

## Overview

scs-jtier owns a dedicated MySQL DaaS database with a primary/read-replica architecture. All reads are routed to the read replica (`continuumScsJtierReadMysql`) and all writes go to the primary (`continuumScsJtierWriteMysql`). The database is owned and operated by Groupon's GDS team. No caching layer is employed — the OWNERS_MANUAL.md explicitly states that the service does not use any caching mechanism.

## Stores

### SCS JTier Write MySQL (`continuumScsJtierWriteMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumScsJtierWriteMysql` |
| Purpose | Primary shopping cart data store — handles all INSERT, UPDATE, DELETE operations |
| Ownership | owned |
| Managed by | GDS team (gds@groupon.com, Google space: gds-daas) |
| Replication | Master/slave setup in us-central1 / eu-west-1; automatic replication |
| Backup | Yes — managed by GDS team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `shopping_carts` | Stores active cart state for each user session | `id`, `b_cookie`, `consumer_id`, `items` (JSON blob), `size`, `uuid`, `created_at`, `updated_at`, `country_code`, `active` |
| `inactive_shopping_carts` | Archive table for carts that have been marked inactive and moved | `id`, `b_cookie`, `consumer_id`, `items`, `size`, `uuid`, `created_at`, `updated_at`, `country_code`, `active` |

#### Access Patterns

- **Read (write connection)**: Not used for reads — all reads route to the read replica.
- **Write**: INSERT new carts (`insertLoggedInCart`, `insertLoggedOutCart`); UPDATE existing carts (`updateLoggedInCart`, `updateLoggedOutCart`); UPDATE `consumer_id` for session merge (`updateConsumerIdForCart`); set `active = 0` for checkout/deactivation (`deactivateCart`); INSERT into `inactive_shopping_carts` (`insertInactiveCarts`); DELETE moved inactive carts from `shopping_carts` (`deleteInactiveCarts`).
- **Indexes**: Not directly visible from DAO source — queries filter on `b_cookie`, `consumer_id`, `country_code`, `active`, and `updated_at`.

---

### SCS JTier Read MySQL (`continuumScsJtierReadMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumScsJtierReadMysql` |
| Purpose | Read replica — handles all SELECT queries for cart retrieval |
| Ownership | owned (replica managed by GDS) |
| Replication | Automatic replication from primary |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `shopping_carts` | Read-only view of active cart state | `b_cookie`, `consumer_id`, `items`, `size`, `country_code`, `active`, `updated_at` |

#### Access Patterns

- **Read**: Lookup cart by `b_cookie` + `country_code` for anonymous users (`findCartByBCookie`, `findSizeByBCookie`); lookup cart by `consumer_id` + `country_code` for authenticated users (`findCartByConsumerId`, `findSizeByConsumerId`); scan for abandoned carts by `country_code`, `active`, `size > 0`, `consumer_id IS NOT NULL`, `updated_at` window (`findAbandonedCarts`); scan for inactive carts by `size = 0`, `active = true`, `updated_at < startTime` (`findInactiveCarts`); scan for already-marked inactive carts (`findMarkedInactiveCarts`).
- **Write**: Not applicable — read replica only.
- **Indexes**: Not directly visible from DAO source — queries filter on `b_cookie`, `consumer_id`, `country_code`, `active`, `size`, and `updated_at`.

## Caches

> No evidence found in codebase. The OWNERS_MANUAL.md explicitly states: "This service does not employ any sort of caching mechanism."

## Data Flows

- On every cart mutation, the write primary is updated first, then a `updated_cart` event is published to Mbus so downstream consumers can react.
- The abandoned carts job reads from the read replica to find qualifying carts, then publishes `abandoned_cart` events to Mbus. No writes occur during the abandoned cart scan.
- The inactive carts job reads from the read replica to find inactive carts, then writes to both `shopping_carts` (deactivation or deletion) and `inactive_shopping_carts` (archival insert) via the write primary.
- Replication lag between the write primary and read replica is monitored via the `MySQL_Replication_Delay_goods_cart_svc_prod` VIP metric.
