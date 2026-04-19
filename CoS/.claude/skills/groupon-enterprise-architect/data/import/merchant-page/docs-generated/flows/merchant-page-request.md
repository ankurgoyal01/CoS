---
service: "merchant-page"
title: "Merchant Page Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "merchant-page-request"
flow_type: synchronous
trigger: "HTTP GET /biz/{citySlug}/{merchantSlug}"
participants:
  - "merchantRouteHandler"
  - "mppClientAdapter"
  - "continuumUniversalMerchantApi"
  - "rapiClientAdapter"
  - "continuumRelevanceApi"
  - "ugcClientAdapter"
  - "continuumUgcService"
  - "mapSigningAdapter"
  - "gims"
  - "merchantViewRenderer"
architecture_ref: "dynamic-merchant-page-request-flow"
---

# Merchant Page Request Flow

## Summary

When a user or crawler requests a merchant place page at `/biz/{citySlug}/{merchantSlug}`, the Merchant Route Handler orchestrates four parallel upstream calls — fetching merchant/place data, related deal cards, user reviews, and a signed map URL — then assembles all results and delegates to the Merchant View Renderer to produce a complete server-side-rendered HTML response with Preact. The flow includes redirect and proxy logic for edge cases where a single matching deal exists or the merchant has moved.

## Trigger

- **Type**: api-call
- **Source**: User browser or search engine crawler → Routing Service → Hybrid Boundary → `continuumMerchantPageService`
- **Frequency**: On-demand (every merchant page view)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Route Handler | Orchestrates all upstream calls and initiates page render | `merchantRouteHandler` |
| MPP Client Adapter | Fetches merchant and place data | `mppClientAdapter` |
| Universal Merchant API | Provides merchant/place record by slug | `continuumUniversalMerchantApi` |
| RAPI Client Adapter | Fetches related deal cards | `rapiClientAdapter` |
| Relevance API | Returns geo-filtered deal cards | `continuumRelevanceApi` |
| UGC Client Adapter | Fetches merchant reviews | `ugcClientAdapter` |
| UGC Service | Returns paginated reviews with related aspects | `continuumUgcService` |
| Map Signing Adapter | Generates signed map image URL | `mapSigningAdapter` |
| GIMS | Signs and returns map tile URL | `gims` |
| Merchant View Renderer | Builds SSR HTML and hydration payload | `merchantViewRenderer` |

## Steps

1. **Receives page request**: The Merchant Route Handler receives `GET /biz/{citySlug}/{merchantSlug}`.
   - From: Hybrid Boundary
   - To: `merchantRouteHandler`
   - Protocol: HTTPS

2. **Starts page tracking**: Invokes `trackingHub.startPageRequest` with `page.type = 'merchant/show'`.
   - From: `merchantRouteHandler`
   - To: tracking hub (in-process)
   - Protocol: direct

3. **Loads merchant data**: Calls `loadMerchantData(params)` which triggers concurrent sub-calls:
   - From: `merchantRouteHandler`
   - To: `mppClientAdapter`, `rapiClientAdapter`, `ugcClientAdapter`
   - Protocol: direct (in-process, concurrent)

4. **Fetches merchant/place record**: MPP Client Adapter calls Universal Merchant API with the city/merchant slug.
   - From: `mppClientAdapter`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

5. **Fetches related deal cards**: RAPI Client Adapter calls Relevance API with category URL, lat/lon, locale, and exclusion filter for current merchant.
   - From: `rapiClientAdapter`
   - To: `continuumRelevanceApi`
   - Protocol: HTTPS/JSON

6. **Fetches merchant reviews**: UGC Client Adapter calls UGC Service with merchant ID, pagination params, and `showRelatedAspects: true`.
   - From: `ugcClientAdapter`
   - To: `continuumUgcService`
   - Protocol: HTTPS/JSON

7. **Evaluates redirect conditions**: After `loadMerchantData` resolves:
   - If `merchantData.redirect` is set, issues an HTTP redirect response.
   - If `merchantData.statusCode` is set (e.g., 404), returns that status code.
   - If `proxy_deal` flag is enabled and exactly one deal was returned, proxies the request to the deal page via `continuumApiLazloService` and returns the deal page response.
   - From: `merchantRouteHandler`
   - To: caller or `continuumApiLazloService`
   - Protocol: HTTP redirect / HTTPS proxy

8. **Generates signed map URL**: Map Signing Adapter calls GIMS to sign the static map image request for the merchant location.
   - From: `mapSigningAdapter`
   - To: `gims`
   - Protocol: HTTPS/JSON

9. **Builds page context**: Assembles the full page context object including merchant data, deal list, review data, locale, feature flags, asset URLs, and hydration payload.
   - From: `merchantRouteHandler`
   - To: `merchantViewRenderer`
   - Protocol: direct (in-process)

10. **Sets Link preload header**: If a deal hero image is identified, sets the HTTP `Link` preload header on the response.
    - From: `merchantRouteHandler`
    - To: HTTP response
    - Protocol: direct

11. **Renders SSR page**: Merchant View Renderer renders the full Preact component tree server-side, injects JSON-LD structured data, page meta tags, and the hydration payload into the page layout.
    - From: `merchantViewRenderer`
    - To: `merchantRouteHandler`
    - Protocol: direct (in-process)

12. **Returns HTML response**: Merchant Route Handler returns the complete rendered HTML to the caller.
    - From: `merchantRouteHandler`
    - To: Hybrid Boundary → browser
    - Protocol: HTTPS, `text/html`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `loadMerchantData` throws | Returns `{ statusCode: 500 }` immediately | HTTP 500 error page |
| Merchant not found (`merchantData.statusCode` set) | Returns the upstream status code | HTTP 404 (or other upstream status) |
| Merchant has moved (`merchantData.redirect` set) | Issues HTTP redirect | HTTP 302 to redirect URL |
| Single deal + `proxy_deal` flag | Proxies request to deal service | Deal page HTML returned instead of merchant page |
| RAPI returns no cards | Deal carousel is omitted from render | Page renders without deal carousel |
| UGC returns no reviews | Review section is empty | Page renders without reviews |
| GIMS / map signing fails | Error silently caught (`no-op`) | Page renders without map image |

## Sequence Diagram

```
Browser           MerchantRouteHandler   mppClientAdapter   continuumUniversalMerchantApi
   |                      |                     |                         |
   |--GET /biz/city/slug-->|                     |                         |
   |                      |--Read merchant data->|                         |
   |                      |                     |--Get place by slug------>|
   |                      |                     |<--merchant/place record--|
   |                      |                     |
   |                      |      rapiClientAdapter    continuumRelevanceApi
   |                      |--Read related deals->|                         |
   |                      |                     |--Cards search----------->|
   |                      |                     |<--deal cards-------------|
   |                      |
   |                      |      ugcClientAdapter       continuumUgcService
   |                      |--Read reviews------->|                         |
   |                      |                     |--Merchant reviews API--->|
   |                      |                     |<--review data------------|
   |                      |
   |                      |      mapSigningAdapter            gims
   |                      |--Generate map URL--->|                         |
   |                      |                     |--Sign map image--------->|
   |                      |                     |<--signed URL-------------|
   |                      |
   |                      |--Render SSR page (merchantViewRenderer)
   |                      |
   |<--200 text/html ------|
```

## Related

- Architecture dynamic view: `dynamic-merchant-page-request-flow`
- Related flows: [RAPI Deal Cards Fragment](rapi-deal-cards.md), [Reviews Fragment](reviews-fragment.md), [Map Image Signing](map-image-signing.md)
