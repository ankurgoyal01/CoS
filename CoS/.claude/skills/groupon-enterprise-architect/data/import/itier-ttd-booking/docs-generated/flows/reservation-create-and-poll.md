---
service: "itier-ttd-booking"
title: "Reservation Create and Poll"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reservation-create-and-poll"
flow_type: synchronous
trigger: "User submits booking from widget; browser loads reservation spinner page and polls status"
participants:
  - "Browser"
  - "continuumTtdBookingService"
  - "itierTtdBooking_webRouting"
  - "reservationController"
  - "reservationWorkflow"
  - "gapiWrapperAdapter"
  - "gliveInventoryAdapter"
  - "apiProxy"
  - "continuumDealCatalogService"
  - "continuumUsersService"
  - "continuumGLiveInventoryService"
architecture_ref: "dynamic-booking-reservation-reservationWorkflow"
---

# Reservation Create and Poll

## Summary

This flow covers the two-phase reservation process for GLive bookings. First, when the user submits the booking widget, the browser is directed to the reservation spinner page (`/live/deals/{dealId}/reservation`), which renders a loading UI. Second, the browser repeatedly polls `/live/deals/{dealId}/reservation/status.json` until the `reservationWorkflow` reports a terminal state (confirmed or failed), at which point the user is redirected accordingly.

## Trigger

- **Type**: user-action (initiation) + api-call (polling)
- **Source**: User submission of booking widget form; subsequent browser polling of status endpoint
- **Frequency**: On demand — one reservation creation event followed by N status polls per booking attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates reservation request; polls status endpoint; receives redirect | — |
| HTTP Routing Layer | Routes reservation and status endpoints | `itierTtdBooking_webRouting` |
| Reservation Controller | Handles spinner page render and status poll responses | `reservationController` |
| Reservation Workflow | Orchestrates reservation creation and polls until terminal state | `reservationWorkflow` |
| GAPI Wrapper Adapter | Fetches deal and user context for reservation | `gapiWrapperAdapter` |
| GLive Inventory Adapter | Creates reservation and polls reservation status | `gliveInventoryAdapter` |
| API Proxy | Routes downstream HTTPS service-client calls | `apiProxy` |
| Deal Catalog Service | Provides deal details needed for reservation context | `continuumDealCatalogService` |
| Users Service | Provides authenticated user identity for reservation | `continuumUsersService` |
| GLive Inventory Service | Owns reservation lifecycle — creates and tracks reservation state | `continuumGLiveInventoryService` |

## Steps

1. **Loads reservation spinner page**: Browser sends GET `/live/deals/{dealId}/reservation`
   - From: `Browser`
   - To: `itierTtdBooking_webRouting`
   - Protocol: HTTPS

2. **Routes to reservation controller**: HTTP Routing Layer dispatches to `reservationController`
   - From: `itierTtdBooking_webRouting`
   - To: `reservationController`
   - Protocol: Direct

3. **Renders reservation spinner page**: Controller returns spinner/loading HTML to browser
   - From: `reservationController`
   - To: `Browser`
   - Protocol: HTTPS (text/html)

4. **Polls reservation status**: Browser sends repeated GET `/live/deals/{dealId}/reservation/status.json`
   - From: `Browser`
   - To: `itierTtdBooking_webRouting`
   - Protocol: HTTPS

5. **Routes to reservation workflow**: Controller delegates orchestration to `reservationWorkflow`
   - From: `reservationController`
   - To: `reservationWorkflow`
   - Protocol: Direct

6. **Loads deal details**: Workflow reads deal metadata and options
   - From: `reservationWorkflow`
   - To: `gapiWrapperAdapter` -> `apiProxy` -> `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

7. **Resolves user identity**: Workflow reads authenticated user context
   - From: `reservationWorkflow`
   - To: `gapiWrapperAdapter` -> `apiProxy` -> `continuumUsersService`
   - Protocol: HTTPS/JSON

8. **Creates or checks reservation**: GLive Inventory Adapter creates reservation on first call, then polls status on subsequent calls
   - From: `reservationWorkflow`
   - To: `gliveInventoryAdapter` -> `apiProxy` -> `continuumGLiveInventoryService`
   - Protocol: HTTPS/JSON

9. **Returns status JSON**: Workflow evaluates reservation state; controller returns JSON `{status: "pending"|"confirmed"|"failed"}` to browser
   - From: `reservationController`
   - To: `Browser`
   - Protocol: HTTPS (application/json)

10. **Redirects on terminal state**: When status is `confirmed` or `failed`, browser redirect logic navigates user to confirmation page or `/live/checkout/error`
    - From: `Browser` (client-side redirect logic driven by status JSON)
    - To: Confirmation page or `/live/checkout/error`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Reservation creation fails in GLive Inventory Service | `gliveInventoryAdapter` returns error to workflow | Workflow returns failed terminal state; browser redirects to `/live/checkout/error` |
| Status polling exceeds maximum attempts | `reservationWorkflow` applies redirect decision logic | Returns failed state; browser redirects to `/live/checkout/error` |
| Deal context unavailable during reservation | `gapiWrapperAdapter` returns error | Workflow aborts; reservation not created; error page shown |
| User not authenticated | `gapiWrapperAdapter` returns unauthenticated | Workflow aborts; user redirected to login |
| API proxy unreachable | All downstream calls fail | Status JSON returns error state; browser redirects to error page |

## Sequence Diagram

```
Browser -> itierTtdBooking_webRouting: GET /live/deals/{dealId}/reservation
itierTtdBooking_webRouting -> reservationController: route request
reservationController --> Browser: text/html spinner page

Browser -> itierTtdBooking_webRouting: GET /live/deals/{dealId}/reservation/status.json
itierTtdBooking_webRouting -> reservationController: route status poll
reservationController -> reservationWorkflow: execute reservation orchestration
reservationWorkflow -> gapiWrapperAdapter: load deal details
gapiWrapperAdapter -> apiProxy: HTTPS
apiProxy -> continuumDealCatalogService: GET deal + options
continuumDealCatalogService --> apiProxy: deal JSON
apiProxy --> gapiWrapperAdapter: deal JSON
reservationWorkflow -> gapiWrapperAdapter: load user context
gapiWrapperAdapter -> apiProxy: HTTPS
apiProxy -> continuumUsersService: GET user
continuumUsersService --> apiProxy: user JSON
apiProxy --> gapiWrapperAdapter: user JSON
reservationWorkflow -> gliveInventoryAdapter: create/poll reservation
gliveInventoryAdapter -> apiProxy: HTTPS
apiProxy -> continuumGLiveInventoryService: POST/GET reservation
continuumGLiveInventoryService --> apiProxy: reservation status JSON
apiProxy --> gliveInventoryAdapter: reservation status JSON
reservationWorkflow --> reservationController: terminal/pending state
reservationController --> Browser: {"status": "pending"|"confirmed"|"failed"}

note over Browser: repeat polling until terminal state
Browser -> Browser: redirect on confirmed/failed
```

## Related

- Architecture dynamic view: `dynamic-booking-reservation-reservationWorkflow`
- Related flows: [Booking Widget Render](booking-widget-render.md)
