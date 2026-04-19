---
service: "itier-3pip-docs"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumThreePipDocsWeb"]
---

# Architecture Context

## System Context

`itier-3pip-docs` sits within the **Continuum Platform** (`continuumSystem`) as a partner-facing web application. External integration partners access the Groupon Developer Portal (hosted at `developers.groupon.com`) to read API documentation and use the Groupon Simulator. The service authenticates users via `continuumUsersService`, enriches deal data through `continuumApiLazloService`, and proxies all partner configuration and onboarding operations through GraphQL to the Partner API (PAPI) and Deal API (GAPI). It is part of Groupon's Interaction Tier (I-Tier) architecture pattern.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| itier-3pip-docs Web App | `continuumThreePipDocsWeb` | WebApp | Node.js (itier-server) | 16.15.0 | Serves 3PIP documentation UI and simulator onboarding APIs |

## Components by Container

### itier-3pip-docs Web App (`continuumThreePipDocsWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `redocPageController` | Renders `/3pip/docs` and composes the merchant layout shell | CoffeeScript / itier-server routing |
| `simulatorApiActions` | Implements onboarding, review, mapping, purchases, and uptime API actions | JavaScript (Express action handlers) |
| `graphqlGateway` | Encapsulates GraphQL queries and mutations to partner and deal backends | `@grpn/graphql`, `@grpn/graphql-papi`, `@grpn/graphql-gapi` |
| `dealDataEnricher` | Fetches and enriches deal data for test-deal setup flows | `@grpn/api-lazlo-client` |
| `frontendBundle` | Preact/React single-page application for partner onboarding and docs | Preact 10, MobX 6, Webpack 4 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumThreePipDocsWeb` | `continuumApiLazloService` | Enriches deal details for setup UX | HTTPS |
| `continuumThreePipDocsWeb` | `continuumUsersService` | Authenticates merchant users | Cookie / OAuth token |
| `frontendBundle` | `redocPageController` | Requests docs shell (SSR) | HTTP (in-process) |
| `frontendBundle` | `simulatorApiActions` | Requests onboarding and simulator data | HTTP REST (browser to server) |
| `simulatorApiActions` | `continuumUsersService` | Validates user session on every API call | Cookie / OAuth token |
| `simulatorApiActions` | `graphqlGateway` | Runs GraphQL operations for partner config | GraphQL (in-process) |
| `dealDataEnricher` | `continuumApiLazloService` | Loads deal by UUID and country code | HTTPS |

> Note: Relationships to `remoteLayoutService`, `graphqlPartnerApi`, `graphqlDealApi`, and `observabilityPlatform` are present in the architecture model as stubs and represent planned or partially implemented integrations.

## Architecture Diagram References

- Component view: `components-continuum-three-pip-docs-web`
- Dynamic flow: `dynamic-continuumThreePipDocsWeb` (partner onboarding flow)
