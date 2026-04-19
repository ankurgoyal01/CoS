---
service: "goods-shipment-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGoodsShipmentDatabase"
    type: "mysql"
    purpose: "Primary persistent store for shipments, carrier config, OAuth2 tokens, and notification state"
---

# Data Stores

## Overview

The Goods Shipment Service owns a single MySQL database (`continuumGoodsShipmentDatabase`) that is its primary and only persistent store. All shipment records, carrier configuration, OAuth2 token state, pending notification queues, and ZIP code reference data are stored here. The service accesses MySQL via JDBI3 with SQL object DAOs and manages schema migrations via Flyway (controlled by the `flywayMigrationsEnabled` configuration flag). There is no Redis or external cache in use.

## Stores

### Goods Shipment MySQL (`continuumGoodsShipmentDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGoodsShipmentDatabase` |
| Purpose | Stores shipment lifecycle data, carrier configuration, carrier OAuth2 tokens, pending notification queues, and ZIP code lookups |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (Flyway); `jtier-quartz-mysql-migrations` handles Quartz scheduler tables |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `shipment` | Core shipment record | `shipmentUuid`, `lineItemId`, `orderLineItemUuid`, `carrier`, `trackingNumber`, `status`, `shippedOn`, `deliveredOn`, `outForDeliveryOn`, `notDeliveredOn`, `expectedDeliveryDate`, `rawStatus`, `history` (carrier events JSON), `channelCountry`, `fulfillmentLineItemId`, `consumerId`, `brand`, `locale`, `address1..state`, `zip`, `country`, `isEmailed`, `quantity`, `poId`, `shipmentType`, `carrierSourceType`, `updatedOn` |
| `carrier_config` | Carrier configuration including which carriers are active per data centre and tracking enabled flags | `carrierCode`, `isShipmentTrackerEnabled`, `datacenter` |
| `oauth2` | Carrier OAuth2 access tokens with expiry metadata | `carrier`, `accessToken`, `expiresAt` |
| `pending_notifiable_shipment` | Queue of shipments awaiting notification delivery with retry counter | `shipmentId`, `retryCount` |
| `zip` | ZIP code reference data for shipment location enrichment | `zip`, geography fields |

#### Access Patterns

- **Read**: Shipments queried by `orderLineItemUuid`, `lineItemId`, `shipmentUuid` (bytes), `orderUuid`, `trackingNumber`, or set of shipment UUIDs. Batch reads used for carrier refresh jobs (paged by `minId` + `batchSize`). Active-shipment queries filter by carrier, status, and date range. Untracked-shipment queries filter by `reportedOn` window and data centre.
- **Write**: Single and batch inserts for shipment creation; targeted updates for status, tracking data, email status, and Aftership registration state. Transactional batch updates use JDBI `@Transaction`. OAuth2 token upserts managed by Auth Service.
- **Indexes**: Not directly visible in DAO source; standard indexes expected on `shipmentUuid` (unique), `orderLineItemUuid`, `orderUuid`, `lineItemId`, `trackingNumber`, `carrier`, `status`, and `reportedOn` for query performance.

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory cache is configured. The Carrier Router holds a `ConcurrentHashMap` of carrier instances in-process as a warm lookup structure, but this is not a persistent or distributed cache.

## Data Flows

All data flows through the MySQL database as the single system of record. Carrier refresh jobs read active shipments, update status fields in-place, and trigger notification services. The Aftership webhook handler reads shipment records by tracking number, updates status, and publishes notifications. No CDC, ETL, or replication pattern is used within the scope of this service.
