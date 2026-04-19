---
service: "minos"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMinosService, continuumMinosPostgres, continuumMinosRedis]
---

# Architecture Context

## System Context

Minos is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It sits in the 3PIP ingestion pipeline, receiving deal payloads from upstream ingestion processes and returning duplicate deal IDs. Minos depends on several other Continuum services (Deal Catalog, Lazlo, Universal Merchant API, Taxonomy, Relevance) for enrichment and candidate retrieval, as well as external platforms (Flux/DS for ML scoring, HDFS/S3 for file-based data exchange, Cerebro for recall lookup). Minos owns two backing stores: a PostgreSQL database and a Redis cache.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Minos Service | `continuumMinosService` | Backend service | Java 11, Dropwizard | JTier 5.14.1 | Dropwizard/JTier service for duplicate-deal detection, scoring orchestration, and recall lookup APIs |
| Minos PostgreSQL | `continuumMinosPostgres` | Database | PostgreSQL | — | Primary transactional store for deals, duplicate scores, partner configs, and recall lookup mappings |
| Minos Redis Cache | `continuumMinosRedis` | Cache | Redis (RaaS) | — | Cache for external API responses and hot lookup data |

## Components by Container

### Minos Service (`continuumMinosService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `minos_httpApi` | REST resources for duplicate lookup, overrides, recall lookup, Quartz trigger, and Flux report endpoints | JAX-RS |
| `minos_coreServices` | Domain orchestration for ingestion persistence, duplicate matching, taxonomy enrichment, and recall lookup updates | Java Services |
| `minos_integrations` | HTTP/HDFS/S3 clients for Deal Catalog, Lazlo, Merchant, Taxonomy, Relevance, DS, and Cerebro dependencies | JTier HTTP Clients |
| `minos_persistence` | JDBI DAOs and Flyway-backed schema access for core entities | JDBI / PostgreSQL |
| `minos_scheduler` | Scheduled scoring refresh workflow that prepares and submits DS jobs | Quartz |
| `minos_cache` | Redis-backed caching wrappers for upstream client responses | Jedis |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMinosService` | `continuumMinosPostgres` | Stores deals, duplicate matches, configs, and recall lookup data | JDBC |
| `continuumMinosService` | `continuumMinosRedis` | Caches upstream API responses | Redis |
| `continuumMinosService` | `continuumDealCatalogService` | Reads launched deals and deal details | REST/HTTP |
| `continuumMinosService` | `continuumApiLazloService` | Loads deal metadata and merchant references | REST/HTTP |
| `continuumMinosService` | `continuumUniversalMerchantApi` | Reads merchant details | REST/HTTP |
| `continuumMinosService` | `continuumTaxonomyService` | Loads category and relationship taxonomy | REST/HTTP |
| `continuumMinosService` | `continuumRelevanceApi` | Queries deal search index for candidate duplicates | REST/HTTP |
| `continuumMinosService` | `hdfsStorage` | Loads recall lookup source data and Flux scoring artifacts | HDFS |
| `minos_httpApi` | `minos_coreServices` | Invokes service workflows for API requests | Direct |
| `minos_coreServices` | `minos_persistence` | Reads/writes deal and configuration state | JDBI |
| `minos_coreServices` | `minos_integrations` | Calls upstream systems for enrichment and scoring | HTTP |
| `minos_coreServices` | `minos_cache` | Reads/writes cached upstream responses | Redis |
| `minos_scheduler` | `minos_coreServices` | Triggers scheduled scoring refresh pipeline | Direct |
| `minos_scheduler` | `minos_integrations` | Submits DS jobs and exchanges scoring artifacts | HTTP/HDFS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-minos-service`
- Dynamic (dedupe flow): `dynamic-minos-dedupe-flow`
