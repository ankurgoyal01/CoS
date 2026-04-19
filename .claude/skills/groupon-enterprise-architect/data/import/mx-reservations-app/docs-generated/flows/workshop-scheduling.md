---
service: "mx-reservations-app"
title: "Workshop Scheduling"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "workshop-scheduling"
flow_type: synchronous
trigger: "Merchant creates or modifies a workshop session in the workshops SPA route"
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

# Workshop Scheduling

## Summary

Workshops are group reservation sessions with defined capacity, timing, and session details. When a merchant creates or modifies a workshop through the `/reservations/workshops` SPA route, the Reservations Domain Modules orchestrates the workshop scheduling workflow: it constructs an authenticated request via the Ajax Context Provider, proxies the submission through the BFF to the API Proxy, and routes it to the Marketing Deal Service for persistence. Workshop listing reads follow the same proxy path.

## Trigger

- **Type**: user-action
- **Source**: Merchant accesses `/reservations/workshops` and creates, edits, or cancels a workshop session
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Creates and manages workshop sessions via the SPA | `merchant` |
| MX Reservations App | BFF server; proxies workshop requests to API Proxy | `continuumMxReservationsApp` |
| Reservations UI | Renders workshop scheduling forms and listings | `mxRes_reservationsUi` |
| Reservations Domain Modules | Executes workshop business workflows (create, update, cancel, list) | `mxRes_reservationsDomainModules` |
| Ajax Context Provider | Builds authenticated requests with session token and endpoint resolution | `mxRes_ajaxContextProvider` |
| API Proxy | Receives proxied workshop requests; routes to backend | `apiProxy` |
| Marketing Deal Service | Stores and retrieves workshop session data | `continuumMarketingDealService` |

## Steps

1. **Merchant opens workshop scheduling page**: Merchant navigates to `/reservations/workshops` and views existing workshop sessions.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: HTTPS (SPA navigation)

2. **UI loads existing workshops**: Reservations UI triggers a domain module call to fetch current workshop listings.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

3. **BFF proxies workshop list request**: Authenticated GET is forwarded through the BFF to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

4. **Workshop data returned and rendered**: Marketing Deal Service returns workshop listings; Reservations UI renders sessions to the merchant.
   - From: `continuumMarketingDealService`
   - To: `merchant` (via proxy chain and SPA render)
   - Protocol: REST / HTTPS, then browser render

5. **Merchant submits workshop creation or edit**: Merchant fills in workshop details (title, date, time, capacity, description) and submits the form.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: User interaction (browser event)

6. **UI triggers workshop scheduling use case**: Reservations UI dispatches the create/update use case to the Reservations Domain Modules.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

7. **Domain module constructs authenticated request**: Domain modules invoke Ajax Context Provider to build an authenticated POST/PUT with workshop data.
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_ajaxContextProvider`
   - Protocol: Direct (in-process)

8. **BFF proxies workshop POST/PUT to API Proxy**: Workshop data is forwarded to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

9. **API Proxy routes to Marketing Deal Service**: API Proxy routes the workshop creation/update request to the Marketing Deal Service.
   - From: `apiProxy`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTPS

10. **Marketing Deal Service persists workshop**: Workshop session is created or updated; confirmation response returned.
    - From: `continuumMarketingDealService`
    - To: `apiProxy`
    - Protocol: REST / HTTPS

11. **Confirmation displayed to merchant**: Success response propagates back through the proxy chain; Reservations UI refreshes workshop listing with the new session.
    - From: `apiProxy`
    - To: `merchant` (via proxy chain and SPA render)
    - Protocol: REST / HTTPS, then browser render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workshop capacity conflict | 409 response forwarded through proxy chain | SPA renders conflict error; merchant adjusts capacity |
| Invalid workshop data (4xx) | Validation error forwarded from Marketing Deal Service | SPA renders field-level validation errors |
| API Proxy unreachable | HTTP error propagated to SPA | Workshop operations unavailable; error state shown |
| Session token expired | itier-user-auth redirects to login | Merchant re-authenticates before retrying |

## Sequence Diagram

```
Merchant -> mxRes_reservationsUi: Navigates to /reservations/workshops
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers workshop list use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated GET
mxRes_ajaxContextProvider -> continuumMxReservationsApp: GET /reservations/api/v2/workshops
continuumMxReservationsApp -> apiProxy: Proxies GET /reservations/api/v2/workshops
apiProxy -> continuumMarketingDealService: Routes workshop list request
continuumMarketingDealService --> apiProxy: Returns workshop sessions
apiProxy --> continuumMxReservationsApp: Returns workshop data
continuumMxReservationsApp --> mxRes_reservationsUi: Returns workshops
mxRes_reservationsUi --> Merchant: Renders workshop list

Merchant -> mxRes_reservationsUi: Submits new workshop form
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers workshop create use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated POST
mxRes_ajaxContextProvider -> continuumMxReservationsApp: POST /reservations/api/v2/workshops
continuumMxReservationsApp -> apiProxy: Proxies POST /reservations/api/v2/workshops
apiProxy -> continuumMarketingDealService: Routes workshop creation
continuumMarketingDealService --> apiProxy: Returns workshop confirmation
apiProxy --> continuumMxReservationsApp: Returns confirmation
continuumMxReservationsApp --> mxRes_reservationsUi: Returns success
mxRes_reservationsUi --> Merchant: Displays created workshop
```

## Related

- Architecture dynamic view: `dynamic-merchant-manages-reservations`
- Related flows: [Merchant Manages Calendar](merchant-manages-calendar.md), [Merchant Creates Reservation](merchant-creates-reservation.md), [Data Loading and Hydration](data-loading-and-hydration.md)
