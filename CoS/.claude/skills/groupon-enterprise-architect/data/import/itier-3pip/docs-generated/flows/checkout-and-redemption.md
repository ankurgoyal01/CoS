---
service: "itier-3pip"
title: "Checkout and Redemption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "checkout-and-redemption"
flow_type: synchronous
trigger: "Consumer submits checkout form with a confirmed booking selection"
participants:
  - "consumer"
  - "continuumThreePipService"
  - "continuumOrdersService"
  - "continuumThirdPartyInventoryService"
  - "continuumEpodsService"
  - "providerViatorApi_12ce90 (or equivalent provider API)"
architecture_ref: "dynamic-booking-request-bookingWorkflow"
---

# Checkout and Redemption

## Summary

The Checkout and Redemption flow covers the final two stages of the 3PIP booking lifecycle: checkout (submitting the confirmed booking to the provider and creating a Groupon order) and redemption (retrieving order details and rendering the post-purchase confirmation/voucher UI). After the consumer confirms their selection, the `continuumThreePipService` finalizes the provider booking, creates the Groupon order via `continuumOrdersService`, and renders the redemption UI using data from `continuumEpodsService` and TPIS.

## Trigger

- **Type**: user-action
- **Source**: Consumer submits the checkout form in the booking iframe after selecting availability
- **Frequency**: On-demand — per completed purchase attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Submits checkout; receives redemption/confirmation UI | `consumer` |
| 3PIP Service | Orchestrates checkout finalization and redemption rendering | `continuumThreePipService` |
| API Router | Receives checkout POST and redemption GET; dispatches to workflow | `apiRouter` |
| Booking Workflow Orchestrator | Coordinates provider finalization, order creation, and redemption data assembly | `bookingWorkflow` |
| Provider Proxy Layer | Executes provider-specific booking confirmation call | `providerProxyLayer` |
| HTTP Adapter Layer | Executes outbound HTTP calls to provider API | `httpAdapterLayer` |
| Orders Service | Creates and stores the authoritative Groupon order record | `continuumOrdersService` |
| TPIS Service | Provides TPIS booking record data for redemption | `continuumThirdPartyInventoryService` |
| ePODS Service | Supplies auxiliary product and order data for redemption UI | `continuumEpodsService` |

## Steps

1. **Receives checkout submission**: Consumer submits the booking checkout form.
   - From: `consumer`
   - To: `continuumThreePipService` (`apiRouter`)
   - Protocol: REST (HTTP POST to provider-specific checkout route, e.g., `/viator/checkout`)

2. **Dispatches to booking workflow**: `apiRouter` routes the checkout request to `bookingWorkflow`.
   - From: `apiRouter`
   - To: `bookingWorkflow`
   - Protocol: direct (in-process)

3. **Confirms booking with provider**: `bookingWorkflow` instructs `providerProxyLayer` to call the external provider API and finalize the booking.
   - From: `providerProxyLayer` via `httpAdapterLayer`
   - To: External provider API (e.g., Viator API)
   - Protocol: REST

4. **Creates Groupon order**: On provider confirmation, `bookingWorkflow` calls `continuumOrdersService` to persist the Groupon order record.
   - From: `continuumThreePipService`
   - To: `continuumOrdersService`
   - Protocol: REST

5. **Reads TPIS booking record**: `bookingWorkflow` retrieves the TPIS booking record for order reconciliation and redemption context.
   - From: `continuumThreePipService`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: REST

6. **Fetches auxiliary order/product data**: `bookingWorkflow` calls `continuumEpodsService` to retrieve auxiliary product and order data needed to render the redemption UI.
   - From: `continuumThreePipService`
   - To: `continuumEpodsService`
   - Protocol: REST

7. **Renders redemption/confirmation UI**: `bookingWorkflow` assembles redemption data and returns the server-rendered Preact confirmation/voucher page to the consumer.
   - From: `continuumThreePipService`
   - To: `consumer`
   - Protocol: REST (HTTP response / server-rendered Preact UI via redemption route, e.g., `/viator/redemption`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider API rejects booking at checkout | `providerProxyLayer` surfaces rejection | Consumer sees checkout failure; no Groupon order created |
| Orders service fails | Order creation error after provider confirms | Provider booking may exist without a Groupon order — requires manual reconciliation; consumer sees error |
| TPIS unreachable during redemption | Redemption data assembly fails | Redemption UI may fail to render; consumer may not see full confirmation |
| ePODS unreachable | Auxiliary order data unavailable | Redemption UI rendered without auxiliary product details; partial degradation |
| Session (Memcached) expired | Booking context lost between checkout steps | Consumer is returned to start of booking flow |

## Sequence Diagram

```
Consumer        -> apiRouter:              POST /<provider>/checkout (checkout submission)
apiRouter       -> bookingWorkflow:        Dispatch checkout
bookingWorkflow -> providerProxyLayer:     Finalize provider booking
providerProxyLayer -> httpAdapterLayer:   Execute provider booking confirmation
httpAdapterLayer -> ProviderAPI:          POST /confirm-booking
ProviderAPI     --> httpAdapterLayer:     Booking confirmed + booking reference
httpAdapterLayer --> providerProxyLayer:  Provider confirmation
providerProxyLayer --> bookingWorkflow:   Booking finalized
bookingWorkflow -> continuumOrdersService: POST /orders (create Groupon order)
continuumOrdersService --> bookingWorkflow: Order created + order ID
bookingWorkflow -> continuumThirdPartyInventoryService: GET TPIS booking record
continuumThirdPartyInventoryService --> bookingWorkflow: TPIS booking data
bookingWorkflow -> continuumEpodsService: GET auxiliary product/order data
continuumEpodsService --> bookingWorkflow: Auxiliary data
bookingWorkflow --> apiRouter:            Redemption UI data assembled
apiRouter       --> Consumer:             Redirect to GET /<provider>/redemption
Consumer        -> apiRouter:              GET /<provider>/redemption
apiRouter       --> Consumer:             Render redemption/confirmation UI (Preact/Redux)
```

## Related

- Architecture dynamic view: `dynamic-booking-request-bookingWorkflow`
- Related flows: [Provider Booking Request](provider-booking-request.md), [Provider Availability Check](provider-availability-check.md), [Provider-Agnostic Booking Module](provider-agnostic-booking-module.md)
