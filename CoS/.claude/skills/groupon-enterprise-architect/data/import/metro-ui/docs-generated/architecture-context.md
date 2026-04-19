---
service: "metro-ui"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMetroUiService]
---

# Architecture Context

## System Context

Metro UI (`continuumMetroUiService`) is a frontend service within the Continuum platform. It sits at the boundary between merchant users (via browser) and Groupon's internal deal management backend services. Merchants access the service directly via the `/merchant/center/draft` path. The service performs server-side rendering and acts as an orchestration layer, fanning out to several internal Continuum services for deal data, geo/place lookups, marketing campaign eligibility, and AI-generated content. All requests pass through `apiProxy` for backend API traffic, or are made directly to specific Continuum service APIs. The service emits logs, metrics, and traces to the shared observability stack.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Metro UI Service | `continuumMetroUiService` | WebApp / Service | Node.js, itier-server, React/Preact | itier-server ^7.7.2 | Renders merchant deal-creation UIs and serves API endpoints for draft, edit, and internal deal workflows |

## Components by Container

### Metro UI Service (`continuumMetroUiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `metroUi_routing` | Defines HTTP routes and controller actions for draft/edit/internal merchant flows | Node.js route handlers |
| `metroUi_pageRendering` | Builds page model/context and renders HTML responses with remote layout integration | itier-render, remote-layout |
| `metroUi_integrationAdapters` | Performs outbound calls to internal/external APIs for geo, places, deal data, and AI/PDS workflows | HTTP clients, service clients |
| `metroUi_frontendBundles` | Compiled JS/CSS bundles for merchant deal creation/editing UX | Webpack bundles, React/Preact |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `metroUi_routing` | `metroUi_pageRendering` | Builds and renders page responses | Internal |
| `metroUi_routing` | `metroUi_integrationAdapters` | Calls integration actions for route handlers | Internal |
| `metroUi_pageRendering` | `metroUi_frontendBundles` | Serves JS/CSS assets for pages | Internal |
| `metroUi_integrationAdapters` | `apiProxy` | Calls backend APIs via proxy | HTTPS/JSON |
| `metroUi_integrationAdapters` | `continuumDealManagementApi` | Reads and updates deal data | HTTPS/JSON |
| `metroUi_integrationAdapters` | `continuumGeoDetailsService` | Retrieves autocomplete and place details | HTTPS/JSON |
| `metroUi_integrationAdapters` | `continuumM3PlacesService` | Fetches merchant places | HTTPS/JSON |
| `metroUi_integrationAdapters` | `continuumMarketingDealService` | Updates merchant campaign/deal eligibility | HTTPS/JSON |
| `metroUi_frontendBundles` | `googleTagManager` | Loads analytics tags in browser | HTTPS |
| `continuumMetroUiService` | `loggingStack` | Emits application logs | Internal |
| `continuumMetroUiService` | `metricsStack` | Publishes service metrics | Internal |
| `continuumMetroUiService` | `tracingStack` | Publishes distributed traces | Internal |

## Architecture Diagram References

- System context: `contexts-continuum-metro-ui`
- Container: `containers-continuum-metro-ui`
- Component: `components-continuum-metro-ui-service`
- Dynamic flow: `dynamic-metro-ui-draft-edit-flow`
