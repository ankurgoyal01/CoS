---
service: "itier-3pip-docs"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Third-Party Partner Integration (3PIP)"
platform: "Continuum"
team: "Third-Party Partner & Operations Experience"
status: active
tech_stack:
  language: "JavaScript / CoffeeScript"
  language_version: "ES2017 / CoffeeScript 1.x"
  framework: "itier-server"
  framework_version: "5.x"
  runtime: "Node.js"
  runtime_version: "16.15.0"
  build_tool: "Webpack"
  package_manager: "npm"
---

# itier-3pip-docs (Groupon Simulator) Overview

## Purpose

`itier-3pip-docs` is the Groupon Simulator — an I-Tier frontend web application that serves third-party integration partner (3PIP) documentation and provides a self-service portal for external partners to onboard, configure, test, and review their Groupon integrations. It renders interactive API documentation (via Redoc) for the Groupon ingestion, transactional, and booking APIs, and exposes a simulator UI that allows partners to manage onboarding configurations, set up test deals, trigger availability syncs, and track integration uptime metrics.

## Scope

### In scope

- Rendering Redoc-based API documentation for 3PIP booking, ingestion, and transactional specs
- Partner authentication via Groupon cookie/OAuth session validation
- Groupon Simulator UI: partner onboarding configuration management
- Test deal setup and deal mapping configuration
- Triggering availability syncs for partner inventory
- Fetching TTD (Things To Do) and HBW (Hotels by World) purchase history
- Reviewing and submitting onboarding configuration reviews
- Retrieving simulator transaction logs
- Displaying partner uptime metrics and API health
- Exposing production API key retrieval for certified partners
- Legacy `/3pip/docs` redirect route

### Out of scope

- Partner API backend processing (handled by PAPI / GraphQL partner API)
- Deal catalog management (handled by GAPI / GraphQL deal API)
- Merchant layout shell rendering (handled by remote-layout service)
- Partner provisioning and account creation
- Actual availability/booking transaction processing

## Domain Context

- **Business domain**: Third-Party Partner Integration (3PIP) — onboarding and simulator tools for external commerce partners
- **Platform**: Continuum
- **Upstream consumers**: External integration partners accessing `https://developers.groupon.com` and `https://developers-staging.groupon.com`; Ghost CMS (widget injection)
- **Downstream dependencies**: `continuumUsersService` (user authentication), `continuumApiLazloService` (deal data enrichment), GraphQL Partner API (PAPI, onboarding configs/mutations), GraphQL Deal API (GAPI, deal catalog)

## Stakeholders

| Role | Description |
|------|-------------|
| Integration Partners | External third-party companies integrating with Groupon's commerce APIs; primary end users of the simulator |
| 3pip-booking Team | Owns and maintains this service; contact via `3pip-booking@groupon.com` or `#3pip` Slack channel |
| Partner Operations | Uses the review and certification workflows to approve partner onboarding configurations |
| Groupon Developers | Internal engineers consuming the `/3pip/docs` API documentation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2017 | `package.json`, `modules/main/actions.js` |
| Language | CoffeeScript | 1.x | `package.json` (`coffeescript: ^1.10.0`), `core/*.coffee` |
| Framework | itier-server (Express) | 5.36.5 | `package.json` (`itier-server: ^5.36.5`) |
| Runtime | Node.js | 16.15.0 | `Dockerfile` (`FROM alpine-node16.15.0`) |
| Build tool | Webpack | 4.44.2 | `package.json` (`webpack: ^4.44.2`) |
| Package manager | npm | | `.npmrc`, `package.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `keldor` | ^7.3.7 | http-framework | Core I-Tier app configuration and middleware orchestration |
| `itier-server` | ^5.36.5 | http-framework | I-Tier Express server entry point and request lifecycle |
| `express` | ^4.14.0 | http-framework | Underlying HTTP server framework |
| `preact` | ^10.5.13 | ui-framework | Lightweight React-compatible frontend component rendering |
| `redoc` | ^2.0.0-rc.56 | ui-framework | OpenAPI spec rendering for 3PIP API documentation pages |
| `@grpn/graphql` | ^3.1.1 | http-client | GraphQL query/mutation client for PAPI and GAPI backends |
| `@grpn/graphql-papi` | ^3.0.0 | http-client | GraphQL client targeting the Groupon Partner API (PAPI) |
| `@grpn/graphql-gapi` | ^5.2.6 | http-client | GraphQL client targeting the Groupon Deal API (GAPI) |
| `@grpn/api-lazlo-client` | ^2.1.1 | http-client | Client for Lazlo deal enrichment API |
| `itier-user-auth` | ^8.1.0 | auth | Merchant and partner user session authentication |
| `itier-feature-flags` | ^3.1.2 | config | Runtime feature flag evaluation |
| `mobx` | ^6.3.3 | state-management | Frontend state management for the Preact/React SPA |
| `itier-instrumentation` | ^9.10.4 | metrics | Application metrics and instrumentation |
| `itier-tracing` | ^1.6.1 | metrics | Distributed tracing and error telemetry |
| `@grpn/grpn-3pip-ingestion-docs` | 2.21.1 | serialization | Versioned OpenAPI spec for 3PIP ingestion API documentation |
| `@grpn/grpn-3pip-transactional-docs` | 2.19.8 | serialization | Versioned OpenAPI spec for 3PIP transactional API documentation |
| `@grpn/grpn-3pip-booking-docs` | 1.2.1 | serialization | Versioned OpenAPI spec for 3PIP booking API documentation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
