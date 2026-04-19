---
service: "seo-deal-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Content, Editorial & SEO"
platform: "Continuum"
team: "SEO"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Dropwizard"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# SEO Deal API Overview

## Purpose

SEO Deal API is the authoritative service for managing SEO-specific deal data within Groupon's Continuum platform. It stores, retrieves, and orchestrates SEO attributes for individual deals — including canonical URLs, redirect targets, noindex flags, and title overrides — and exposes this data to search-engine-facing consumers. The service also manages URL removal workflows and submits URL updates to external indexing services (IndexNow, Google Search Console) to keep search engine indexes aligned with deal lifecycle changes.

## Scope

### In scope

- Persisting and serving SEO attributes per deal (canonical URL, redirect URL, noindex flag, brand overrides, title attributes)
- Managing deal redirect entries: creating, updating, bulk-updating, and cancelling redirects for expired deals
- Providing processed redirect history with paginated query support (`startDate`, `endDate`, `page`, `pageSize`, `changedBy`, `redirectFrom`)
- Accepting automated redirect uploads from the `seo-deal-redirect` Airflow pipeline via PUT requests with mTLS authentication
- Managing URL removal request workflows: creation, approval, rejection, and per-request status updates
- Submitting URL batch update requests to IndexNow (`/index-now/request`)
- Creating Jira issues for SEO tracking via the Jira client
- Providing a noindex disable endpoint consumed by the deal ingestion pipeline (`ingestion-jtier`)
- Assembling enriched SEO deal data by orchestrating downstream services (Deal Catalog, Taxonomy, Inventory, M3 Places, Landing Pages, Coupons)

### Out of scope

- Consumer-facing deal rendering (handled by the `deal` frontend service)
- SEO admin UI workflows and presentation logic (handled by `seo-admin-ui`)
- Automated expired-to-live deal mapping computation (handled by `seo-deal-redirect` Airflow pipeline)
- Landing page management (handled by `lpapi`)
- Sitemap generation at the crawl infrastructure level

## Domain Context

- **Business domain**: Content, Editorial & SEO
- **Platform**: Continuum
- **Upstream consumers**: `seo-admin-ui` (admin console reads/writes deal SEO data via HTTP), `seo-deal-redirect` (automated redirect upload pipeline using mTLS PUT), `ingestion-jtier` (disables SEO indexing during deal ingestion via Retrofit/OkHttp)
- **Downstream dependencies**: `continuumSeoDealPostgres` (owned PostgreSQL database via JDBI), `continuumDealCatalogService`, `continuumTaxonomyService`, `continuumInventoryService`, `continuumM3PlacesService`, `continuumJiraService`, `landingPageService` (stub only), `couponService` (stub only), `indexNowService` (stub only), `googleSearchConsole` (stub only)

## Stakeholders

| Role | Description |
|------|-------------|
| SEO Team | Owns and operates the service; manages SEO attributes and redirect workflows |
| Computational SEO | Primary team channel (computational-seo@groupon.com); handles incidents and feature development |
| Deal Ingestion Team | Consumes the noindex disable endpoint during deal loading pipeline runs |
| SEO Admin UI users | SEO analysts who manage deal attributes, redirects, and URL removal via the admin console |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | Not specified in DSL | `architecture/models/components/seoDealApi.dsl` |
| Framework | Dropwizard / JAX-RS | Not specified in DSL | `architecture/models/components/seoDealApi.dsl` — "Java, Dropwizard" |
| Persistence client | JDBI | Not specified | `architecture/models/components/seoDealApi.dsl` — SEO Data DAO component uses JDBI |
| HTTP clients | Retrofit + OkHttp (inferred) | Not specified | `ingestion-jtier/src/main/java/.../SEOService.java` — Retrofit interface targeting seo-deal-api |
| Runtime | JVM | Not specified | Inferred from Java/Dropwizard stack |
| Build tool | Maven | Not specified | Inferred from Dropwizard/JTier project conventions |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dropwizard | Not specified | http-framework | REST framework providing embedded Jetty, JAX-RS, metrics, health checks, and config |
| JAX-RS | Not specified | http-framework | Annotation-based REST resource definitions for API endpoints |
| JDBI | Not specified | db-client | SQL query mapping and DAO abstraction over PostgreSQL |
| Retrofit | Not specified | http-client | HTTP client interface used by `ingestion-jtier` to call seo-deal-api |
| OkHttp | Not specified | http-client | Underlying HTTP transport for service-to-service calls |
| OpenSSL / PKCS12 | Not specified | auth | mTLS certificate authentication for inbound requests from `seo-deal-redirect` pipeline |
| Gofer | Not specified | http-client | HTTP client used by `seo-admin-ui` to call seo-deal-api (evidenced in `deal-server-client/client.js`) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
