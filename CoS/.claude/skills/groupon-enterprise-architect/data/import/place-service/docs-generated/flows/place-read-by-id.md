---
service: "place-service"
title: "Place Read by ID"
generated: "2026-03-03"
type: flow
flow_name: "place-read-by-id"
flow_type: synchronous
trigger: "HTTP GET request for a single place by UUID"
participants:
  - "placeSvc_apiControllers"
  - "placeSvc_orchestration"
  - "placeSvc_cacheClient"
  - "placeSvc_queryEngine"
  - "placeSvc_postgresGateway"
  - "placeSvc_indexGateway"
  - "placeSvc_merchantClient"
  - "continuumPlacesServiceRedis"
  - "continuumPlacesServicePostgres"
  - "continuumPlacesServiceOpenSearch"
  - "continuumM3MerchantService"
architecture_ref: "dynamic-place-read-flow"
---

# Place Read by ID

## Summary

This flow handles a single-place lookup by UUID. It implements a cache-first strategy: the orchestration layer checks Redis before delegating to the query engine. On a cache miss, the query engine reads from Postgres (primary) or falls back to OpenSearch. If merchant enrichment is requested, the merchant service is called. The refreshed result is written back to Redis.

## Trigger

- **Type**: api-call
- **Source**: Any internal Groupon service or consumer API with a registered `client_id`
- **Frequency**: On-demand (high frequency — ~1M RPM in US production per SLA documentation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives HTTP GET, validates `client_id` and path params, delegates to orchestration | `placeSvc_apiControllers` |
| Place Service Orchestration | Coordinates cache check, query dispatch, enrichment, and cache write | `placeSvc_orchestration` |
| Redis Cache Client | Reads and writes cached place payloads | `placeSvc_cacheClient` |
| Place Query Engine | Executes place lookup from Postgres or OpenSearch | `placeSvc_queryEngine` |
| Postgres Gateway | Reads ICF place record from Postgres | `placeSvc_postgresGateway` |
| OpenSearch Gateway | Reads indexed place document as fallback | `placeSvc_indexGateway` |
| Merchant Client | Fetches merchant metadata for enrichment | `placeSvc_merchantClient` |
| Place Redis Cache | External Redis cache store | `continuumPlacesServiceRedis` |
| Place Postgres | Primary place persistence store | `continuumPlacesServicePostgres` |
| Place OpenSearch | Search index fallback store | `continuumPlacesServiceOpenSearch` |
| M3 Merchant Service | Provides merchant details | `continuumM3MerchantService` |

## Steps

1. **Receive GET place request**: HTTP GET arrives at `/v2.0/places/{id}` or `/v3.0/places/{id}` with `client_id` and optional `view_type` parameters.
   - From: calling service
   - To: `placeSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Delegate to orchestration**: API controller validates the request and delegates to the orchestration layer.
   - From: `placeSvc_apiControllers`
   - To: `placeSvc_orchestration`
   - Protocol: direct

3. **Read place cache**: Orchestration constructs a cache key and queries Redis for a cached place payload.
   - From: `placeSvc_orchestration`
   - To: `placeSvc_cacheClient` → `continuumPlacesServiceRedis`
   - Protocol: Redis protocol

4. **Cache hit — return cached response**: If Redis returns a valid (non-expired) place payload, the orchestration layer shapes the response according to `view_type` and returns immediately. Steps 5–9 are skipped.
   - From: `continuumPlacesServiceRedis`
   - To: caller (via `placeSvc_orchestration` → `placeSvc_apiControllers`)
   - Protocol: HTTP response

5. **Cache miss — query place via query engine**: On cache miss, orchestration delegates to the query engine.
   - From: `placeSvc_orchestration`
   - To: `placeSvc_queryEngine`
   - Protocol: direct

6. **Read ICF place from Postgres**: Query engine reads the canonical place record from Postgres.
   - From: `placeSvc_queryEngine`
   - To: `placeSvc_postgresGateway` → `continuumPlacesServicePostgres`
   - Protocol: TCP/PostgreSQL

7. **OpenSearch fallback**: If Postgres does not satisfy the query (or for specific query shapes), the query engine queries the OpenSearch index as a fallback.
   - From: `placeSvc_queryEngine`
   - To: `placeSvc_indexGateway` → `continuumPlacesServiceOpenSearch`
   - Protocol: HTTPS

8. **Load merchant details (optional)**: If merchant enrichment is requested, orchestration calls the merchant service.
   - From: `placeSvc_orchestration`
   - To: `placeSvc_merchantClient` → `continuumM3MerchantService`
   - Protocol: HTTPS/JSON

9. **Write refreshed cache payload**: Orchestration writes the fetched and enriched place payload back to Redis with a 15–30 minute TTL.
   - From: `placeSvc_orchestration`
   - To: `placeSvc_cacheClient` → `continuumPlacesServiceRedis`
   - Protocol: Redis protocol

10. **Return place response**: Orchestration shapes the response per `view_type` (`external` or `internal`) and returns it to the API controller, which sends the HTTP response.
    - From: `placeSvc_orchestration`
    - To: calling service
    - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Cache miss — falls through to Postgres/OpenSearch | Higher latency; Postgres/OpenSearch handles the read |
| Place not found in Postgres or OpenSearch | Return HTTP 404 | Caller receives `404 Not Found` |
| Merchant service unavailable | Degrade gracefully; omit merchant enrichment from response | Caller receives place data without merchant details |
| OpenSearch unavailable | Return error from query engine | Caller receives HTTP 500 if no Postgres fallback succeeded |
| Invalid `client_id` | Return HTTP 403 | Caller receives `403 Forbidden` |

## Sequence Diagram

```
Caller -> placeSvc_apiControllers: GET /v3.0/places/{id}?client_id=xxx
placeSvc_apiControllers -> placeSvc_orchestration: delegate(placeId, params)
placeSvc_orchestration -> continuumPlacesServiceRedis: GET cache key
continuumPlacesServiceRedis --> placeSvc_orchestration: cache HIT (place payload)
placeSvc_orchestration --> placeSvc_apiControllers: shaped response (view_type)
placeSvc_apiControllers --> Caller: HTTP 200 (OutputPlace JSON)

# On cache MISS:
continuumPlacesServiceRedis --> placeSvc_orchestration: cache MISS
placeSvc_orchestration -> placeSvc_queryEngine: fetchPlace(placeId)
placeSvc_queryEngine -> continuumPlacesServicePostgres: SELECT place WHERE id = ?
continuumPlacesServicePostgres --> placeSvc_queryEngine: ICF place record
placeSvc_queryEngine --> placeSvc_orchestration: OutputPlace
placeSvc_orchestration -> continuumM3MerchantService: GET /merchant/{id} (if requested)
continuumM3MerchantService --> placeSvc_orchestration: merchant details
placeSvc_orchestration -> continuumPlacesServiceRedis: SET cache key (TTL 15-30min)
placeSvc_orchestration --> placeSvc_apiControllers: shaped response
placeSvc_apiControllers --> Caller: HTTP 200 (OutputPlace JSON)
```

## Related

- Architecture dynamic view: `dynamic-place-read-flow`
- Related flows: [Place Search](place-search.md), [Google Place Candidate Lookup](google-place-lookup.md)
