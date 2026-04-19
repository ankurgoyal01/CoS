---
service: "occasions-itier"
title: "Deal Pagination AJAX"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-pagination-ajax"
flow_type: synchronous
trigger: "Browser AJAX GET to /occasion/:occasion/deals/start/:offset or /occasion/deals-json"
participants:
  - "Browser"
  - "continuumOccasionsItier"
  - "continuumOccasionsMemcached"
  - "apiProxy"
  - "continuumRelevanceApi"
architecture_ref: "dynamic-occasion-request-flow"
---

# Deal Pagination AJAX

## Summary

This flow handles AJAX-driven deal list pagination on occasion pages. After the initial page load, the browser requests subsequent deal pages by POSTing an offset value. occasions-itier checks Memcached for a cached response, fetches from Groupon V2 API and RAPI on a miss, and returns a JSON fragment (or HTML card markup) for client-side injection into the deal list.

## Trigger

- **Type**: user-action (scroll or "load more" interaction)
- **Source**: Browser AJAX GET to `/occasion/:occasion/deals/start/:offset` or `/occasion/deals-json`
- **Frequency**: per-request (on-demand as user scrolls/paginates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Sends AJAX pagination request; injects returned cards into page | — |
| Occasions ITA | Handles pagination logic; coordinates cache and upstream calls | `continuumOccasionsItier` |
| Occasions Memcached | Provides cached deal slice for the given occasion+offset key | `continuumOccasionsMemcached` |
| Groupon V2 API | Returns deal data for the requested occasion and offset window | `apiProxy` |
| RAPI (Relevance API) | Returns ranked recommendations for the offset window | `continuumRelevanceApi` |

## Steps

1. **Receives pagination request**: Browser sends AJAX `GET /occasion/:occasion/deals/start/:offset` with the current occasion slug and zero-based offset.
   - From: `Browser`
   - To: `continuumOccasionsItier`
   - Protocol: REST / HTTPS (XHR / Fetch)

2. **Checks Memcached for cached deal slice**: Queries `continuumOccasionsMemcached` using a cache key composed of occasion slug, geo key, and offset value.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

3. **Returns cached response on hit**: If a valid cache entry exists, returns the cached deal JSON or card HTML directly to the browser without calling upstream APIs.
   - From: `continuumOccasionsItier`
   - To: `Browser`
   - Protocol: REST / HTTPS (JSON response)

4. **Fetches deal slice on cache miss**: Calls Groupon V2 API via `itier-groupon-v2-client` with occasion slug, geo context, and offset to retrieve the next deal page.
   - From: `continuumOccasionsItier`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

5. **Fetches ranked recommendations for slice**: Calls RAPI to retrieve ranked deal IDs relevant to the offset window.
   - From: `continuumOccasionsItier`
   - To: `continuumRelevanceApi`
   - Protocol: REST / HTTPS

6. **Writes deal slice to Memcached**: Stores the assembled deal slice in `continuumOccasionsMemcached` for future requests with the same key.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

7. **Returns deal JSON to browser**: Sends the paginated deal slice as JSON (or HTML card markup) for client-side injection into the existing deal list.
   - From: `continuumOccasionsItier`
   - To: `Browser`
   - Protocol: REST / HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 API unavailable | Return empty deal slice or error JSON | Browser shows no additional deals or an error message |
| RAPI unavailable | Return unranked deal list | Deals shown without recommendation ranking |
| Memcached unavailable | Fall through to live upstream call on every request | Elevated upstream API load |
| Invalid `offset` value | Request rejected with error response | Browser handles gracefully; no additional deals loaded |

## Sequence Diagram

```
Browser -> continuumOccasionsItier: GET /occasion/:occasion/deals/start/:offset
continuumOccasionsItier -> continuumOccasionsMemcached: Read deal slice cache (occasion+geo+offset key)
continuumOccasionsMemcached --> continuumOccasionsItier: Cache hit OR miss
continuumOccasionsItier -> apiProxy: GET deal slice (on cache miss)
apiProxy --> continuumOccasionsItier: Deal slice
continuumOccasionsItier -> continuumRelevanceApi: GET ranked recommendations
continuumRelevanceApi --> continuumOccasionsItier: Ranked deal IDs
continuumOccasionsItier -> continuumOccasionsMemcached: Write deal slice cache
continuumOccasionsItier --> Browser: Deal JSON / card HTML
```

## Related

- Architecture dynamic view: `dynamic-occasion-request-flow`
- Related flows: [Occasion Page Render](occasion-page-render.md), [Embedded Cards Loader](embedded-cards-loader.md)
