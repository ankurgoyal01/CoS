---
service: "ugc-api"
title: "Review Read (Merchant)"
generated: "2026-03-03"
type: flow
flow_name: "review-read-merchant"
flow_type: synchronous
trigger: "Consumer frontend or SEO API requests merchant reviews or rating summary"
participants:
  - "continuumUgcApiService"
  - "continuumUgcPostgresReadReplica"
  - "continuumUgcRedisCache"
  - "continuumTaxonomyService"
  - "continuumMerchantApi"
architecture_ref: "dynamic-ugcApiService"
---

# Review Read (Merchant)

## Summary

Consumer-facing pages and SEO pipelines request reviews and rating summaries for a given merchant. The UGC API checks the Redis read cache for a cached response, falls back to querying the PostgreSQL read replica, enriches the result with taxonomy aspect data and merchant context, caches the aggregated response, and returns the paginated result set to the caller. The flow supports filtering by deal, aspect, rating tier, date range, and sort order.

## Trigger

- **Type**: api-call
- **Source**: Consumer web/mobile frontend, SEO API (`seoapi`), or Merchant Partner Portal (MPP)
- **Frequency**: On-demand per page load; high read volume

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Frontend / SEO API | Initiates read request for merchant UGC | External |
| UGC API Service | Orchestrates cache check, DB query, enrichment, and response | `continuumUgcApiService` |
| UGC Redis Cache | Serves cached review summaries for popular merchants | `continuumUgcRedisCache` |
| UGC Postgres (Read Replica) | Provides paginated review records and aggregated ratings | `continuumUgcPostgresReadReplica` |
| Taxonomy Service | Provides taxonomy and aspect category data for filtering and enrichment | `continuumTaxonomyService` |
| Merchant API | Provides merchant profile data for review context enrichment | `continuumMerchantApi` |

## Steps

1. **Receive read request**: Caller sends `GET /ugc/v1.0/merchants/{merchantId}/reviews` or `GET /ugc/v1.0/merchants/{merchantId}/summary` with query parameters (aspect, dealId, filter_by, orderBy, offset, limit, locale, client_id, etc.).
   - From: Consumer Frontend / SEO API
   - To: `continuumUgcApiService`
   - Protocol: REST/HTTP

2. **Check Redis cache** (for summary/aggregate requests): UGC API checks the read cache for a pre-computed merchant summary keyed by merchantId and locale.
   - From: `continuumUgcApiService`
   - To: `continuumUgcRedisCache`
   - Protocol: Redis protocol

3. **Cache hit — return cached response** (if summary is cached): Cached summary is returned immediately without DB query.
   - From: `continuumUgcRedisCache`
   - To: `continuumUgcApiService`
   - Protocol: Redis protocol

4. **Cache miss — query read replica**: UGC API queries the PostgreSQL read replica with paginated, filtered, and ordered SQL via JDBI DAO (filter by merchant ID, deal ID, aspect, rating tier, date range, sort by time/value/helpfulness).
   - From: `continuumUgcApiService`
   - To: `continuumUgcPostgresReadReplica`
   - Protocol: JDBC

5. **Fetch taxonomy aspects** (for aspect-enriched responses): When `showRelatedAspects=true` or aspect filtering is requested, UGC API calls the Taxonomy Service to resolve aspect category data.
   - From: `continuumUgcApiService`
   - To: `continuumTaxonomyService`
   - Protocol: REST/HTTP

6. **Fetch merchant data** (for enriched merchant context): UGC API calls the Merchant API to retrieve merchant name, category, and other metadata for response enrichment.
   - From: `continuumUgcApiService`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

7. **Cache aggregated result**: Computed rating summary or aggregated response is written to `continuumUgcRedisCache` for future requests.
   - From: `continuumUgcApiService`
   - To: `continuumUgcRedisCache`
   - Protocol: Redis protocol

8. **Return paginated response**: UGC API returns the paginated JSON response with review records, total count, and enriched summary data.
   - From: `continuumUgcApiService`
   - To: Consumer Frontend / SEO API
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis cache unavailable | Fall back to DB query | Increased DB load; request succeeds |
| Read replica unavailable | JDBI exception propagated | HTTP 500 returned; reviews not served |
| Taxonomy Service unavailable | Aspect enrichment skipped or error returned | Aspect data missing in response; core reviews may still be returned |
| Merchant API unavailable | Merchant context missing or error returned | Merchant metadata missing; core reviews may still be returned |
| Invalid merchantId (not a UUID) | Validation annotation rejection | HTTP 400 Bad Request |

## Sequence Diagram

```
ConsumerFrontend -> continuumUgcApiService: GET /ugc/v1.0/merchants/{merchantId}/reviews?...
continuumUgcApiService -> continuumUgcRedisCache: GET cached summary (if summary request)
continuumUgcRedisCache --> continuumUgcApiService: Cache miss
continuumUgcApiService -> continuumUgcPostgresReadReplica: SELECT reviews WHERE merchantId=... LIMIT/OFFSET
continuumUgcPostgresReadReplica --> continuumUgcApiService: Paginated review records
continuumUgcApiService -> continuumTaxonomyService: GET aspect/category data
continuumTaxonomyService --> continuumUgcApiService: Taxonomy aspects
continuumUgcApiService -> continuumMerchantApi: GET merchant profile
continuumMerchantApi --> continuumUgcApiService: Merchant data
continuumUgcApiService -> continuumUgcRedisCache: SET aggregated summary
continuumUgcApiService --> ConsumerFrontend: HTTP 200 paginated reviews/summary
```

## Related

- Architecture dynamic view: No dynamic views defined in `architecture/views/dynamics.dsl`
- Related flows: [Review Submission](review-submission.md), [Content Moderation (Admin)](content-moderation-admin.md)
