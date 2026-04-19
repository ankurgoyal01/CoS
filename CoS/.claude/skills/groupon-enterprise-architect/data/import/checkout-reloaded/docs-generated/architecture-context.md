---
service: "checkout-reloaded"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCheckoutReloadedService, continuumCheckoutReloadedDb]
---

# Architecture Context

## System Context

checkout-reloaded sits within the Continuum platform as the consumer-facing BFF layer for the checkout experience. Browsers and mobile web views call it directly via HTTP; it does not expose a machine-to-machine API to other backend services. It depends on a set of internal Continuum services (Cart, Order, Pricing, Deal Catalog) and one external payment provider (Adyen) to fulfill each request. The `continuumCheckoutReloadedDb` PostgreSQL instance is accessed via the Checkout Repository component to persist and load checkout session state.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Checkout Reloaded Service | `continuumCheckoutReloadedService` | Service / BFF | TypeScript, Node.js, itier-server | 20.19.6 / 7.14.2 | SSR BFF that orchestrates the consumer checkout experience |
| Checkout Reloaded Database | `continuumCheckoutReloadedDb` | Database | PostgreSQL | — | Persists checkout session and order state on behalf of the BFF |

## Components by Container

### Checkout Reloaded Service (`continuumCheckoutReloadedService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `checkoutReloaded_api` | Accepts checkout requests from clients, validates payloads, enforces CSRF checks | Express Controller (TypeScript) |
| `checkoutReloaded_orchestrator` | Coordinates pricing validation, inventory checks, payment authorization, and order confirmation workflow | Application Service (TypeScript) |
| `checkoutReloaded_repository` | Persists and loads checkout sessions and order state; translates between domain objects and DB schema | Data Access Layer (TypeScript / SQL) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCheckoutReloadedService` | `continuumCheckoutReloadedDb` | Reads and writes checkout data | SQL |
| `checkoutReloaded_api` | `checkoutReloaded_orchestrator` | Delegates validated checkout requests for orchestration | Direct (in-process) |
| `checkoutReloaded_orchestrator` | `checkoutReloaded_repository` | Loads and persists checkout session state | Direct (in-process) |
| `continuumCheckoutReloadedService` | Adyen Payment SDK | Authorizes payment transactions | HTTPS / SDK |
| `continuumCheckoutReloadedService` | Cart Service | Loads and updates cart data | REST / HTTP |
| `continuumCheckoutReloadedService` | Pricing Service | Validates and applies pricing | REST / HTTP |
| `continuumCheckoutReloadedService` | Order Service | Finalizes orders after payment authorization | REST / HTTP |
| `continuumCheckoutReloadedService` | Deal Catalog Service | Fetches deal and product details for cart display | REST / HTTP |
| `continuumCheckoutReloadedService` | Auth/Identity Service (UMAPI) | Validates merchant and user identity | REST / HTTP |
| `continuumCheckoutReloadedService` | Layout Service | Retrieves shared header and footer HTML | REST / HTTP |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumCheckoutReloadedService`
- Dynamic flow: `dynamic-checkout-reloaded-request-flow`
