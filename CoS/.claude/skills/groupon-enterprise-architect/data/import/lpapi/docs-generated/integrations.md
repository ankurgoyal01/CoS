---
service: "lpapi"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

LPAPI has four downstream service dependencies: two internal Continuum services (`continuumTaxonomyService`, `continuumRelevanceApi`) and two external/platform services (`continuumUgcService`, Google Search Console). All integrations use synchronous HTTP/HTTPS. There is no async messaging in the integration layer. The Google Search Console dependency is currently stub-only in the federated model — the relationship exists but the target is not modeled as a full Continuum service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Search Console | HTTPS | Enriches indexability decisions with search performance metrics | no | stub only — `unknown_googlesearchconsole_035db05d` |

### Google Search Console Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Not modeled — stub only in federated architecture
- **Auth**: > No evidence found — likely API key or OAuth2 service account
- **Purpose**: The `autoIndexGscCollector` component in `continuumLpapiAutoIndexer` optionally fetches search performance metrics (impressions, clicks, position) to enrich per-page indexing recommendations
- **Failure mode**: Optional integration — auto-index analysis continues without GSC data if unavailable
- **Circuit breaker**: > No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service | HTTP | Import and synchronize taxonomy category data into LPAPI | `continuumTaxonomyService` |
| Relevance API (RAPI) | HTTP | Fetch deal card and merchant context for landing page logic and analysis | `continuumRelevanceApi` |
| UGC Service | HTTP | Retrieve merchant review payloads for UGC enrichment | `continuumUgcService` |

### Taxonomy Service (`continuumTaxonomyService`) Detail

- **Protocol**: HTTP
- **Base URL / SDK**: JTier Taxonomy Client (typed client library)
- **Auth**: Internal service-to-service
- **Purpose**: `continuumLpapiApp` calls the Taxonomy Service to import and sync taxonomy category hierarchies. These categories are stored in `continuumLpapiPrimaryPostgres` and used to classify landing pages. See [Taxonomy Sync and Category Management flow](flows/taxonomy-sync-and-category-management.md).
- **Failure mode**: Taxonomy sync may be delayed or skipped; existing stored categories remain available
- **Circuit breaker**: > No evidence found

### Relevance API (`continuumRelevanceApi`) Detail

- **Protocol**: HTTP
- **Base URL / SDK**: OkHttp client
- **Auth**: Internal service-to-service
- **Purpose**: Three consumers use RAPI:
  1. `continuumLpapiApp` — uses relevance signals in landing page response logic
  2. `continuumLpapiAutoIndexer` (`autoIndexAnalyzer`) — queries deal card availability to inform indexability analysis
  3. `continuumLpapiUgcWorker` (`ugcRapiFetcher`) — fetches merchant card context to identify UGC sync targets
- **Failure mode**: Landing page responses and analysis runs degrade gracefully; RAPI is a read-only signal source
- **Circuit breaker**: > No evidence found

### UGC Service (`continuumUgcService`) Detail

- **Protocol**: HTTP
- **Base URL / SDK**: OkHttp client
- **Auth**: Internal service-to-service
- **Purpose**: `continuumLpapiUgcWorker` (`ugcServiceFetcher`) fetches merchant review payloads from the UGC Service. Results are normalized and stored in `continuumLpapiPrimaryPostgres`. See [UGC Worker Sync flow](flows/ugc-worker-sync.md).
- **Failure mode**: UGC sync skipped for affected merchants; previously stored reviews remain
- **Circuit breaker**: > No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. LPAPI is an internal service used by SEO tooling, CMS operators, and automated SEO pipelines within the Continuum Platform.

## Dependency Health

> No evidence found for explicit circuit breaker or health check wiring in the federated architecture module. Retry and timeout behavior is likely configured via OkHttp client settings and JTier framework defaults in the service repository.
