---
service: "glive-inventory-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGliveInventoryDb"
    type: "mysql"
    purpose: "Primary relational store for inventory, events, products, reservations, and reporting"
  - id: "continuumGliveInventoryRedis"
    type: "redis"
    purpose: "Caching, locking, and background job coordination"
  - id: "continuumGliveInventoryVarnish"
    type: "varnish"
    purpose: "HTTP response caching for inventory and availability endpoints"
---

# Data Stores

## Overview

GLive Inventory Service uses a three-tier data storage strategy. MySQL serves as the primary relational database for all persistent state -- inventory records, events, products, reservations, and reporting data. Redis provides caching, distributed locking, and coordination for background job workflows. Varnish operates as an HTTP cache layer in front of the API, reducing backend load for high-traffic availability and inventory queries.

## Stores

### GLive Inventory DB (`continuumGliveInventoryDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGliveInventoryDb` |
| Purpose | Primary relational store for GLive inventory, events, products, reservations, and reporting data |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` | Ticket products representing sellable live-event inventory items | id, name, status, partner_type, partner_id, created_at, updated_at |
| `events` | Individual event occurrences within a product (specific date/time/venue) | id, product_id, event_date, venue, capacity, status |
| `reservations` | Ticket reservations holding inventory for a pending purchase | id, product_id, event_id, quantity, status, expires_at, external_ref |
| `orders` | Completed ticket purchase records linked to reservations | id, reservation_id, external_order_id, status, purchased_at |
| `inventory_counts` | Current and historical inventory quantities per event | id, event_id, total, available, reserved, sold |
| `merchant_payment_reports` | Generated payment and accounting reports for merchants | id, merchant_id, report_type, period, generated_at |
| `pricing` | Pricing tiers and rules for ticket products | id, product_id, price, currency, tier |

#### Access Patterns

- **Read**: High-frequency reads for availability queries (product + event + inventory_counts joins), reservation status lookups, and product listing queries. Read-heavy workload amplified by Varnish cache misses.
- **Write**: Reservation create/update/delete operations, inventory count adjustments after purchases and releases, product and event CRUD operations, report generation writes.
- **Indexes**: Primary keys on all tables; indexes on product_id, event_id, status, event_date for query performance; composite indexes on reservation lookup patterns.

### GLive Inventory Redis (`continuumGliveInventoryRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumGliveInventoryRedis` |
| Purpose | Caching, distributed locking, and background job coordination for inventory workflows |
| Ownership | owned |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Background job queues for Resque/ActiveJob workers | queue name, job payload |
| Cache keys | Cached inventory and availability data | product/event cache keys, TTL |
| Lock keys | Distributed locks for concurrent reservation and inventory operations | lock key, TTL, owner |
| Coordination state | Intermediate processing state for multi-step workflows | workflow keys |

#### Access Patterns

- **Read**: Cache lookups for inventory availability, lock existence checks, job queue depth queries
- **Write**: Cache sets with TTL, lock acquisition/release, job enqueue/dequeue, intermediate state storage
- **Indexes**: Redis key naming conventions provide implicit indexing (e.g., `glive:cache:product:{id}`, `glive:lock:reservation:{id}`)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| GLive Inventory Redis | Redis | Application-level caching of inventory data, availability results, and workflow state | Variable per key type |
| GLive Inventory Varnish | Varnish HTTP cache | HTTP response caching for inventory and availability API endpoints | Configured per endpoint/response header |

### Varnish HTTP Cache (`continuumGliveInventoryVarnish`)

Varnish sits in front of the GLive Inventory Service API (`continuumGliveInventoryService_httpApi`) and caches HTTP responses for inventory and availability endpoints. Cache invalidation is triggered by domain services (`continuumGliveInventoryService_domainServices`) via HTTP PURGE requests when inventory state changes.

- **Cache hit path**: Varnish serves cached response directly to consumers (Groupon Website, Admin UI)
- **Cache miss path**: Varnish routes request to GLive Inventory Service, caches the response, and returns it
- **Invalidation**: Domain services send HTTP PURGE to Varnish when products, events, or availability change

## Data Flows

- **API to MySQL**: HTTP API controllers delegate to domain services, which read/write MySQL via ActiveRecord ORM
- **API to Redis**: Domain services use Redis for caching and locking during inventory operations
- **Workers to MySQL/Redis**: Background job runners access MySQL for persistence and Redis for job coordination, using the same ORM and client connections as the main service
- **Varnish to API**: Varnish routes cache misses to the API; domain services trigger PURGE on state changes
- **MessageBus events**: Inventory state changes are published to MessageBus topics after being persisted to MySQL, ensuring the database is the source of truth
