---
service: "relevance-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumRelevanceApi, continuumFeynmanSearch]
---

# Architecture Context

## System Context

The Relevance Service sits within the Continuum Platform (`continuumSystem`) as the primary search and browse aggregation layer. It receives search requests from consumer-facing applications (routed through the API Proxy), queries underlying search providers for deal results, applies relevance scoring and ranking, and returns ordered results. It depends on the Enterprise Data Warehouse (EDW) for feature data used by its ranking models, and is progressively migrating search workloads to the Booster engine.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Relevance API (RAPI) | `continuumRelevanceApi` | Service | Java / Vert.x | -- | Primary API gateway for search and browse aggregation, orchestrating requests to underlying search providers for Continuum |
| Feynman Search | `continuumFeynmanSearch` | Service | Java / Elasticsearch | -- | Legacy search service for browse and search functionality; to be fully replaced by Booster |

## Components by Container

### Relevance API (RAPI) (`continuumRelevanceApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Ranking Engine (`relevance_rankingEngine`) | Rank search results using ML models and feature vectors | Java |
| Features Client (`relevance_featuresClient`) | Fetch feature vectors from the Enterprise Data Warehouse for ranking model input | Java |
| Indexer (`relevance_indexer`) | Build and maintain search indexes from ingested data | Worker |
| Feynman Search (`relevance_feynmanSearch`) | Elasticsearch-powered search within Relevance; being replaced by Booster (partial today) | Java / Elasticsearch |

### Feynman Search (`continuumFeynmanSearch`)

No internal components are modeled for this container. It is a standalone Elasticsearch-backed search service marked for decommission.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRelevanceApi` | `continuumFeynmanSearch` | Search (Elasticsearch) | REST (SyncAPI) |
| `relevance_rankingEngine` | `relevance_featuresClient` | Fetch features | Internal |
| `relevance_featuresClient` | `edw` | Read features | Batch |
| `relevance_indexer` | `edw` | Train/ingest | Batch |
| `relevance_feynmanSearch` | `booster` | Offload ranking/search (partial, growing) | API |
| `rapiTeam` | `continuumRelevanceApi` | Owns and operates | Ownership |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-relevance`
- Component: `components-relevance-api`
