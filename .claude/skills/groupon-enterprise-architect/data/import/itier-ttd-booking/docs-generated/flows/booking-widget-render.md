---
service: "itier-ttd-booking"
title: "Booking Widget Render"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "booking-widget-render"
flow_type: synchronous
trigger: "User navigates to /live/checkout/booking/{dealId}"
participants:
  - "Browser"
  - "continuumTtdBookingService"
  - "itierTtdBooking_webRouting"
  - "gliveBookingRedesignController"
  - "gapiWrapperAdapter"
  - "gliveInventoryAdapter"
  - "apiProxy"
  - "continuumDealCatalogService"
  - "continuumUsersService"
  - "continuumGLiveInventoryService"
architecture_ref: "dynamic-booking-reservation-reservationWorkflow"
---

# Booking Widget Render

## Summary

This flow handles the full server-side rendering of the GLive booking widget page. When a user navigates to `/live/checkout/booking/{dealId}`, the `gliveBookingRedesignController` orchestrates parallel data fetches for deal metadata, authenticated user context, and GLive availability, then assembles and returns the complete booking widget HTML to the browser.

## Trigger

- **Type**: user-action
- **Source**: Browser HTTP GET request to `/live/checkout/booking/{dealId}`
- **Frequency**: On demand — each user page load

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates request; receives rendered HTML | — |
| HTTP Routing Layer | Receives inbound GET, routes to booking controller | `itierTtdBooking_webRouting` |
| GLive Booking Redesign Controller | Orchestrates data assembly and renders widget HTML | `gliveBookingRedesignController` |
| GAPI Wrapper Adapter | Fetches deal metadata and user context from GAPI V2 | `gapiWrapperAdapter` |
| GLive Inventory Adapter | Fetches GLive availability and event data | `gliveInventoryAdapter` |
| API Proxy | Routes downstream HTTPS service-client calls | `apiProxy` |
| Deal Catalog Service | Provides deal metadata and option attributes | `continuumDealCatalogService` |
| Users Service | Provides authenticated user context | `continuumUsersService` |
| GLive Inventory Service | Provides GLive availability and event options | `continuumGLiveInventoryService` |

## Steps

1. **Receives booking page request**: Browser sends GET `/live/checkout/booking/{dealId}`
   - From: `Browser`
   - To: `itierTtdBooking_webRouting`
   - Protocol: HTTPS

2. **Routes to booking controller**: HTTP Routing Layer dispatches to `gliveBookingRedesignController`
   - From: `itierTtdBooking_webRouting`
   - To: `gliveBookingRedesignController`
   - Protocol: Direct

3. **Loads deal metadata**: GAPI Wrapper Adapter fetches deal details, options, and inventory-service attributes
   - From: `gliveBookingRedesignController`
   - To: `gapiWrapperAdapter` -> `apiProxy` -> `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

4. **Resolves user identity**: GAPI Wrapper Adapter retrieves authenticated user context
   - From: `gliveBookingRedesignController`
   - To: `gapiWrapperAdapter` -> `apiProxy` -> `continuumUsersService`
   - Protocol: HTTPS/JSON

5. **Loads GLive availability**: GLive Inventory Adapter fetches availability and event data for the deal
   - From: `gliveBookingRedesignController`
   - To: `gliveInventoryAdapter` -> `apiProxy` -> `continuumGLiveInventoryService`
   - Protocol: HTTPS/JSON

6. **Assembles booking widget payload**: Controller combines deal, user, and availability data into a unified rendering context; applies Expy/Optimizely experiment assignments (see [Experimentation Serving](experimentation-serving.md))
   - From: `gliveBookingRedesignController`
   - To: `gliveBookingRedesignController` (internal assembly)
   - Protocol: Direct

7. **Returns rendered HTML**: Controller renders booking widget HTML and returns it to the browser
   - From: `gliveBookingRedesignController`
   - To: `Browser`
   - Protocol: HTTPS (text/html)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal metadata fetch fails | `gapiWrapperAdapter` returns error to controller | Controller renders error page or returns 500 |
| User context unavailable | `gapiWrapperAdapter` returns unauthenticated context | Page may redirect to login or render limited widget |
| GLive availability fetch fails | `gliveInventoryAdapter` returns error | Controller redirects to `/live/checkout/error` |
| API proxy unreachable | All downstream calls fail | Controller returns 500; browser receives error page |

## Sequence Diagram

```
Browser -> itierTtdBooking_webRouting: GET /live/checkout/booking/{dealId}
itierTtdBooking_webRouting -> gliveBookingRedesignController: route request
gliveBookingRedesignController -> gapiWrapperAdapter: load deal metadata
gapiWrapperAdapter -> apiProxy: HTTPS request
apiProxy -> continuumDealCatalogService: GET deal + options
continuumDealCatalogService --> apiProxy: deal metadata JSON
apiProxy --> gapiWrapperAdapter: deal metadata JSON
gliveBookingRedesignController -> gapiWrapperAdapter: load user context
gapiWrapperAdapter -> apiProxy: HTTPS request
apiProxy -> continuumUsersService: GET user context
continuumUsersService --> apiProxy: user JSON
apiProxy --> gapiWrapperAdapter: user JSON
gliveBookingRedesignController -> gliveInventoryAdapter: load availability
gliveInventoryAdapter -> apiProxy: HTTPS request
apiProxy -> continuumGLiveInventoryService: GET availability
continuumGLiveInventoryService --> apiProxy: availability JSON
apiProxy --> gliveInventoryAdapter: availability JSON
gliveBookingRedesignController -> gliveBookingRedesignController: assemble + render widget
gliveBookingRedesignController --> Browser: text/html booking widget page
```

## Related

- Architecture dynamic view: `dynamic-booking-reservation-reservationWorkflow`
- Related flows: [Reservation Create and Poll](reservation-create-and-poll.md), [Experimentation Serving](experimentation-serving.md)
