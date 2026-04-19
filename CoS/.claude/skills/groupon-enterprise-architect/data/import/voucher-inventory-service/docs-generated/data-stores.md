---
service: "voucher-inventory-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumVoucherInventoryDb"
    type: "mysql"
    purpose: "Product-level configuration including inventory products, consumer contracts, and redemption policies"
  - id: "continuumVoucherInventoryUnitsDb"
    type: "mysql"
    purpose: "Inventory units, unit redemptions, order mappings, and status history"
  - id: "continuumVoucherInventoryRedisCache"
    type: "redis"
    purpose: "Caching, distributed locking, rate limiting, and Sidekiq job queues"
  - id: "continuumVoucherInventoryMessageBus"
    type: "activemq"
    purpose: "Domain event publishing and consumption via JMS topics and queues"
---

# Data Stores

## Overview

The Voucher Inventory Service uses a split-database architecture with two MySQL databases (product configuration vs. unit operations), a Redis cache layer, and an ActiveMQ message bus. The product database (`continuumVoucherInventoryDb`) stores inventory product definitions, consumer contracts, and redemption policies. The units database (`continuumVoucherInventoryUnitsDb`) stores high-volume voucher unit records, redemptions, and order mappings. Redis provides caching, distributed locking, and serves as the Sidekiq queue backend. ActiveMQ handles all asynchronous event publishing and consumption.

## Stores

### Voucher Inventory DB (`continuumVoucherInventoryDb`)

| Property | Value |
|----------|-------|
| Type | MySQL (AWS RDS) |
| Architecture ref | `continuumVoucherInventoryDb` |
| Purpose | Primary relational database for product-level configuration including inventory products, consumer contracts, and redemption policies |
| Ownership | owned |
| Migrations path | Standard Rails `db/migrate/` convention (product database) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `inventory_products` | Stores inventory product configuration and attributes | product_id, deal_id, status, configuration attributes |
| `consumer_contracts` | Defines consumer-facing terms and conditions for voucher products | contract_id, product_id, terms, validity period |
| `redemption_policies` | Rules governing how vouchers can be redeemed | policy_id, product_id, policy type, constraints |
| `redemption_code_pools` | Third-party redemption code pool configuration and thresholds | pool_id, product_id, threshold, consumption count |

#### Access Patterns

- **Read**: Product lookups by ID, deal-based queries, quantity summary aggregations, code pool threshold checks
- **Write**: Product creation/updates, policy configuration changes, code pool uploads and consumption tracking
- **Indexes**: Expected on product_id, deal_id, status columns

### Voucher Inventory Units DB (`continuumVoucherInventoryUnitsDb`)

| Property | Value |
|----------|-------|
| Type | MySQL (AWS RDS) |
| Architecture ref | `continuumVoucherInventoryUnitsDb` |
| Purpose | High-volume datastore for inventory units, unit redemptions, order mappings, and status history |
| Ownership | shared (owned by voucher-inventory-jtier) |
| Migrations path | Standard Rails `db/migrate/` convention (units database) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `inventory_units` | Individual voucher unit records with status tracking | unit_id, product_id, order_id, status, timestamps |
| `unit_redemptions` | Redemption records for voucher units | redemption_id, unit_id, merchant_id, redeemed_at |
| `order_mappings` | Maps voucher units to order line items | mapping_id, unit_id, order_id, line_item_id |
| `unit_status_history` | Audit trail of unit status transitions | history_id, unit_id, from_status, to_status, changed_at |

#### Access Patterns

- **Read**: Unit lookups by ID, order-based queries, status filtering, bulk searches for reconciliation, sold count aggregations
- **Write**: Unit creation (reservation), status transitions (redemption, refund, expiration), bulk status updates, reconciliation corrections, GDPR anonymization
- **Indexes**: Expected on unit_id, product_id, order_id, status columns

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Voucher Inventory Redis Cache | Redis (AWS ElastiCache) | Distributed locking for concurrent unit operations, sold-count and quantity summary caching, rate limiting, temporary data storage | Varies by use case |
| Sidekiq Queue Backend | Redis (AWS ElastiCache) | Sidekiq job queue storage for background workers | Until processed |

Architecture ref: `continuumVoucherInventoryRedisCache`

### Redis Access Patterns

- **Distributed locks**: Used by `continuumVoucherInventoryApi_cacheAccessors` for concurrent unit operations (reservations, redemptions) to prevent race conditions
- **Sold count cache**: Updated by `continuumVoucherInventoryWorkers_voucherInventoryEventsListener` to maintain real-time quantity summaries
- **Rate limiting**: Short-lived counters for API rate limiting via `continuumVoucherInventoryApi_observability`
- **Async publishing coordination**: Used by `continuumVoucherInventoryWorkers_asyncPublishers` for Redis queues and locks during event publishing

## Data Flows

- **API to DB**: The API container (`continuumVoucherInventoryApi`) reads and writes to both MySQL databases via ActiveRecord/JDBC. Product configuration goes to `continuumVoucherInventoryDb`; unit operations go to `continuumVoucherInventoryUnitsDb`.
- **Workers to DB**: The Workers container (`continuumVoucherInventoryWorkers`) performs backfill operations against both databases and status reconciliation against the Units DB.
- **Event-driven updates**: Order status change events consumed from the message bus trigger unit status updates in the Units DB. Internal VIS events trigger sold count recalculations cached in Redis.
- **EDW export**: Daily batch ETL exports build analytical snapshots from both databases and upload to S3/EDW via the `continuumVoucherInventoryApi_edwExporter` component.
- **GDPR anonymization**: Right-to-forget events trigger PII scrubbing across both databases via the `continuumVoucherInventoryWorkers_gdprListener`.
