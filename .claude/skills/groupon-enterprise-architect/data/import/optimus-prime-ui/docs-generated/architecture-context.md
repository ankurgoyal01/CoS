---
service: "optimus-prime-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumOptimusPrimeUi"]
---

# Architecture Context

## System Context

Optimus Prime UI is a container within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce and tooling engine. It serves as the sole browser-facing entry point to the Optimus Prime ETL platform. End users (internal data engineers and analysts) load the SPA in their browser and interact with ETL pipeline management features. The UI delegates all domain logic and persistence to the `continuumOptimusPrimeApi` backend container via authenticated HTTPS/JSON calls. Interaction telemetry and performance data are forwarded to `googleAnalytics` via the gtag JavaScript SDK. The UI has no direct database connections; it is entirely stateless from an infrastructure perspective.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Optimus Prime UI | `continuumOptimusPrimeUi` | WebApp | Vue 2, Vite, Vuetify | 2.7.14 / 4.1.4 / 2.6.14 | Web application used to create and run ETL pipelines, manage jobs, connections, workspaces, and run history. |

## Components by Container

### Optimus Prime UI (`continuumOptimusPrimeUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Routing and View Composition (`continuumOptimusPrimeUiRouter`) | Defines the route map under `src/router` and composes page views under `src/views`; drives navigation between Home, Jobs, Connections, DataFetcher, DataLoader, and Workspace views | Vue Router + Vue components |
| Application State Store (`continuumOptimusPrimeUiStateStore`) | Manages reactive domain state for jobs, connections, workspaces, datafetchers, dataloaders, and runtime UI state via Pinia stores | Pinia |
| API Client Layer (`continuumOptimusPrimeUiApiClient`) | Wraps Axios with per-domain endpoint modules; all HTTPS/JSON calls to `optimus-prime-api` flow through this layer | Axios + service modules |
| Background Polling Tasks (`continuumOptimusPrimeUiBackgroundTasks`) | Maintains browser-side timer loops that poll for execution state updates, schedule ticks, and health checks; emits `onExecutionAdd`, `onExcutionUpdate`, `onJobsUpdate`, `onDatafetcherAdd`, `onDatafetcherUpdate`, `onDataloaderAdd`, `onDataloaderUpdate`, `onHealthCheckError`, `onHealthCheckOk` events via the internal EventBus | Browser timers/workers |
| Telemetry and Error Reporting (`continuumOptimusPrimeUiTelemetry`) | Intercepts Vue and window error handlers; reports interaction, exception, performance, and web-vitals events to Google Analytics via the `GA` utility and `reportWebVitals` | gtag + web-vitals |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOptimusPrimeUi` | `continuumOptimusPrimeApi` | Uses /api/v2 endpoints for user profile, jobs, runs, workspaces, connections, datafetchers, dataloaders, storage, and metadata | HTTPS/JSON |
| `continuumOptimusPrimeUi` | `googleAnalytics` | Sends interaction, exception, timing, and web-vitals telemetry via gtag | HTTPS |
| `continuumOptimusPrimeUiRouter` | `continuumOptimusPrimeUiStateStore` | Navigates views and drives store-backed workflows | In-process |
| `continuumOptimusPrimeUiRouter` | `continuumOptimusPrimeUiApiClient` | Loads route-level data and submits user actions | In-process |
| `continuumOptimusPrimeUiStateStore` | `continuumOptimusPrimeUiApiClient` | Reads and writes Optimus domain data via API calls | In-process |
| `continuumOptimusPrimeUiBackgroundTasks` | `continuumOptimusPrimeUiApiClient` | Polls execution and schedule updates | In-process |
| `continuumOptimusPrimeUiApiClient` | `continuumOptimusPrimeUiTelemetry` | Publishes error and performance events | In-process (EventBus) |

## Architecture Diagram References

- System context: `contexts-continuumOptimusPrimeUi`
- Container: `containers-continuumOptimusPrimeUi`
- Component: `components-optimus-prime-ui`
