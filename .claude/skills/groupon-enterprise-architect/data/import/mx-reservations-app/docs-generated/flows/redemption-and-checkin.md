---
service: "mx-reservations-app"
title: "Redemption and Check-In"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "redemption-and-checkin"
flow_type: synchronous
trigger: "Merchant enters or scans a customer redemption code in the redemption SPA route"
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

# Redemption and Check-In

## Summary

The redemption and check-in flow allows merchants to validate and process customer vouchers or reservation bookings at the point of service. The merchant enters or scans a redemption code in the `/reservations/redemption` SPA route; the Reservations Domain Modules submits the redemption request through the Ajax Context Provider and BFF proxy to the API Proxy, which routes it to the Marketing Deal Service for validation and state update. The result — success, already-redeemed, or invalid — is returned to the merchant.

## Trigger

- **Type**: user-action
- **Source**: Merchant enters or scans a customer redemption code in the `/reservations/redemption` SPA route
- **Frequency**: On demand (at point of customer service)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates redemption by submitting a voucher or reservation code | `merchant` |
| MX Reservations App | BFF server; proxies redemption request to API Proxy | `continuumMxReservationsApp` |
| Reservations UI | Renders redemption input form; displays validation result | `mxRes_reservationsUi` |
| Reservations Domain Modules | Executes redemption business workflow; orchestrates request and response handling | `mxRes_reservationsDomainModules` |
| Ajax Context Provider | Builds authenticated POST with redemption code and session token | `mxRes_ajaxContextProvider` |
| API Proxy | Receives proxied redemption request; routes to backend | `apiProxy` |
| Marketing Deal Service | Validates redemption code; marks voucher/booking as redeemed | `continuumMarketingDealService` |

## Steps

1. **Merchant submits redemption code**: Merchant enters or scans a customer voucher or booking code into the redemption input field and submits.
   - From: `merchant`
   - To: `mxRes_reservationsUi`
   - Protocol: User interaction (browser event)

2. **UI triggers redemption use case**: Reservations UI dispatches the redemption use case to the Reservations Domain Modules with the submitted code.
   - From: `mxRes_reservationsUi`
   - To: `mxRes_reservationsDomainModules`
   - Protocol: Direct (in-process)

3. **Domain module constructs redemption request**: Reservations Domain Modules invokes Ajax Context Provider to build an authenticated POST request containing the redemption code.
   - From: `mxRes_reservationsDomainModules`
   - To: `mxRes_ajaxContextProvider`
   - Protocol: Direct (in-process)

4. **BFF proxies redemption POST to API Proxy**: Authenticated redemption POST is forwarded through the BFF to API Proxy at `/reservations/api/v2/*`.
   - From: `continuumMxReservationsApp`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

5. **API Proxy routes to Marketing Deal Service**: API Proxy forwards the redemption request to the Marketing Deal Service for validation and processing.
   - From: `apiProxy`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTPS

6. **Marketing Deal Service validates and marks redeemed**: Marketing Deal Service checks the redemption code (validity, expiry, prior use) and marks it as redeemed if valid. Returns success or rejection response.
   - From: `continuumMarketingDealService`
   - To: `apiProxy`
   - Protocol: REST / HTTPS

7. **Result returned to merchant**: The redemption outcome propagates back through API Proxy → BFF → Domain Modules → Reservations UI → merchant browser. The SPA displays a success confirmation or an appropriate rejection reason.
   - From: `apiProxy`
   - To: `merchant` (via `continuumMxReservationsApp`, `mxRes_ajaxContextProvider`, `mxRes_reservationsDomainModules`, `mxRes_reservationsUi`)
   - Protocol: REST / HTTPS, then Direct (in-process), then browser render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid redemption code (404) | Error response forwarded through proxy chain | SPA renders "code not found" message to merchant |
| Already-redeemed code (409/422) | Conflict response forwarded through proxy chain | SPA renders "already redeemed" state with redemption timestamp |
| Expired code | Rejection response from Marketing Deal Service | SPA renders "code expired" message |
| API Proxy unreachable | HTTP error propagated to SPA | Redemption unavailable; merchant shown error; may need fallback manual process |
| Session token expired | itier-user-auth redirects to login | Merchant re-authenticates before retrying redemption |

## Sequence Diagram

```
Merchant -> mxRes_reservationsUi: Submits redemption code
mxRes_reservationsUi -> mxRes_reservationsDomainModules: Triggers redemption use case
mxRes_reservationsDomainModules -> mxRes_ajaxContextProvider: Requests authenticated POST
mxRes_ajaxContextProvider -> continuumMxReservationsApp: POST /reservations/api/v2/redemptions
continuumMxReservationsApp -> apiProxy: Proxies POST /reservations/api/v2/redemptions
apiProxy -> continuumMarketingDealService: Routes redemption validation request
continuumMarketingDealService --> apiProxy: Returns redemption result (success / already-redeemed / invalid)
apiProxy --> continuumMxReservationsApp: Returns redemption response
continuumMxReservationsApp --> mxRes_ajaxContextProvider: Returns result
mxRes_ajaxContextProvider --> mxRes_reservationsDomainModules: Returns result
mxRes_reservationsDomainModules --> mxRes_reservationsUi: Updates redemption state
mxRes_reservationsUi --> Merchant: Displays redemption outcome
```

## Related

- Architecture dynamic view: `dynamic-merchant-manages-reservations`
- Related flows: [Merchant Creates Reservation](merchant-creates-reservation.md), [Data Loading and Hydration](data-loading-and-hydration.md)
