---
service: "seo-deal-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 5
---

# Integrations

## Overview

SEO Deal API depends on five internal Continuum services for data enrichment and three external services for search engine indexing and operational workflows. All dependencies are consumed via synchronous REST/HTTP calls. Internal service clients are implemented as dedicated HTTP client components within the service. External integrations (IndexNow, Google Search Console, Jira) are accessed via dedicated client components in the API Resources layer. Two internal dependencies (landingPageService, couponService) are modeled as stubs only — they are referenced in the component model but not in the federated architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| IndexNow | rest | Submits URL updates to notify search engines of content changes | no | `indexNowService` (stub only) |
| Google Search Console | rest | Submits indexing requests for new and updated deal URLs | no | `googleSearchConsole` (stub only) |
| Jira | rest | Creates Jira issues for SEO operational tracking | no | `continuumJiraService` |

### IndexNow Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Not specified in available source evidence (stub only in federated model)
- **Auth**: Not specified in available source evidence
- **Purpose**: Notify search engines (Bing, Yandex, etc.) of URL updates when deal SEO data changes, via the IndexNow protocol
- **Failure mode**: Non-critical; IndexNow submission failure does not block deal attribute writes
- **Circuit breaker**: Not specified in available source evidence

### Google Search Console Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Not specified in available source evidence (stub only in federated model)
- **Auth**: Not specified in available source evidence
- **Purpose**: Submit indexing requests for deal URLs to Google's indexing API
- **Failure mode**: Non-critical; indexing request failure does not block deal attribute writes
- **Circuit breaker**: Not specified in available source evidence

### Jira Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Not specified in available source evidence; referenced as `continuumJiraService`
- **Auth**: Not specified in available source evidence
- **Purpose**: Creates Jira issues for SEO-related operational events and tracking
- **Failure mode**: Non-critical operational dependency
- **Circuit breaker**: Not specified in available source evidence

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | rest | Reads deal catalog data (title, permalink, UUID lookup) to assemble enriched SEO deal responses | `continuumDealCatalogService` |
| Taxonomy Service | rest | Reads taxonomy/category data for deal enrichment and redirect suggestion | `continuumTaxonomyService` |
| Inventory Service | rest | Reads inventory data for deal enrichment | `continuumInventoryService` |
| M3 Places Service | rest | Reads place/location data for geo-enriched SEO deal pages | `continuumM3PlacesService` |
| Landing Page Service | rest | Reads landing page data (stub only — not in federated model) | `landingPageService` |
| Coupon Service | rest | Reads coupon data (stub only — not in federated model) | `couponService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `seo-admin-ui` | REST/HTTP | Admin console for SEO analysts to read/write deal attributes, manage redirects, and handle URL removal |
| `seo-deal-redirect` | REST/HTTP (mTLS) | Automated Airflow pipeline uploads expired-to-live redirect mappings via bulk PUT requests |
| `ingestion-jtier` | REST/HTTP | Deal ingestion pipeline calls noindex disable endpoint during deal loading |
| `proxykong` | HTTP routing | API gateway routes external requests to this service (evidenced by proxykong route config referencing `seo-deal-api`) |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

No circuit breaker, retry, or health check configuration was found in the available architecture DSL source for seo-deal-api. The `seo-deal-redirect` pipeline implements client-side rate limiting (1250 calls/60s) and error handling per response. The `ingestion-jtier` consumer logs and swallows failures from the SEO client (`LOGGER.warn("failed_to_disable_seo_indexing")`), treating the SEO indexing call as non-critical.
