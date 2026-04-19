---
service: "lpapi"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for LPAPI (SEO Landing Page API).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Landing Page CRUD](landing-page-crud.md) | synchronous | API call | Create, read, update, or delete a landing page record and its associated routes, crosslinks, and attribute metadata |
| [Auto-Index Analysis Job](auto-index-analysis-job.md) | scheduled | Scheduled job / manual trigger | Background worker evaluates landing pages for indexability using relevance signals and optionally GSC metrics, then persists recommendations |
| [UGC Worker Sync](ugc-worker-sync.md) | scheduled | Scheduled job | Background worker fetches merchant UGC reviews and upserts normalized review records into the LPAPI store |
| [Taxonomy Sync and Category Management](taxonomy-sync-and-category-management.md) | synchronous | API call / operator action | Imports and synchronizes taxonomy category data from the Taxonomy Service into LPAPI's category store |
| [Route Resolution and URL Mapping](route-resolution-and-url-mapping.md) | synchronous | API call | Resolves an incoming URL path to a landing page route model using the routing state engine |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Auto-Index Analysis Job** spans `continuumLpapiAutoIndexer` and `continuumRelevanceApi`. See the `autoIndexFlow` dynamic view in the architecture model.
- **UGC Worker Sync** spans `continuumLpapiUgcWorker`, `continuumRelevanceApi`, and `continuumUgcService`. See the `ugcSyncFlow` dynamic view in the architecture model.
- **Taxonomy Sync** spans `continuumLpapiApp` and `continuumTaxonomyService`.
