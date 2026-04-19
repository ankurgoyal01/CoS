---
service: "tpis-inventory-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumThirdPartyInventoryDb"
    type: "mysql"
    purpose: "Persists TPIS events and inventory data from external partners"
---

# Data Stores

## Overview

The Third Party Inventory Service uses a single MySQL database (`continuumThirdPartyInventoryDb`) as its primary data store. The database persists TPIS events and inventory data received from external partner platforms. Data is replicated to both the Enterprise Data Warehouse (EDW) and BigQuery for analytics and reporting purposes.

## Stores

### 3rd Party Inventory DB (`continuumThirdPartyInventoryDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumThirdPartyInventoryDb` |
| Purpose | Persists TPIS events and inventory data from external partners |
| Ownership | owned |
| Migrations path | Not discoverable from architecture DSL |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| (inferred) inventory events | Tracks inventory change events from third-party partners | event_id, partner_id, inventory_id, event_type, timestamp |
| (inferred) inventory products | Stores third-party inventory product definitions | product_id, partner_id, deal_id, status, availability |
| (inferred) inventory units | Individual third-party inventory unit records | unit_id, product_id, status, booking_reference |

> Exact table names and schemas are not discoverable from the architecture DSL. Service owners should document the actual database schema here.

#### Access Patterns

- **Read**: Inventory product lookups by ID, unit queries for booking details, availability checks for feed generation, status queries for deal management
- **Write**: Partner inventory event ingestion, product and unit status updates, booking flow data persistence
- **Indexes**: Expected on product_id, partner_id, deal_id, status, and event timestamp columns

## Caches

No cache layer (Redis, Memcached, or in-memory) is defined in the architecture DSL for this service.

> Service owners should document any caching strategy used by TPIS.

## Data Flows

- **Service to DB**: The Third Party Inventory Service (`continuumThirdPartyInventoryService`) reads and writes TPIS events and inventory data to MySQL via JDBC.
- **DB to EDW**: Inventory data is replicated from `continuumThirdPartyInventoryDb` to the Enterprise Data Warehouse for analytical reporting.
- **DB to BigQuery**: Inventory data is replicated from `continuumThirdPartyInventoryDb` to BigQuery for analytics and ad-hoc querying.
- **External partners to Service**: Third-party partner platforms provide inventory data that TPIS ingests and persists (integration pattern to be documented by service owner).
