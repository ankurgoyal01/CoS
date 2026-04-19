---
service: "place-service"
title: "Google Place Candidate Lookup"
generated: "2026-03-03"
type: flow
flow_name: "google-place-lookup"
flow_type: synchronous
trigger: "HTTP GET to Google place lookup endpoint for a specific M3 place ID"
participants:
  - "placeSvc_apiControllers"
  - "placeSvc_orchestration"
  - "placeSvc_cacheClient"
  - "placeSvc_googlePlacesClient"
  - "continuumPlacesServiceRedis"
  - "googleMaps"
architecture_ref: "dynamic-place-read-flow"
---

# Google Place Candidate Lookup

## Summary

This flow retrieves Google Maps place candidates for a given M3 place record. The service first checks Redis for a cached Google candidate result. On a cache miss, it fetches the M3 place details, constructs a full address plus merchant name query string, and calls the Google Maps Find Place From Text API. The returned candidates (place ID, address, name, lat/lng) are cached in Redis before being returned to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon systems requiring Google geo-enrichment for an M3 place
- **Frequency**: On-demand; rate reduced by Redis cache with 15–30 minute TTL

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers (GooglePlaceController) | Receives HTTP GET, validates `client_id` and place ID | `placeSvc_apiControllers` |
| Place Service Orchestration | Coordinates cache check and Google lookup dispatch | `placeSvc_orchestration` |
| Redis Cache Client | Reads and writes cached Google place candidates | `placeSvc_cacheClient` |
| Google Places Client | Calls Google Maps Find Place From Text API | `placeSvc_googlePlacesClient` |
| Place Redis Cache | External Redis cache store for candidate results | `continuumPlacesServiceRedis` |
| Google Maps | External Google Maps Places API | `googleMaps` |

## Steps

1. **Receive lookup request**: HTTP GET arrives at `/v2.0/places/{id}/googleplace` with `client_id`.
   - From: calling service
   - To: `placeSvc_apiControllers` (GooglePlaceController)
   - Protocol: REST/HTTP

2. **Validate and delegate**: Controller validates `client_id` and delegates to orchestration layer with the M3 place ID.
   - From: `placeSvc_apiControllers`
   - To: `placeSvc_orchestration`
   - Protocol: direct

3. **Check Redis cache**: Orchestration checks Redis for a cached `GooglePlaceResponse` keyed by place ID and merchant name.
   - From: `placeSvc_orchestration` → `placeSvc_cacheClient`
   - To: `continuumPlacesServiceRedis`
   - Protocol: Redis protocol

4. **Cache hit — return cached candidates**: If a valid cached `GooglePlaceResponse` exists, return it immediately. Steps 5–8 are skipped.
   - From: `continuumPlacesServiceRedis`
   - To: calling service (via orchestration → controller)
   - Protocol: HTTP/JSON

5. **Cache miss — fetch M3 place record**: On cache miss, orchestration fetches the current M3 place to obtain location data and merchant name.
   - From: `placeSvc_orchestration`
   - To: `placeSvc_queryEngine` → `continuumPlacesServicePostgres` (or Redis)
   - Protocol: direct / Redis / TCP

6. **Construct search query**: Google Places Client generates a full address string from the place's location fields (street address, city, postcode, country) combined with the merchant name.
   - From: `placeSvc_googlePlacesClient` (PlaceIdFinderUtils.generateFullAddress)
   - Protocol: local computation

7. **Call Google Maps Find Place From Text API**: Google Places Client calls `PlacesApi.findPlaceFromText()` with the TEXT_QUERY input type and requests fields `FORMATTED_ADDRESS`, `GEOMETRY`, `NAME`, `PLACE_ID`.
   - From: `placeSvc_googlePlacesClient`
   - To: `googleMaps` (Google Maps Places API)
   - Protocol: HTTPS/JSON via `google-maps-services` SDK (GeoApiContext)

8. **Map candidates and cache result**: Response is mapped into a `GooglePlaceResponse` with a list of `GooglePlaceCandidate` objects (placeId, fullAddress, name, latitude, longitude). Result is written to Redis with TTL.
   - From: `placeSvc_googlePlacesClient` → `placeSvc_orchestration` → `placeSvc_cacheClient`
   - To: `continuumPlacesServiceRedis`
   - Protocol: Redis protocol

9. **Return candidates**: `GooglePlaceResponse` is returned to the caller.
   - From: `placeSvc_apiControllers`
   - To: calling service
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Place not found | Orchestration returns null/404 before Google call | HTTP 404 to caller |
| Place location or merchant name is null/empty | `GoogleClient` returns null; LOGGER.warn emitted | HTTP 200 with null/empty candidates |
| Google API throws exception | Caught in `GoogleClient`; `InternalServerException` thrown; metric submitted | HTTP 500 to caller |
| Google API quota exceeded | Exception caught in `GoogleClient` | HTTP 500 to caller |
| Redis unavailable | Cache miss — Google API called directly | Higher Google API usage; result not cached |

## Sequence Diagram

```
Caller -> placeSvc_apiControllers: GET /v2.0/places/{id}/googleplace?client_id=xxx
placeSvc_apiControllers -> placeSvc_orchestration: getGooglePlace(placeId, clientId)
placeSvc_orchestration -> continuumPlacesServiceRedis: GET google_candidate::{placeId}
continuumPlacesServiceRedis --> placeSvc_orchestration: cache MISS
placeSvc_orchestration -> placeSvc_queryEngine: fetchPlace(placeId)
placeSvc_queryEngine --> placeSvc_orchestration: OutputPlace (with location, merchant name)
placeSvc_orchestration -> placeSvc_googlePlacesClient: getGooglePlace(outputPlace, merchantName)
placeSvc_googlePlacesClient -> googleMaps: FindPlaceFromText(fullAddress, TEXT_QUERY, fields=[NAME,PLACE_ID,FORMATTED_ADDRESS,GEOMETRY])
googleMaps --> placeSvc_googlePlacesClient: PlacesSearchResult[]
placeSvc_googlePlacesClient --> placeSvc_orchestration: GooglePlaceResponse (candidates)
placeSvc_orchestration -> continuumPlacesServiceRedis: SET google_candidate::{placeId} (TTL 15-30min)
placeSvc_orchestration --> placeSvc_apiControllers: GooglePlaceResponse
placeSvc_apiControllers --> Caller: HTTP 200 (GooglePlaceResponse JSON)
```

## Related

- Architecture dynamic view: `dynamic-place-read-flow`
- Related flows: [Place Read by ID](place-read-by-id.md)
