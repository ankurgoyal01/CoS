---
service: "relevance-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Relevance Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Search Query Processing](search-query-processing.md) | synchronous | API request | End-to-end flow from search query receipt through Elasticsearch lookup to ranked result delivery |
| [Relevance Scoring](relevance-scoring.md) | synchronous | Search query (sub-flow) | Ranking Engine applies ML models using EDW feature vectors to score and rank candidate results |
| [Elasticsearch Index Rebuild](elasticsearch-index-rebuild.md) | batch | Scheduled / manual | Indexer ingests data from EDW and rebuilds Elasticsearch indexes for fresh search results |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Consumer Search Flow**: The end-to-end consumer search experience spans API Proxy -> Relevance API (RAPI) -> Feynman Search / Booster. The cross-service runtime flow involving API Proxy and Lazlo is modeled centrally in `views/runtime/continuum-runtime.dsl`.
- **Booster Migration Flow**: Progressive traffic migration from Feynman Search to Booster is managed via feature flags and traffic splitting at the RAPI level.
