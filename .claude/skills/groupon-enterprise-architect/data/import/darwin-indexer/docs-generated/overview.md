---
service: "darwin-indexer"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Search / Relevance"
platform: "Continuum"
team: "Relevance Platform Team"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Dropwizard"
  framework_version: "1.3.25"
  runtime: "JVM"
  runtime_version: "8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# darwin-indexer Overview

## Purpose

darwin-indexer is a scheduled batch indexing service that builds and maintains Elasticsearch indexes for Groupon's deal and hotel offer search experiences. It aggregates data from multiple upstream catalog, taxonomy, geo, merchant, and inventory services, enriches each document with badges and review signals, and writes fully-denormalized documents into Elasticsearch. It also publishes item-level intrinsic feature events to the Holmes platform via Kafka to support machine-learning ranking pipelines.

## Scope

### In scope

- Scheduled full and incremental indexing of deal documents into Elasticsearch
- Scheduled full and incremental indexing of hotel offer documents into Elasticsearch
- Aggregation and enrichment of deal data from Deal Catalog, Taxonomy, Geo, Merchant, Inventory, Badges, UGC Review, and Merchant Place services
- Blue/green index alias switchover to enable zero-downtime index rebuilds
- Publication of `ItemIntrinsicFeatureEvent` messages to Kafka (Holmes platform)
- Reading item feature data from Watson Feature Bucket (S3)
- Reading sponsored/feature data from Redis cache
- Exposing admin metrics and health checks on port 9001 via Dropwizard admin interface

### Out of scope

- Serving search queries (handled by Elasticsearch and downstream search services)
- Deal authoring or catalog management (handled by Deal Catalog service)
- Hotel offer catalog management (handled by Hotel Offer Catalog service)
- ML model training (handled by Holmes platform)
- Real-time user-facing API endpoints (this service is indexing-only)

## Domain Context

- **Business domain**: Search / Relevance
- **Platform**: Continuum
- **Upstream consumers**: Search services and ranking pipelines that query the Elasticsearch indexes; Holmes platform consuming `ItemIntrinsicFeatureEvent` events
- **Downstream dependencies**: Deal Catalog, Taxonomy, Geo, Merchant API, Inventory, Badges, UGC Review, Merchant Place, Hotel Offer Catalog, Redis Cache, Elasticsearch, Kafka, Watson Feature Bucket (S3), PostgreSQL

## Stakeholders

| Role | Description |
|------|-------------|
| Relevance Platform Team | Owns and operates darwin-indexer; responsible for index health and freshness |
| Search Engineers | Consume Elasticsearch indexes produced by this service |
| Holmes / ML Team | Consume `ItemIntrinsicFeatureEvent` events for ranking model training and inference |
| Merchant-facing teams | Indirectly depend on correct indexing for deal discoverability |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | Inventory summary |
| Framework | Dropwizard | 1.3.25 | Inventory summary |
| Runtime | JVM | 8 | Inventory summary |
| Build tool | Maven | — | Inventory summary |
| Package manager | Maven | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Elasticsearch | 5.6.16 | db-client | Primary index write target; document storage and search |
| Lucene | 6.6.1 | db-client | Underlying Elasticsearch engine; used for query/analysis primitives |
| RxJava | 1.0.14 | async | Reactive pipeline composition for parallel data fetching and enrichment |
| Retrofit2 | 2.3.0 | http-framework | HTTP client for calling upstream REST services (Deal Catalog, Merchant API, etc.) |
| Jackson | 2.13.2 | serialization | JSON serialization/deserialization of index documents and API responses |
| Dropwizard Metrics | 4.1.8 | metrics | Operational metrics export (counters, gauges, timers) |
| PostgreSQL | 9.4.1208 | db-client | Indexer metadata storage (index run state, offsets, audit) |
| Quartz | — | scheduling | Cron-based job scheduling for full and incremental index runs |
| Joda-Money | 0.10.0 | validation | Currency and money value handling in deal documents |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
