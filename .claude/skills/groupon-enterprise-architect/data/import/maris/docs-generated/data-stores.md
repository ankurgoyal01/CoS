---
service: "maris"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "marisMySql"
    type: "mysql"
    purpose: "Primary transactional datastore for reservations, units, status logs, and Expedia responses"
---

# Data Stores

## Overview

MARIS owns a single MySQL database (`marisMySql`) as its primary transactional data store. All reservation lifecycle state, inventory unit status, Expedia API response payloads, and status audit logs are persisted here. There are no caches or secondary stores. Schema management is handled via `jtier-migrations` and connection pooling via HikariCP 5.1.0.

## Stores

### MARIS MySQL (`marisMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `marisMySql` |
| Purpose | Primary transactional datastore for reservations, status logs, Expedia responses, and inventory unit state |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (specific path not discoverable from architecture model) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `reservations` | Records hotel reservations created via Expedia Rapid, including booking references and status | Reservation ID, Expedia itinerary ID, unit ID, status, created/updated timestamps |
| `units` | Tracks inventory unit state throughout the fulfillment lifecycle | Unit ID, product ID, status, assigned order ID, redemption state |
| `status_logs` | Audit log of all unit and reservation status transitions | Entity ID, entity type, from status, to status, transition timestamp |
| `expedia_responses` | Stores raw Expedia API responses for availability, booking, and cancellation operations | Request type, entity reference, payload, recorded timestamp |

#### Access Patterns

- **Read**: Looks up reservation and unit state by ID for API responses; queries units by order or product ID during event processing; reads stored Expedia responses for replay or debugging
- **Write**: Inserts new reservations and units on booking; updates status fields on order status events and batch job processing; appends status log entries on every state transition; stores raw Expedia response payloads
- **Indexes**: Indexes on reservation ID, unit ID, and order ID are expected for efficient lookup; specific index definitions not discoverable from the architecture model

## Caches

> Not applicable. MARIS does not use an in-memory cache or distributed cache layer. All state reads go directly to `marisMySql`.

## Data Flows

All writes originate from three sources:
1. **API requests** — reservation creation, unit updates, and redemption recording write directly to `marisMySql` via the `marisPersistence` layer
2. **Event consumption** — `Orders.StatusChanged` events trigger status updates and status log entries
3. **Scheduled batch jobs** — refund sync and cancellation processing jobs update unit and reservation records for outstanding cases

There is no CDC, ETL, or replication pipeline visible in the architecture model. Downstream consumers receive state changes via the `InventoryUnits.Updated.Mrgetaways` and `UpdatedSnapshot` MBus topics rather than by reading the database directly.
