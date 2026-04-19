---
service: "bookability-dashboard"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Bookability / Third-Party Integrations"
platform: "Continuum"
team: "3PIP-CBE (Merchant Experience)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.8.3"
  framework: "React"
  framework_version: "19.1.0"
  runtime: "Browser (Bun used for build and CI)"
  runtime_version: "Bun 1.x"
  build_tool: "Vite 7.0.4"
  package_manager: "Bun"
---

# Bookability Dashboard (ConDash) Overview

## Purpose

Bookability Dashboard (internally called ConDash — Connectivity Dashboard) is a React single-page application that gives Groupon operations and engineering teams real-time visibility into merchant connectivity, deal health, and bookability status across all monitored third-party booking platforms. It aggregates data from the Partner Service API and surfaces actionable metrics so teams can detect, investigate, and resolve booking issues without querying backend systems directly.

## Scope

### In scope

- Real-time display of merchant connectivity status across all dynamically discovered booking partners (Square, Mindbody, Booker, and others)
- Deal-level health check visualization (bookability, service duration, location, pricing, slots, platform-specific checks)
- Time-to-bookability reporting with per-platform breakdown and date range filtering
- Deal investigation workflow: acknowledge, categorize, and resolve problematic deals
- Manual trigger of deal health checks for specific products
- CSV export of deal and investigation data
- URL-based state management enabling shareable deep links to specific merchants or deals

### Out of scope

- Scheduling and execution of health checks (owned by Partner Service)
- External booking platform API communication (owned by EPODS/Partner Service)
- Merchant data persistence and deal lifecycle management (owned by Partner Service)
- Consumer-facing bookability flows (owned by MBNXT / commerce platforms)

## Domain Context

- **Business domain**: Merchant Bookability / Third-Party Integrations
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon employees (operations, engineering, merchant success teams); accessed directly via browser at `/bookability/dashboard/`
- **Downstream dependencies**: `continuumPartnerService` (all merchant, deal, health-check, and investigation data); `continuumUniversalMerchantApi` (internal OAuth authentication); `apiProxy` (routes dashboard API requests)

## Stakeholders

| Role | Description |
|------|-------------|
| Operations / Merchant Success | Primary users who monitor deal health and initiate investigations |
| 3PIP-CBE Engineering | Service owners; develop and deploy the dashboard |
| Partner Service team | Provides the backend API consumed by the dashboard |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.8.3 | `package.json` → `overrides.typescript` |
| Framework | React | 19.1.0 | `package.json` → `dependencies.react` |
| Build tool | Vite | 7.0.4 | `package.json` → `devDependencies.vite` |
| Package manager | Bun | 1.x | `Jenkinsfile`, `bun.lock` present |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `react` | ^19.1.0 | ui-framework | Core UI rendering |
| `react-dom` | ^19.1.0 | ui-framework | DOM rendering for React |
| `typescript` | ~5.8.3 | language | Static typing and compilation |
| `vite` | ^7.0.4 | build | Dev server, HMR, production bundling |
| `recharts` | ^3.1.0 | ui-framework | Charting library (declared; not actively used in current views) |
| `lucide-react` | ^0.525.0 | ui-framework | Icon components used throughout the dashboard |
| `react-router-dom` | ^7.8.2 | ui-framework | Routing (minimal usage; app uses native browser `history.pushState`) |
| `vitest` | ^3.1.3 | testing | Unit and feature test runner |
| `selenium-webdriver` | ^4.32.0 | testing | Feature/integration test automation |
| `eslint` | ^9.30.1 | validation | Linting with React-specific plugins |
| `@vitejs/plugin-react` | ^4.6.0 | build | Vite React JSX transform plugin |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
