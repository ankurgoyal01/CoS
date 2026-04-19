---
service: "wolf-hound"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Content / Editorial"
platform: "Continuum"
team: "Content/Editorial Platform"
status: active
tech_stack:
  language: "JavaScript"
  language_version: ""
  framework: "Express"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "npm"
  package_manager: "npm"
---

# Wolfhound Editor UI Overview

## Purpose

Wolfhound Editor UI (`wolf-hound`) is the backend-for-frontend (BFF) web application that powers Groupon's editorial page management tooling. It provides a server-side Express application that both serves the editorial UI shell and exposes BFF API routes, delegating all persistence and business logic to the Wolfhound API backend. The service enables content editors to create, schedule, publish, and manage editorial pages and templates across the Continuum platform.

## Scope

### In scope

- Serving the Vue.js workboard application shell and legacy Backbone/Hogan-rendered editorial pages
- BFF API routing for page CRUD, template management, scheduling, and publishing operations
- BFF API routing for taxonomy and cluster rule operations
- Request orchestration — aggregating responses from multiple upstream services (Wolfhound API, LPAPI, MECS, Deals, Clusters, Users) into editor-ready payloads
- User authentication and permission checks delegated to the Users API
- Session and group-based access control for editorial operations

### Out of scope

- Persistence of editorial content (owned by `continuumWolfhoundApi`)
- Deal and product data management (owned by `continuumMarketingDealService` and `continuumDealsClusterService`)
- Image and tag metadata storage (owned by `continuumMarketingEditorialContentService`)
- Geolocation and division metadata (owned by `continuumBhuvanService`)
- Relevance ranking logic (owned by `continuumRelevanceApi`)

## Domain Context

- **Business domain**: Content / Editorial
- **Platform**: Continuum
- **Upstream consumers**: Editorial content authors and administrators accessing the Wolfhound web UI
- **Downstream dependencies**: `continuumWolfhoundApi`, `continuumWhUsersApi`, `continuumLpapiService`, `continuumMarketingEditorialContentService`, `continuumMarketingDealService`, `continuumDealsClusterService`, `continuumRelevanceApi`, `continuumBhuvanService`

## Stakeholders

| Role | Description |
|------|-------------|
| Content Editor | Primary user; creates, edits, schedules, and publishes editorial pages |
| Editorial Admin | Manages templates, taxonomies, and group permissions |
| Content/Editorial Platform Team | Owns and operates the service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | — | `architecture/models/components/continuumWolfHound.dsl` |
| Framework | Express | — | `architecture/models/components/continuumWolfHound.dsl` |
| Runtime | Node.js | — | `architecture/models/components/continuumWolfHound.dsl` |
| Build tool | npm | — | Node.js ecosystem standard |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Express | — | http-framework | HTTP server and BFF routing |
| Vue.js | — | ui-framework | Workboard frontend SPA shell |
| Axios | — | http-framework | Frontend HTTP client for BFF API calls |
| Backbone | — | ui-framework | Legacy frontend models and views |
| Hogan | — | ui-framework | Server-side template rendering for legacy pages |
| request / request-promise | — | http-framework | Outbound HTTP client for upstream service calls |

Categories: `http-framework`, `ui-framework`

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
