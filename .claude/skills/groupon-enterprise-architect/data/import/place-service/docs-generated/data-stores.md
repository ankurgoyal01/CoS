---
service: "place-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPlacesServicePostgres"
    type: "postgresql"
    purpose: "Primary ICF place record persistence"
  - id: "continuumPlacesServiceOpenSearch"
    type: "elasticsearch"
    purpose: "Place search index and count queries"
  - id: "continuumPlacesServiceRedis"
    type: "redis"
    purpose: "API response cache and Google place candidate cache"
---

# Data Stores

## Overview

The M3 Place Service uses three data stores: PostgreSQL as the primary system of record for ICF place records, OpenSearch/Elasticsearch as the search and count index backend, and Redis as an in-application response cache. Postgres write capability is NA-only; EMEA reads from a replicated replica managed by the GDS team. Backup is managed by the DaaS team.

## Stores

### Place Postgres (`continuumPlacesServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPlacesServicePostgres` |
| Purpose | Primary place persistence service backing ICF/M3 place reads and writes |
| Ownership | owned |
| Migrations path | Managed externally by GDS team (DB connection config in `place-service-secrets` repo) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Place (ICF record) | Canonical place record | Place UUID, name, location (street address, city, postcode, country, lat/lng), phone, status, visibility, brand IDs, category IDs, extended attributes, source ID, timestamps |
| Place history | Change audit log for place records | Place UUID, change timestamp, field deltas, source |

#### Access Patterns

- **Read**: Single place lookup by ID (`placeSvc_postgresGateway`), called on cache miss from the orchestration layer
- **Write**: Create and update operations via `placeSvc_writePipeline`; write instance is NA-only; EMEA reads from replica
- **Indexes**: Not directly inspectable from this repository; managed by DaaS team

### Place OpenSearch (`continuumPlacesServiceOpenSearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch (OpenSearch-compatible, ES 7.x client) |
| Architecture ref | `continuumPlacesServiceOpenSearch` |
| Purpose | Search/index backend for place search, counts, and legacy/index fallback reads |
| Ownership | owned |
| Migrations path | Index management via `ESUtil` (`src/main/java/com/groupon/m3/placereadservice/persistence/client/ESUtil.java`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Place index document | Searchable and filterable place records | Place UUID, name, location fields, status, visibility, brand IDs, category IDs, place type, extended attributes, geo-point, score fields |

#### Access Patterns

- **Read**: Full-text search, filtered queries, count aggregations, and geo-radius queries via `placeSvc_indexGateway`; used as primary search path and fallback when Postgres does not satisfy the query shape
- **Write**: Place index document upserts triggered by the `placeSvc_writePipeline` on create/update
- **Indexes**: Geo-point index for radius search; full-text analyzed fields for name/query search; keyword fields for filter aggregations

#### Endpoint configuration

| Environment | Endpoint variable |
|-------------|-------------------|
| staging-us-central1 | `M3_PLACEREAD_OS_STAGING_ESDOMAIN_ENDPOINT` |
| production-us-central1 | `M3_PLACEREAD_OS_PROD_ESDOMAIN_ENDPOINT` |
| production-eu-west-1 | `M3_PLACEREAD_OS_PROD_ESDOMAIN_ENDPOINT` |

### Place Redis Cache (`continuumPlacesServiceRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumPlacesServiceRedis` |
| Purpose | In-app cache for place responses, Google place candidates, and neighborhood enrichment values |
| Ownership | owned (RaaS — Redis-as-a-Service managed by platform team) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Place response cache | Cached place API responses | Cache key derived from request parameters; value is serialized place payload (LZ4 or zstd compressed) |
| Google place candidate cache | Cached Google Maps lookup results | Cache key derived from place ID and merchant name; value is `GooglePlaceResponse` |
| Neighborhood cache | Cached neighborhood enrichment values | Cache key derived from geo coordinates |

#### Access Patterns

- **Read**: Cache lookup performed first by `placeSvc_orchestration` before delegating to `placeSvc_queryEngine` (Postgres/OpenSearch); cache lookup also performed before Google Maps API calls
- **Write**: Cache populated after a successful Postgres or OpenSearch read, and after a successful Google Maps lookup
- **TTL**: 15–30 minutes (randomized to prevent thundering herd) per `doc/owners_manual.md`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumPlacesServiceRedis` | redis | Place API response cache, Google place candidates, neighborhood enrichment | 15–30 min (randomized) |

## Data Flows

1. On place read: Request arrives at `placeSvc_apiControllers`, delegates to `placeSvc_orchestration`, which checks Redis (`placeSvc_cacheClient`). On cache hit, returns cached response. On cache miss, delegates to `placeSvc_queryEngine`, which reads from Postgres (`placeSvc_postgresGateway`) or falls back to OpenSearch (`placeSvc_indexGateway`). Merchant enrichment is fetched from M3 Merchant Service if requested. Result is written back to Redis.
2. On place write: `placeSvc_writePipeline` transforms incoming payload, writes to Postgres, and updates the OpenSearch index document.
3. Postgres replication: Write operations execute against the NA primary Postgres instance; GDS team manages cross-region replication to EMEA replica. Backups managed by DaaS team.
