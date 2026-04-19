---
service: "place-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumM3PlacesService, continuumPlacesServicePostgres, continuumPlacesServiceOpenSearch, continuumPlacesServiceRedis]
---

# Architecture Context

## System Context

The M3 Place Service lives within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. It acts as the central authority for merchant place data — physical location records used across deal creation, redemption, and merchant management. The service is called by downstream Groupon services that need place metadata, and it in turn depends on its own data stores (Postgres, OpenSearch, Redis), the M3 Merchant Service for merchant enrichment, and Google Maps for geo-candidate lookup.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| M3 Places Service | `continuumM3PlacesService` | Backend | HTTP/JSON (Spring MVC / Tomcat) | 3.0.x | Place lookup service providing redemption locations and place metadata |
| Place Postgres | `continuumPlacesServicePostgres` | Database | PostgreSQL | — | Primary place persistence service backing ICF/M3 place reads and writes |
| Place OpenSearch | `continuumPlacesServiceOpenSearch` | Database | OpenSearch/Elasticsearch 7.17 | 7.17.22 | Search/index backend for place search, counts, and legacy/index fallback reads |
| Place Redis Cache | `continuumPlacesServiceRedis` | Cache | Redis (Jedis 2.9.0) | — | In-app cache for place responses, Google place candidates, and neighborhood enrichment values |

## Components by Container

### M3 Places Service (`continuumM3PlacesService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`placeSvc_apiControllers`) | HTTP controllers for place read/write, source, status, and defrank endpoints | Spring MVC Controllers |
| Place Service Orchestration (`placeSvc_orchestration`) | Core application orchestration for place retrieval, enrichment, caching, and response shaping | PlaceService |
| Place Query Engine (`placeSvc_queryEngine`) | Builds and executes place search/count/get-by-id workflows with source fallback | PlaceQueryService |
| Place Write Pipeline (`placeSvc_writePipeline`) | Transforms input and executes place write, merge, and history workflows | PlaceWriter + PlaceWriteController |
| Redis Cache Client (`placeSvc_cacheClient`) | Encapsulates Redis cache access and serialization for place and Google candidate data | RedisClient/Jedis |
| OpenSearch Gateway (`placeSvc_indexGateway`) | Encapsulates OpenSearch/Elasticsearch query and indexing access | ESUtil + RestHighLevelClient |
| Postgres Gateway (`placeSvc_postgresGateway`) | Reads ICF place data via Postgres persistence service | PostgresPlacePersistenceService |
| Merchant Client (`placeSvc_merchantClient`) | Calls merchant service APIs for merchant metadata | M3MerchantClient |
| Google Places Client (`placeSvc_googlePlacesClient`) | Calls Google Maps APIs and maps place candidate responses | GoogleClient |
| Voltron Gateway (`placeSvc_voltronGateway`) | Calls Voltron workflows for place processing and history retrieval | VoltronCaller |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumM3PlacesService` | `continuumPlacesServiceRedis` | Caches and retrieves API/query payloads | Redis protocol |
| `continuumM3PlacesService` | `continuumPlacesServicePostgres` | Reads persisted place records and metadata | TCP/PostgreSQL |
| `continuumM3PlacesService` | `continuumPlacesServiceOpenSearch` | Searches, counts, and fetches indexed place data | HTTPS |
| `continuumM3PlacesService` | `continuumM3MerchantService` | Fetches merchant details for place responses | HTTPS/JSON |
| `continuumM3PlacesService` | `googleMaps` | Looks up Google place candidates | HTTPS/JSON |
| `placeSvc_apiControllers` | `placeSvc_orchestration` | Delegates API request handling and response shaping | direct |
| `placeSvc_apiControllers` | `placeSvc_queryEngine` | Executes direct search/count/query validation flows | direct |
| `placeSvc_apiControllers` | `placeSvc_writePipeline` | Executes place write/merge/history workflows | direct |
| `placeSvc_orchestration` | `placeSvc_cacheClient` | Reads/writes cached place and Google place data | direct |
| `placeSvc_orchestration` | `placeSvc_merchantClient` | Fetches merchant details for enrichment | direct |
| `placeSvc_queryEngine` | `placeSvc_indexGateway` | Queries indexed place/search documents | direct |
| `placeSvc_queryEngine` | `placeSvc_postgresGateway` | Reads place records from Postgres persistence | direct |
| `placeSvc_writePipeline` | `placeSvc_indexGateway` | Writes/updates place index documents | direct |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumM3PlacesService`
- Dynamic (place read flow): `dynamic-place-read-flow`
