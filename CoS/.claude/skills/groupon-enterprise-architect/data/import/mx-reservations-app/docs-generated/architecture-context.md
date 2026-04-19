---
service: "mx-reservations-app"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMxReservationsApp]
---

# Architecture Context

## System Context

MX Reservations App is a container within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It sits at the merchant-facing boundary: merchants interact with it directly through a browser, and it delegates all data operations downstream to the API Proxy, which routes to the Marketing Deal Service. The app is stateless and owns no persistent data store; all reservation state is managed by backend services. It is deployed alongside other Continuum containers in the snc1 and dub1 data centres.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MX Reservations App | `continuumMxReservationsApp` | WebApp / BFF | Node.js, TypeScript, React/Preact | Node 10/12, TS 3.7.2 | Merchant-facing SPA and server delivering booking, calendar, workshop, and redemption workflows |
| API Proxy | `apiProxy` | Backend Service (stub) | — | — | External dependency: proxies `/reservations/api/v2/*` requests to backend services |
| Marketing Deal Service | `continuumMarketingDealService` | Backend Service (stub) | — | — | External dependency: handles reservation and booking API data |

## Components by Container

### MX Reservations App (`continuumMxReservationsApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Reservations UI (`mxRes_reservationsUi`) | SPA routes, pages, and widgets for merchant reservation management; triggers all booking, calendar, workshop, and redemption use cases | React/Preact |
| Reservations Domain Modules (`mxRes_reservationsDomainModules`) | Client-side business workflows for booking, calendar management, workshop scheduling, and redemption processing | TypeScript |
| Ajax Context Provider (`mxRes_ajaxContextProvider`) | Builds authenticated API requests, manages token refresh, and performs endpoint path substitution for live API operations | TypeScript |
| Memory Server Adapter (`mxRes_memoryServerAdapter`) | In-process mock API handlers used when demo or test mode is active; intercepts requests before they reach the live API | JavaScript |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `merchant` | `continuumMxReservationsApp` | Manages reservations and calendars | HTTPS / Browser |
| `continuumMxReservationsApp` | `apiProxy` | Calls `/reservations/api/v2` endpoints | REST / HTTPS |
| `apiProxy` | `continuumMarketingDealService` | Routes reservation and booking API requests | REST / HTTPS |
| `mxRes_reservationsUi` | `mxRes_reservationsDomainModules` | Triggers booking, calendar, workshop, and redemption use cases | Direct (in-process) |
| `mxRes_reservationsDomainModules` | `mxRes_ajaxContextProvider` | Uses HTTP client context for live API operations | Direct (in-process) |
| `mxRes_ajaxContextProvider` | `mxRes_memoryServerAdapter` | Routes requests to in-memory handlers when demo mode is enabled | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-mx-reservations-app`
- Dynamic view: `dynamic-merchant-manages-reservations`
