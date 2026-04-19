---
service: "merchant-page"
title: "Reviews Fragment Flow"
generated: "2026-03-03"
type: flow
flow_name: "reviews-fragment"
flow_type: synchronous
trigger: "HTTP GET /merchant-page/reviews"
participants:
  - "reviewsRouteHandler"
  - "ugcClientAdapter"
  - "continuumUgcService"
architecture_ref: "dynamic-merchant-page-request-flow"
---

# Reviews Fragment Flow

## Summary

The Reviews Fragment flow serves paginated merchant review data to the hydrated browser client on the merchant place page. The Reviews Route Handler receives a merchant ID and pagination parameters, calls the UGC Service via the UGC Client Adapter with `showRelatedAspects: true`, and returns the review data as a JSON response. This endpoint supports the client-side "load more reviews" interaction on the merchant page.

## Trigger

- **Type**: api-call (AJAX from hydrated browser client)
- **Source**: Browser JavaScript on the rendered merchant page triggers a review load (initial render or pagination)
- **Frequency**: On-demand (per review page load or "load more" action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Reviews Route Handler | Receives the AJAX request, extracts pagination params, and returns review JSON | `reviewsRouteHandler` |
| UGC Client Adapter | Calls UGC Service merchant reviews API | `ugcClientAdapter` |
| UGC Service | Returns paginated reviews with related aspects | `continuumUgcService` |

## Steps

1. **Receives AJAX request**: Reviews Route Handler receives `GET /merchant-page/reviews` with query parameters (`merchantId`, `offset`, `limit`, `orderBy`).
   - From: browser client (hydrated JavaScript)
   - To: `reviewsRouteHandler`
   - Protocol: HTTPS

2. **Builds UGC query**: Constructs UGC service parameters including `id` (merchantId), `offset`, `limit`, `orderBy`, and `showRelatedAspects: true`.
   - From: `reviewsRouteHandler`
   - To: `ugcClientAdapter`
   - Protocol: direct (in-process)

3. **Fetches reviews**: UGC Client Adapter calls `continuumUgcService` merchant reviews API.
   - From: `ugcClientAdapter`
   - To: `continuumUgcService`
   - Protocol: HTTPS/JSON

4. **Handles UGC response**: `handleUgcResponse` wraps the call, normalising errors and empty results.
   - From: `ugcClientAdapter`
   - To: `reviewsRouteHandler`
   - Protocol: direct (in-process)

5. **Returns review JSON**: Returns the review data object with status `200`.
   - From: `reviewsRouteHandler`
   - To: browser client
   - Protocol: HTTPS/JSON (`application/json`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UGC Service call fails | `handleUgcResponse` wraps error; returns normalised empty/error result | Empty review data returned; no crash |
| Missing `merchantId` | Passed as `undefined` to UGC client; UGC Service handles gracefully | Empty or error response from UGC |
| UGC Service returns no reviews | Returns empty result with status 200 | Reviews section shows no content |

## Sequence Diagram

```
Browser (JS)       reviewsRouteHandler    ugcClientAdapter    continuumUgcService
     |                    |                    |                      |
     |--GET /merchant-page/reviews?merchantId=X&offset=0&limit=10--->|  |
     |                    |                    |                      |
     |                    |--Fetch reviews---->|                      |
     |                    |                    |--Merchant reviews--->|
     |                    |                    |   (showRelatedAspects: true)
     |                    |                    |<--review data--------|
     |                    |                    |                      |
     |                    |<--review result----|                      |
     |                    |                    |                      |
     |<--200 { reviews, aspects, ... }|        |                      |
```

## Related

- Architecture dynamic view: `dynamic-merchant-page-request-flow`
- Related flows: [Merchant Page Request](merchant-page-request.md), [RAPI Deal Cards Fragment](rapi-deal-cards.md)
