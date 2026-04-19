---
service: "seer-frontend"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Engineering Metrics / Developer Productivity"
platform: "Continuum"
team: "Project Seer"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2022"
  framework: "React"
  framework_version: "18.2.0"
  runtime: "Node.js"
  runtime_version: "20.13 (Alpine)"
  build_tool: "Vite"
  build_tool_version: "4.1.0"
  package_manager: "npm"
---

# Seer Frontend Overview

## Purpose

Seer Frontend is the browser-based single-page application (SPA) for Project Seer, Groupon's centralized engineering-metrics platform. It provides engineering teams with interactive dashboards that visualize performance indicators drawn from multiple internal tooling APIs. The application allows teams to monitor code quality, alert volume, sprint progress, incident frequency, CI build times, pull-request cycle times, and deployment cadence — all from a single navigation bar.

## Scope

### In scope

- Rendering interactive bar charts for seven metric categories (code quality, alerts, sprint, incidents, build times, PR merge times, deployments)
- Fetching metric data from the `seer-service` backend at runtime via the `/api` path prefix
- Client-side routing between metric-category views (`/quality`, `/alerts`, `/sprint`, `/incidents`, `/builds`, `/pulls`, `/deployments`)
- Displaying configurable threshold reference tables for SonarQube code-quality metrics
- Supporting date-range and service/team filtering inputs on each metric view
- Building a static production bundle for container-based serving

### Out of scope

- Data collection and aggregation (handled by `seer-service` backend)
- Authentication and authorization flows (no auth layer visible in codebase)
- Storage or persistence of metric data
- Alert firing or notification dispatch
- Jira, Jenkins, SonarQube, OpsGenie, or Deploybot API calls (all proxied through backend)

## Domain Context

- **Business domain**: Engineering Metrics / Developer Productivity
- **Platform**: Continuum
- **Upstream consumers**: Human users (engineers, tech leads) via web browser
- **Downstream dependencies**: `seer-service` backend (via HTTPS/JSON REST calls to `/api` paths)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering Teams | Primary audience; consume dashboards to measure team health and velocity |
| Tech Leads / Engineering Managers | Review sprint volatility, defect rates, and incident trends |
| Project Seer Team | Own and operate the service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2022 (ESM) | `package.json` — `"type": "module"` |
| Framework | React | 18.2.0 | `package.json` — `"react": "^18.2.0"` |
| Runtime | Node.js | 20.13 (Alpine) | `Dockerfile` — `node:20.13-alpine` |
| Build tool | Vite | 4.1.0 | `package.json` — `"vite": "^4.1.0"` |
| Package manager | npm | (bundled with Node 20) | `package-lock.json` present |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| react | ^18.2.0 | ui-framework | Core UI rendering and state management |
| react-dom | ^18.2.0 | ui-framework | DOM mounting of React component tree |
| react-router-dom | ^6.23.0 | ui-framework | Client-side SPA routing between metric views |
| react-bootstrap | ^2.10.2 | ui-framework | Bootstrap-compatible React component library (Navbar, Container, Nav, Row, Col) |
| bootstrap | ^5.3.3 | ui-framework | CSS framework providing base styles |
| react-chartjs-2 | ^5.2.0 | ui-framework | React wrapper for Chart.js bar charts |
| chart.js | (peer of react-chartjs-2) | ui-framework | Underlying charting engine (Bar, CategoryScale, LinearScale, etc.) |
| @vitejs/plugin-react | ^3.1.0 | build | Vite plugin enabling JSX transform and React Fast Refresh |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
