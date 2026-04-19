---
service: "wolfhound-api"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "SEO Content Management"
platform: "Continuum"
team: "MEI (nmallesh)"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Wolfhound API Overview

## Purpose

Wolfhound API is Groupon's SEO content management and serving REST API. It owns the full lifecycle of SEO pages — creation, versioning, scheduling, publishing, and runtime enrichment — as well as the management of templates, taxonomies, traffic rules, redirects, tags, and mobile page payloads. It sits at the intersection of content authoring and consumer-facing page rendering within the Continuum platform.

## Scope

### In scope

- CRUD and publish operations for SEO pages (v2 and v3)
- Page versioning, scheduling, and publish-state management
- Template management and Handlebars-based rendering
- Taxonomy hierarchy composition and bootstrap
- Traffic rules and redirect management
- Tag and blogger management
- Mobile page payload assembly (Relevance API integration)
- Deals cluster navigation content fetching
- Experiment/feature-flag evaluation via Expy/Optimizely
- Email subscription form submission to Salesforce Marketing Cloud
- Runtime in-memory cache warm-up and refresh for published pages

### Out of scope

- Consumer-facing HTML rendering (handled downstream by rendering services)
- Taxonomy source-of-truth data (owned by `continuumTaxonomyService`)
- Experiment definition and configuration (owned by `continuumExpyService`)
- Deal/offer data (owned by `continuumDealsClusterService` and `continuumLpapiService`)
- Audience/targeting rule definition (owned by `continuumConsumerAuthorityService`)

## Domain Context

- **Business domain**: SEO Content Management
- **Platform**: Continuum
- **Upstream consumers**: SEO authoring tools, internal CMS operators, and downstream page-serving services that query published page state
- **Downstream dependencies**: Wolfhound Postgres, Relevance API, Deals Cluster, LPAPI, Consumer Authority, Taxonomy v2, Expy/Optimizely, Salesforce Marketing Cloud

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | nmallesh (MEI team) |
| SEO/Content Editors | Consume the API to author and publish pages |
| Platform Architects | Reference `continuumWolfhoundApi` in the central C4 model |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `architecture/models/components/continuumWolfhoundApi.dsl` |
| Framework | Dropwizard / JTier | 5.14.0 | Service summary |
| Runtime | JVM | 17 | Service summary |
| Build tool | Maven | — | Service summary |
| Package manager | Maven | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | — | db-client | JTier managed PostgreSQL datasource integration |
| jtier-jdbi3 | — | orm | JDBI 3 SQL object binding for DAO layer |
| jtier-retrofit | — | http-framework | Managed Retrofit HTTP client factory for external calls |
| handlebars | 4.3.0 | ui-framework | Server-side template rendering for page content |
| json-patch | 1.13 | validation | RFC 6902 JSON Patch support for partial page updates |
| mbus-client | — | message-client | MBus messaging client (imported; not directly active in observed flows) |
| finch | 4.0.31 | metrics | Internal metrics and instrumentation library |
| jackson | 2.17.3 | serialization | JSON serialization/deserialization |
| testcontainers | 1.17.1 | testing | Integration test container lifecycle management |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
