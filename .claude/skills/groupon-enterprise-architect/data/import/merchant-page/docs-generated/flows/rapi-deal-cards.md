---
service: "merchant-page"
title: "RAPI Deal Cards Fragment Flow"
generated: "2026-03-03"
type: flow
flow_name: "rapi-deal-cards"
flow_type: synchronous
trigger: "HTTP GET /merchant-page/rapi/{city}/{permalink}"
participants:
  - "rapiRouteHandler"
  - "rapiClientAdapter"
  - "continuumRelevanceApi"
  - "merchantViewRenderer"
architecture_ref: "dynamic-merchant-page-request-flow"
---

# RAPI Deal Cards Fragment Flow

## Summary

The RAPI Deal Cards Fragment flow is triggered by the hydrated browser client on the merchant page to lazy-load related deal cards. The RAPI Route Handler receives geo-filtered search parameters, calls the Relevance API via the RAPI Client Adapter, renders the returned cards into HTML using `grpn-card-ui`, and returns the rendered HTML fragment as a JSON response. This flow enables the deal card carousel to load asynchronously after initial page paint.

## Trigger

- **Type**: api-call (AJAX from hydrated browser client)
- **Source**: Browser JavaScript running on the rendered merchant page makes an AJAX GET request
- **Frequency**: On-demand (once per merchant page view that has deal content to display)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RAPI Route Handler | Receives the AJAX request and orchestrates the deal card fetch | `rapiRouteHandler` |
| RAPI Client Adapter | Calls Relevance API with search parameters | `rapiClientAdapter` |
| Relevance API | Returns geo- and category-filtered deal cards | `continuumRelevanceApi` |
| Merchant View Renderer | Renders deal card HTML using `grpn-card-ui` | `merchantViewRenderer` |

## Steps

1. **Receives AJAX request**: RAPI Route Handler receives `GET /merchant-page/rapi/{city}/{permalink}` with query parameters (`placeId`, `merchantName`, `categoryUrl`, `titleKey`, `lat`, `lon`, `lazyLoad`, `sort`).
   - From: browser client (hydrated JavaScript)
   - To: `rapiRouteHandler`
   - Protocol: HTTPS

2. **Validates category URL**: If `categoryUrl` is absent, returns an empty JSON response `{}` with status `200` immediately and exits.
   - From: `rapiRouteHandler`
   - To: caller
   - Protocol: HTTPS/JSON

3. **Builds search query**: Constructs Relevance API query parameters including locale, geo-coordinates (`ell`), category/subcategory filter, merchant exclusion filter (`NOT merchant_place_id:{placeId}`), limit (8), platform type, and optional visitor/consumer IDs from session.
   - From: `rapiRouteHandler`
   - To: `rapiClientAdapter`
   - Protocol: direct (in-process)

4. **Fetches deal cards**: RAPI Client Adapter calls `continuumRelevanceApi` cards search endpoint.
   - From: `rapiClientAdapter`
   - To: `continuumRelevanceApi`
   - Protocol: HTTPS/JSON

5. **Handles empty result**: If no cards are returned, returns `{}` with the upstream status code.
   - From: `rapiRouteHandler`
   - To: caller
   - Protocol: HTTPS/JSON

6. **Formats card data**: Wraps the returned cards in a carousel structure with a localised section title using `setCardsAsCarousel`.
   - From: `rapiRouteHandler`
   - To: `merchantViewRenderer`
   - Protocol: direct (in-process)

7. **Renders card HTML**: `grpn-card-ui`'s `presentAndRenderCards` renders the card data to an HTML string, applying `lazyLoad` configuration.
   - From: `merchantViewRenderer`
   - To: `rapiRouteHandler`
   - Protocol: direct (in-process)

8. **Returns JSON fragment**: Returns `{ html: "<rendered cards html>" }` with status `200`.
   - From: `rapiRouteHandler`
   - To: browser client
   - Protocol: HTTPS/JSON (`application/json`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `categoryUrl` parameter | Returns `{}` with 200 immediately | No cards displayed; no error shown |
| Relevance API returns no cards | Returns `{}` with upstream status code | No cards displayed |
| Relevance API call fails | `handleRapiCardsResponse` wraps error; returns empty card result | No cards displayed |
| Card rendering fails | Propagates error through itier-server error handler | Fragment returns error status |

## Sequence Diagram

```
Browser (JS)         rapiRouteHandler     rapiClientAdapter    continuumRelevanceApi
     |                     |                    |                       |
     |--GET /merchant-page/rapi/{city}/{permalink}?placeId=...-->|       |
     |                     |                    |                       |
     |                     |--Validate categoryUrl (exit if missing)    |
     |                     |                    |                       |
     |                     |--Fetch deal cards->|                       |
     |                     |                    |--Cards search-------->|
     |                     |                    |<--deal card objects---|
     |                     |                    |                       |
     |                     |<--cards------------|                       |
     |                     |                    |                       |
     |                     |--setCardsAsCarousel (in-process)           |
     |                     |--presentAndRenderCards (grpn-card-ui)      |
     |                     |                    |                       |
     |<--200 { html: "..." }|                   |                       |
```

## Related

- Architecture dynamic view: `dynamic-merchant-page-request-flow`
- Related flows: [Merchant Page Request](merchant-page-request.md), [Reviews Fragment](reviews-fragment.md)
