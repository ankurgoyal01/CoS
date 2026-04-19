---
service: "bhuvan"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBhuvanPostgres"
    type: "postgresql"
    purpose: "Primary geo entity storage — places, taxonomy, relationships, POI data"
  - id: "continuumBhuvanRedisCluster"
    type: "redis"
    purpose: "Response cache, geo details cache, spatial index, place geometry cache"
  - id: "continuumBhuvanElasticSearch"
    type: "elasticsearch"
    purpose: "Autocomplete and search indexes for geodetail APIs"
  - id: "continuumMaxMindGeoIpDb"
    type: "file"
    purpose: "Local IP geolocation database"
---

# Data Stores

## Overview

Bhuvan uses four data stores. The primary durable store is a Postgres 11 / PostGIS database owning all geo entity, taxonomy, relationship, and POI data. A Redis Memorystore cluster provides four logical caches: generic request/response caching, geo details caching, a geo spatial index (Redis GEO), and a place geometry cache. An ElasticSearch cluster stores autocomplete and search indexes. A local MaxMind GeoIP2 City database file enables fast in-process IP-to-coordinate resolution.

---

## Stores

### Bhuvan Postgres DB (`continuumBhuvanPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql / PostGIS |
| Architecture ref | `continuumBhuvanPostgres` |
| Purpose | Primary geo entity, taxonomy, relationship, and POI data store |
| Ownership | owned |
| Migrations path | `jtier-migrations` (managed by JTier, DDL in `src/main/docker/postgres/`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `places` | Core geo entity (any place type) | `uuid`, `source_uuid`, `place_type_uuid`, `lat`, `lng`, `data` (jsonb), `active`, `locale` |
| `place_localized_contents` | Localized names, URLs, abbreviated names per place and locale | `place_uuid`, `locale`, `name`, `url`, `abbr_name`, `full_name` |
| `place_geoms` | PostGIS geometry for each place (GeoJSON + native geometry column) | `place_uuid`, `geojson`, `geom` (PostGIS geometry) |
| `sources` | Data source registry (e.g., Google, internal) | `uuid`, `description` |
| `source_names` | Aliases/names for each source with ranking | `source_uuid`, `name`, `rank` |
| `place_types` | Classification of place types per source | `uuid`, `source_uuid`, `type` |
| `place_indexes` | Index definitions for spatial lookups (query JSON) | `uuid`, `type`, `query` (jsonb), `active` |
| `place_index_names` | Names and aliases for place indexes | `index_uuid`, `name`, `rank` |
| `relationship_types` | Named relationship type definitions (e.g., "contains", "borders") | `uuid`, `name`, `description` |
| `relationships` | Direct relationships between two places | `uuid`, `relationship_type_uuid`, `src_uuid`, `dst_uuid` |
| `relationships_closure` | Transitive closure of relationships for fast hierarchy traversal | `relationship_type_uuid`, `src_uuid`, `dst_uuid`, `depth` |
| `client_ids` | Registered API client identifiers | `id`, `name` |
| `client_id_roles` | Roles assigned to each client ID | `client_id`, `role` |

#### Access Patterns

- **Read**: High-frequency reads of place entities, localized content, and geometry via JDBI3 DAOs on the read-only Postgres connection. Spatial lookups delegated to Redis GEO index first, with Postgres as fallback or for data loading.
- **Write**: Write operations (taxonomy mutations) use the read-write Postgres connection. Batch relationship builds (`relationship-build` command) write computed relationships into `relationships` and `relationships_closure`. DB migrations run via the `migrate` CLI command.
- **Indexes**: GIN index on `places.data` (jsonb), btree on `places(source_uuid, id)`, GIN trigram on `place_localized_contents.name`, GiST on `place_geoms.geom`, btree on `relationships_closure(src_uuid, relationship_type_uuid)`.

---

### Bhuvan Redis Cluster (`continuumBhuvanRedisCluster`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumBhuvanRedisCluster` |
| Purpose | Multi-purpose cache and geo spatial index |
| Ownership | owned (Redis Memorystore) |
| Migrations path | Not applicable |

#### Logical Cache Layers

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Request/Response Cache (`response_cache`) | redis | Caches serialized HTTP responses for geo entity queries; also used for relationship caching | Configured per deployment |
| Geo Details Cache | redis | Dedicated cache for geocode, autocomplete, timezone, and address normalization results | Configured per deployment |
| Place Geometry Cache | redis | Caches place GeoJSON geometries to avoid repeated Postgres round-trips during spatial operations | Configured per deployment |
| Geo Spatial Index | redis (GEO commands) | Redis GEO data structure holding indexed positions of geo entities for radius/proximity queries | Persistent (rebuilt on demand) |

**Serialization**: Cache entries are serialized using Kryo binary format (kryo 5.5.0 + kryo-serializers 0.45).

---

### Bhuvan ElasticSearch Cluster (`continuumBhuvanElasticSearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `continuumBhuvanElasticSearch` |
| Purpose | Autocomplete and place search indexes supporting geodetail APIs |
| Ownership | owned (managed cluster) |
| Migrations path | Not applicable (index rebuilt via `geo-spatial-indexer` command or `POST /indexes/rebuild`) |

#### Access Patterns

- **Read**: Autocomplete queries via `ElasticSearchService` / `ElasticSearchRetrofitService` using the ElasticSearch REST client (v8.12.1).
- **Write**: Indexes are populated when the `geo-spatial-indexer` command runs or when `POST /indexes/rebuild` is called at runtime.

---

### MaxMind GeoIP2 City Database (`continuumMaxMindGeoIpDb`)

| Property | Value |
|----------|-------|
| Type | file (mmdb) |
| Architecture ref | `continuumMaxMindGeoIpDb` |
| Purpose | In-process IP-to-geographic-coordinates resolution |
| Ownership | external (MaxMind, updated periodically) |
| Location | `/var/groupon/maxmind/GeoIP2-City.mmdb` (baked into Docker image) |

The GeoIP2-City database file (package `GeoIP2-City_20250211`) is bundled in the Docker image at build time via `src/main/docker/Dockerfile`. Reads are performed in-process using the `geolib-ipgeocode` library with no network calls required at runtime.

## Data Flows

1. Geo entity data originates in the Postgres DB (loaded via bulk SQL seed files or taxonomy API writes).
2. The `geo-spatial-indexer` CLI command reads entities from Postgres and writes them to the Redis GEO spatial index.
3. The `relationship-build` CLI command reads entities and computes geometry-based relationships, writing the results to the `relationships` and `relationships_closure` Postgres tables.
4. At query time, the service checks the Redis response/geo-details/geometry caches first; on misses, it reads from Postgres and populates the cache.
5. Autocomplete queries hit ElasticSearch; fallback behavior may query Postgres directly.
6. IP geolocation resolves via MaxMind in-process first; if unsuccessful, delegates to Bhoomi geocoding service.
