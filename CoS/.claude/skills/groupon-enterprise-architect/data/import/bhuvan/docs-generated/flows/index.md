---
service: "bhuvan"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Bhuvan — the Groupon place discovery service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Geo Entity Search](geo-entity-search.md) | synchronous | HTTP GET `/v1.x/divisions` (or localities, neighborhoods, postalcodes) | Resolves a list of geo entities by name, permalink, country, lat/lng, or IP address using Redis spatial index and Postgres |
| [IP-Based Location Detection](ip-location-detection.md) | synchronous | HTTP GET with `ipaddress` query param | Converts an IP address to a division or locality using MaxMind GeoIP2 and Bhoomi fallback |
| [Autocomplete Address Resolution](autocomplete.md) | synchronous | HTTP GET `/geodetails/autocomplete` or `/api/mobile/...` | Returns address suggestions using ElasticSearch, external Maps APIs, and experiment-driven behavior |
| [Taxonomy Place Management](taxonomy-place-management.md) | synchronous | HTTP GET/POST/PUT/DELETE `/places`, `/sources`, `/placeTypes`, `/indexes`, `/relationshipTypes` | CRUD management of the geo taxonomy: places, sources, place types, indexes, and relationship types |
| [Geo Spatial Index Rebuild](geo-spatial-index-rebuild.md) | batch | CLI command `geo-spatial-indexer` or `POST /indexes/rebuild` | Reads geo entities from Postgres and writes them to Redis GEO spatial index for proximity queries |
| [Relationship Build](relationship-build.md) | batch | CLI command `relationship-build` | Computes geometry-based relationships between geo entities and persists them to the Postgres `relationships` and `relationships_closure` tables |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **IP-Based Location Detection** flow spans `continuumBhuvanService` and `continuumBhoomiService` when the MaxMind local database cannot resolve an IP address.
- The **Autocomplete Address Resolution** flow spans `continuumBhuvanService`, `continuumBhuvanElasticSearch`, `continuumMapsProviderApis`, and `continuumExperimentationService`.
- Reference the central architecture dynamic views for cross-service interactions within the Continuum platform.
