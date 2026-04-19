---
service: "travel-inventory"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumTravelInventoryDb"
    type: "mysql"
    purpose: "Primary relational store for hotel inventory, room types, rate plans, availability, audit logs, worker tasks, and reporting data"
  - id: "continuumTravelInventoryHotelProductCache"
    type: "redis"
    purpose: "Cache for hotel product detail data used during shopping and availability queries"
  - id: "continuumTravelInventoryInventoryProductCache"
    type: "redis"
    purpose: "Cache for inventory product snapshots used during shopping and booking flows"
  - id: "continuumBackpackAvailabilityCache"
    type: "memcached"
    purpose: "Cache holding Backpack availability results to speed up shopping requests"
  - id: "continuumAwsSftpTransfer"
    type: "sftp"
    purpose: "Managed SFTP endpoint for daily inventory report CSV file export"
---

# Data Stores

## Overview

Getaways Inventory Service uses a MySQL relational database as the system of record for all hotel inventory data, two Redis caches for hotel product detail and inventory product data, a Memcached cache for Backpack availability results, and an AWS SFTP endpoint for daily report file export. The primary service container (`continuumTravelInventoryService`) reads and writes all stores. The cron container (`continuumTravelInventoryCron`) triggers report generation indirectly via HTTP call to the main service.

## Stores

### Getaways Inventory DB (`continuumTravelInventoryDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumTravelInventoryDb` |
| Purpose | Primary relational store for hotel inventory, room types, rate plans, availability, audit logs, worker tasks, and reporting data |
| Ownership | owned |
| Migrations path | Managed via Flyway (path in service codebase) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `hotels` | Hotel records with property-level metadata | id, name, status, location, contact reference |
| `room_types` | Room type definitions per hotel | id, hotel_id, name, capacity, description |
| `rate_plans` | Rate plan configurations per room type | id, room_type_id, name, rate, currency, restrictions |
| `availability` | Date-level availability and pricing records | id, rate_plan_id, date, available_count, price |
| `product_sets` | Product set groupings for inventory | id, hotel_id, product configuration |
| `taxes` | Tax configuration records | id, tax_type, rate, applicable scope |
| `booking_fees` | Booking fee configurations | id, fee_type, amount, applicable scope |
| `audit_logs` | Audit trail of inventory changes | id, entity_type, entity_id, action, timestamp, user |
| `worker_tasks` | Background worker task tracking | id, task_type, status, started_at, completed_at |
| `report_jobs` | Daily inventory report generation tracking | id, status, report_date, file_path, completed_at |

#### Access Patterns

- **Read**: Shopping Domain reads availability, pricing, and product data for consumer flows; Extranet Domain reads hotel, room type, and rate plan records; Audit Domain reads audit log entries; Worker Domain reads large batches for report generation; Connect Domain reads hierarchy mapping data; OTA Domain reads existing inventory for merge operations
- **Write**: Extranet Domain creates and updates hotels, room types, rate plans, product sets, taxes, and booking fees; Shopping Domain writes reservation records; OTA Domain persists OTA-driven rate and inventory updates; Audit Domain writes audit log entries; Worker Domain writes report job state; Persistence Layer manages Flyway migrations
- **Indexes**: Expected indexes on foreign keys (hotel_id, room_type_id, rate_plan_id), availability date ranges, and audit log entity references. Consult schema for full index list.

#### Database Roles

The Persistence Layer implements database role routing, directing read-heavy workloads (shopping, reporting) to read replicas and write operations (Extranet, OTA) to the primary instance. Audit and reporting workloads may use dedicated connection pools.

---

### Hotel Product Detail Cache (`continuumTravelInventoryHotelProductCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumTravelInventoryHotelProductCache` |
| Purpose | Cache for hotel product detail data used during shopping and availability queries |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Hotel product detail entries | Cached hotel product detail snapshots | hotel ID key, serialized product detail JSON, TTL |

#### Access Patterns

- **Read**: Shopping Domain reads cached hotel product details before falling back to MySQL
- **Write**: Caching Layer writes product details after retrieval from MySQL; Extranet Domain invalidates and updates entries after Extranet changes

---

### Inventory Product Cache (`continuumTravelInventoryInventoryProductCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumTravelInventoryInventoryProductCache` |
| Purpose | Cache for inventory product snapshots used during shopping and booking flows |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Inventory product entries | Cached inventory product snapshots | product key, serialized inventory product JSON, TTL |

#### Access Patterns

- **Read**: Shopping Domain reads cached inventory products for availability and pricing calculations
- **Write**: Caching Layer writes inventory product snapshots after retrieval; Extranet Domain invalidates stale entries after inventory changes

---

### Backpack Availability Cache (`continuumBackpackAvailabilityCache`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `continuumBackpackAvailabilityCache` |
| Purpose | Cache holding Backpack availability results to speed up subsequent shopping requests |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Backpack availability entries | Cached Backpack/TIS availability query results | availability key, serialized availability data, TTL |

#### Access Patterns

- **Read**: Shopping Domain reads cached Backpack availability before making live calls to Backpack Reservation Service
- **Write**: Backpack Memcache Integration writes availability results after retrieval from Backpack Reservation Service

---

### AWS SFTP Transfer (`continuumAwsSftpTransfer`)

| Property | Value |
|----------|-------|
| Type | sftp |
| Architecture ref | `continuumAwsSftpTransfer` |
| Purpose | Managed SFTP endpoint where daily inventory report CSV files are pushed for downstream consumption |
| Ownership | external (AWS managed) |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: Worker Domain generates CSV report files and the AWS SFTP Client transfers them to this endpoint
- **Read**: Downstream consumers (finance, reporting) pull CSV files from this SFTP endpoint

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumTravelInventoryHotelProductCache` | redis | Hotel product detail data for shopping and availability | Varies by configuration |
| `continuumTravelInventoryInventoryProductCache` | redis | Inventory product snapshots for shopping and booking | Varies by configuration |
| `continuumBackpackAvailabilityCache` | memcached | Backpack availability results for shopping request reuse | Varies by configuration |
| In-memory caches (Caching Layer) | in-memory | Lookup tables and localization helpers | Application lifecycle |

## Data Flows

- Hotel inventory master data originates in MySQL via Extranet or OTA writes and flows through the Caching Layer (Redis) for read optimization in shopping flows.
- Backpack availability results are fetched from the Backpack Reservation Service, cached in Memcached, and reused across subsequent shopping requests for the same parameters.
- Daily inventory reports are generated by the Worker Domain reading large batches from MySQL, assembling CSV files, and transferring them to the AWS SFTP endpoint via the SFTP Client.
- Cache invalidation is triggered by Extranet Domain writes -- when hotels, room types, or rate plans change, the Caching Layer updates or invalidates the affected Redis entries.
- The Cron container triggers report generation on schedule, but all data access occurs within the main service container.
