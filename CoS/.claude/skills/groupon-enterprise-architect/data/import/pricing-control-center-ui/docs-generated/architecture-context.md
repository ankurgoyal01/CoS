---
service: "pricing-control-center-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumPricingControlCenterUi"]
---

# Architecture Context

## System Context

`continuumPricingControlCenterUi` is a Node.js iTier web application that sits within the Continuum platform. It is accessed exclusively by internal Groupon operators (the Dynamic Pricing team) through the Hybrid Boundary ingress (`control-center.groupondev.com` in production, `control-center--staging.groupondev.com` in staging). The UI enforces authentication through Doorman SSO before serving any page. All data retrieval and mutation is delegated downstream to `pricing-control-center-jtier` via HBProxyClient over HTTPS. The service holds no persistent data state of its own.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Pricing Control Center UI | `continuumPricingControlCenterUi` | WebApp | Node.js, Preact, iTier | Node.js ^16 | Server-rendered web application serving all PCC pages and acting as API proxy to the jtier backend |

## Components by Container

### Pricing Control Center UI (`continuumPricingControlCenterUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `routeAndPageHandlers` | Implements route actions, request validation, and response orchestration for all PCC endpoints | JavaScript (`modules/*/actions.js`, `modules/*/open-api.js`) |
| `pricingControlCenterApiClient` | Wraps HBProxyClient calls to all `pricing-control-center-jtier` endpoints; forwards `authn-token` header on every request | JavaScript (`modules/client/client.js`) |
| `authRedirectGateway` | Handles Doorman redirect initiation (`/doorman`), auth token cookie writes on callback (`/post-user-auth-token`), and guards all page routes against missing tokens | JavaScript (`modules/auth/actions.js`, `modules/home/actions.js`) |
| `pageCompositionRenderer` | Composes server-rendered Preact views and shared UI components for page responses | Preact (`modules/*/views/app.js`, `modules/components/*.js`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPricingControlCenterUi` | `pricingControlCenterJtierApi_9b3f4a1e` (stub) | Calls pricing APIs and upload endpoints via HBProxyClient | HTTPS/JSON |
| `continuumPricingControlCenterUi` | `doormanAuth_2e7c6d5b` (stub) | Redirects users for authentication and receives token callback | HTTPS |
| `routeAndPageHandlers` | `pricingControlCenterApiClient` | Calls backend pricing endpoints to load/update data | Direct (in-process) |
| `routeAndPageHandlers` | `authRedirectGateway` | Builds Doorman auth redirects and token handoff | Direct (in-process) |
| `routeAndPageHandlers` | `pageCompositionRenderer` | Renders Preact pages for each route | Direct (in-process) |

## Architecture Diagram References

- Component view: `pccUiComponents`
- Dynamic view (auth and search flow): `pccUiAuthAndSearchFlow` (disabled — external stubs not yet in federated model)
- DSL source: `structurizr/import/pricing-control-center-ui/architecture/`
