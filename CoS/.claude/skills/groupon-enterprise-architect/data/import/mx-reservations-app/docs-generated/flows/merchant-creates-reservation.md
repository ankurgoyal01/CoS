---
service: "mx-reservations-app"
title: "Merchant Creates Reservation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-creates-reservation"
flow_type: synchronous
trigger: "Merchant submits a booking form in the Reservations UI SPA"
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

# Merchant Creates Reservation

## Summary

When a merchant selects a time slot and submits a reservation booking, the Reservations UI delegates the operation to the Reservations Domain Modules, which constructs an authenticated API request via the Ajax Context Provider and POSTs it through the BFF proxy path to the API Proxy. The API Proxy routes the creation request to the Marketing Deal Service, which persists the reservation and returns confirmation. The result is surfaced back to the merchant in the SPA.

## Trigger

- **Type**: user-action
- **Source**: Merchant submits booking form in the `/reservations/booking` SPA route
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates booking by submitting the reservation form | `merchant` |
| MX Reservations App | BFF server; proxies booking POST to API Proxy | `continuumMxReservationsApp` |
| Reservations UI | Renders booking form; receives merchant input and dispatches use case | `mxRes_reservationsUi` |
| Reservations Domain Modules | Executes the booking business workflow; orchestrates request construction | `mxRes_reservationsDomainModules` |
| Ajax Context Provider | Builds authenticated POST request with session token and endpoint path | `mxRes_ajaxContextProvider` |
| API Proxy | Receives proxied POST; routes to backend | `apiProxy` |
| Marketing Deal Service | Persists reservation; returns confirmation | `continuumMarketingDealService` |

## Steps

1. **Merchant submits booking form**: Merchant selects a timeslot and fills in reservation details, then submits the booking form.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: User interaction (browser event)

2. **UI triggers booking use case**: Reservations UI dispatches the booking use case to the Reservations Domain Modules.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

3. **Domain module prepares API request**: Reservations Domain Modules invokes the Ajax Context Provider to construct an authenticated POST request with session token and correct endpoint path.
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_ajaxContextProvider`
   - Protocol: Direct (in-process)

4. **BFF proxies booking request**: The authenticated request is sent to the BFF Express server, which forwards it to the API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

5. **API Proxy routes to Marketing Deal Service**: API Proxy receives the booking POST and routes it to the Marketing Deal Service for persistence.
   - From: `apiProxy`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTPS

6. **Marketing Deal Service persists reservation**: Marketing Deal Service creates the reservation record and returns a confirmation response.
   - From: `continuumMarketingDealService`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

7. **Confirmation propagates back to merchant**: The success response flows back through API Proxy → BFF → Ajax Context Provider → Domain Modules → Reservations UI → merchant browser, which displays a confirmation state.
   - From: `apiProxy`
   - To: `merchant` (via `continuumMxReservationsApp`, `mxRes_ajaxContextProvider`, `mxRes_reservationsDomainModules`, `mxRes_reservationsUi`)
   - Protocol: REST / HTTPS, then Direct (in-process), then browser render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API Proxy unreachable | HTTP error propagated back through BFF | Reservations UI displays error state to merchant |
| Marketing Deal Service returns 4xx | Error response forwarded through proxy chain | SPA renders validation or conflict error to merchant |
| Marketing Deal Service returns 5xx | Error response forwarded through proxy chain | SPA renders a generic server error; merchant may retry |
| Session token expired | itier-user-auth intercepts request; redirects to login | Merchant re-authenticates before retrying booking |

## Sequence Diagram

```
Merchant -> mxRes_reservationsUi: Submits booking form
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers booking use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated POST
mxRes_ajaxContextProvider -> continuumMxReservationsApp: Sends POST /reservations/api/v2/reservations
continuumMxReservationsApp -> apiProxy: Proxies POST /reservations/api/v2/reservations
apiProxy -> continuumMarketingDealService: Routes reservation creation request
continuumMarketingDealService --> apiProxy: Returns reservation confirmation
apiProxy --> continuumMxReservationsApp: Returns confirmation response
continuumMxReservationsApp --> mxRes_ajaxContextProvider: Returns confirmation
mxRes_ajaxContextProvider --> mxRes_reservationsDomainModules: Returns result
mxRes_reservationsDomainModules --> mxRes_reservationsUi: Updates booking state
mxRes_reservationsUi --> Merchant: Displays reservation confirmation
```

## Related

- Architecture dynamic view: `dynamic-merchant-manages-reservations`
- Related flows: [Merchant Manages Calendar](merchant-manages-calendar.md), [Data Loading and Hydration](data-loading-and-hydration.md)
