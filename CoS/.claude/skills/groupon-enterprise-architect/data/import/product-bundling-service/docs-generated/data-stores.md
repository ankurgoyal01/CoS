---
service: "product-bundling-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumProductBundlingPostgres"
    type: "postgresql"
    purpose: "Stores bundle configuration, creative content mappings, and bundle records"
---

# Data Stores

## Overview

Product Bundling Service owns a single PostgreSQL database as its primary data store, accessed through two separate connection pools: one for reads and one for writes. The service uses JDBI DAOs via the `jtier-jdbi` library for all SQL interactions. Schema migrations are managed by `jtier-migrations`. No caches or secondary stores are owned by this service.

## Stores

### Product Bundling Postgres (`continuumProductBundlingPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumProductBundlingPostgres` |
| Purpose | Stores bundle config, bundled product creative content mappings, and persisted bundle records |
| Ownership | owned |
| Migrations path | `src/main/resources/` (managed via `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `bundles` | Persisted bundle records associating deals with bundled products | deal UUID, bundle type, bundled product ID, products (deal option UUIDs) |
| `bundles_config` | Configuration per bundle type (picker, position, type metadata) | bundle type, picker type, position type |
| `bundled_product_creative_contents` | Locale-specific creative content for bundled products | bundled product ID, locale, title, subtitle, pitch markup, merchant name |
| Client ID table (auth) | PostgreSQL-backed client ID registry for API authentication | client ID, metadata (via `jtier-auth-postgres`) |

#### Access Patterns

- **Read**: Bundles read by deal UUID (optionally filtered by timestamp) via the `pbsPersistenceAdapter`. Config records read by bundle type. Creative contents read by bundled product ID and locale. Uses a dedicated read connection pool (`readPostgres`).
- **Write**: Bundle records replaced atomically per deal UUID + bundle type (delete all then insert new). Writes use a separate write connection pool (`writePostgres`).
- **Indexes**: Not directly visible from source; primary keys on deal UUID + bundle type compound key implied by CRUD logic.

## Caches

> No evidence found in codebase. The service does not use Redis, Memcached, or any in-memory cache layer. HTTP responses include a `Cache-Control: max-age` header driven by `cacheControlMaxAgeInDays` (default: 5 days) to allow downstream caching by consumers.

## Data Flows

- Bundle records are written synchronously during API calls and after warranty refresh job execution.
- After any bundle write or delete, the service immediately calls Deal Catalog Service via HTTP to upsert or remove the bundle node, keeping Deal Catalog's view consistent with the PBS database.
- Recommendation refresh jobs read external HDFS files and publish to Kafka; they do not write recommendation data back to the PBS Postgres database.
