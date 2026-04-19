---
service: "clo-ita"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCloItaService"]
---

# Architecture Context

## System Context

`clo-ita` is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It sits at the frontend boundary of the CLO product, receiving HTTP requests from web and mobile UI clients and orchestrating calls to multiple Continuum backend services. It does not own a database; instead it aggregates and shapes responses from `apiProxy`, `continuumMarketingDealService`, `continuumUsersService`, `continuumOrdersService`, `continuumGeoDetailsService`, and `continuumDealCatalogService`.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| CLO ITA Service | `continuumCloItaService` | BFF / Web server | Node.js, Express, itier-server | I-Tier BFF serving CLO claim, enrollment, consent, and transaction summary experiences |

## Components by Container

### CLO ITA Service (`continuumCloItaService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Routing Layer (`cloHttpRoutes`) | Route registration and request wiring; dispatches incoming HTTP requests to the appropriate controller action | Express routes + controller dispatcher |
| Domain Controllers (`cloDomainControllers`) | Feature controllers implementing claim, enrollments, consent, transaction summary, and missing cash-back workflows | Keldor controllers (itier-server) |
| Proxy and Request Adapters (`cloProxyAdapters`) | Request modules and API adapters used to call downstream services and normalize responses | itier request modules + adapters |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `cloHttpRoutes` | `cloDomainControllers` | Dispatches incoming HTTP routes to controller actions | Direct (in-process) |
| `cloDomainControllers` | `cloProxyAdapters` | Uses request adapters to call backend APIs and shape responses | Direct (in-process) |
| `continuumCloItaService` | `apiProxy` | Calls shared proxy endpoints for claim and enrollment APIs | HTTPS/JSON |
| `continuumCloItaService` | `continuumMarketingDealService` | Reads deal details and claim eligibility context | HTTPS/JSON |
| `continuumCloItaService` | `continuumUsersService` | Reads user profile and consent/enrollment state | HTTPS/JSON |
| `continuumCloItaService` | `continuumOrdersService` | Reads transaction and order summaries for CLO users | HTTPS/JSON |
| `continuumCloItaService` | `continuumGeoDetailsService` | Reads geo details for location-aware experiences | HTTPS/JSON |
| `continuumCloItaService` | `continuumDealCatalogService` | Reads deal catalog metadata for rendering | HTTPS/JSON |

## Architecture Diagram References

- Component view: `components-clo-ita`
- Dynamic claim flow: `dynamic-claim-flow`
