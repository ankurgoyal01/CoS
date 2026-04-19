---
service: "itier-3pip"
title: "Provider-Agnostic Booking Module"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "provider-agnostic-booking-module"
flow_type: synchronous
trigger: "Groupon deal page loads the booking iframe for any supported provider"
participants:
  - "consumer"
  - "continuumThreePipService"
  - "continuumDealCatalogService"
  - "continuumThirdPartyInventoryService"
architecture_ref: "components-continuum-three-pip-service"
---

# Provider-Agnostic Booking Module

## Summary

The Provider-Agnostic Booking Module describes how `continuumThreePipService` initializes the correct provider-specific booking experience from a single unified entry point. Regardless of the provider (Viator, Peek, AMC, Vivid, Grubhub, Mindbody, or HBW), the `apiRouter` receives the request, reads deal context from the Deal Catalog and TPIS, then routes to the `bookingWorkflow` which selects the correct `providerProxyLayer` proxy. This abstraction allows Groupon to add new provider integrations without changing the top-level routing or consumer-facing iframe URL structure.

## Trigger

- **Type**: user-action
- **Source**: A Groupon deal page embeds the booking iframe; the consumer's browser loads the iframe URL for a deal backed by any supported 3rd-party provider
- **Frequency**: On-demand — each deal page load that includes a 3PIP booking iframe

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Loads the deal page; triggers iframe initialization | `consumer` |
| 3PIP Service | Top-level request receiver; routes to appropriate provider path | `continuumThreePipService` |
| API Router | Entry point; identifies provider from route and dispatches | `apiRouter` |
| Booking Workflow Orchestrator | Resolves provider context and initializes the correct flow path | `bookingWorkflow` |
| Provider Proxy Layer | Holds provider-specific proxy adapters for all 7 supported providers | `providerProxyLayer` |
| Shared Domain Helpers | Provides shared data transformation and presentational utilities used across all providers | `sharedDomainHelpers` |
| HTTP Adapter Layer | Executes all outbound HTTP calls regardless of provider | `httpAdapterLayer` |
| Deal Catalog Service | Supplies deal metadata to identify the provider and deal type | `continuumDealCatalogService` |
| TPIS Service | Provides the canonical inventory and booking context for the deal | `continuumThirdPartyInventoryService` |

## Steps

1. **Receives iframe load request**: Consumer's browser sends a GET request to the booking module URL (e.g., `/viator/booking?dealId=<id>`).
   - From: `consumer`
   - To: `continuumThreePipService` (`apiRouter`)
   - Protocol: REST (HTTP GET)

2. **Identifies provider from route**: `apiRouter` parses the route prefix (viator, peek, amc, vivid, grubhub, mindbody, hbw) to identify the provider and dispatches to `bookingWorkflow`.
   - From: `apiRouter`
   - To: `bookingWorkflow`
   - Protocol: direct (in-process)

3. **Fetches deal metadata**: `bookingWorkflow` retrieves deal metadata from the Deal Catalog to validate the deal and establish booking context.
   - From: `continuumThreePipService`
   - To: `continuumDealCatalogService`
   - Protocol: REST

4. **Fetches TPIS inventory context**: `bookingWorkflow` queries TPIS to obtain the inventory record and booking configuration for the deal.
   - From: `continuumThreePipService`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: REST

5. **Selects provider proxy**: `bookingWorkflow` selects the correct provider proxy adapter from `providerProxyLayer` based on deal/provider context.
   - From: `bookingWorkflow`
   - To: `providerProxyLayer`
   - Protocol: direct (in-process)

6. **Applies shared domain helpers**: `bookingWorkflow` uses `sharedDomainHelpers` to transform deal and inventory data into provider-normalized presentational data.
   - From: `bookingWorkflow`
   - To: `sharedDomainHelpers`
   - Protocol: direct (in-process)

7. **Renders initialized booking UI**: The service returns the server-rendered Preact/Redux booking module UI, pre-populated with deal and provider context.
   - From: `continuumThreePipService`
   - To: `consumer`
   - Protocol: REST (HTTP response / server-rendered Preact UI)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown/unsupported provider in route | `apiRouter` returns 404 or error page | Consumer sees error; booking module does not initialize |
| Deal Catalog unavailable | Module initialization fails | Consumer sees error UI in iframe; cannot proceed to booking |
| TPIS unavailable | Module initialization fails | Consumer sees error UI in iframe; cannot proceed to booking |
| Deal not found or inactive | Deal Catalog returns not-found or expired response | Consumer sees deal unavailability message in iframe |

## Sequence Diagram

```
Consumer        -> apiRouter:              GET /<provider>/booking?dealId=<id>
apiRouter       -> bookingWorkflow:        Dispatch with provider + dealId context
bookingWorkflow -> continuumDealCatalogService: GET deal metadata (dealId)
continuumDealCatalogService --> bookingWorkflow: Deal metadata (provider type, options)
bookingWorkflow -> continuumThirdPartyInventoryService: GET inventory/booking config
continuumThirdPartyInventoryService --> bookingWorkflow: Inventory + booking context
bookingWorkflow -> providerProxyLayer:     Select provider proxy adapter (e.g. viator)
providerProxyLayer --> bookingWorkflow:   Provider proxy initialized
bookingWorkflow -> sharedDomainHelpers:   Transform deal + inventory data for UI
sharedDomainHelpers --> bookingWorkflow:  Normalized booking module props
bookingWorkflow --> apiRouter:            Booking module render data
apiRouter       --> Consumer:             Render initialized booking module UI (Preact/Redux)
```

## Related

- Architecture component view: `components-continuum-three-pip-service`
- Architecture dynamic view: `dynamic-booking-request-bookingWorkflow`
- Related flows: [Provider Booking Request](provider-booking-request.md), [Provider Availability Check](provider-availability-check.md), [Checkout and Redemption](checkout-and-redemption.md)
