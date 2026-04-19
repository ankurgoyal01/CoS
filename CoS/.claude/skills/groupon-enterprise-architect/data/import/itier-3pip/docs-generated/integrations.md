---
service: "itier-3pip"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 7
internal_count: 4
---

# Integrations

## Overview

itier-3pip has a broad integration footprint with 7 external provider APIs and 4 internal Groupon services. All integrations are synchronous REST. External provider calls are routed through the `providerProxyLayer` component and executed via the `httpAdapterLayer` using `gofer` and `keldor` HTTP clients. Internal Groupon service calls use dedicated client libraries (`itier-tpis-client`, `itier-groupon-v2-client`, `@grpn/graphql`).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Viator API | REST | Books inventory and checks availability for experience deals | yes | `providerViatorApi_12ce90` |
| Peek API | REST | Books inventory and checks availability for activities | yes | `providerPeekApi_1a4ffd` |
| AMC API | REST | Books movie tickets | yes | `providerAmcApi_8d20ab` |
| Vivid API | REST | Books event/entertainment tickets | yes | `providerVividApi_4f8321` |
| Grubhub API | REST | Reads food menu and places delivery/pickup orders | yes | `providerGrubhubApi_678d53` |
| Mindbody API | REST | Books fitness classes and wellness appointments | yes | `providerMindbodyApi_2af2d3` |
| HBW API | REST | Books HBW experiences | yes | `providerHbwApi_44fcd9` |

### Viator API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer` using `gofer`/`keldor` HTTP clients
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Checks availability of Viator-managed experience inventory and creates bookings on behalf of the Groupon consumer
- **Failure mode**: Booking flow fails; consumer receives error in iframe; no Groupon order is created
- **Circuit breaker**: No evidence found in architecture model

### Peek API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Checks availability of Peek-managed activity inventory and creates bookings
- **Failure mode**: Booking flow fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

### AMC API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Reserves and purchases AMC movie tickets for Groupon consumers
- **Failure mode**: Booking flow fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

### Vivid API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Books entertainment and event tickets via Vivid's inventory system
- **Failure mode**: Booking flow fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

### Grubhub API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Reads restaurant menus and submits food delivery or pickup orders
- **Failure mode**: Order placement fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

### Mindbody API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Books fitness classes and wellness appointments in Mindbody's scheduling system
- **Failure mode**: Booking flow fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

### HBW API Detail

- **Protocol**: REST
- **Base URL / SDK**: Accessed via `httpAdapterLayer`
- **Auth**: Provider-specific credentials (managed via secrets)
- **Purpose**: Books HBW-managed experiences
- **Failure mode**: Booking flow fails; consumer receives error in iframe
- **Circuit breaker**: No evidence found in architecture model

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog | REST | Retrieves deal metadata required to render the booking UI and validate the consumer's deal | `continuumDealCatalogService` |
| Orders | REST | Creates and reads Groupon orders after a booking is confirmed | `continuumOrdersService` |
| TPIS (3rd-Party Inventory Service) | REST | Uses TPIS booking flows and data; provides the canonical inventory and booking record layer | `continuumThirdPartyInventoryService` |
| ePODS | REST | Retrieves auxiliary product and order data needed for redemption flows | `continuumEpodsService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon Consumer (browser) | HTTP (iframe embed) | Accesses booking and redemption UIs embedded in Groupon deal pages |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All outbound HTTP calls to both external provider APIs and internal services are made via `gofer` and `keldor` clients, which provide structured request/response logging via `groupon-steno`.
- Metrics and tracing are instrumented via `itier-instrumentation` 9.11.2, which emits per-dependency latency and error-rate signals.
- No explicit circuit breaker configuration is documented in the architecture model; retry and timeout behavior is expected to be configured per client library defaults or Helm values.
