---
service: "bhuvan"
title: "Geo Spatial Index Rebuild"
generated: "2026-03-03"
type: flow
flow_name: "geo-spatial-index-rebuild"
flow_type: batch
trigger: "CLI command geo-spatial-indexer or HTTP POST /indexes/rebuild"
participants:
  - "continuumBhuvanService_geoSpatialIndexerCommand"
  - "continuumBhuvanService_httpApiInternal"
  - "continuumBhuvanService_geoSpatialService"
  - "continuumBhuvanService_roDataStore"
  - "continuumBhuvanService_placeGeomCache"
  - "continuumBhuvanPostgres"
  - "continuumBhuvanRedisCluster"
architecture_ref: "dynamic-continuum-bhuvan-geo-spatial-index-rebuild"
---

# Geo Spatial Index Rebuild

## Summary

This flow populates or rebuilds the Redis GEO spatial index used by Bhuvan for proximity-based geo entity queries. It reads all geo entities from Postgres (optionally using the place geometry cache), writes them into a Redis GEO data structure, and makes them available for radius-based queries. This operation is computationally intensive and can be triggered either via the CLI `geo-spatial-indexer` command (for batch operation) or at runtime via `POST /indexes/rebuild` (for on-demand refresh without a pod restart).

## Trigger

- **Type**: manual or operational
- **Source**: Operations team running the CLI command, or an operator calling `POST /indexes/rebuild` via HTTP
- **Frequency**: On-demand (run after geo data updates or when Redis index is empty/stale)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Geo Spatial Indexer Command | CLI entry point; orchestrates the index build | `continuumBhuvanService_geoSpatialIndexerCommand` |
| Internal & Ops HTTP API | Runtime trigger via `POST /indexes/rebuild?index_name=<name>` | `continuumBhuvanService_httpApiInternal` |
| Geo Spatial Service | Executes the indexing of geo entities into Redis GEO structures | `continuumBhuvanService_geoSpatialService` |
| Read-Only Data Store | Reads geo entities from Postgres for the indexing operation | `continuumBhuvanService_roDataStore` |
| Place Geometry Cache | Caches place geometries in Redis to speed up repeated geometry lookups | `continuumBhuvanService_placeGeomCache` |
| Bhuvan Postgres DB | Source of truth for geo entity coordinates and metadata | `continuumBhuvanPostgres` |
| Bhuvan Redis Cluster | Destination for the rebuilt GEO spatial index entries | `continuumBhuvanRedisCluster` |

## Steps

### CLI Trigger Path

1. **Starts indexer command**: Operator invokes `java -jar bhuvan-<version>.jar geo-spatial-index -i <index-name> <config.yml>`.
   - From: operator / deployment script
   - To: `continuumBhuvanService_geoSpatialIndexerCommand`
   - Protocol: CLI (JVM process)

2. **Loads index configuration**: The `GeoEntitiesService` loads the index definition (query, type, place types) from the geo-entities configuration.
   - From: `continuumBhuvanService_geoSpatialIndexerCommand`
   - To: `continuumBhuvanService_geoEntitiesService`
   - Protocol: direct (in-process)

3. **Reads geo entities from Postgres**: The Read-Only Data Store fetches all entities matching the index definition (e.g., all active divisions with lat/lng) from Postgres.
   - From: `continuumBhuvanService_roDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3)

4. **Loads place geometries into cache**: For each entity, place geometries are loaded from Postgres and cached in the Place Geometry Cache in Redis.
   - From: `continuumBhuvanService_placeGeomCache`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis (Lettuce)

5. **Writes entities to Redis GEO index**: GeoSpatialService adds each entity's coordinates to the Redis GEO data structure for the named index.
   - From: `continuumBhuvanService_geoSpatialService`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis GEOADD commands (Lettuce)

6. **Indexing complete**: Command exits. Redis spatial index is now available for query use.

### HTTP Trigger Path (Runtime)

1. **Receives rebuild request**: `POST /indexes/rebuild?index_name=Geoplaces-Divisions` received by Internal & Ops HTTP API.
   - From: operator / script
   - To: `continuumBhuvanService_httpApiInternal`
   - Protocol: REST/HTTP

2. **Delegates to Geo Spatial Service**: HTTP API calls `GeoSpatialService.indexEntities(indexName)` synchronously.

3. **Follows same steps 3–5 as CLI path**: Reads from Postgres, caches geometries, writes to Redis.

4. **Returns boolean result**: Returns `true` on success; `false` on failure.
   - From: `continuumBhuvanService_httpApiInternal`
   - To: caller
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres unavailable | Command fails with exception | Index rebuild aborted; existing Redis index remains |
| Redis unavailable | Command fails with exception | Index rebuild aborted |
| Unknown index name | Returns `400 Bad Request` (HTTP path) or exception (CLI path) | Operation rejected |
| Partial failure mid-index | Index may be partially populated; re-run required | Existing index may be incomplete |
| HTTP rebuild during high traffic | WARNING: expensive operation; may degrade performance during rebuild | Consider running CLI command during off-peak hours |

## Sequence Diagram

```
Operator -> GeoSpatialIndexerCommand: geo-spatial-index -i Geoplaces-Divisions development.yml
GeoSpatialIndexerCommand -> GeoEntitiesService: loadIndexConfig(Geoplaces-Divisions)
GeoEntitiesService --> GeoSpatialIndexerCommand: indexConfig
GeoSpatialIndexerCommand -> GeoSpatialService: indexEntities(indexConfig)
GeoSpatialService -> RODataStore: fetchAllEntities(indexConfig.query)
RODataStore -> Postgres: SELECT uuid, lat, lng FROM places WHERE ...
Postgres --> RODataStore: [entities]
GeoSpatialService -> PlaceGeomCache: loadGeometries([entity_uuids])
PlaceGeomCache -> Redis: MSET geom:uuid1 geom1 ...
GeoSpatialService -> Redis: GEOADD Geoplaces-Divisions lng1 lat1 uuid1 lng2 lat2 uuid2 ...
Redis --> GeoSpatialService: OK
GeoSpatialService --> GeoSpatialIndexerCommand: done
```

## Related

- Architecture dynamic view: `dynamic-continuum-bhuvan-geo-spatial-index-rebuild`
- Related flows: [Geo Entity Search](geo-entity-search.md), [Relationship Build](relationship-build.md)
- README section: [Geo Spatial Indexer](../../../import-repos/bhuvan/README.md#geo-spatial-indexer)
