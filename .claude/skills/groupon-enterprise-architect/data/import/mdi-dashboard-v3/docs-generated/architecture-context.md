---
service: "mdi-dashboard-v3"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMarketingDealServiceDashboardV3]
---

# Architecture Context

## System Context

MDI Dashboard V3 is a container within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. It acts as an internal-only web application consumed exclusively by Groupon operators and merchandisers through a browser. It has no public consumer-facing exposure. The service aggregates data from eight distinct Continuum backend services and one external SaaS (Salesforce) to present a unified diagnostics and insights interface. All outbound service calls use HTTP/JSON over the internal network.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MDI Dashboard V3 | `continuumMarketingDealServiceDashboardV3` | WebApp (Internal) | Node.js, Preact, Itier | 7.x | Internal web dashboard for deal diagnostics, cluster analysis, RAPI exploration, feeds operations, and merchant insights |

## Components by Container

### MDI Dashboard V3 (`continuumMarketingDealServiceDashboardV3`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Routing Layer (`mdiv3_routingLayer`) | Itier/Keldor route handlers dispatching browser requests to the correct feature module and API endpoint | Node.js |
| Browser Module (`mdiv3_browserModule`) | Deal browsing and search workflows including map-assisted geospatial exploration | Preact/JS |
| Show Deal Module (`mdiv3_showDealModule`) | Deal detail, attributes, sales performance charts, refresh trigger, and booster update workflows | Preact/JS |
| Clusters Module (`mdiv3_clustersModule`) | Cluster list, cluster detail inspection, and cluster history timeline workflows | Preact/JS |
| RAPI Module (`mdiv3_rapiModule`) | Relevance API query builder, result card inspection, and debug mode workflows | Preact/JS |
| Feeds Module (`mdiv3_feedsModule`) | Feed listing, batch expansion, upload-batch inspection, and dispatcher status flows | Preact/JS |
| Merchant Insights Module (`mdiv3_merchantInsightsModule`) | Merchant-centric top-city ranking and cluster performance analysis workflows | Preact/JS |
| Integrations Layer (`mdiv3_integrationsLayer`) | Server-side API adapters, URL composition, and response transformation for all dependent services | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMarketingDealServiceDashboardV3` | `continuumMarketingDealService` | Reads deals, divisions, and refresh/performance endpoints | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `continuumRelevanceApi` | Queries relevance cards search endpoints | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `continuumApiLazloService` | Builds deep links for deal detail inspection | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `apiProxy` | Uses proxied relevance search endpoints | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `continuumDealCatalogService` | Builds deal catalog links for operators | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `continuumVoucherInventoryService` | Builds voucher inventory links for operators | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `continuumAdInventoryService` | Triggers booster/status update endpoint | HTTP/JSON |
| `continuumMarketingDealServiceDashboardV3` | `salesForce` | Builds Salesforce deep links for merchant/deal context | HTTPS |
| `continuumMarketingDealServiceDashboardV3` | `loggingStack` | Emits application logs | Steno/Filebeat |
| `continuumMarketingDealServiceDashboardV3` | `metricsStack` | Emits service metrics | SMA/Wavefront |
| `continuumMarketingDealServiceDashboardV3` | `tracingStack` | Emits distributed traces | itier-tracing |

> Note: Relationships to Deals Cluster Service, MDS Feed Service, Deal Performance Service V2, and LPAPI are present in the codebase but are stub-only in the architecture DSL — these services are not yet fully modelled in the central workspace.

## Architecture Diagram References

- Component: `components-continuum-marketing-deal-service-dashboard-v3`
