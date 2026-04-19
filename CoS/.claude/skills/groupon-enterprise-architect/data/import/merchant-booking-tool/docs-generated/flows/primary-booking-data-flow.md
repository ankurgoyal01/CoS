---
service: "merchant-booking-tool"
title: "Primary Booking Data Flow"
generated: "2026-03-03"
type: flow
flow_name: "primary-booking-data-flow"
flow_type: synchronous
trigger: "Merchant navigates to a booking management page"
participants:
  - "merchant"
  - "continuumMerchantBookingTool"
  - "mbtWebRoutes"
  - "mbtMerchantApiClient"
  - "continuumUniversalMerchantApi"
  - "continuumLayoutService"
architecture_ref: "dynamic-merchant-booking-primary-flow"
---

# Primary Booking Data Flow

## Summary

When a merchant navigates to a booking management page, the Merchant Booking Tool receives the HTTPS request and orchestrates a server-side render. The Routing and Page Composition component (`mbtWebRoutes`) calls the Merchant API Client Adapter (`mbtMerchantApiClient`) to fetch booking-service data, and simultaneously requests the merchant shell from the Layout Service. The assembled Preact page is returned to the merchant's browser as a rendered HTML response.

## Trigger

- **Type**: user-action
- **Source**: Merchant browser request over HTTPS to a `/reservations/mbt/*` page route
- **Frequency**: On demand, per merchant navigation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates page request | `merchant` |
| Merchant Booking Tool | I-tier web application host; orchestrates page composition | `continuumMerchantBookingTool` |
| Routing and Page Composition | Receives request, dispatches data fetches, composes and renders Preact page | `mbtWebRoutes` |
| Merchant API Client Adapter | Executes HTTP/JSON calls to booking service for required domain data | `mbtMerchantApiClient` |
| Universal Merchant API | Returns booking-service data (reservations, calendars, accounts, campaigns, workshops, staff profiles) | `continuumUniversalMerchantApi` |
| Layout Service | Returns merchant shell/layout and app context for page assembly | `continuumLayoutService` |

## Steps

1. **Receive page request**: Merchant browser sends an HTTPS GET request to a booking page route under `/reservations/mbt/*`.
   - From: `merchant`
   - To: `continuumMerchantBookingTool` / `mbtWebRoutes`
   - Protocol: HTTPS

2. **Fetch booking domain data**: `mbtWebRoutes` invokes the `mbtMerchantApiClient` with the appropriate booking entity type (reservations, calendars, accounts, campaigns, workshops, or staff profiles).
   - From: `mbtWebRoutes`
   - To: `mbtMerchantApiClient`
   - Protocol: In-process call

3. **Call Universal Merchant API**: `mbtMerchantApiClient` sends HTTP/JSON request to the `continuumUniversalMerchantApi` booking-service endpoint for the requested data.
   - From: `mbtMerchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

4. **Receive booking data response**: `continuumUniversalMerchantApi` returns the requested booking data as JSON.
   - From: `continuumUniversalMerchantApi`
   - To: `mbtMerchantApiClient` / `mbtWebRoutes`
   - Protocol: HTTPS/JSON

5. **Fetch merchant shell layout**: `mbtWebRoutes` (or the I-tier framework) requests the merchant shell and app context from the `continuumLayoutService`.
   - From: `continuumMerchantBookingTool`
   - To: `continuumLayoutService`
   - Protocol: HTTPS

6. **Compose and render Preact page**: `mbtWebRoutes` assembles the booking data and layout into a Preact-rendered server-side HTML response.
   - From: `mbtWebRoutes`
   - To: `merchant`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumUniversalMerchantApi` returns error | I-tier error handling; surface error page | Merchant sees an error page; booking data not displayed |
| `continuumLayoutService` unavailable | Page may render without merchant shell | Merchant receives content without navigation shell |
| Network timeout to Merchant API | Request fails; I-tier timeout handling | Error page returned to merchant |

## Sequence Diagram

```
Merchant -> mbtWebRoutes: GET /reservations/mbt/* (HTTPS)
mbtWebRoutes -> mbtMerchantApiClient: Fetch booking data (in-process)
mbtMerchantApiClient -> continuumUniversalMerchantApi: HTTP/JSON booking service request
continuumUniversalMerchantApi --> mbtMerchantApiClient: Booking data JSON response
mbtWebRoutes -> continuumLayoutService: Request merchant shell (HTTPS)
continuumLayoutService --> mbtWebRoutes: Layout/app context response
mbtWebRoutes --> Merchant: Rendered Preact page (HTTPS HTML)
```

## Related

- Architecture dynamic view: `dynamic-merchant-booking-primary-flow`
- Related flows: [Proxy Write Flow](proxy-write-flow.md)
- See [Architecture Context](../architecture-context.md) for component relationships
