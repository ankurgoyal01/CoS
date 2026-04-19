---
service: "mpp-service-v2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMppServiceV2Db"
    type: "postgresql"
    purpose: "Primary persistent store for slugs, taxonomy snapshots, related places, index sync state, and place update status"
---

# Data Stores

## Overview

MPP Service V2 owns a single PostgreSQL database (`continuumMppServiceV2Db`) that serves as the primary data store for all service state. The database is configured with a read/write split (`readPostgres` and `writePostgres` in the JTier `MppPostgresConfig`), enabling read traffic to be distributed across replicas. The schema is managed via JTier's `jtier-migrations` framework and lives under the `mpp_service` schema (local DB: `mpp_service_local`). An in-process Caffeine cache backs the taxonomy place attribute read path to avoid repeated database or upstream API calls.

## Stores

### MPP Service V2 DB (`continuumMppServiceV2Db`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL 14 |
| Architecture ref | `continuumMppServiceV2Db` |
| Purpose | Persistent store for slugs, taxonomy snapshots, related places, index sync state, and place update status |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (JTier framework); local setup via `conf/db_util/setup_local_db.sql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Slug table | Stores canonical slug (permalink) records for merchant places | place UUID, slug string, indexed flag, location |
| Slug redirect table | Maps old or alternate slugs to canonical slugs | old slug, canonical slug, place UUID |
| Taxonomy categories | Snapshot of taxonomy category hierarchy | category UUID, name, parent UUID, depth |
| Taxonomy locales | Per-locale translations for taxonomy categories | category UUID, locale, translated name |
| Place attributes | Snapshot of place attribute taxonomy data | attribute UUID, name, parent, children, locales |
| Related places | Pre-computed related place associations | place UUID, related place UUID, relation type |
| Related locations | Location data for related places | UUID, street address, coordinates |
| Place update status | Queue and processing status for place update messages | place UUID, status (`QUEUE`, processing states) |
| Index sync config | Configuration for index-sync job (batch size, thread count, enabled state) | config key, value |
| Index sync job run | Audit log of index-sync job executions | run ID, start time, end time, status, checkpoint |
| Category image paths | Image path data for taxonomy categories | category UUID, image path |

#### Access Patterns

- **Read**: Place data assembly reads slugs by UUID or slug string; taxonomy reads use the in-memory Caffeine cache as primary path, falling back to the DB via `TaxonomyDaoService`; related places are read by place UUID; index-sync reads batches of candidate slugs ordered by last-synced timestamp
- **Write**: Slug records are written on new place ingestion and updated on index state changes; taxonomy snapshots are refreshed by Quartz jobs; place update status is upserted by `PlaceUpdateProcessor` on MBus events; index-sync job writes run audit records and updates slug indexed flags; related places are written by the cross-link Quartz job
- **Indexes**: Not directly visible in the repository; indexed columns are expected on place UUID and slug string for slug lookup, and on place UUID for update status

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `PlaceAttributeCache` | in-memory (Caffeine) | Caches `PlaceAttributeTaxonomyData` by UUID, parent UUID, and locale to serve the taxonomy read path without repeated DB hits | No TTL configured; max size 1,000 entries per dimension; populated on startup and refreshed by Quartz job |

## Data Flows

- **MBus event → DB**: `PlaceUpdateProcessor` receives `placeDataUpdate` messages and writes place UUIDs to the place-update-status table with status `QUEUE`.
- **Quartz PlaceUpdateJob → DB → M3 → DB**: The `PlaceUpdateJob` reads queued places from the place-update-status table, fetches updated data from M3, and writes refreshed slug and related-place records back to the database.
- **Quartz IndexSyncJob → RAPI → DB**: The `IndexSyncJob` reads slug candidates from the database, queries RAPI for deal/index state, and updates the `indexed` flag on slug records and writes job-run audit entries.
- **Quartz CrossLinkJob → LP API → DB**: The `CrossLinkJob` fetches cross-link data from LP API and persists related-place associations.
- **Quartz SitemapJob → DB → file**: The `SitemapJob` reads slug records and generates sitemap files served by the `/mpp/v1/sitemap` endpoint.
