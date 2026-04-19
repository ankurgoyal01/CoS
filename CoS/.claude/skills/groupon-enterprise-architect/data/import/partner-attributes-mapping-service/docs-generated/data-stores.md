---
service: "partner-attributes-mapping-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPartnerAttributesMappingPostgres"
    type: "postgresql"
    purpose: "Primary datastore for partner attribute mappings and partner secrets"
---

# Data Stores

## Overview

PAMS owns a single PostgreSQL database that stores two distinct datasets: the bidirectional ID mappings between Groupon and partner entity IDs, and the HMAC signing secrets associated with each registered partner. The service connects using two separate connection pools — one read-write and one read-only — both managed via the `jtier-daas-postgres` library. Schema migrations run at startup using `jtier-migrations` (Flyway).

## Stores

### Partner Attributes Mapping PostgreSQL (`continuumPartnerAttributesMappingPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPartnerAttributesMappingPostgres` |
| Purpose | Primary datastore for partner attribute mappings and partner secrets |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `partner_attributes_map` | Stores the bidirectional mapping between Groupon entity UUIDs and partner entity IDs, scoped by partner namespace and entity type | `id`, `partner_namespace`, `groupon_id` (UUID), `partner_id`, `entity_type`, `created_at`, `updated_at` |
| `partner_secrets` | Stores HMAC signing secrets for each registered partner | `partner`, `secret`, `version`, `digest`, `created_at`, `updated_at` |

#### Access Patterns — `partner_attributes_map`

- **Read**: Queries by `(partner_namespace, entity_type, partner_id IN (...))` to resolve Groupon IDs from partner IDs; queries by `(partner_namespace, entity_type, groupon_id IN (...))` to resolve partner IDs from Groupon IDs; existence check by `(partner_namespace, groupon_id)` before delete
- **Write**: Batch insert of new mappings (`SqlBatch`); update `partner_id` by `(partner_namespace, entity_type, groupon_id)`; update `groupon_id` by `(partner_namespace, entity_type, partner_id)`; delete by `(partner_namespace, groupon_id)` returning deleted row
- **Indexes**: Columns `partner_namespace`, `entity_type`, `groupon_id`, and `partner_id` are used in WHERE clauses; exact index definitions are in the migration scripts at `src/main/resources/db/migration`

#### Access Patterns — `partner_secrets`

- **Read**: Single-row lookup by `partner` name; full table scan to load all secrets into the `PartnerRegistry`
- **Write**: Insert new partner secret row; update `secret`, `version`, and `digest` by `partner` name
- **Indexes**: Primary key is `partner` name

## Caches

> No evidence found in codebase. No in-memory or distributed caches (Redis, Memcached) are configured. The `PartnerRegistry` holds all partner secrets in JVM heap memory (loaded from `partner_secrets` table), refreshed on secret create/update operations.

## Data Flows

Mapping data flows exclusively between the service JVM and the PostgreSQL instance via JDBI3. There are two JDBI instances:

- **Read-write JDBI** (`jdbi`): Used by `PartnerAttributesMappingService`, `PartnerAttributesSecretService`, and `PartnerRegistry` for all write operations and secret reads.
- **Read-only JDBI** (`jdbiReadOnly`): Used by `PartnerAttributesMappingService` for all search/lookup queries (`getMappingsByPartnerId`, `getMappingsByGrouponId`).

No CDC, ETL, or replication pipelines were found in the codebase.
