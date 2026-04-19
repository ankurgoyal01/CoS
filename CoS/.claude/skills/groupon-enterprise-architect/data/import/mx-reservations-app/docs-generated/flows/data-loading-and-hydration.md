---
service: "mx-reservations-app"
title: "Data Loading and Hydration"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "data-loading-and-hydration"
flow_type: synchronous
trigger: "Merchant navigates to any SPA route; server renders initial HTML and client hydrates"
participants:
  - "merchant"
  - "continuumMxReservationsApp"
  - "mxRes_reservationsUi"
  - "mxRes_reservationsDomainModules"
  - "mxRes_ajaxContextProvider"
  - "mxRes_memoryServerAdapter"
  - "apiProxy"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-merchant-manages-reservations"
---

# Data Loading and Hydration

## Summary

When a merchant first loads or navigates within the MX Reservations App, the itier-server Express layer serves an initial HTML shell, which the React/Preact SPA client then hydrates. During hydration and route activation, the Reservations Domain Modules fetches required data (reservations, calendar slots, context data from itier-divisions, itier-geodetails, itier-subscriptions) through the Ajax Context Provider. In live mode, requests are proxied through the BFF to the API Proxy. In demo or test mode, the Memory Server Adapter intercepts requests and returns mock data in-process, bypassing all network calls.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to any `/reservations/*` route (initial page load or SPA navigation)
- **Frequency**: Per page load / per navigation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Navigates to a reservations route; receives and executes the SPA | `merchant` |
| MX Reservations App | Express server; serves HTML shell; proxies initial data requests | `continuumMxReservationsApp` |
| Reservations UI | SPA entry point; bootstraps React/Preact component tree; triggers data fetch | `mxRes_reservationsUi` |
| Reservations Domain Modules | Executes data-loading use cases for the active route | `mxRes_reservationsDomainModules` |
| Ajax Context Provider | Constructs authenticated data-fetch requests; routes to live API or demo adapter | `mxRes_ajaxContextProvider` |
| Memory Server Adapter | Intercepts requests in demo/test mode; returns in-process mock data | `mxRes_memoryServerAdapter` |
| API Proxy | Receives proxied data fetch requests in live mode | `apiProxy` |
| Marketing Deal Service | Returns reservation and context data for hydration | `continuumMarketingDealService` |

## Steps

1. **Merchant requests a reservations route**: Merchant navigates to `/reservations`, `/reservations/booking`, `/reservations/calendar`, `/reservations/workshops`, or `/reservations/redemption`.
   - From: `merchant`
   - To: `continuumMxReservationsApp`
   - Protocol: HTTPS (initial GET)

2. **Express server serves HTML shell**: itier-server Express layer serves the HTML entry point with embedded SPA bundle references and any server-side rendered content.
   - From: `continuumMxReservationsApp`
   - To: `merchant`
   - Protocol: HTTPS (HTML response)

3. **Browser executes SPA bundle**: Merchant's browser loads and executes the Webpack-bundled React/Preact application.
   - From: `merchant` (browser)
   - To: `mxRes_reservationsUi`
   - Protocol: Browser execution

4. **SPA triggers route-specific data load**: Reservations UI activates the route component tree and dispatches initial data load use cases to the Reservations Domain Modules.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

5. **Domain modules request initial data**: Reservations Domain Modules invokes the Ajax Context Provider to construct authenticated data fetch requests for the active route (reservations list, calendar slots, context data, feature flags).
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_ajaxContextProvider`
   - Protocol: Direct (in-process)

6a. **Live mode — BFF proxies data request**: Ajax Context Provider sends the request through the BFF to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

6b. **Demo/test mode — Memory Server Adapter intercepts**: When demo mode is active, Ajax Context Provider routes the request to the Memory Server Adapter instead of the live API. No network call is made.
   - From: `mxRes_ajaxContextProvider`
   - To: `mxRes_memoryServerAdapter`
   - Protocol: Direct (in-process)

7. **Marketing Deal Service returns data (live mode)**: API Proxy routes to Marketing Deal Service, which returns the required reservation and context data.
   - From: `apiProxy`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTPS

8. **SPA hydrates with data**: Response data propagates back to the Reservations UI; React/Preact component tree hydrates with merchant-specific reservation, calendar, workshop, or redemption data. The page becomes interactive.
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_reservationsUi`
   - Protocol: Direct (in-process)

9. **Merchant sees fully loaded page**: Reservations UI renders the complete interactive view for the active route.
   - From: `mxRes_reservationsUi`
   - To: `merchant`
   - Protocol: Browser render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Initial HTML request fails (server down) | No SPA served | Browser shows network error; merchant cannot access app |
| Data fetch fails during hydration | HTTP error returned from API Proxy | SPA renders empty/error state; merchant sees degraded view |
| itier-user-auth session not valid | Session validation fails; redirect to login | Merchant must re-authenticate before accessing any route |
| itier-divisions / itier-geodetails unavailable | Context data fetch fails | SPA may render with partial context; locale/geo defaults applied |
| Demo mode unintentionally active | Memory Server Adapter returns mock data | Merchant sees synthetic data; no real reservation data shown |

## Sequence Diagram

```
Merchant -> continuumMxReservationsApp: GET /reservations/<route>
continuumMxReservationsApp --> Merchant: HTML shell + SPA bundle
Merchant -> mxRes_reservationsUi: Browser executes SPA
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers data load use cases
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated data fetch

alt Live mode
    mxRes_ajaxContextProvider -> continuumMxReservationsApp: GET /reservations/api/v2/<data>
    continuumMxReservationsApp -> apiProxy: Proxies GET /reservations/api/v2/<data>
    apiProxy -> continuumMarketingDealService: Routes data request
    continuumMarketingDealService --> apiProxy: Returns reservation/calendar/workshop data
    apiProxy --> continuumMxReservationsApp: Returns data response
    continuumMxReservationsApp --> mxRes_ajaxContextProvider: Returns data
else Demo/test mode
    mxRes_ajaxContextProvider -> mxRes_memoryServerAdapter: Routes request to mock handler
    mxRes_memoryServerAdapter --> mxRes_ajaxContextProvider: Returns mock data
end

mxRes_ajaxContextProvider --> mxRes_reservationsDomainModules: Returns data result
mxRes_reservationsDomainModules --> mxRes_reservationsUi: Populates domain state
mxRes_reservationsUi --> Merchant: Renders hydrated, interactive SPA route
```

## Related

- Architecture dynamic view: `dynamic-merchant-manages-reservations`
- Related flows: [Merchant Creates Reservation](merchant-creates-reservation.md), [Merchant Manages Calendar](merchant-manages-calendar.md), [Workshop Scheduling](workshop-scheduling.md), [Redemption and Check-In](redemption-and-checkin.md)
