---
service: "itier-3pip"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for TPIS Booking ITA (itier-3pip).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Provider Booking Request](provider-booking-request.md) | synchronous | Consumer initiates booking in iframe | Consumer selects a provider deal, the service loads deal metadata, checks provider availability, and creates a Groupon order |
| [Provider Availability Check](provider-availability-check.md) | synchronous | Consumer loads booking UI | Service queries the relevant provider API for available slots, times, or tickets to populate the booking selection UI |
| [Checkout and Redemption](checkout-and-redemption.md) | synchronous | Consumer submits checkout form | Service submits the confirmed booking to the provider, creates a Groupon order, and renders the redemption/confirmation UI |
| [Provider-Agnostic Booking Module](provider-agnostic-booking-module.md) | synchronous | Deal page loads booking iframe | The booking module initializes for any supported provider by routing through the API router and provider proxy layer to the correct provider integration path |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The **Provider Booking Request** flow spans `continuumThreePipService`, `continuumDealCatalogService`, `continuumOrdersService`, and external provider APIs. It is documented in the central Structurizr dynamic view: `dynamic-booking-request-bookingWorkflow`.
- The **Checkout and Redemption** flow additionally spans `continuumThirdPartyInventoryService` and `continuumEpodsService`.
- All cross-service flows are synchronous REST with no intermediate event bus.
