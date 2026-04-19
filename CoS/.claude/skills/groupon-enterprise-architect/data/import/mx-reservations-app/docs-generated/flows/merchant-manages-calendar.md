---
service: "mx-reservations-app"
title: "Merchant Manages Calendar"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-manages-calendar"
flow_type: synchronous
trigger: "Merchant navigates to the calendar SPA route or submits an availability change"
participants:
  - "merchant"
  - "continuumMxReservationsApp"
  - "mxRes_reservationsUi"
  - "mxRes_reservationsDomainModules"
  - "mxRes_ajaxContextProvider"
  - "apiProxy"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-merchant-manages-reservations"
---

# Merchant Manages Calendar

## Summary

Merchants view and manage their availability calendar through the `/reservations/calendar` SPA route. On load, the Reservations UI requests current calendar data from the backend; when a merchant updates availability slots, the domain modules dispatch the change through the Ajax Context Provider and BFF proxy to the API Proxy and ultimately the Marketing Deal Service. Both read and write operations use the same synchronous proxy path.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to `/reservations/calendar` route, or submits an availability update in the calendar UI
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Views calendar and submits availability changes | `merchant` |
| MX Reservations App | BFF server; proxies calendar reads and writes to API Proxy | `continuumMxReservationsApp` |
| Reservations UI | Renders calendar view; dispatches read and write use cases | `mxRes_reservationsUi` |
| Reservations Domain Modules | Executes calendar business workflows (fetch availability, update slots) | `mxRes_reservationsDomainModules` |
| Ajax Context Provider | Builds authenticated GET/PUT requests with session token | `mxRes_ajaxContextProvider` |
| API Proxy | Receives proxied calendar requests; routes to backend | `apiProxy` |
| Marketing Deal Service | Stores and retrieves merchant calendar and availability data | `continuumMarketingDealService` |

## Steps

### Calendar Load (Read)

1. **Merchant navigates to calendar route**: Merchant opens `/reservations/calendar` in the browser.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: HTTPS (SPA navigation)

2. **UI triggers calendar data fetch**: Reservations UI dispatches the calendar load use case to the Reservations Domain Modules.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

3. **Domain module requests calendar data**: Domain modules invoke Ajax Context Provider to build an authenticated GET request for availability data.
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_ajaxContextProvider`
   - Protocol: Direct (in-process)

4. **BFF proxies GET to API Proxy**: Authenticated GET request is forwarded to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

5. **API Proxy fetches calendar data**: API Proxy routes the request to Marketing Deal Service, which returns availability slot data.
   - From: `apiProxy`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTPS

6. **Calendar data rendered for merchant**: Response propagates back through the proxy chain; Reservations UI renders the calendar view with current availability.
   - From: `continuumMarketingDealService`
   - To: `merchant` (via proxy chain and SPA render)
   - Protocol: REST / HTTPS, then browser render

### Availability Update (Write)

7. **Merchant submits availability change**: Merchant modifies a time slot (opens, closes, adjusts capacity) and saves the change.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: User interaction (browser event)

8. **UI triggers calendar update use case**: Reservations UI dispatches the update use case to domain modules.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

9. **BFF proxies update to API Proxy**: Authenticated PUT/POST request with updated slot data is forwarded through the BFF to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

10. **Marketing Deal Service persists change**: API Proxy routes to Marketing Deal Service, which updates the availability record and confirms.
    - From: `apiProxy`
    - To: `continuumMarketingDealService`
    - Protocol: REST / HTTPS

11. **Confirmation returned to merchant**: Success response propagates back; Reservations UI reflects the updated calendar state.
    - From: `continuumMarketingDealService`
    - To: `merchant` (via proxy chain and SPA render)
    - Protocol: REST / HTTPS, then browser render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Calendar data unavailable (GET fails) | HTTP error propagated to SPA | Reservations UI displays empty calendar with error message |
| Availability update conflict (409) | Conflict response forwarded through proxy chain | SPA renders conflict error; merchant can refresh and retry |
| API Proxy unreachable | HTTP error returned to SPA | Calendar management unavailable; error state shown |
| Session token expired | itier-user-auth redirects to login | Merchant re-authenticates before continuing |

## Sequence Diagram

```
Merchant -> mxRes_reservationsUi: Navigates to /reservations/calendar
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers calendar load use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated GET
mxRes_ajaxContextProvider -> continuumMxReservationsApp: GET /reservations/api/v2/calendar
continuumMxReservationsApp -> apiProxy: Proxies GET /reservations/api/v2/calendar
apiProxy -> continuumMarketingDealService: Routes calendar data request
continuumMarketingDealService --> apiProxy: Returns availability data
apiProxy --> continuumMxReservationsApp: Returns calendar response
continuumMxReservationsApp --> mxRes_reservationsUi: Returns calendar data
mxRes_reservationsUi --> Merchant: Renders calendar view

Merchant -> mxRes_reservationsUi: Submits availability change
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers calendar update use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated PUT
mxRes_ajaxContextProvider -> continuumMxReservationsApp: PUT /reservations/api/v2/calendar
continuumMxReservationsApp -> apiProxy: Proxies PUT /reservations/api/v2/calendar
apiProxy -> continuumMarketingDealService: Routes availability update
continuumMarketingDealService --> apiProxy: Returns update confirmation
apiProxy --> continuumMxReservationsApp: Returns confirmation
continuumMxReservationsApp --> mxRes_reservationsUi: Returns success
mxRes_reservationsUi --> Merchant: Displays updated calendar
```

## Related

- Architecture dynamic view: `dynamic-merchant-manages-reservations`
- Related flows: [Merchant Creates Reservation](merchant-creates-reservation.md), [Workshop Scheduling](workshop-scheduling.md), [Data Loading and Hydration](data-loading-and-hydration.md)
