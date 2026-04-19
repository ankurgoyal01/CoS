---
service: "itier-ttd-booking"
title: "TTD Pass Rendering"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "ttd-pass-rendering"
flow_type: synchronous
trigger: "User or system requests /ttd-pass-deals"
participants:
  - "Browser"
  - "continuumTtdBookingService"
  - "itierTtdBooking_webRouting"
  - "ttdPassController"
  - "ttdPassAdapter"
  - "AlligatorCardsService"
architecture_ref: "dynamic-booking-reservation-reservationWorkflow"
---

# TTD Pass Rendering

## Summary

This flow handles retrieval and rendering of TTD pass content — digital pass cards associated with Things-To-Do deals. When a request is received at `/ttd-pass-deals`, the `ttdPassController` delegates to `ttdPassAdapter`, which calls the Alligator Cards Service to fetch card data. The controller then renders the TTD pass page or card response and returns it to the caller.

## Trigger

- **Type**: user-action / api-call
- **Source**: Browser or upstream system HTTP GET to `/ttd-pass-deals`
- **Frequency**: On demand — per page load or card content request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates TTD pass content request; receives rendered response | — |
| HTTP Routing Layer | Receives inbound request and routes to TTD pass controller | `itierTtdBooking_webRouting` |
| TTD Pass Controller | Handles route, invokes adapter, renders pass page/cards | `ttdPassController` |
| TTD Pass Integration Adapter | Calls Alligator Cards API and card rendering utilities | `ttdPassAdapter` |
| Alligator Cards Service | Provides TTD pass card data for the given deal | External |

## Steps

1. **Receives TTD pass request**: Browser sends GET `/ttd-pass-deals`
   - From: `Browser`
   - To: `itierTtdBooking_webRouting`
   - Protocol: HTTPS

2. **Routes to TTD pass controller**: HTTP Routing Layer dispatches to `ttdPassController`
   - From: `itierTtdBooking_webRouting`
   - To: `ttdPassController`
   - Protocol: Direct

3. **Retrieves TTD pass cards**: TTD Pass Integration Adapter calls Alligator Cards Service for card data and invokes card rendering utilities
   - From: `ttdPassController`
   - To: `ttdPassAdapter`
   - Protocol: Direct

4. **Calls Alligator Cards API**: Adapter sends request to Alligator Cards Service
   - From: `ttdPassAdapter`
   - To: Alligator Cards Service
   - Protocol: HTTPS/JSON

5. **Returns card data**: Alligator Cards Service responds with TTD pass card payload
   - From: Alligator Cards Service
   - To: `ttdPassAdapter`
   - Protocol: HTTPS/JSON

6. **Renders and returns pass page**: Controller renders TTD pass page or card response with retrieved data
   - From: `ttdPassController`
   - To: `Browser`
   - Protocol: HTTPS (text/html or application/json)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Alligator Cards Service unavailable | `ttdPassAdapter` returns error to controller | Controller renders empty state or error page for TTD pass section |
| No TTD pass cards configured for deal | Alligator Cards Service returns empty card set | Controller renders empty pass page; booking widget flow is unaffected |
| Adapter card rendering utility fails | Controller receives render error | Error state rendered; booking widget and reservation flows are unaffected |

## Sequence Diagram

```
Browser -> itierTtdBooking_webRouting: GET /ttd-pass-deals
itierTtdBooking_webRouting -> ttdPassController: route request
ttdPassController -> ttdPassAdapter: retrieve and render TTD pass cards
ttdPassAdapter -> AlligatorCardsService: GET card data (HTTPS/JSON)
AlligatorCardsService --> ttdPassAdapter: TTD pass card payload
ttdPassAdapter --> ttdPassController: rendered card response
ttdPassController --> Browser: text/html or JSON TTD pass page
```

## Related

- Architecture dynamic view: `dynamic-booking-reservation-reservationWorkflow`
- Related flows: [Booking Widget Render](booking-widget-render.md)
