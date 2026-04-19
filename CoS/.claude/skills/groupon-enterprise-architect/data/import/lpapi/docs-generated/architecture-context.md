---
service: "lpapi"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLpapiApp, continuumLpapiAutoIndexer, continuumLpapiUgcWorker, continuumLpapiPrimaryPostgres, continuumLpapiReadOnlyPostgres]
---

# Architecture Context

## System Context

LPAPI is a service within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It owns the data layer for SEO landing page URLs and exposes a REST API to internal consumers. Two companion background workers (`continuumLpapiAutoIndexer` and `continuumLpapiUgcWorker`) extend the system with scheduled enrichment pipelines. All three processes share a PostgreSQL primary/replica pair.

External dependencies include the `continuumTaxonomyService` for category data, `continuumRelevanceApi` for deal and merchant signals, and `continuumUgcService` for user-generated review content. An optional stub relationship to Google Search Console provides search performance metrics for indexability decisions.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| LPAPI App | `continuumLpapiApp` | API Process | Java, Dropwizard, JTier | Primary REST API process for landing page CRUD, routing logic, and SEO metadata operations |
| LPAPI Auto Indexer | `continuumLpapiAutoIndexer` | Background Worker | Java Worker | Evaluates landing pages and writes indexability analysis results |
| LPAPI UGC Worker | `continuumLpapiUgcWorker` | Background Worker | Java Worker | Fetches merchant UGC signals and writes normalized review data |
| LPAPI Primary Postgres | `continuumLpapiPrimaryPostgres` | Data Store | PostgreSQL | Primary datastore for LPAPI entities, page data, routes, and worker writes |
| LPAPI Read-Only Postgres | `continuumLpapiReadOnlyPostgres` | Data Store | PostgreSQL | Read replica used for read-heavy query paths |

## Components by Container

### LPAPI App (`continuumLpapiApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `appApiResources` | Exposes REST endpoints for landing page and metadata management | JAX-RS Resources |
| `appRoutingState` | Maps landing page URLs to route models; handles site/locale resolution | Routing Engine |
| `appDataAccess` | DAO and persistence adapters for pages, routes, taxonomy, and crosslinks | JDBI DAO |
| `appAutoIndexCoordinator` | Orchestration hooks to configure and launch auto-index runs | Worker Orchestration |
| `appUgcOrchestrator` | Orchestration hooks to configure and launch UGC synchronization | Worker Orchestration |

### LPAPI Auto Indexer (`continuumLpapiAutoIndexer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `autoIndexScheduler` | Schedules periodic analysis jobs and coordinates job lifecycle | Job Scheduler |
| `autoIndexCrawler` | Retrieves rendered landing pages from routing service for analysis inputs | Crawler |
| `autoIndexAnalyzer` | Analyzes page quality and deal signals by querying Relevance API | Analyzer |
| `autoIndexDataAccess` | Reads page metadata; writes analysis and job results to LPAPI stores | JDBI DAO |
| `autoIndexGscCollector` | Optionally enriches indexing decisions with Google Search Console metrics | Integration Adapter |

### LPAPI UGC Worker (`continuumLpapiUgcWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ugcSyncRunner` | Coordinates UGC synchronization cycles across configured locales and pages | Job Runner |
| `ugcRapiFetcher` | Fetches merchant/deal card context to identify UGC targets | Integration Adapter |
| `ugcServiceFetcher` | Calls UGC API endpoints to retrieve merchant review content | Integration Adapter |
| `ugcDataAccess` | Persists normalized UGC review payloads and lookup metadata | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLpapiApp` | `continuumLpapiPrimaryPostgres` | Reads/writes LPAPI operational data | JDBC |
| `continuumLpapiApp` | `continuumLpapiReadOnlyPostgres` | Reads LPAPI routing/search state | JDBC |
| `continuumLpapiApp` | `continuumTaxonomyService` | Imports and synchronizes taxonomy data | HTTP |
| `continuumLpapiApp` | `continuumRelevanceApi` | Uses relevance signals for landing page logic | HTTP |
| `continuumLpapiAutoIndexer` | `continuumLpapiPrimaryPostgres` | Writes auto-index jobs and results | JDBC |
| `continuumLpapiAutoIndexer` | `continuumLpapiReadOnlyPostgres` | Reads pages/routes for analysis | JDBC |
| `continuumLpapiAutoIndexer` | `continuumRelevanceApi` | Fetches deal cards for page analysis | HTTP |
| `continuumLpapiUgcWorker` | `continuumLpapiPrimaryPostgres` | Upserts UGC review records | JDBC |
| `continuumLpapiUgcWorker` | `continuumRelevanceApi` | Fetches merchant card context | HTTP |
| `continuumLpapiUgcWorker` | `continuumUgcService` | Fetches merchant UGC reviews | HTTP |

## Architecture Diagram References

- Component view (LPAPI App): `lpapiAppComponents`
- Component view (Auto Indexer): `lpapiAutoIndexerComponents`
- Component view (UGC Worker): `lpapiUgcWorkerComponents`
- Dynamic view (Auto Index flow): `autoIndexFlow`
- Dynamic view (UGC Sync flow): `ugcSyncFlow`
