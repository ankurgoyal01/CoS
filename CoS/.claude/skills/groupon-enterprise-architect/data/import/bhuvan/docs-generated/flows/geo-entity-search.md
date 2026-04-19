---
service: "bhuvan"
title: "Geo Entity Search"
generated: "2026-03-03"
type: flow
flow_name: "geo-entity-search"
flow_type: synchronous
trigger: "HTTP GET request to /v1.x/divisions, /v1.0/localities, /v1.0/neighborhoods, or /v1.0/postalcodes"
participants:
  - "continuumBhuvanService_httpApiGeoPlaces"
  - "continuumBhuvanService_reqRespCache"
  - "continuumBhuvanService_geoSpatialService"
  - "continuumBhuvanService_roDataStore"
  - "continuumBhuvanRedisCluster"
  - "continuumBhuvanPostgres"
architecture_ref: "dynamic-continuum-bhuvan-geo-entity-search"
---

# Geo Entity Search

## Summary

This flow handles synchronous HTTP requests from internal consumers to search for geo entities such as divisions, localities, neighborhoods, and postal codes. The service first checks the Redis response cache for a cached response, then queries the Redis GEO spatial index for coordinate-based lookups, and finally reads entity metadata from Postgres. Results are written back to the response cache before returning to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon services (commerce, frontend, etc.) calling `GET /v1.x/divisions` or related endpoints
- **Frequency**: Per-request (high frequency — core geo entity lookup)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Geo Places HTTP API | Receives and validates the inbound HTTP request; orchestrates the lookup | `continuumBhuvanService_httpApiGeoPlaces` |
| Request/Response Cache | Returns cached response if available; stores new responses | `continuumBhuvanService_reqRespCache` |
| Geo Spatial Service | Performs Redis GEO radius/position queries for lat/lng or IP-based lookups | `continuumBhuvanService_geoSpatialService` |
| Read-Only Data Store | Reads entity metadata, localized content, and related entities from Postgres | `continuumBhuvanService_roDataStore` |
| Bhuvan Redis Cluster | Backing store for response cache and spatial index | `continuumBhuvanRedisCluster` |
| Bhuvan Postgres DB | Primary entity store | `continuumBhuvanPostgres` |

## Steps

1. **Receives request**: Geo Places HTTP API receives `GET /v1.x/divisions` (or localities/neighborhoods/postalcodes) with query parameters (name, permalink, country, status, lat/lng, ipaddress, offset, limit, include_* flags, client_id).
   - From: `caller (internal service)`
   - To: `continuumBhuvanService_httpApiGeoPlaces`
   - Protocol: REST/HTTP

2. **Validates client**: API validates the `client_id` parameter against the BhuvanClientService registry.
   - From: `continuumBhuvanService_httpApiGeoPlaces`
   - To: `continuumBhuvanService_clientService`
   - Protocol: direct (in-process)

3. **Checks response cache**: API checks the Redis response cache for a cached response to the exact query parameters.
   - From: `continuumBhuvanService_reqRespCache`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis (Lettuce)

4. **Cache hit — returns cached response**: If a cached response exists, the service returns it immediately without querying Postgres.
   - From: `continuumBhuvanService_httpApiGeoPlaces`
   - To: caller
   - Protocol: REST/HTTP JSON

5. **Cache miss — queries spatial index** (for lat/lng or IP-based queries): Geo Places API delegates to the Geo Spatial Service to query the Redis GEO index for entities within the specified radius.
   - From: `continuumBhuvanService_geoSpatialService`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis GEO commands (Lettuce)

6. **Reads entity metadata from Postgres**: The Read-Only Data Store retrieves matching entity records, localized content, and optionally related entities (postalcodes, localities, etc.) from Postgres.
   - From: `continuumBhuvanService_roDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3)

7. **Populates response cache**: The assembled response is stored in Redis before returning to the caller.
   - From: `continuumBhuvanService_reqRespCache`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis (Lettuce)

8. **Returns response**: JSON array (v1.0) or paginated `PaginatedEntities` envelope (v1.1+) is returned to the caller.
   - From: `continuumBhuvanService_httpApiGeoPlaces`
   - To: caller
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `client_id` | Returns `401 Unauthorized` | Request rejected |
| Invalid query parameters | Returns `400 Bad Request` | Request rejected |
| No results found | Returns empty array or `404 Not Found` depending on version and `fallback` param | Empty result or 404 |
| Redis unavailable | Cache miss treated as cache bypass; queries Postgres directly | Degraded performance, still functional |
| Postgres unavailable | Returns `503 Service Unavailable` | Request fails |
| Rate limit exceeded | Returns `429 Too Many Requests` | Request rejected |

## Sequence Diagram

```
Caller -> GeoPlacesAPI: GET /v1.x/divisions?client_id=X&lat=Y&lng=Z
GeoPlacesAPI -> ClientService: validate client_id
ClientService --> GeoPlacesAPI: valid
GeoPlacesAPI -> ReqRespCache: check cache(key)
ReqRespCache -> Redis: GET cache:key
Redis --> ReqRespCache: miss
ReqRespCache --> GeoPlacesAPI: miss
GeoPlacesAPI -> GeoSpatialService: query(lat, lng, radius)
GeoSpatialService -> Redis: GEORADIUS index lat lng radius
Redis --> GeoSpatialService: [entity_ids]
GeoSpatialService --> GeoPlacesAPI: [entity_ids]
GeoPlacesAPI -> RODataStore: fetchByIds([entity_ids])
RODataStore -> Postgres: SELECT ... WHERE uuid IN (...)
Postgres --> RODataStore: [entity_rows]
RODataStore --> GeoPlacesAPI: [entities]
GeoPlacesAPI -> ReqRespCache: store(key, response)
ReqRespCache -> Redis: SET cache:key response
GeoPlacesAPI --> Caller: 200 [entities]
```

## Related

- Architecture dynamic view: `dynamic-continuum-bhuvan-geo-entity-search`
- Related flows: [IP-Based Location Detection](ip-location-detection.md), [Geo Spatial Index Rebuild](geo-spatial-index-rebuild.md)
