---
service: "wolfhound-api"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Wolfhound API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Page Publish Flow](page-publish.md) | synchronous | API call to `POST /wh/v2/pages/{id}/publish` or `POST /wh/v3/pages/{id}/publish` | Publishes a page version, validates external dependencies, persists publish state, and refreshes in-memory caches |
| [Page Retrieval and Enrichment Flow](page-retrieval-enrichment.md) | synchronous | API call to `GET /wh/v2/pages/{id}`, `GET /wh/v3/pages/{id}`, or `GET /wh/v2/mobile` | Retrieves a page record and enriches it with data from Relevance API, Deals Cluster, Consumer Authority, and Expy before returning to caller |
| [Taxonomy Bootstrap Flow](taxonomy-bootstrap.md) | batch | Service startup or manual `POST /wh/v2/taxonomies` trigger | Fetches the full category hierarchy from Taxonomy Service, persists entries to Wolfhound Postgres, and seeds the runtime taxonomy cache |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The Page Publish Flow spans `continuumWolfhoundApi`, `continuumLpapiService`, and `continuumExpyService` for dependency validation. It is modeled as a dynamic view in the architecture repository:

- Architecture dynamic view: `dynamic-wolfhound-page-publish-flow`
