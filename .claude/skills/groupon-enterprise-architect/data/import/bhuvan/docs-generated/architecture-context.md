---
service: "bhuvan"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumBhuvanService"
    - "continuumBhuvanPostgres"
    - "continuumBhuvanRedisCluster"
    - "continuumBhuvanElasticSearch"
    - "continuumMaxMindGeoIpDb"
    - "continuumBhoomiService"
    - "continuumExperimentationService"
    - "continuumMapsProviderApis"
---

# Architecture Context

## System Context

Bhuvan sits within the **Continuum** platform as a core geospatial service in the `geo-fabric` group. It serves internal Groupon services requiring location resolution, division discovery, autocomplete, and address normalization. It depends on a Postgres/PostGIS database for persistent geo entity storage, a Redis Memorystore cluster for spatial index and multi-layer caching, an ElasticSearch cluster for autocomplete indexes, a local MaxMind GeoIP2 database for IP geolocation, and several external HTTP APIs (Bhoomi, Google Maps, MapTiler, Avalara).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Bhuvan Geo Service | `continuumBhuvanService` | Backend | Java 11, JTier, Dropwizard, Jersey | 1.0.x | Primary deployable service JAR exposing all geo REST APIs |
| Bhuvan Postgres DB | `continuumBhuvanPostgres` | Database | Postgres 11, PostGIS | 11 | Stores geo entities, taxonomy, relationships, POI data |
| Bhuvan Redis Cluster | `continuumBhuvanRedisCluster` | Cache | Redis, Lettuce | 5+ | Response caching, geo details cache, spatial index, place geometry cache |
| Bhuvan ElasticSearch Cluster | `continuumBhuvanElasticSearch` | Database | ElasticSearch | 8.12.x | Autocomplete and search indexes for geodetail APIs |
| MaxMind GeoIP2 City Database | `continuumMaxMindGeoIpDb` | Database | MaxMind GeoIP2 | GeoIP2-City_20250211 | Local IP geolocation database file |
| Bhoomi Geocoding Service | `continuumBhoomiService` | Backend | HTTP, Bhoomi | - | External IP-to-coordinate geocoding |
| Experimentation Service (Finch/Expy) | `continuumExperimentationService` | Backend | Finch / Expy | 4.0.33 | A/B testing for autocomplete and geo behavior |
| Maps & Address Provider APIs | `continuumMapsProviderApis` | Backend | HTTP/JSON | - | Google Maps, MapTiler, Avalara APIs |

## Components by Container

### Bhuvan Geo Service (`continuumBhuvanService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumBhuvanService_httpApiGeoPlaces` | Exposes `/v1.x/divisions`, `/v1.0/localities`, `/v1.0/neighborhoods`, `/v1.0/postalcodes`, `/v1.0/timezones` | Java, Dropwizard, Jersey |
| `continuumBhuvanService_httpApiGeoDetails` | Exposes `/geodetails` and mobile `/api/mobile/...` endpoints for geocode, autocomplete, place details, address normalization | Java, Dropwizard, Jersey |
| `continuumBhuvanService_httpApiTaxonomy` | Exposes CRUD endpoints for `/indexes`, `/sources`, `/placeTypes`, `/places`, `/relationshipTypes` | Java, Dropwizard, Jersey |
| `continuumBhuvanService_httpApiInternal` | Internal ops endpoints: cache administration, client configuration, heartbeat, map keys | Java, Dropwizard, Jersey |
| `continuumBhuvanService_componentFactory` | Wires all service components: JDBI, Redis clients, ElasticSearch, experimentation | Java |
| `continuumBhuvanService_roDataStore` | Read-only Postgres access via JDBI3 DAOs | Java, JDBI3, Postgres |
| `continuumBhuvanService_rwDataStore` | Read-write Postgres access for taxonomy mutations | Java, JDBI3, Postgres |
| `continuumBhuvanService_geoSpatialService` | Redis GEO index management and spatial lookup | Java, Redis, Lettuce |
| `continuumBhuvanService_geoEntitiesService` | Loads index/place-type/source configuration from geo-entities config | Java |
| `continuumBhuvanService_geoDetailsService` | Orchestrates geocode, reverse-geocode, autocomplete, timezone, and place-detail resolution | Java |
| `continuumBhuvanService_reqRespCache` | Generic request/response cache and relationship cache backed by Redis | Java, Redis, Lettuce |
| `continuumBhuvanService_geoDetailsCache` | Dedicated Redis cache for geodetail responses | Java, Redis, Lettuce |
| `continuumBhuvanService_placeGeomCache` | Redis cache for place geometries supporting fast spatial queries | Java, Redis, Lettuce |
| `continuumBhuvanService_bhoomiClientService` | Retrofit-based client to Bhoomi for IP-to-coordinate geocoding | Java, Retrofit |
| `continuumBhuvanService_elasticSearchService` | ElasticSearch client for autocomplete and search index queries | Java, ElasticSearch |
| `continuumBhuvanService_experimentationService` | Integrates with Optimize/Finch for experimentation bucketing | Java, Finch/Expy |
| `continuumBhuvanService_clientService` | Loads and validates registered GeoClient definitions from YAML files | Java |
| `continuumBhuvanService_experimentationMetrics` | Emits metrics for experimentation decisions via JTier SMA | Java, Metrics |
| `continuumBhuvanService_healthAndMetrics` | Dropwizard health check and metrics integration | Java, Dropwizard |
| `continuumBhuvanService_geoSpatialIndexerCommand` | CLI command to build Redis spatial indices from Postgres | Java, Dropwizard CLI |
| `continuumBhuvanService_relationshipBuildCommand` | CLI command to compute and persist geo entity relationships based on geometry overlap | Java, Dropwizard CLI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBhuvanService` | `continuumBhuvanPostgres` | Reads and writes geo entities, taxonomy, relationships, POI data | Postgres (JDBI3) |
| `continuumBhuvanService` | `continuumBhuvanRedisCluster` | Response cache, geo details cache, spatial index, place geometry cache | Redis (Lettuce) |
| `continuumBhuvanService` | `continuumBhuvanElasticSearch` | Indexes and queries autocomplete and search indices | ElasticSearch REST |
| `continuumBhuvanService` | `continuumMaxMindGeoIpDb` | Local IP geolocation lookups | MaxMind GeoIP2 (file) |
| `continuumBhuvanService` | `continuumBhoomiService` | IP-to-coordinate geocoding via Retrofit BhoomiClient | HTTP/JSON |
| `continuumBhuvanService` | `continuumExperimentationService` | A/B experiment bucketing for autocomplete behavior | HTTP/JSON, Expy |
| `continuumBhuvanService` | `continuumMapsProviderApis` | Address normalization, geocode, autocomplete, place details, timezone | HTTP/JSON |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum-bhuvan`
- Component: `components-continuum-bhuvan-service`
