---
service: "itier-tpp"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTppWebApp"]
---

# Architecture Context

## System Context

I-Tier TPP is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It serves as the internal operations portal for the Third-Party Partner Integration (3PIP) program. Merchant users and Groupon operations staff interact with the portal over HTTPS. The portal itself calls downstream Continuum services (Partner Service, API Lazlo, Deal Catalog, Geo Details) and external booking platform APIs (Booker, Mindbody) to fulfill its responsibilities. It does not expose a public consumer-facing API; all routes are protected by macaroon-based authentication via Doorman.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| I-Tier TPP Web App | `continuumTppWebApp` | Web Application | Node.js (Express, Preact) | 3.0.0 | Node.js web application that serves the Third Party Partner Portal UI and backend routes |

## Components by Container

### I-Tier TPP Web App (`continuumTppWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `httpRoutes` | Defines route mappings for portal pages and API endpoints in `core/routes.js` | Express routes |
| `featureControllers` | Implements module controllers for offers, partners, onboarding, admin, and tools pages | Node.js controllers |
| `requestModuleRegistry` | Registers request-scoped integrations: auth, rendering, service clients | `core/request_modules.js` |
| `serviceAdapters` | Initializes and proxies API clients for Partner Service, Groupon V2, Deal Catalog, Booker, and Mindbody | Gofer / ApiProxy clients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `merchant` (person) | `continuumTppWebApp` | Uses TPP for partner onboarding and operations | HTTPS |
| `continuumTppWebApp` | `continuumPartnerService` | Reads and updates partner data | REST |
| `continuumTppWebApp` | `continuumApiLazloService` | Fetches deals and related Groupon entities | REST |
| `continuumTppWebApp` | `continuumDealCatalogService` | Retrieves deal history | REST |
| `continuumTppWebApp` | `bookerApi` | Manages Booker onboarding and merchant mappings | REST |
| `continuumTppWebApp` | `mindbodyApi` | Manages Mindbody onboarding and merchant mappings | REST |
| `continuumTppWebApp` | `continuumGeoDetailsService` | Loads division and location metadata | REST |
| `httpRoutes` | `featureControllers` | Dispatches inbound requests | direct |
| `featureControllers` | `requestModuleRegistry` | Resolves request-scoped modules and helpers | direct |
| `featureControllers` | `serviceAdapters` | Uses wrapped service clients for partner operations | direct |
| `serviceAdapters` | `requestModuleRegistry` | Builds authenticated clients from registered modules | direct |

## Architecture Diagram References

- System context: `contexts-itier-tpp`
- Container: `containers-itier-tpp`
- Component: `components-itier-tpp`
- Dynamic (onboarding flow): `dynamic-itier-tpp-onboarding-flow`
