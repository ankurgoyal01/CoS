---
service: "PizzaNG"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Customer Support / GSO"
platform: "continuum"
team: "GSO / Customer Support Engineering"
status: active
tech_stack:
  language: "Node.js"
  language_version: "12.22.12"
  framework: "I-Tier"
  framework_version: "7.9.2"
  runtime: "Node.js"
  runtime_version: "12.22.12"
  build_tool: "webpack"
  package_manager: "npm"
---

# PizzaNG Overview

## Purpose

PizzaNG is a CS (Customer Support) agent productivity tool that integrates with Groupon's CRM ecosystem to surface customer, order, deal, and refund data directly within the agent's workflow. It provides a React UI (and Chrome extension) that agents use while handling support tickets in Zendesk, pulling together data from multiple backend systems to reduce Average Handle Time (AHT). The I-Tier BFF (`continuumPizzaNgService`) orchestrates all downstream service calls so that agents receive enriched context in a single interface.

## Scope

### In scope

- Serving the PizzaNG React UI and Chrome extension assets to CS agents
- BFF API endpoints for retrieving customer, order, deal, and snippet data (`/api/bff/pizza`, `/api/bff/create-order`)
- Orchestrating calls to CAAP, Cyclops, CFS Service, Deal Catalog, API Proxy/Lazlo, Zendesk, Doorman, Ingestion Service, and Merchant Success APIs
- In-memory caching of ticket field metadata with 2-hour freshness (`ticketFields` cache)
- NLP/ECE scoring for deal content via CFS Service
- Regional and locale resolution for agent workflows
- Telemetry logging via the GSO Logger module

### Out of scope

- Customer data storage (owned by CAAP and CRM systems)
- Order lifecycle management (owned by commerce services)
- Zendesk ticket creation outside the ingestion flow
- SEM or marketing tooling
- Direct database access

## Domain Context

- **Business domain**: Customer Support / GSO (Global Support Operations)
- **Platform**: Continuum
- **Upstream consumers**: CS agents accessing PizzaNG via browser or Chrome extension while working Zendesk tickets
- **Downstream dependencies**: CAAP, Cyclops, `continuumCfsService`, `continuumDealCatalogService`, `apiProxy` (Lazlo), `zendesk`, Doorman, Ingestion Service, Merchant Success APIs, `legacyWeb`

## Stakeholders

| Role | Description |
|------|-------------|
| CS Agent | Primary user; resolves customer support tickets using PizzaNG tools |
| GSO Operations | Owns agent workflow requirements and deal/refund policies |
| Customer Support Engineering | Owns and maintains the PizzaNG service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 12.22.12 | inventory |
| Framework | I-Tier | 7.9.2 | inventory |
| Runtime | Node.js | 12.22.12 | inventory |
| Build tool | webpack | 4.42.0 | inventory |
| Package manager | npm | | inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.9.2 | http-framework | I-Tier server runtime and BFF routing |
| preact | 10.5.13 | ui-framework | Lightweight React-compatible UI rendering (legacy path) |
| react | 16.13.0 | ui-framework | React UI shell and component tree |
| redux | 4.0.4 | state-management | Client-side state management for agent UI |
| axios | 0.18.0 | http-framework | HTTP client for Cyclops and other integrations |
| @grpn/graphql | 3.1.0 | http-framework | Groupon GraphQL client utilities |
| express | 4.14.0 | http-framework | Express router underpinning BFF API routes |
| itier-instrumentation | 9.10.4 | metrics | Observability and metrics instrumentation |
| gofer | 3.5.1 | http-framework | HTTP client for CAAP, Deal Catalog, Lazlo, CFS, Zendesk integrations |
| keldor | 7.3.8 | http-framework | I-Tier proxy and middleware utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
