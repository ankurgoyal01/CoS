---
service: "deal"
title: "Deal Page Load"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-page-load"
flow_type: synchronous
trigger: "Consumer HTTP GET request to /deals/:deal-permalink"
participants:
  - "Browser / Mobile App"
  - "dealWebApp"
  - "Groupon V2 Deal API"
  - "Groupon V2 Pricing API"
  - "Groupon V2 Merchant API"
  - "Groupon V2 Wishlists API"
  - "GraphQL APIs"
  - "Experimentation Service"
  - "Online Booking Service"
  - "MapProxy / Mapbox"
architecture_ref: "dynamic-continuum-deal-page-load"
---

# Deal Page Load

## Summary

The deal page load flow is the primary SSR rendering process for the deal service. When a consumer requests a deal URL, `dealWebApp` issues parallel HTTP calls to multiple backend APIs to collect deal data, pricing, merchant info, availability, wishlist state, and A/B test variants. The assembled data is rendered server-side into a full HTML response and returned to the consumer's browser or mobile app.

## Trigger

- **Type**: user-action / api-call
- **Source**: Consumer browser or mobile app HTTP GET to `/deals/:deal-permalink`; may be proxied via Akamai CDN
- **Frequency**: Per request (on-demand, high volume consumer traffic)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / Mobile App | Initiates request; receives rendered HTML | N/A (external consumer) |
| Deal Web App | Orchestrates parallel API calls; renders HTML response | `dealWebApp` |
| Groupon V2 Deal API | Provides deal metadata, description, options, images | > No evidence found in codebase. |
| Groupon V2 Pricing API | Provides deal pricing and discount data | > No evidence found in codebase. |
| Groupon V2 Merchant API | Provides merchant name, address, contact info | > No evidence found in codebase. |
| Groupon V2 Wishlists API | Provides consumer wishlist state for the deal | > No evidence found in codebase. |
| GraphQL APIs | Provides supplemental deal/merchant data | > No evidence found in codebase. |
| Experimentation Service | Assigns A/B test variants for the requesting consumer | > No evidence found in codebase. |
| Online Booking Service | Provides appointment availability for bookable deals | > No evidence found in codebase. |
| MapProxy / Mapbox | Provides map tile data for merchant location | > No evidence found in codebase. |

## Steps

1. **Receive Request**: Consumer browser sends `GET /deals/:deal-permalink` to `dealWebApp` (via Akamai CDN if cached page has expired).
   - From: `Browser / Mobile App`
   - To: `dealWebApp`
   - Protocol: HTTP

2. **Assign A/B Test Variants**: `dealWebApp` calls the Experimentation Service to determine which experiment variants apply to the requesting consumer.
   - From: `dealWebApp`
   - To: `Experimentation Service`
   - Protocol: REST/HTTP

3. **Parallel API Fetch**: `dealWebApp` issues parallel HTTP calls (using `itier-groupon-v2-client` and `@grpn/graphql`) to collect all data required for rendering:
   - Fetches deal metadata, description, and options from Groupon V2 Deal API
   - Fetches pricing and discount data from Groupon V2 Pricing API
   - Fetches merchant name, address, and contact from Groupon V2 Merchant API
   - Fetches consumer wishlist state from Groupon V2 Wishlists API
   - Fetches supplemental data from GraphQL APIs
   - Fetches appointment availability from Online Booking Service (for bookable deals)
   - Fetches map tile reference from MapProxy / Mapbox (for deals with merchant location)
   - From: `dealWebApp`
   - To: Multiple backend APIs (parallel)
   - Protocol: REST/HTTP, GraphQL/HTTP

4. **Evaluate Feature Flags**: `dealWebApp` evaluates feature flags via `itier-feature-flags` using the consumer context and experiment variant assignments to determine which UI components to render.
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process

5. **Render HTML**: `dealWebApp` assembles the collected data and renders the SSR HTML page using Preact components and itier-render. Controllers involved: deal, merchant, buy_button_form, deal_highlights, special_content (and amp for AMP requests).
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process (Preact / itier-render)

6. **Return Response**: `dealWebApp` sends the rendered HTML response to the consumer browser/app.
   - From: `dealWebApp`
   - To: `Browser / Mobile App`
   - Protocol: HTTP 200 (HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 Deal API unavailable | Request fails; error page rendered | HTTP 500 or error page returned to consumer |
| Groupon V2 Pricing API timeout | Pricing data omitted or partial render | Deal page renders with missing price data |
| Online Booking Service unavailable | Booking section omitted | Deal page renders without availability/booking UI |
| MapProxy / Mapbox unavailable | Map section omitted | Deal page renders without merchant map |
| Experimentation Service unavailable | Default (control) variant used | Deal page renders with default feature set |
| Wishlists API unavailable | Wishlist state not shown | Deal page renders without wishlist indicator |

## Sequence Diagram

```
Browser -> dealWebApp: GET /deals/:deal-permalink
dealWebApp -> ExperimentationService: GET variant assignments
ExperimentationService --> dealWebApp: variant assignments
dealWebApp -> V2DealAPI: GET deal metadata (parallel)
dealWebApp -> V2PricingAPI: GET pricing data (parallel)
dealWebApp -> V2MerchantAPI: GET merchant info (parallel)
dealWebApp -> V2WishlistsAPI: GET wishlist state (parallel)
dealWebApp -> GraphQLAPIs: query supplemental data (parallel)
dealWebApp -> OnlineBookingService: GET availability (parallel, if bookable)
dealWebApp -> MapProxy: GET map reference (parallel, if location deal)
V2DealAPI --> dealWebApp: deal metadata
V2PricingAPI --> dealWebApp: pricing data
V2MerchantAPI --> dealWebApp: merchant info
V2WishlistsAPI --> dealWebApp: wishlist state
GraphQLAPIs --> dealWebApp: supplemental data
OnlineBookingService --> dealWebApp: availability slots
MapProxy --> dealWebApp: map tile reference
dealWebApp -> dealWebApp: evaluate feature flags + render HTML (Preact/itier-render)
dealWebApp --> Browser: HTTP 200 HTML deal page
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-page-load`
- Related flows: [Deal Purchase](deal-purchase.md), [AB Test Variant Assignment](ab-test-variant-assignment.md)
