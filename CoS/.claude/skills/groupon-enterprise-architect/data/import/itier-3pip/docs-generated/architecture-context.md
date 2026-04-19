---
service: "itier-3pip"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumThreePipService]
---

# Architecture Context

## System Context

itier-3pip (`continuumThreePipService`) is a container within the Continuum Platform (`continuumSystem`) — Groupon's core commerce engine. It sits at the boundary between Groupon consumers and a set of external 3rd-party inventory provider APIs. Consumers reach the service through an iframe embedded in Groupon deal pages; the service then orchestrates multi-step booking workflows by calling both external provider APIs and internal Continuum services such as Deal Catalog, Orders, TPIS, and ePODS.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| 3PIP Service | `continuumThreePipService` | Backend / Web | Node.js, Express, Preact, Redux | Node.js 12.22.3 / Express 4.14.0 | Serves booking and redemption iframe UIs and orchestrates provider integrations |
| Memcached | *(unnamed in DSL)* | Cache | Memcached | — | Session and response cache for booking state |

> Stub containers (continuumDealCatalogService, continuumOrdersService, continuumThirdPartyInventoryService, continuumEpodsService) are defined as local validation stubs and resolve to containers owned by other services.

## Components by Container

### 3PIP Service (`continuumThreePipService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiRouter` | Route registration, request middleware, and module dispatch — the entry point for all inbound HTTP requests | Express/Koa-style routing |
| `bookingWorkflow` | Domain workflow logic for booking, checkout, and redemption interactions; coordinates provider proxies and shared helpers | JavaScript modules |
| `providerProxyLayer` | Provider-specific proxy adapters for Viator, Peek, AMC, Vivid, Grubhub, Mindbody, and HBW; selects the correct integration path per request | Proxy initializers |
| `sharedDomainHelpers` | Reusable presentational and data-transformation helpers shared across booking flows and UI rendering | Shared backend/frontend helpers |
| `httpAdapterLayer` | Outbound HTTP client wrappers and request modules used by provider proxies to call external APIs | HTTP clients (gofer, keldor) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `consumer` | `continuumThreePipService` | Uses Groupon booking and redemption pages via iframe | HTTP/browser |
| `continuumThreePipService` | `continuumDealCatalogService` | Retrieves deal metadata | REST |
| `continuumThreePipService` | `continuumOrdersService` | Creates and reads orders | REST |
| `continuumThreePipService` | `continuumThirdPartyInventoryService` | Uses TPIS booking flows and data | REST |
| `continuumThreePipService` | `continuumEpodsService` | Retrieves auxiliary product/order data | REST |
| `continuumThreePipService` | Viator API | Books inventory and checks availability | REST |
| `continuumThreePipService` | Peek API | Books inventory and checks availability | REST |
| `continuumThreePipService` | AMC API | Books inventory and checks availability | REST |
| `continuumThreePipService` | Vivid API | Books inventory and checks availability | REST |
| `continuumThreePipService` | Grubhub API | Reads menu and places food orders | REST |
| `continuumThreePipService` | Mindbody API | Books classes and appointments | REST |
| `continuumThreePipService` | HBW API | Books HBW experiences | REST |
| `apiRouter` | `bookingWorkflow` | Routes module-specific requests to booking workflows | direct |
| `bookingWorkflow` | `providerProxyLayer` | Selects provider integration and orchestration path | direct |
| `bookingWorkflow` | `sharedDomainHelpers` | Uses shared transformations and presenter helpers | direct |
| `providerProxyLayer` | `httpAdapterLayer` | Executes outbound HTTP calls through common client wrappers | direct |

## Architecture Diagram References

- Component: `components-continuum-three-pip-service`
- Dynamic (booking request flow): `dynamic-booking-request-bookingWorkflow`
