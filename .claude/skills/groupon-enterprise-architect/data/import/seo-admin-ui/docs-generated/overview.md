---
service: "seo-admin-ui"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Search Engine Optimization"
platform: "continuum"
team: "SEO Engineering"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js ^20"
  framework: "I-Tier"
  framework_version: "7.9.3"
  runtime: "Node"
  runtime_version: "20.19.4"
  build_tool: "npm + webpack"
  package_manager: "npm"
---

# SEO Admin UI Overview

## Purpose

seo-admin-ui is the internal admin console for Groupon's SEO Engineering team, built on the Continuum I-Tier platform. It provides tooling to create and manage SEO tasks, update canonical URLs, manage landing page routes, handle SEO deal attributes, submit URL removal requests, and analyse page crosslinks. The service acts as the primary operator interface for all SEO configuration and workflow management on the Continuum platform.

## Scope

### In scope

- Landing page route CRUD (create, read, update, delete)
- Canonical URL update management
- SEO deal attributes management and page generation
- URL removal request submission and tracking
- Auto-index worker orchestration
- Page route auditing against live routes
- Crosslinks analysis and visualization (powered by Neo4j and D3)
- Integration with Google Search Console API for indexing signals
- Health endpoint exposure at `/status.json`

### Out of scope

- Public-facing SEO page rendering (handled by landing page services)
- Deal catalog data ownership (consumed from Deal Catalog via GraphQL)
- Keyword data storage (consumed from Keyword KB API)
- Content authoring (delegated to MECS)

## Domain Context

- **Business domain**: Search Engine Optimization
- **Platform**: Continuum
- **Upstream consumers**: SEO engineers and content operators (browser-based admin UI)
- **Downstream dependencies**: Google Search Console API, MECS, SEO Checkoff Service, LPAPI, Deal Catalog (GraphQL), SEO Deal API, Keyword KB API, Neo4j, Memcached

## Stakeholders

| Role | Description |
|------|-------------|
| SEO Engineers | Primary users; manage canonical updates, URL removal requests, and page audits |
| Content Operators | Manage landing page routes and SEO deals through the admin UI |
| Platform / SRE | Responsible for deployment, uptime, and observability |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^20 | package.json engines field |
| Framework | I-Tier (itier-server) | 7.9.3 | package.json dependency |
| Runtime | Node | 20.19.4 | .nvmrc / package.json engines |
| Build tool | webpack | 5.91.0 | package.json devDependency |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.9.3 | http-framework | I-Tier server runtime and routing |
| preact | 10.5.14 | ui-framework | Lightweight React-compatible UI rendering |
| @grpn/lpapi-client | 1.9.18 | http-client | Client for Landing Page API (LPAPI) |
| @grpn/graphql-gapi | 5.2.9 | http-client | GraphQL client for Deal Catalog (GAPI) |
| itier-instrumentation | 9.13.4 | metrics | Service instrumentation and telemetry |
| itier-tracing | 1.9.1 | metrics | Distributed tracing integration |
| keldor-config | 4.23.2 | config | Centralised Continuum config management |
| itier-feature-flags | 3.1.2 | config | Runtime feature flag evaluation |
| @grpn/neo4j-seo | 1.0.3 | db-client | Neo4j client for page ranking and crosslinks |
| itier-user-auth | 8.1.0 | auth | I-Tier session-based user authentication |
| d3 | 6.7.0 | ui-framework | Crosslinks graph visualization |
| seo-deal-page | 4.11.4 | http-framework | SEO deal page rendering library |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
