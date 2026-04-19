---
service: "seer-frontend"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSeerFrontendApp"]
---

# Architecture Context

## System Context

Seer Frontend sits within the Continuum Platform (`continuumSystem`) as an internal engineering tooling application. Engineers open the SPA in a browser; the SPA communicates exclusively with the `seer-service` backend API (referenced in the DSL as `seerBackendApi_unk_7b2f`) over HTTPS/JSON. The SPA itself has no direct connection to Jira, Jenkins, SonarQube, OpsGenie, or Deploybot — all external integrations are mediated by the backend. No external users outside Groupon's engineering organization are expected to access this service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Seer Frontend Web App | `continuumSeerFrontendApp` | WebApp | React/Vite | React 18.2, Vite 4.1 | Single-page application for Project Seer dashboards and operational metrics |

## Components by Container

### Seer Frontend Web App (`continuumSeerFrontendApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| App Shell (`appShell`) | Client-side routing and layout composition; mounts Header and BrowserRouter | React |
| Header Navigation (`headerNav`) | Top-level nav bar with links to all seven metric sections; owns route `<Routes>` definitions | React / react-router-dom |
| Dropdown Filters (`dropdownFilters`) | Service selector, team selector, sprint board selector, date-range pickers, and SEV-level pickers; fetches filter options from backend | React |
| Dashboard Charts (`chartsDashboard`) | Renders bar charts for each metric category using Chart.js; fetches data from backend on filter change | React / react-chartjs-2 |
| API Client (`seerFrontend_apiClient`) | Browser `fetch` calls to `/api/*` paths; handles JSON parsing and error logging | Fetch API |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `appShell` | `headerNav` | Renders top-level navigation and route outlet | in-process |
| `appShell` | `dropdownFilters` | Renders filter controls within each route view | in-process |
| `appShell` | `chartsDashboard` | Renders chart panels within each route view | in-process |
| `dropdownFilters` | `seerFrontend_apiClient` | Fetches filter option data (service names, team IDs, board IDs) | in-process |
| `chartsDashboard` | `seerFrontend_apiClient` | Fetches time-series metric data for charts | in-process |
| `continuumSeerFrontendApp` | `seerBackendApi_unk_7b2f` | Requests metrics and reports from backend API | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSeerFrontendApp`
- Component: `components-continuumSeerFrontendApp`
