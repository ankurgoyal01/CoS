---
service: "seo-deal-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSeoDealApiService", "continuumSeoDealPostgres"]
---

# Architecture Context

## System Context

SEO Deal API (`continuumSeoDealApiService`) is a service within the **Continuum Platform** (`continuumSystem`) — Groupon's core commerce engine. It occupies the SEO data layer between Groupon's deal catalog and search engine indexing infrastructure. The service receives reads and writes from `seo-admin-ui` (admin console), bulk redirect uploads from the `seo-deal-redirect` Airflow pipeline, noindex requests from `ingestion-jtier` (deal ingestion), and serves enriched deal SEO data assembled from multiple upstream Continuum services. It writes to its own PostgreSQL store and pushes indexing updates to external services (IndexNow, Google Search Console) and creates Jira issues for operational tracking.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEO Deal API Service | `continuumSeoDealApiService` | Backend service | Java, Dropwizard | Not specified | Provides SEO deal pages, sitemaps, redirects, and related orchestration |
| SEO Deal Database | `continuumSeoDealPostgres` | Database | PostgreSQL | Not specified | Stores SEO deal data, redirects, queues, and history |

## Components by Container

### SEO Deal API Service (`continuumSeoDealApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`seoDealApi_apiResources`) | HTTP resources for SEO deals, sitemaps, redirects, and index updates | Dropwizard/JAX-RS |
| Orchestrator (`orchestrator`) | Coordinates retrieval and assembly of SEO deal data from multiple downstream services | Java |
| SEO Data DAO (`seoDataDao`) | Persists and reads SEO deal data from the PostgreSQL store | JDBI |
| Deal Catalog Client (`seoDealApi_dealCatalogClient`) | HTTP client for fetching deal catalog data | HTTP client |
| Taxonomy Client (`seoDealApi_taxonomyClient`) | HTTP client for fetching taxonomy/category data | HTTP client |
| Inventory Client (`seoDealApi_inventoryClient`) | HTTP client for fetching inventory data | HTTP client |
| Landing Page Client (`landingPageClient`) | HTTP client for fetching landing page data | HTTP client |
| Coupon Client (`couponClient`) | HTTP client for fetching coupon data | HTTP client |
| M3 Client (`m3Client`) | HTTP client for fetching place/location data | HTTP client |
| IndexNow Client (`indexNowClient`) | Client for submitting URL updates to IndexNow | HTTP client |
| Jira Client (`seoDealApi_jiraClient`) | Client for creating Jira issues | HTTP client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSeoDealApiService` | `continuumSeoDealPostgres` | Reads and writes SEO deal data | JDBC / SQL |
| `continuumSeoDealApiService` | `continuumDealCatalogService` | Reads deal catalog data | REST/HTTP |
| `continuumSeoDealApiService` | `continuumTaxonomyService` | Reads taxonomy data | REST/HTTP |
| `continuumSeoDealApiService` | `continuumInventoryService` | Reads inventory data | REST/HTTP |
| `continuumSeoDealApiService` | `continuumM3PlacesService` | Reads place data | REST/HTTP |
| `continuumSeoDealApiService` | `continuumJiraService` | Creates Jira issues | REST/HTTP |
| `seoDealApi_apiResources` | `orchestrator` | Delegates request orchestration | Direct (in-process) |
| `orchestrator` | `seoDataDao` | Reads and writes SEO deal data | Direct (in-process) |
| `orchestrator` | `seoDealApi_dealCatalogClient` | Fetches deal catalog data | Direct (in-process) |
| `orchestrator` | `seoDealApi_taxonomyClient` | Fetches taxonomy data | Direct (in-process) |
| `orchestrator` | `seoDealApi_inventoryClient` | Fetches inventory data | Direct (in-process) |
| `orchestrator` | `landingPageClient` | Fetches landing page data | Direct (in-process) |
| `orchestrator` | `couponClient` | Fetches coupon data | Direct (in-process) |
| `orchestrator` | `m3Client` | Fetches place data | Direct (in-process) |
| `seoDealApi_apiResources` | `indexNowClient` | Submits URL updates to IndexNow | Direct (in-process) |
| `seoDealApi_apiResources` | `seoDealApi_jiraClient` | Creates Jira issues | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuumSeoDealApiService`
- Container: `containers-continuumSeoDealApiService`
- Component: `components-seoDealApiServiceComponents`
