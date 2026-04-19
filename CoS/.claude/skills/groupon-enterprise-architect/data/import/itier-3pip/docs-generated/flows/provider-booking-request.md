---
service: "itier-3pip"
title: "Provider Booking Request"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "provider-booking-request"
flow_type: synchronous
trigger: "Consumer initiates a booking from a Groupon deal page iframe"
participants:
  - "consumer"
  - "continuumThreePipService"
  - "continuumDealCatalogService"
  - "continuumOrdersService"
  - "providerViatorApi_12ce90 (or equivalent provider API)"
architecture_ref: "dynamic-booking-request-bookingWorkflow"
---

# Provider Booking Request

## Summary

The Provider Booking Request flow is the primary end-to-end booking path for a Groupon consumer selecting and confirming a 3rd-party provider deal. The consumer initiates the flow through the booking iframe; the `continuumThreePipService` loads deal metadata, routes to the correct provider proxy, creates the booking with the external provider API, and finally creates a confirmed Groupon order. This flow is documented in the Structurizr dynamic view `dynamic-booking-request-bookingWorkflow`.

## Trigger

- **Type**: user-action
- **Source**: Consumer selects a deal and submits booking on a Groupon deal page (iframe embed)
- **Frequency**: On-demand — per consumer booking attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Initiates booking; receives confirmation | `consumer` |
| 3PIP Service | Orchestrates the full booking workflow | `continuumThreePipService` |
| API Router | Receives inbound request; dispatches to booking workflow | `apiRouter` |
| Booking Workflow Orchestrator | Coordinates deal metadata retrieval, provider call, and order creation | `bookingWorkflow` |
| Provider Proxy Layer | Selects and executes the correct provider-specific integration | `providerProxyLayer` |
| HTTP Adapter Layer | Executes outbound HTTP calls to provider API and internal services | `httpAdapterLayer` |
| Deal Catalog Service | Supplies deal metadata | `continuumDealCatalogService` |
| Orders Service | Creates the confirmed Groupon order | `continuumOrdersService` |
| Provider API (e.g. Viator) | Receives and confirms the booking | `providerViatorApi_12ce90` (or equivalent) |

## Steps

1. **Receives booking request**: Consumer submits the booking form in the iframe.
   - From: `consumer`
   - To: `continuumThreePipService` (`apiRouter`)
   - Protocol: REST (HTTP POST to provider-specific checkout route)

2. **Dispatches to booking workflow**: `apiRouter` routes the request to `bookingWorkflow` for the identified provider module.
   - From: `apiRouter`
   - To: `bookingWorkflow`
   - Protocol: direct (in-process)

3. **Loads deal metadata**: `bookingWorkflow` fetches deal metadata to validate the deal and enrich booking context.
   - From: `continuumThreePipService`
   - To: `continuumDealCatalogService`
   - Protocol: REST

4. **Selects provider integration path**: `bookingWorkflow` delegates to `providerProxyLayer` to identify and invoke the correct provider proxy.
   - From: `bookingWorkflow`
   - To: `providerProxyLayer`
   - Protocol: direct (in-process)

5. **Creates booking with provider API**: `providerProxyLayer` calls the external provider API via `httpAdapterLayer` to reserve or confirm the booking.
   - From: `providerProxyLayer` via `httpAdapterLayer`
   - To: External provider API (e.g., Viator API)
   - Protocol: REST

6. **Creates Groupon order**: On provider confirmation, `bookingWorkflow` calls the Orders service to create the authoritative Groupon order record.
   - From: `continuumThreePipService`
   - To: `continuumOrdersService`
   - Protocol: REST

7. **Returns booking confirmation**: The service renders the confirmation UI and returns it to the consumer's iframe.
   - From: `continuumThreePipService`
   - To: `consumer`
   - Protocol: REST (HTTP response / server-rendered Preact UI)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog unavailable | Request fails during metadata fetch | Consumer sees booking error; no provider call or order is made |
| Provider API returns unavailability | `providerProxyLayer` surfaces error | Consumer is returned to availability selection; no order created |
| Provider API timeout or 5xx | `httpAdapterLayer` propagates error | Consumer sees provider error UI; no Groupon order created |
| Orders service fails to create order | Error in final order creation step | Booking may be confirmed at provider but no Groupon order — requires manual reconciliation |
| Session cache (Memcached) unavailable | Session context lost | Booking flow fails; consumer may need to restart from deal page |

## Sequence Diagram

```
Consumer        -> apiRouter:              POST /<provider>/checkout (booking selection)
apiRouter       -> bookingWorkflow:        Dispatch booking request
bookingWorkflow -> continuumDealCatalogService: GET deal metadata
continuumDealCatalogService --> bookingWorkflow: Deal metadata response
bookingWorkflow -> providerProxyLayer:     Select provider proxy (e.g. Viator)
providerProxyLayer -> httpAdapterLayer:   Execute outbound provider booking call
httpAdapterLayer -> ProviderAPI:          POST /booking (create booking)
ProviderAPI     --> httpAdapterLayer:     Booking confirmed
httpAdapterLayer --> providerProxyLayer:  Provider booking response
providerProxyLayer --> bookingWorkflow:   Booking confirmed, booking reference
bookingWorkflow -> continuumOrdersService: POST /orders (create Groupon order)
continuumOrdersService --> bookingWorkflow: Order created
bookingWorkflow --> apiRouter:            Booking + order confirmation data
apiRouter       --> Consumer:             Render confirmation UI (Preact/Redux)
```

## Related

- Architecture dynamic view: `dynamic-booking-request-bookingWorkflow`
- Related flows: [Provider Availability Check](provider-availability-check.md), [Checkout and Redemption](checkout-and-redemption.md), [Provider-Agnostic Booking Module](provider-agnostic-booking-module.md)
