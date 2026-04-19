---
service: "wolfhound-api"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumWolfhoundApi, continuumWolfhoundPostgres]
---

# Architecture Context

## System Context

Wolfhound API is a container within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It provides SEO content management capabilities to internal authoring tools and exposes published page state to downstream serving consumers. It depends on several other Continuum containers for data enrichment (Relevance API, Deals Cluster, LPAPI, Consumer Authority, Taxonomy) and integrates with the external Salesforce Marketing Cloud and Expy/Optimizely experimentation platform.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Wolfhound API | `continuumWolfhoundApi` | Backend service | Java, Dropwizard, JTier | 5.14.0 | SEO content management and serving API for pages, templates, schedules, taxonomies, traffic, and mobile page payloads |
| Wolfhound Postgres | `continuumWolfhoundPostgres` | Database | PostgreSQL | — | Primary relational datastore for pages, versions, schedules, templates, redirects, and metadata |

## Components by Container

### Wolfhound API (`continuumWolfhoundApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `wolfApi_apiResources` — API Resources Layer | Exposes JAX-RS v2/v3 endpoints for pages, publishing, templates, schedules, taxonomies, tags, traffic, mobile, and integrations | Dropwizard/Jersey Resources |
| `orchestrationServices` — Domain Services Layer | Core business logic for page lifecycle, publishing, scheduling, mobile rendering, taxonomy composition, experimentation, and integrations | Java Services |
| `wolfhoundApi_persistenceDaos` — Persistence Layer | JDBI DAO layer for CRUD and query operations on pages, versions, schedules, templates, redirects, bloggers, traffic, and tags | JDBI + SQL |
| `externalGatewayClients` — External Gateway Clients | Retrofit/HTTP clients for RAPI, Deals Cluster, LPAPI, Consumer Authority, Taxonomy, Expy APIs, and Salesforce endpoints | Retrofit + Apache HttpClient |
| `cacheAndBootstraps` — Cache and Bootstrapping | In-memory boot caches for published pages, subdirectories, and translations loaded at startup and refreshed during workflows | Executor Services + In-Memory Cache |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `wolfApi_apiResources` | `orchestrationServices` | Invokes page, publishing, schedule, taxonomy, and integration use cases | Direct (in-process) |
| `orchestrationServices` | `wolfhoundApi_persistenceDaos` | Reads and writes page/content domain state | Direct (in-process) |
| `orchestrationServices` | `externalGatewayClients` | Retrieves and updates data in external dependencies | Direct (in-process) |
| `orchestrationServices` | `cacheAndBootstraps` | Populates and refreshes runtime caches | Direct (in-process) |
| `cacheAndBootstraps` | `wolfhoundApi_persistenceDaos` | Loads and refreshes cached records from storage | Direct (in-process) |
| `continuumWolfhoundApi` | `continuumWolfhoundPostgres` | Reads and writes pages, templates, schedules, redirects, and traffic data | JDBI/JDBC |
| `continuumWolfhoundApi` | `continuumRelevanceApi` | Queries cards and facets for mobile and deal components | HTTP |
| `continuumWolfhoundApi` | `continuumDealsClusterService` | Fetches cluster navigation and top-cluster content | HTTP |
| `continuumWolfhoundApi` | `continuumLpapiService` | Resolves LPAPI page references and list queries | HTTP |
| `continuumWolfhoundApi` | `continuumConsumerAuthorityService` | Fetches audience membership and targeting attributes | HTTP |
| `continuumWolfhoundApi` | `continuumTaxonomyService` | Fetches category hierarchy and taxonomy metadata | HTTP |
| `continuumWolfhoundApi` | `continuumExpyService` | Evaluates and manages experiments | HTTP |
| `continuumWolfhoundApi` | `salesforceMarketingCloud` | Submits email subscription forms | HTTPS |

## Architecture Diagram References

- Component view: `components-wolfhound-api`
- Page publish dynamic view: `dynamic-wolfhound-page-publish-flow`
