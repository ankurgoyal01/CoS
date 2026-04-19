---
service: "occasions-itier"
title: "Occasion Page Render"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "occasion-page-render"
flow_type: synchronous
trigger: "HTTP GET request from a browser to /occasions, /occasion/:occasion, /collection/:occasion, or /:permalink_base"
participants:
  - "Browser"
  - "continuumOccasionsItier"
  - "continuumOccasionsMemcached"
  - "continuumGeoDetailsService"
  - "apiProxy"
  - "continuumRelevanceApi"
  - "Alligator"
  - "Birdcage"
architecture_ref: "dynamic-occasion-request-flow"
---

# Occasion Page Render

## Summary

This flow handles the full server-side rendering of an occasion-based deal browsing page. When a user navigates to an occasion URL, occasions-itier resolves geo context, evaluates feature flags, assembles deal and campaign data from caches or live upstream calls, applies a merchandising theme, and returns a complete HTML page rendered via Preact and Keldor.

## Trigger

- **Type**: user-action
- **Source**: Browser HTTP GET to `/occasions`, `/occasion/:occasion`, `/collection/:occasion`, or `/:permalink_base`
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates page navigation; renders returned HTML | — |
| Occasions ITA | Orchestrates all upstream calls; renders HTML page | `continuumOccasionsItier` |
| Occasions Memcached | Provides cached campaign and deal data | `continuumOccasionsMemcached` |
| GeoDetails API | Resolves geo context from request metadata | `continuumGeoDetailsService` |
| Groupon V2 API | Returns deal data for the resolved occasion and geo | `apiProxy` |
| RAPI (Relevance API) | Returns ranked deal recommendations | `continuumRelevanceApi` |
| Alligator | Returns facet metadata for deal filtering | — |
| Birdcage | Evaluates feature flags for page rendering variants | — |

## Steps

1. **Receives page request**: Browser sends `GET /occasion/:occasion` (or variant route) to `continuumOccasionsItier`.
   - From: `Browser`
   - To: `continuumOccasionsItier`
   - Protocol: REST / HTTPS

2. **Resolves geo context**: Calls GeoDetails API with request IP/headers to determine the user's region, city, and division.
   - From: `continuumOccasionsItier`
   - To: `continuumGeoDetailsService`
   - Protocol: REST / HTTPS

3. **Evaluates feature flags**: Calls Birdcage to determine active feature flags and A/B test assignments for this request context.
   - From: `continuumOccasionsItier`
   - To: `Birdcage`
   - Protocol: REST / HTTPS

4. **Reads occasion theme from in-process memory**: Looks up the occasion slug in the in-process theme map (populated by the Campaign Service poller). No network call if cache is warm.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsItier` (in-process)
   - Protocol: direct

5. **Checks Memcached for cached deal data**: Queries `continuumOccasionsMemcached` with a cache key derived from occasion slug, geo key, and offset. Returns cached payload if found (cache hit).
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

6. **Fetches deal data on cache miss**: If Memcached does not have a valid entry, calls Groupon V2 API via `itier-groupon-v2-client` to retrieve deals for the occasion and geo context.
   - From: `continuumOccasionsItier`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

7. **Fetches ranked recommendations**: Calls RAPI to retrieve ranked deal recommendations to augment the occasion deal list.
   - From: `continuumOccasionsItier`
   - To: `continuumRelevanceApi`
   - Protocol: REST / HTTPS

8. **Fetches facet metadata**: Calls Alligator to retrieve facet/filter options applicable to the occasion's deal set.
   - From: `continuumOccasionsItier`
   - To: `Alligator`
   - Protocol: REST / HTTPS

9. **Writes deal data to Memcached**: On a cache miss, stores the freshly fetched deal response in `continuumOccasionsMemcached` for subsequent requests.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

10. **Renders HTML page**: Assembles deals, theme config, facets, geo context, and feature flag state; renders Preact components server-side via Keldor; returns complete HTML to the browser.
    - From: `continuumOccasionsItier`
    - To: `Browser`
    - Protocol: REST / HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GeoDetails API unavailable | Fall back to default division/region | Page renders with default geo; deal set may not be geo-targeted |
| Groupon V2 API unavailable and cache miss | Deal section renders empty or with error state | Page returns with degraded content |
| RAPI unavailable | Omit recommendations from page | Page renders without ranked deal recommendations |
| Alligator unavailable | Omit facet filters | Page renders without deal filtering controls |
| Birdcage unavailable | Use default feature flag values | Page renders with baseline feature set |
| Memcached unavailable | All requests fall through to live upstream calls | Elevated upstream API load; page still renders if upstreams are available |

## Sequence Diagram

```
Browser -> continuumOccasionsItier: GET /occasion/:occasion
continuumOccasionsItier -> continuumGeoDetailsService: Resolve geo context
continuumGeoDetailsService --> continuumOccasionsItier: Geo context (region, division)
continuumOccasionsItier -> Birdcage: Evaluate feature flags
Birdcage --> continuumOccasionsItier: Flag assignments
continuumOccasionsItier -> continuumOccasionsMemcached: Read deal cache (occasion+geo key)
continuumOccasionsMemcached --> continuumOccasionsItier: Cache hit OR miss
continuumOccasionsItier -> apiProxy: GET deals (on cache miss)
apiProxy --> continuumOccasionsItier: Deal list
continuumOccasionsItier -> continuumRelevanceApi: GET ranked recommendations
continuumRelevanceApi --> continuumOccasionsItier: Ranked deal IDs
continuumOccasionsItier -> Alligator: GET facets
Alligator --> continuumOccasionsItier: Facet metadata
continuumOccasionsItier -> continuumOccasionsMemcached: Write deal cache (on miss)
continuumOccasionsItier --> Browser: Rendered HTML page
```

## Related

- Architecture dynamic view: `dynamic-occasion-request-flow`
- Related flows: [Deal Pagination AJAX](deal-pagination-ajax.md), [Cache Refresh Background](cache-refresh-background.md)
