---
service: "bhuvan"
title: "IP-Based Location Detection"
generated: "2026-03-03"
type: flow
flow_name: "ip-location-detection"
flow_type: synchronous
trigger: "HTTP GET request with ipaddress query parameter to any geo entity endpoint"
participants:
  - "continuumBhuvanService_httpApiGeoPlaces"
  - "continuumBhuvanService_geoDetailsService"
  - "continuumBhuvanService_bhoomiClientService"
  - "continuumMaxMindGeoIpDb"
  - "continuumBhoomiService"
  - "continuumBhuvanService_geoSpatialService"
  - "continuumBhuvanRedisCluster"
  - "continuumBhuvanPostgres"
architecture_ref: "dynamic-continuum-bhuvan-ip-location"
---

# IP-Based Location Detection

## Summary

This flow handles requests where the caller passes an `ipaddress` query parameter instead of (or in addition to) explicit `lat`/`lng` coordinates. Bhuvan first attempts to resolve the IP to geographic coordinates using the local MaxMind GeoIP2-City database file. If MaxMind cannot resolve the IP, the request is forwarded to the Bhoomi geocoding service. The resolved coordinates are then used to continue the standard geo entity search flow.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon services providing an IP address (e.g., user's request IP) to resolve their geographic location
- **Frequency**: Per-request (used when explicit lat/lng is not available)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Geo Places HTTP API | Receives the request; detects `ipaddress` param and initiates IP resolution | `continuumBhuvanService_httpApiGeoPlaces` |
| Geo Details Service | Orchestrates IP-to-coordinate resolution | `continuumBhuvanService_geoDetailsService` |
| Bhoomi Geocoder Client Service | Retrofit-based client to Bhoomi for fallback IP resolution | `continuumBhuvanService_bhoomiClientService` |
| MaxMind GeoIP2 City DB | In-process IP geolocation file lookup | `continuumMaxMindGeoIpDb` |
| Bhoomi Geocoding Service | External IP-to-coordinate geocoding service | `continuumBhoomiService` |
| Geo Spatial Service | Proximity lookup once coordinates are resolved | `continuumBhuvanService_geoSpatialService` |
| Bhuvan Redis Cluster | Spatial index backing store | `continuumBhuvanRedisCluster` |
| Bhuvan Postgres DB | Entity metadata reads | `continuumBhuvanPostgres` |

## Steps

1. **Receives request with IP address**: Geo Places HTTP API receives a request with `ipaddress=<ip>` query parameter (e.g., `GET /v1.x/divisions?ipaddress=203.0.113.1&client_id=web`).
   - From: caller
   - To: `continuumBhuvanService_httpApiGeoPlaces`
   - Protocol: REST/HTTP

2. **Attempts MaxMind IP lookup**: The service performs an in-process lookup of the IP address against the local MaxMind GeoIP2-City database file at `/var/groupon/maxmind/GeoIP2-City.mmdb` using `geolib-ipgeocode`.
   - From: `continuumBhuvanService_geoDetailsService`
   - To: `continuumMaxMindGeoIpDb`
   - Protocol: file read (in-process)

3. **MaxMind resolves IP (happy path)**: MaxMind returns lat/lng coordinates for the IP address. Flow continues to step 5.

4. **MaxMind fails — delegates to Bhoomi (fallback)**: If MaxMind cannot resolve the IP, the `BhoomiClientService` sends an HTTP request to the Bhoomi geocoding service to resolve the IP to coordinates.
   - From: `continuumBhuvanService_bhoomiClientService`
   - To: `continuumBhoomiService`
   - Protocol: HTTP/JSON (JTier Retrofit)

5. **Queries Redis spatial index with resolved coordinates**: With lat/lng coordinates now available, the Geo Spatial Service queries the Redis GEO index for nearby geo entities within the default or specified radius.
   - From: `continuumBhuvanService_geoSpatialService`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis GEO commands (Lettuce)

6. **Reads entity metadata from Postgres**: The Read-Only Data Store fetches entity records for the resolved entity IDs.
   - From: `continuumBhuvanService_roDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3)

7. **Returns resolved geo entities**: JSON response with divisions (or localities, etc.) is returned to the caller.
   - From: `continuumBhuvanService_httpApiGeoPlaces`
   - To: caller
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MaxMind cannot resolve IP | Delegates to Bhoomi geocoding service | Flow continues if Bhoomi succeeds |
| Bhoomi service unavailable | Returns null coordinates; fallback to default location or error | Degraded or error response |
| Both MaxMind and Bhoomi fail | Returns `400 Bad Request` or empty result | Caller must provide explicit lat/lng |
| IP in private/reserved range | MaxMind returns no result; Bhoomi may also fail | Returns default location or error |

## Sequence Diagram

```
Caller -> GeoPlacesAPI: GET /v1.x/divisions?ipaddress=203.0.113.1&client_id=X
GeoPlacesAPI -> GeoDetailsService: resolveCoordinates(ip=203.0.113.1)
GeoDetailsService -> MaxMindGeoIpDb: lookup(203.0.113.1)
MaxMindGeoIpDb --> GeoDetailsService: null (not found)
GeoDetailsService -> BhoomiClientService: geocode(ip=203.0.113.1)
BhoomiClientService -> BhoomiService: GET /geocode?ip=203.0.113.1
BhoomiService --> BhoomiClientService: {lat: 41.85, lng: -87.65}
BhoomiClientService --> GeoDetailsService: {lat: 41.85, lng: -87.65}
GeoDetailsService --> GeoPlacesAPI: {lat: 41.85, lng: -87.65}
GeoPlacesAPI -> GeoSpatialService: query(lat=41.85, lng=-87.65)
GeoSpatialService -> Redis: GEORADIUS index 41.85 -87.65 50 mi
Redis --> GeoSpatialService: [division_ids]
GeoPlacesAPI -> RODataStore: fetchByIds([division_ids])
RODataStore -> Postgres: SELECT ...
Postgres --> RODataStore: [division_rows]
GeoPlacesAPI --> Caller: 200 [divisions]
```

## Related

- Architecture dynamic view: `dynamic-continuum-bhuvan-ip-location`
- Related flows: [Geo Entity Search](geo-entity-search.md), [Autocomplete Address Resolution](autocomplete.md)
