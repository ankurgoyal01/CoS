---
service: "occasions-itier"
title: "Embedded Cards Loader"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "embedded-cards-loader"
flow_type: synchronous
trigger: "Browser AJAX GET to /occasion/embedded-cards-loader"
participants:
  - "Browser"
  - "continuumOccasionsItier"
  - "continuumOccasionsMemcached"
  - "apiProxy"
architecture_ref: "dynamic-occasion-request-flow"
---

# Embedded Cards Loader

## Summary

This flow serves pre-rendered deal card HTML fragments via the `/occasion/embedded-cards-loader` endpoint. It supports lazy loading patterns where the initial page load defers rendering of lower-priority deal cards. occasions-itier renders the card markup server-side using Preact components and `grpn-card-ui`, serving the result as an HTML fragment that the browser injects into the page DOM. Card data is sourced from Memcached or Groupon V2 API on a cache miss.

## Trigger

- **Type**: user-action (lazy load or scroll trigger in browser)
- **Source**: Browser AJAX GET to `/occasion/embedded-cards-loader` with card identifiers as query parameters
- **Frequency**: per-request (on demand during page interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests card HTML for lazy injection; inserts returned markup into DOM | — |
| Occasions ITA | Renders card HTML server-side; coordinates data fetch | `continuumOccasionsItier` |
| Occasions Memcached | Provides cached card permalink and deal data | `continuumOccasionsMemcached` |
| Groupon V2 API | Returns deal data for requested card IDs on cache miss | `apiProxy` |

## Steps

1. **Receives embedded card request**: Browser sends `GET /occasion/embedded-cards-loader` with card identifiers (deal IDs or permalink keys) as query parameters.
   - From: `Browser`
   - To: `continuumOccasionsItier`
   - Protocol: REST / HTTPS (XHR / Fetch)

2. **Resolves card permalink from in-process memory**: Looks up card IDs against the in-process card permalink map populated by the Campaign Service poller.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsItier` (in-process memory)
   - Protocol: direct (in-process)

3. **Checks Memcached for cached card data**: Queries `continuumOccasionsMemcached` for cached deal data associated with the requested card IDs.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

4. **Fetches deal data on cache miss**: Calls Groupon V2 API via `itier-groupon-v2-client` to retrieve deal details for any card IDs not found in cache.
   - From: `continuumOccasionsItier`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

5. **Writes fetched data to Memcached**: Stores retrieved deal data in `continuumOccasionsMemcached` for future embedded card requests.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

6. **Renders card HTML**: Renders Preact components using `grpn-card-ui` card templates server-side, producing HTML markup for each requested card.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsItier` (SSR renderer)
   - Protocol: direct (in-process)

7. **Returns card HTML fragment**: Sends rendered HTML cards back to the browser for DOM injection.
   - From: `continuumOccasionsItier`
   - To: `Browser`
   - Protocol: REST / HTTPS (HTML fragment response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 API unavailable | Return empty or minimal card HTML | Cards not rendered; lazy-loaded section appears empty |
| Card ID not found in permalink map | Skip card or return placeholder HTML | Missing cards omitted from response |
| Memcached unavailable | Fall through to live API call | Elevated Groupon V2 API load |
| Rendering error | Log error; return partial or empty fragment | Affected cards not displayed in browser |

## Sequence Diagram

```
Browser -> continuumOccasionsItier: GET /occasion/embedded-cards-loader?cards=...
continuumOccasionsItier -> continuumOccasionsItier (in-process): Resolve card permalinks
continuumOccasionsItier -> continuumOccasionsMemcached: Read card data cache
continuumOccasionsMemcached --> continuumOccasionsItier: Cache hit OR miss
continuumOccasionsItier -> apiProxy: GET deal data for cards (on cache miss)
apiProxy --> continuumOccasionsItier: Deal data
continuumOccasionsItier -> continuumOccasionsMemcached: Write card data cache
continuumOccasionsItier -> continuumOccasionsItier (SSR renderer): Render card HTML (Preact + grpn-card-ui)
continuumOccasionsItier --> Browser: HTML card fragments
```

## Related

- Architecture dynamic view: `dynamic-occasion-request-flow`
- Related flows: [Occasion Page Render](occasion-page-render.md), [Deal Pagination AJAX](deal-pagination-ajax.md)
