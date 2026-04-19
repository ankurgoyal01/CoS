---
service: "taxonomyV2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTaxonomyV2Postgres"
    type: "postgresql"
    purpose: "Primary taxonomy data store"
  - id: "continuumTaxonomyV2Redis"
    type: "redis"
    purpose: "Denormalized read cache"
---

# Data Stores

## Overview

Taxonomy V2 uses a two-tier storage strategy: PostgreSQL (via Groupon's DaaS managed service) is the authoritative source of truth for all taxonomy structures, and Redis (via Groupon's RaaS managed service) acts as a denormalized cache-aside layer for low-latency reads. Content changes are always committed to Postgres first; the Redis cache is then rebuilt or invalidated via the snapshot activation workflow. The service owns both stores exclusively.

## Stores

### TaxonomyV2 Postgres DB (`continuumTaxonomyV2Postgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumTaxonomyV2Postgres` |
| Purpose | Authoritative relational store for taxonomy content — categories, relationships, locales, attributes, content versions, snapshots, snapshot maps, and service users |
| Ownership | Owned |
| Migrations path | Managed via `jtier-migrations` (JTier standard migration bundle) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Taxonomy | Top-level taxonomy record (e.g., "Business Type") | `guid`, `name`, `description`, `root_categories` |
| Category | Individual category node within a taxonomy tree | `guid`, `name`, `description`, `parent`, `depth`, `taxonomy_guid` |
| Relationship | Cross-category relationship edge | `guid`, `relationship_type_guid`, `source_category_guid`, `target_category_guid` |
| RelationshipType | Taxonomy of relationship types (e.g., "Parent/Child") | `guid`, `name`, `description` |
| Locale | Locale-specific translations for a category | `name` (locale code), `category_name`, `description`, `attributes` |
| Attribute | Key-value metadata attached to categories and locales | `name`, `value`, locale association |
| ContentVersion | Versioned snapshot of taxonomy content | version identifier, activation state |
| SnapshotMap | Maps snapshot UUIDs to content versions and environments | snapshot UUID, environment, content version reference |
| ServiceUser | Users and roles for authorization within the service | user identifier, role |

#### Access Patterns

- **Read**: JDBI DAOs query Postgres to materialize the Redis cache during snapshot activation; also queried directly for search and management operations not served from cache
- **Write**: Snapshot activation writes metadata updates (snapshot state, activation timestamps) and service user management; taxonomy content itself is imported from the upstream authoring service
- **Indexes**: Not directly visible in source; standard JDBI/DaaS conventions apply (GUIDs as primary keys)

#### Production Endpoints

| Region | Role | Host |
|--------|------|------|
| US-Central1 (GCP) | Read/Write | `taxonomyV2-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| EU-WEST-1 (AWS) | Read-Only replica | `taxonomyv2-ro-emea-production-db.gds.prod.gcp.groupondev.com` |
| Database name | — | `taxonomyv2_prod` |

#### Staging Endpoints

| Region | Role | Host |
|--------|------|------|
| US-Central1 (GCP) | Read/Write | `taxonomyv2-rw-na-staging-db.gds.stable.gcp.groupondev.com` |
| Europe-west1 (GCP) | Read/Write | `pg-core-us-100-stg-rw.gds.stable.gcp.groupondev.com` |
| Database name | — | `taxonomyv2_stg` |

---

### TaxonomyV2 Redis Cache (`continuumTaxonomyV2Redis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumTaxonomyV2Redis` |
| Purpose | Cache-aside store for denormalized taxonomy content enabling low-latency reads at high throughput (~42K rpm for category by GUID at p99 20ms) |
| Ownership | Owned (provisioned via RaaS — raas-team@groupon.com) |
| Migrations path | Not applicable — cache is rebuilt from Postgres on snapshot activation |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Category lookup | Denormalized category objects by GUID | category GUID → category + children + attributes + locales + relationships |
| Taxonomy tree | Full or flat taxonomy hierarchy | taxonomy GUID → ordered category tree |
| Search index | Category name search structures per taxonomy | taxonomy GUID → name → category GUID list |

#### Access Patterns

- **Read**: High-volume consumer-facing reads served entirely from Redis; the `continuumTaxonomyV2Service_cachingCore` component resolves requests against the Redis cache before falling back to Postgres
- **Write**: Bulk-written during snapshot activation — the `continuumTaxonomyV2Service_cachingCore` materializes denormalized views from Postgres into Redis; triggered via cache invalidation messages on `jms.topic.taxonomyV2.cache.invalidate`
- **Indexes**: Redis key design is internal to the Redisson-based caching layer

#### Production Redis Endpoints

| Region | Endpoint |
|--------|----------|
| US-Central1 (GCP) | `taxonomyv2.us-central1.caches.prod.gcp.groupondev.com` |
| EU-WEST-1 (AWS) | `taxonomyv2--redis.prod.prod.eu-west-1.aws.groupondev.com` |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumTaxonomyV2Redis` | Redis (RaaS via Redisson) | Denormalized taxonomy content for sub-20ms read access | Cache is invalidated and rebuilt on each snapshot activation; TTL not separately configured |

## Data Flows

1. Taxonomy content is authored in the upstream `continuumTaxonomyV2AuthoringService` and pushed to the Taxonomy V2 service via HTTP.
2. Content is persisted to PostgreSQL as a new content version and associated snapshot.
3. On snapshot activation (via `PUT /snapshots/activate`), the service publishes a cache invalidation message to `jms.topic.taxonomyV2.cache.invalidate`.
4. The cache invalidation processor consumes the message and triggers the `continuumTaxonomyV2Service_cachingCore` to read from Postgres and materialize denormalized data into Redis.
5. Read requests from consumers are served from Redis; Postgres is the fallback and the source for cache rebuilds.
6. Varnish edge cache is separately invalidated via HTTP BAN after Redis is rebuilt.
