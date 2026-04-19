---
service: "marketing-and-editorial-content-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMarketingEditorialContentPostgresWrite"
    type: "postgresql"
    purpose: "Primary read/write datastore for editorial content and audit records"
  - id: "continuumMarketingEditorialContentPostgresRead"
    type: "postgresql"
    purpose: "Read-only replica endpoint for search and get query traffic"
---

# Data Stores

## Overview

MECS owns a single PostgreSQL database with separate primary (write) and read-replica (read) endpoints. The write endpoint handles all INSERT, UPDATE, and DELETE operations across content and audit tables. The read endpoint serves all search and get queries, reducing load on the primary. Schema migrations are managed by Flyway via the jtier-migrations bundle. The service routes JDBI connections through a `DataAccessor` that holds separate JDBI instances for each endpoint.

## Stores

### MECS Postgres (Write) (`continuumMarketingEditorialContentPostgresWrite`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMarketingEditorialContentPostgresWrite` |
| Purpose | Primary datastore for all writes — content creation, update, deletion, and audit record insertion |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `images` | Stores image content records | `uuid` (unique), `last_modified_user`, `metadata` (JSONB), `created_at`, `updated_at` |
| `images_audit` | Audit trail for INSERT and UPDATE operations on `images` (trigger-driven) | `image_uuid`, `username`, `action` (INSERT/UPDATE), `audited_at` |
| `text` | Stores text content records with component classification | `uuid` (unique), `component` (TEXT_COMPONENT enum), `last_modified_user`, `metadata` (JSONB), `created_at`, `updated_at` |
| `text_audit` | Audit trail for INSERT and UPDATE operations on `text` (trigger-driven) | `text_uuid`, `username`, `action` (INSERT/UPDATE), `audited_at` |

#### Access Patterns

- **Read**: Queries routed to the read replica via `readOnlyPostgres` JDBI instance. Supports search by metadata fields and pagination (limit/offset).
- **Write**: Inserts and updates go to the primary via `postgres` JDBI instance. Audit records are written by PostgreSQL triggers on INSERT/UPDATE on `images` and `text` tables; DELETE audit entries are written at the application layer.
- **Indexes**: `idx_images_uuid` (btree on `uuid`), `idx_images_username` (btree on `last_modified_user`), `idx_ia_image_uuid` (btree on `image_uuid`), `idx_text_uuid` (btree on `uuid`), `idx_text_username` (btree on `last_modified_user`), `idx_ta_text_uuid` (btree on `text_uuid`). Additional composite indexes added in later migrations (`V20190430`, `V20210713`).

### MECS Postgres (Read) (`continuumMarketingEditorialContentPostgresRead`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMarketingEditorialContentPostgresRead` |
| Purpose | Read-only replica for search and get query traffic |
| Ownership | owned |
| Migrations path | Not applicable — schema managed by primary |

#### Access Patterns

- **Read**: All `GET /mecs/image`, `GET /mecs/image/{uuid}`, `GET /mecs/text`, `GET /mecs/text/{uuid}`, and `GET /mecs/tag` requests route queries here.
- **Write**: Not applicable — read-only endpoint.

**Production hostnames:**
- Write: `marketing-and-editorial-content-service-rw-na-production-db.gds.prod.gcp.groupondev.com`
- Read: `marketing-and-editorial-content-service-ro-na-production-db.gds.prod.gcp.groupondev.com`
- Database name (production): `editorial_content_prod`

**Staging hostnames:**
- Write: `marketing-and-editorial-content-service-rw-na-staging-db.gds.stable.gcp.groupondev.com`
- Read: `marketing-and-editorial-content-service-ro-na-staging-db.gds.stable.gcp.groupondev.com`
- Database name (staging): `mecs_stg`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| ClientId cache | in-memory (Guava) | Caches authenticated ClientId entries to reduce PostgreSQL auth lookups | 5 minutes after last access, max 100 entries |

> No Redis, Memcached, or distributed cache is used. The only cache is the in-memory ClientId cache configured via `clientId.cacheSpec`.

## Data Flows

All content data flows from API requests through the business service layer into the JDBI data access layer, which routes writes to the primary PostgreSQL instance and reads to the read replica. PostgreSQL triggers automatically write audit rows to `images_audit` and `text_audit` on INSERT and UPDATE operations. Application code writes DELETE audit records explicitly before removing the main record.
