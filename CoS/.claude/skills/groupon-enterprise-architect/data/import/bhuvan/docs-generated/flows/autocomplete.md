---
service: "bhuvan"
title: "Autocomplete Address Resolution"
generated: "2026-03-03"
type: flow
flow_name: "autocomplete"
flow_type: synchronous
trigger: "HTTP GET to autocomplete geodetail or mobile endpoint"
participants:
  - "continuumBhuvanService_httpApiGeoDetails"
  - "continuumBhuvanService_geoDetailsService"
  - "continuumBhuvanService_geoDetailsCache"
  - "continuumBhuvanService_elasticSearchService"
  - "continuumBhuvanService_experimentationService"
  - "continuumBhuvanService_experimentationMetrics"
  - "continuumBhuvanRedisCluster"
  - "continuumBhuvanElasticSearch"
  - "continuumMapsProviderApis"
  - "continuumExperimentationService"
architecture_ref: "dynamic-continuum-bhuvan-autocomplete"
---

# Autocomplete Address Resolution

## Summary

This flow handles autocomplete requests from internal consumers (typically frontend or mobile services). The service evaluates A/B experiment flags to determine whether to use the ElasticSearch-backed internal autocomplete index or delegate to external providers (Google Maps, MapTiler). Results are cached in the Redis Geo Details Cache to minimize repeated external API calls. Experiment bucketing decisions are recorded as metrics.

## Trigger

- **Type**: api-call
- **Source**: Frontend services, mobile clients (via mobile API gateway), or internal services calling autocomplete geodetail endpoints
- **Frequency**: Per-request (high frequency — user-facing search typeahead)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Geo Details HTTP API | Receives autocomplete request; validates params | `continuumBhuvanService_httpApiGeoDetails` |
| Geo Details Service | Orchestrates experiment lookup, cache check, and autocomplete resolution | `continuumBhuvanService_geoDetailsService` |
| Geo Details Cache | Redis-backed cache for autocomplete results | `continuumBhuvanService_geoDetailsCache` |
| ElasticSearch Service | Queries internal ES autocomplete index | `continuumBhuvanService_elasticSearchService` |
| Experimentation Service Client | Evaluates experiment flags to select autocomplete provider/behavior | `continuumBhuvanService_experimentationService` |
| Experimentation Metrics | Records experiment bucketing decisions | `continuumBhuvanService_experimentationMetrics` |
| Bhuvan Redis Cluster | Backing store for geo details cache | `continuumBhuvanRedisCluster` |
| Bhuvan ElasticSearch Cluster | Internal autocomplete search index | `continuumBhuvanElasticSearch` |
| Maps & Address Provider APIs | External autocomplete (Google Maps / MapTiler) | `continuumMapsProviderApis` |
| Experimentation Service (Expy) | A/B experiment evaluation backend | `continuumExperimentationService` |

## Steps

1. **Receives autocomplete request**: Geo Details HTTP API receives the autocomplete query (e.g., partial address string, locale, lat/lng context).
   - From: caller
   - To: `continuumBhuvanService_httpApiGeoDetails`
   - Protocol: REST/HTTP

2. **Checks geo details cache**: GeoDetailsService checks the Redis Geo Details Cache for a cached response to the exact query.
   - From: `continuumBhuvanService_geoDetailsCache`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis (Lettuce)

3. **Cache hit — returns cached results**: Returns cached autocomplete suggestions immediately.
   - From: `continuumBhuvanService_httpApiGeoDetails`
   - To: caller
   - Protocol: REST/HTTP JSON

4. **Cache miss — evaluates experiment**: GeoDetailsService invokes ExperimentationService to bucket the request into an A/B experiment variant, selecting the autocomplete backend (ElasticSearch vs. external provider).
   - From: `continuumBhuvanService_experimentationService`
   - To: `continuumExperimentationService`
   - Protocol: HTTP/JSON (Expy)

5. **Records experiment metric**: ExperimentationMetrics emits a metric for the bucketing decision.
   - From: `continuumBhuvanService_experimentationMetrics`
   - To: metrics stack
   - Protocol: JTier SMA metrics

6. **Variant A — queries ElasticSearch**: If the experiment routes to the internal provider, ElasticSearchService queries the ElasticSearch autocomplete index.
   - From: `continuumBhuvanService_elasticSearchService`
   - To: `continuumBhuvanElasticSearch`
   - Protocol: ElasticSearch REST (HTTP)

7. **Variant B — queries external Maps API**: If the experiment routes to an external provider, GeoDetailsService calls the Google Maps / MapTiler autocomplete API via the `geolib-autocomplete` library.
   - From: `continuumBhuvanService_geoDetailsService`
   - To: `continuumMapsProviderApis`
   - Protocol: HTTP/JSON

8. **Stores result in geo details cache**: The autocomplete results are stored in the Redis Geo Details Cache.
   - From: `continuumBhuvanService_geoDetailsCache`
   - To: `continuumBhuvanRedisCluster`
   - Protocol: Redis (Lettuce)

9. **Returns autocomplete suggestions**: JSON list of autocomplete suggestions returned to the caller.
   - From: `continuumBhuvanService_httpApiGeoDetails`
   - To: caller
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ElasticSearch unavailable | Falls back to external Maps API (if experiment config allows) | Degraded — uses external provider |
| External Maps API unavailable | Returns empty results or error | Autocomplete degraded |
| Experimentation service unavailable | Default experiment variant applied | Flow continues with default behavior |
| Redis cache unavailable | Bypasses cache; queries backend directly | Increased latency; still functional |

## Sequence Diagram

```
Caller -> GeoDetailsAPI: GET /geodetails/autocomplete?q=chic&locale=en_US&client_id=X
GeoDetailsAPI -> GeoDetailsService: autocomplete(q=chic, locale=en_US)
GeoDetailsService -> GeoDetailsCache: get(cache_key)
GeoDetailsCache -> Redis: GET geo_details:autocomplete:chic:en_US
Redis --> GeoDetailsCache: miss
GeoDetailsCache --> GeoDetailsService: miss
GeoDetailsService -> ExperimentationService: bucket(user_context)
ExperimentationService -> ExpyService: evaluate(experiment, user)
ExpyService --> ExperimentationService: variant=elasticsearch
ExperimentationService --> GeoDetailsService: variant=elasticsearch
GeoDetailsService -> ExperimentationMetrics: emit(experiment, variant)
GeoDetailsService -> ElasticSearchService: search(q=chic, index=autocomplete)
ElasticSearchService -> ElasticSearch: POST /autocomplete/_search
ElasticSearch --> ElasticSearchService: [suggestions]
ElasticSearchService --> GeoDetailsService: [suggestions]
GeoDetailsService -> GeoDetailsCache: set(cache_key, suggestions)
GeoDetailsCache -> Redis: SET geo_details:autocomplete:chic:en_US suggestions
GeoDetailsService --> GeoDetailsAPI: [suggestions]
GeoDetailsAPI --> Caller: 200 [suggestions]
```

## Related

- Architecture dynamic view: `dynamic-continuum-bhuvan-autocomplete`
- Related flows: [IP-Based Location Detection](ip-location-detection.md), [Geo Entity Search](geo-entity-search.md)
