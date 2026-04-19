---
service: "itier-3pip"
title: "Provider Availability Check"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "provider-availability-check"
flow_type: synchronous
trigger: "Consumer loads the booking selection UI for a provider deal"
participants:
  - "consumer"
  - "continuumThreePipService"
  - "continuumThirdPartyInventoryService"
  - "providerViatorApi_12ce90 (or equivalent provider API)"
architecture_ref: "dynamic-booking-request-bookingWorkflow"
---

# Provider Availability Check

## Summary

The Provider Availability Check flow populates the booking selection UI with real-time available options from the external provider. When a consumer opens the booking iframe on a Groupon deal page, the `continuumThreePipService` routes the request through TPIS (`continuumThirdPartyInventoryService`) and/or calls the provider API directly to retrieve available time slots, event dates, ticket quantities, or appointment openings. The results are rendered in the Preact/Redux booking UI for consumer selection.

## Trigger

- **Type**: user-action
- **Source**: Consumer opens or loads the booking iframe on a Groupon deal page
- **Frequency**: On-demand — each time the booking UI loads or a consumer changes selection criteria (e.g., date, party size)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Requests availability display; browses options | `consumer` |
| 3PIP Service | Receives availability request; orchestrates provider query | `continuumThreePipService` |
| API Router | Receives inbound GET request; routes to booking workflow | `apiRouter` |
| Booking Workflow Orchestrator | Coordinates TPIS and/or provider availability calls | `bookingWorkflow` |
| Provider Proxy Layer | Executes provider-specific availability query logic | `providerProxyLayer` |
| HTTP Adapter Layer | Executes outbound HTTP call to provider API | `httpAdapterLayer` |
| TPIS Service | Provides inventory and booking flow data for TPIS-managed providers | `continuumThirdPartyInventoryService` |
| Provider API (e.g. Viator) | Returns available inventory slots | `providerViatorApi_12ce90` (or equivalent) |

## Steps

1. **Receives availability request**: Consumer's browser loads the booking UI iframe, sending a GET request for the provider's booking page.
   - From: `consumer`
   - To: `continuumThreePipService` (`apiRouter`)
   - Protocol: REST (HTTP GET to provider-specific booking route, e.g., `/viator/booking`)

2. **Dispatches to booking workflow**: `apiRouter` identifies the provider module and routes to `bookingWorkflow`.
   - From: `apiRouter`
   - To: `bookingWorkflow`
   - Protocol: direct (in-process)

3. **Queries TPIS for inventory data**: `bookingWorkflow` calls TPIS to retrieve canonical booking flow data and inventory context for the deal.
   - From: `continuumThreePipService`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: REST

4. **Selects provider proxy for availability**: `bookingWorkflow` delegates to `providerProxyLayer` to execute the provider-specific availability query.
   - From: `bookingWorkflow`
   - To: `providerProxyLayer`
   - Protocol: direct (in-process)

5. **Fetches availability from provider API**: `providerProxyLayer` calls the external provider API via `httpAdapterLayer` to retrieve available options.
   - From: `providerProxyLayer` via `httpAdapterLayer`
   - To: External provider API (e.g., Viator API)
   - Protocol: REST

6. **Transforms and renders availability UI**: `bookingWorkflow` uses `sharedDomainHelpers` to transform provider-specific availability data into a normalized format and renders the Preact/Redux booking selection UI.
   - From: `bookingWorkflow`
   - To: `consumer`
   - Protocol: REST (HTTP response / server-rendered Preact UI)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider API returns no availability | `providerProxyLayer` surfaces empty/no-availability response | Consumer sees "no availability" message in booking UI |
| Provider API timeout or 5xx | `httpAdapterLayer` propagates error | Consumer sees provider error UI; prompted to try again |
| TPIS unavailable | Request fails during inventory data fetch | Consumer sees booking error; availability check aborted |
| Memcached unavailable | Session context cannot be established | Availability page may load in degraded/sessionless state |

## Sequence Diagram

```
Consumer        -> apiRouter:              GET /<provider>/booking (availability request)
apiRouter       -> bookingWorkflow:        Dispatch availability request
bookingWorkflow -> continuumThirdPartyInventoryService: GET inventory/booking flow data
continuumThirdPartyInventoryService --> bookingWorkflow: Inventory context
bookingWorkflow -> providerProxyLayer:     Select provider availability proxy
providerProxyLayer -> httpAdapterLayer:   Execute outbound availability call
httpAdapterLayer -> ProviderAPI:          GET /availability (slots, dates, tickets)
ProviderAPI     --> httpAdapterLayer:     Available options response
httpAdapterLayer --> providerProxyLayer:  Availability data
providerProxyLayer --> bookingWorkflow:   Normalized availability options
bookingWorkflow -> sharedDomainHelpers:   Transform availability for UI presentation
sharedDomainHelpers --> bookingWorkflow:  Presentable availability data
bookingWorkflow --> apiRouter:            Availability UI render data
apiRouter       --> Consumer:             Render availability selection UI (Preact/Redux)
```

## Related

- Architecture dynamic view: `dynamic-booking-request-bookingWorkflow`
- Related flows: [Provider Booking Request](provider-booking-request.md), [Checkout and Redemption](checkout-and-redemption.md), [Provider-Agnostic Booking Module](provider-agnostic-booking-module.md)
