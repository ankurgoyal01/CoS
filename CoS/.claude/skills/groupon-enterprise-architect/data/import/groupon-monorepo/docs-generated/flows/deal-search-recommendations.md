---
service: "groupon-monorepo"
title: "Deal Search and Recommendations"
generated: "2026-03-03"
type: flow
flow_name: "deal-search-recommendations"
flow_type: synchronous
trigger: "API request from consumer frontend or admin UI"
participants:
  - "encoreGo"
  - "booster"
  - "googlePlaces"
architecture_ref: "dynamic-deal-search-recommendations"
---

# Deal Search and Recommendations

## Summary

This flow handles deal search and recommendation requests through the Encore Go backend. The lrapi service receives search requests, preprocesses queries via the Suggest service (typo correction, locality detection, radius prediction, adult content detection), executes search against Vespa.ai via the vespa-reader internal service, enriches results with deal data from the Redis cache (with Lazlo API fallback), and returns enriched deal listings. The autocomplete service follows a similar pattern for typeahead suggestions.

## Trigger

- **Type**: api-call
- **Source**: Consumer frontend (MBNXT), admin UI, or external API clients
- **Frequency**: High-volume, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| lrapi Service | Deal search API with query preprocessing | `encoreGo` (gorapi/lrapi) |
| Autocomplete Service | Autocomplete and recommendation API | `encoreGo` (gorapi/autocomplete) |
| Vespa Reader Service | Internal Vespa.ai search integration | `encoreGo` (vespa-reader) |
| Suggest Service | Query preprocessing (typo fix, locality detection) | External service |
| DealDataProvider | Redis cache + Lazlo fallback for deal enrichment | `encoreGo` (gorapi/internal/infrastructure) |
| Booster API | Personalized deal recommendations (configurable) | `booster` |

## Steps

1. **Receive Search Request**: Client sends search query with location, division, filters
   - From: Consumer frontend / API client
   - To: `encoreGo` (lrapi service)
   - Protocol: REST (POST /deals)

2. **Validate Request**: Validate required fields (division, location, platform, sort)
   - From: `encoreGo` (lrapi service)
   - To: Internal validation
   - Protocol: Direct

3. **Preprocess Query**: Call Suggest service for query enhancement
   - From: `encoreGo` (lrapi use case)
   - To: Suggest Service
   - Protocol: REST (POST /query-preprocessing, SLA <= 20ms)

4. **Apply Preprocessing Results**: Update query with corrections, override location if locality detected, flag adult content
   - From: `encoreGo` (lrapi use case)
   - To: Internal state update
   - Protocol: Direct

5. **Execute Vespa Search**: Search deals in Vespa.ai via internal vespa-reader service
   - From: `encoreGo` (lrapi use case, Vespa adapter)
   - To: `encoreGo` (vespa-reader service)
   - Protocol: Internal Encore service call

6. **Query Vespa.ai**: vespa-reader executes search against Vespa cluster
   - From: `encoreGo` (vespa-reader)
   - To: Vespa.ai cluster
   - Protocol: REST (HTTP/2, connection pooling)

7. **Enrich Deal Data**: Fetch full deal details from Redis cache (with Lazlo fallback)
   - From: `encoreGo` (DealDataProvider)
   - To: Redis cache
   - Protocol: Redis (go-redis)

8. **Lazlo Fallback**: On cache miss, fetch deal details from Continuum Lazlo API
   - From: `encoreGo` (DealDataProvider)
   - To: Continuum Lazlo Service
   - Protocol: REST

9. **Backfill Cache**: Write fetched deal data back to Redis for future requests
   - From: `encoreGo` (DealDataProvider)
   - To: Redis cache
   - Protocol: Redis (go-redis)

10. **Apply Field Filtering**: Filter response fields if `fields` parameter provided
    - From: `encoreGo` (lrapi use case)
    - To: Internal transformation
    - Protocol: Direct

11. **Return Results**: Return enriched deals with pagination and facets
    - From: `encoreGo` (lrapi service)
    - To: Consumer frontend / API client
    - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Suggest service timeout | Continue with original query (graceful degradation) | Search works without query preprocessing |
| Vespa.ai error | Return error to client | Search fails; client shows error message |
| Vespa.ai 429 (rate limit) | Rate limiting and retry backoff | Search delayed but eventually succeeds |
| Redis cache miss | Automatic fallback to Lazlo API | Slightly higher latency; results still returned |
| Lazlo API failure | Return deal UUIDs without enrichment data | Partial results; some fields may be missing |
| Validation failure | Return 400 error with field details | Client corrects request parameters |

## Sequence Diagram

```
Client -> lrapi Service: POST /deals (query, location, filters)
lrapi Service -> lrapi Service: Validate request
lrapi Service -> Suggest Service: POST /query-preprocessing
Suggest Service --> lrapi Service: Preprocessed query (typo fix, locality, radius)
lrapi Service -> Vespa Adapter: Search with preprocessed query
Vespa Adapter -> vespa-reader: Internal search call
vespa-reader -> Vespa.ai: HTTP/2 search request
Vespa.ai --> vespa-reader: Search results (deal UUIDs, scores, facets)
vespa-reader --> Vespa Adapter: Results
lrapi Service -> DealDataProvider: Enrich deal UUIDs
DealDataProvider -> Redis: Batch GET deal data
Redis --> DealDataProvider: Cached deals (partial)
DealDataProvider -> Lazlo API: Fetch missing deals
Lazlo API --> DealDataProvider: Deal details
DealDataProvider -> Redis: Batch SET (backfill cache)
DealDataProvider --> lrapi Service: Enriched deals
lrapi Service --> Client: Enriched deals + pagination + facets
```

## Related

- Architecture dynamic view: `dynamic-deal-search-recommendations`
- Related flows: [Deal Creation and Publishing](deal-creation-publishing.md)
