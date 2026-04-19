---
service: "vss"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumVssMySql"
    type: "mysql"
    purpose: "Primary voucher-user aggregated search store"
---

# Data Stores

## Overview

VSS owns a single MySQL database provisioned via Groupon's DaaS (Database-as-a-Service) platform. This store acts as a materialized, searchable projection of voucher and user data aggregated from VIS (inventory) and the Users Service. The database uses master/slave replication with automated backups. Reads are served from the read-only replica; writes go to the read-write master.

## Stores

### VSS MySQL (`continuumVssMySql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumVssMySql` |
| Purpose | Primary aggregated store for voucher-user search data |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` and `jtier-quartz-mysql-migrations` (schema migrations run on startup) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Voucher-User records | Stores the association between a voucher/inventory unit and its purchaser/consumer user data | `inventoryUnitId`, `merchantId`, `grouponCode`, `redemptionCode`, `purchaser.*`, `consumer.*` |
| Customer | Stores purchaser and consumer identity data | `id` (account ID), `firstName`, `lastName`, `maskedEmail`, `sameNameKey` |
| Backfill units queue | Staging table for units to be backfilled by the Quartz scheduler | `uuid`, `inventoryServiceId`, `updatedAt` |
| Quartz job tables | Scheduler state for backfill jobs (provisioned by `jtier-quartz-mysql-migrations`) | Quartz standard schema |

#### Access Patterns

- **Read**: Search queries join voucher unit and customer tables by `merchantId` and free-text fields (name, code, email). Read-only replica (`mysql_ro_config`) serves search API traffic. Throughput target: 50K RPM.
- **Write**: Inventory update events and user update events upsert records via the read-write master (`mysql_rw_config`). Backfill scheduler writes unit UUIDs to staging table in batches (`voucherUnitsBatchSize` configurable). GDPR erasure events delete/obfuscate records by user account ID.
- **Indexes**: Not directly visible from repository source; managed via migration scripts.

## Caches

> No evidence found in codebase. The `dropwizard-redis` dependency is present in `pom.xml` but no Redis cache configuration or usage is discoverable in the service source. Redis may be available as a JTier platform feature but is not actively used by VSS.

## Data Flows

1. **Inventory event path**: JMS `InventoryUnits.Updated` events arrive via mbus → `inventoryUnitsUpdatedProcessor` parses unit data → `voucherUserDataService` writes to MySQL master via `voucherUsersDataDbi`.
2. **User event path**: JMS user account/email/erasure events arrive → corresponding processor delegates to `usersUpdateProcessorHelper` → `voucherUserDataService` updates or deletes records in MySQL master.
3. **Backfill path**: `voucherBackfillScheduler` (Quartz) periodically reads unit UUIDs from backfill staging table → fetches inventory details from VIS or VIS 2.0 via HTTP → fetches user details from Users Service → writes complete voucher-user records to MySQL master.
4. **Search read path**: Merchant Centre calls `GET /v1/vouchers/search` → `vssResource` delegates to `searchService` → `voucherUserDataService` queries MySQL read replica via `voucherUsersDataDbi` → returns matched records.
