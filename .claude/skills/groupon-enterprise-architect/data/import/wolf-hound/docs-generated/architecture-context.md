---
service: "wolf-hound"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumWolfHound]
---

# Architecture Context

## System Context

Wolfhound Editor UI (`continuumWolfHound`) is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It is the sole user-facing editorial tooling surface for content authors and sits at the boundary between human editors and a constellation of backend Continuum services. The UI shell and BFF API layer are both served from the same Node.js/Express process; there is no separate frontend CDN origin for the application shell.

Editors interact directly with the application via browser. All data operations fan out over HTTP to the relevant Continuum backend containers. There is no direct database ownership; all state is delegated downstream.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Wolfhound Editor UI | `continuumWolfHound` | WebApp / BFF | Node.js, Express, Vue.js | — | Serves the editorial UI shell and exposes BFF API routes for page, template, scheduling, and publishing operations |

## Components by Container

### Wolfhound Editor UI (`continuumWolfHound`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `routeControllers` | Express route handlers in `routes/*` that orchestrate editor endpoints and validate incoming requests | Express Routers |
| `domainServiceAdapters` | Service modules in `service/*` wrapping upstream APIs: Wolfhound API, Users, LPAPI, MECS, Deals, and Clusters | Node.js Service Layer |
| `outboundHttpClient` | Shared request and logging helpers managing HTTP verbs, error handling, and request instrumentation for all upstream calls | request / request-promise |
| `bffApiLayer` | Vue and legacy Backbone frontend API clients (under `src/api` and `public/js`) that call BFF endpoints for pages, templates, reports, editor actions, and scheduling | Vue.js + Axios + Backbone Models |
| `viewRenderingLayer` | Server-side template rendering and static asset hosting for legacy Hogan views and the Vue workboard app shell | Hogan + Express Static |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWolfHound` | `continuumWhUsersApi` | Validates users and manages groups/permissions | HTTP |
| `continuumWolfHound` | `continuumWolfhoundApi` | Reads and writes pages, templates, schedules, taxonomies, and reports | HTTP |
| `continuumWolfHound` | `continuumLpapiService` | Searches and updates LPAPI rules/pages | HTTP |
| `continuumWolfHound` | `continuumMarketingEditorialContentService` | Queries image and tag metadata | HTTP |
| `continuumWolfHound` | `continuumMarketingDealService` | Fetches deal divisions and deal details | HTTP |
| `continuumWolfHound` | `continuumDealsClusterService` | Loads cluster rules and top cluster content | HTTP |
| `continuumWolfHound` | `continuumRelevanceApi` | Queries deal cards and relevance search results | HTTP |
| `continuumWolfHound` | `continuumBhuvanService` | Fetches geoplaces division metadata | HTTP |
| `routeControllers` | `domainServiceAdapters` | Invokes domain service adapters for deal, LPAPI, groups, users, and content operations | direct |
| `domainServiceAdapters` | `outboundHttpClient` | Uses shared HTTP requester and request wrappers for upstream calls | direct |
| `bffApiLayer` | `routeControllers` | Calls BFF endpoints for pages, templates, reports, editor actions, and scheduling | direct |
| `bffApiLayer` | `viewRenderingLayer` | Loads server-rendered templates and static bundles for legacy pages and Vue app shell | direct |

## Architecture Diagram References

- Component: `components-wolf-hound`
- Dynamic publish flow: `dynamic-editorial-publish-flow`
