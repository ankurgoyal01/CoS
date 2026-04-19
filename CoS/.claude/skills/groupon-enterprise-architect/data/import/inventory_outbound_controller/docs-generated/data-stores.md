---
service: "inventory_outbound_controller"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumInventoryOutboundControllerDb"
    type: "mysql"
    purpose: "Primary persistent store for fulfillment, shipment, order, and inventory unit data"
---

# Data Stores

## Overview

inventory_outbound_controller owns a single MySQL database (`continuumInventoryOutboundControllerDb`) as its primary and only data store. This database holds all durable fulfillment state: orders, fulfillments, shipments, routing configuration, inventory units, and email notification records. Schema migrations are managed by Liquibase. There is no cache or secondary store owned by this service.

## Stores

### Outbound Controller Database (`continuumInventoryOutboundControllerDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumInventoryOutboundControllerDb` |
| Purpose | Persistent store for fulfillment lifecycle state, shipment records, routing configuration, inventory unit tracking, and email notifications |
| Ownership | owned |
| Migrations path | Managed via Liquibase 3.3 (migration files location not confirmed from inventory) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Orders | Tracks order records for fulfillment processing | order ID, sales order ID, status, user ID, timestamps |
| Fulfillments | Represents individual fulfillment assignments linking orders to inventory and 3PL routing | fulfillment ID, order ID, status, provider, created/updated timestamps |
| Shipments | Records shipment details and tracking information from 3PL acknowledgements | shipment ID, fulfillment ID, carrier, tracking number, ship date, status |
| Routing config | Stores fulfillment routing rules and deal-level configuration | deal ID, routing rules, provider preferences |
| Inventory units | Tracks unit-level inventory assignments to fulfillments | unit ID, fulfillment ID, sku, quantity, status |
| Email notifications | Records email notification events sent (e.g., via Rocketman) | notification ID, order ID, type, sent timestamp |

#### Access Patterns

- **Read**: Frequent reads by `outboundFulfillmentOrchestration` to check fulfillment eligibility, look up order state, and retrieve routing config; reads by `outboundApiControllers` for sales order and shipment queries
- **Write**: Writes on every fulfillment state transition (create, update, cancel, complete); writes on every shipment acknowledgement; writes on GDPR anonymization; writes on every import job run
- **Indexes**: No evidence found for specific index definitions — expected on order ID, fulfillment ID, and status columns given the access patterns

## Caches

> No evidence found in codebase. This service does not use a cache layer. All reads go directly to MySQL.

## Data Flows

- `outboundFulfillmentOrchestration` writes fulfillment state to MySQL on every inbound inventory update event, fulfillment import job execution, and API-triggered cancellation.
- `outboundMessagingAdapters` triggers persistence writes after processing logistics gateway and shipment tracker events.
- Liquibase manages all schema changes; migrations are applied at deployment time.
- No CDC, ETL, or materialized view patterns are evidenced. MySQL is the single source of truth for all fulfillment state.
- GDPR anonymization writes overwrite PII fields in-place within the orders and related tables; no separate audit table is evidenced.
