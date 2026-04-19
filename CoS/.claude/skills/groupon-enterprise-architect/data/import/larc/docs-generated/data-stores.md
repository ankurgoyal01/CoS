---
service: "larc"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTravelLarcDatabase"
    type: "mysql"
    purpose: "Primary store for ingestion jobs, hotel mappings, rate descriptions, nightly LARs, and archive records"
---

# Data Stores

## Overview

LARC owns a single primary MySQL database (`LAR_data_test` in test; production database name managed by DaaS configuration). The database is the central store for all operational data: ingestion job lifecycle, hotel-to-QL2 mappings, rate description mappings, computed nightly LAR values, and archived historical rate records. There are no separate caches or external object stores used by this service.

## Stores

### LARC Database (`continuumTravelLarcDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumTravelLarcDatabase` |
| Purpose | Primary operational datastore for ingestion jobs, hotel/QL2 mappings, rate descriptions, nightly LARs, and archive |
| Ownership | owned |
| Migrations path | `jtier-migrations` bundle (Flyway-compatible, managed by `MySQLMigrationBundle`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `IngestionJob` | Tracks the lifecycle of each QL2 file download and CSV ingestion job | `id`, `stage` (StageEnum), `status` (StatusEnum), `user`, `path`, `fileTimestamp` |
| `LivePricingJob` | Tracks live pricing update jobs per product set | `productSetUuid`, `startDate`, `endDate`, `status` |
| `Hotel` | Maps Groupon hotel UUIDs to QL2 integer IDs | `uuid`, `ql2Id` |
| `RateDescription` | Maps QL2 rate description names to Groupon room types | `uuid`, `ql2Id`, `name`, `site`, `roomTypeUuid`, `status` (ZERO_INDEX, hotelOnly, optedOut, unassigned, assignedToRoom) |
| `NightlyLar` | Stores the computed lowest available rate per room type per night | `roomTypeUuid`, `night`, `amount`, `ql2Timestamp` |
| `NightlyLarArchived` | Historical archive of nightly LAR records purged from the active table | mirrors `NightlyLar` fields |
| `ApprovedRateDiscountPercentage` | Stores per-rate-plan approved discount percentages with effective dates | `ratePlanUuid`, `date`, `discountPercentage`, `rate` |

#### Access Patterns

- **Read**: Worker schedulers query `NightlyLar` by `roomTypeUuid` and date range to calculate LARs for each rate plan; API reads hotel, rate description, and discount percentage records by UUID
- **Write**: FTP download worker writes new ingestion job records and inserts bulk `NightlyLar` rows parsed from QL2 CSV; rate computation writes computed LAR updates back after sending to Inventory Service; archive worker migrates old records from `NightlyLar` to `NightlyLarArchived`
- **Indexes**: Not directly observable from available source; indexes expected on `roomTypeUuid` + `night` in `NightlyLar` for range queries

## Caches

> No evidence found in codebase. LARC does not use Redis, Memcached, or any explicit in-memory cache layer. The `ConnectorCache` class is an internal JDBI connector factory cache, not a data cache.

## Data Flows

QL2 CSV files downloaded from the FTP/SFTP server are parsed row-by-row and bulk-inserted into `NightlyLar`. The rate computation engine reads these records, computes the minimum rate per night per travel window, and writes the results to the Inventory Service via HTTP. Periodically, the table archive worker moves stale records (past nights, old QL2 timestamps, unused records — controlled by feature flags) from `NightlyLar` to `NightlyLarArchived` to keep the active table lean.
