---
service: "PizzaNG"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPizzaNgService, continuumPizzaNgUi]
---

# Architecture Context

## System Context

PizzaNG sits within the Continuum platform as a CS agent productivity layer. CS agents interact with the React UI or Chrome extension (`continuumPizzaNgUi`); the I-Tier BFF (`continuumPizzaNgService`) orchestrates calls to up to nine downstream services to assemble agent-facing views. The service has no persistent data store of its own — all state lives in the downstream CRM and commerce systems. The central architecture dynamic view for the core agent flow is referenced as `pizzang-core-flow` (currently disabled in federation due to stub-only participants).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| PizzaNG Service | `continuumPizzaNgService` | Service | Node.js, Express | 12.22.12 / 4.14.0 | I-Tier BFF that serves PizzaNG APIs and web assets |
| PizzaNG UI and Extension | `continuumPizzaNgUi` | WebApp | React, JavaScript, Chrome Extension | 16.13.0 | React UI and Chrome extension assets used by CS agents |

## Components by Container

### PizzaNG Service (`continuumPizzaNgService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumPizzaNgApiRouter` | Express routes and request handling for BFF endpoints | Express Router |
| `continuumPizzaNgAuthComponent` | Authenticates users from OGWall/request headers | Node.js Module |
| `continuumPizzaNgDoormanIntegration` | Resolves Doorman endpoint integration for downstream auth flow | Node.js Module |
| `continuumPizzaNgCaapIntegration` | Client/actions integration for customer, order, refund, and snippet APIs | Gofer Client + Actions |
| `continuumPizzaNgCyclopsIntegration` | Client/actions integration for Cyclops voucher and customer workflows | Axios Client + Actions |
| `continuumPizzaNgDealCatalogIntegration` | Fetches deal category and lookup data | Gofer Client + Actions |
| `continuumPizzaNgLazloIntegration` | Retrieves deal details through API proxy endpoints | Gofer Client + Actions |
| `continuumPizzaNgCfsIntegration` | Performs ECE scoring via Content Flagging Service | Gofer Client + Actions |
| `continuumPizzaNgZendeskIntegration` | Reads ticket and search data from Zendesk | Gofer Client + Actions |
| `continuumPizzaNgIngestionIntegration` | Creates Zendesk tickets via the ingestion service endpoint | Gofer Client + Actions |
| `continuumPizzaNgConfigComponent` | Serves configuration-backed data (VAS, websites, links) | Node.js Module |
| `continuumPizzaNgRegionsComponent` | Resolves region and locale metadata for request handling | Node.js Module |
| `continuumPizzaNgLoggerComponent` | Transforms and submits telemetry/log payloads | Node.js Module |

### PizzaNG UI and Extension (`continuumPizzaNgUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumPizzaNgUiShell` | React application and extension shell used by support agents | React, Redux |
| `continuumPizzaNgLegacyExtensionBridge` | Legacy static scripts and browser-extension integration hooks | JavaScript |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPizzaNgUi` | `continuumPizzaNgService` | Invokes BFF APIs and loads static assets | HTTPS |
| `continuumPizzaNgService` | `cyclops` | Calls Cyclops APIs for voucher and customer operations | HTTPS/JSON |
| `continuumPizzaNgService` | `continuumCfsService` | Sends text payloads for ECE scoring | HTTPS/JSON |
| `continuumPizzaNgService` | `continuumDealCatalogService` | Fetches deal catalog metadata | HTTPS/JSON |
| `continuumPizzaNgService` | `apiProxy` | Uses API proxy and Lazlo-backed endpoints | HTTPS/JSON |
| `continuumPizzaNgService` | `zendesk` | Queries Zendesk tickets and metadata | HTTPS/JSON |
| `continuumPizzaNgUi` | `legacyWeb` | Opens Groupon domains for referenced links | HTTPS |
| `continuumPizzaNgService` | CAAP | Calls CAAP APIs for customer/order/refund/snippet workflows (stub — not in federated model) | HTTPS/JSON |
| `continuumPizzaNgService` | Doorman | Obtains authentication token flow entrypoints (stub — not in federated model) | HTTPS |
| `continuumPizzaNgService` | Ingestion Service | Creates Zendesk tickets through ingestion endpoint (stub — not in federated model) | HTTPS/JSON |
| `continuumPizzaNgService` | Merchant Success APIs | Calls Merchant Success APIs for merchant workflows (stub — not in federated model) | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-pizzang`
- Container: `containers-pizzang`
- Component (service): `components-pizza-ng-service`
- Dynamic (core flow): `pizzang-core-flow` (disabled in federation — references stub-only elements)
