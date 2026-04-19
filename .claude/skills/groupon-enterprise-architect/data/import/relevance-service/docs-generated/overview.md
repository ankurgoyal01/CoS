---
service: "relevance-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search & Relevance"
platform: "Continuum"
team: "RAPI Team"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Vert.x"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Gradle"
  package_manager: "Gradle"
---

# Relevance Service Overview

## Purpose

The Relevance Service is the primary search and browse aggregation layer within the Continuum Platform. It receives search queries from consumer-facing applications via the API Proxy, orchestrates them through underlying search providers (Feynman Search / Elasticsearch and the next-generation Booster engine), applies machine-learned ranking and relevance scoring models, and returns ranked deal results. The service exists to ensure that consumers see the most relevant deals when browsing or searching on Groupon.

## Scope

### In scope

- Receiving and processing search and browse queries from upstream API consumers
- Orchestrating queries to Feynman Search (Elasticsearch) for deal lookup
- Applying machine-learned ranking models via the Ranking Engine component
- Fetching feature vectors from the Enterprise Data Warehouse (EDW) for ranking model input
- Building and maintaining search indexes via the Indexer component
- Progressively offloading ranking and search workloads to the Booster engine
- Returning relevance-scored, ranked deal results to upstream callers

### Out of scope

- Deal creation, modification, or lifecycle management (handled by Deal Service, Deal Management API)
- Autocomplete and typeahead functionality (handled by Autocomplete Service)
- Travel-specific search flows (handled by Travel Search)
- Consumer authentication and session management (handled by Consumer Authority)
- Deal content rendering or page assembly (handled by Layout Service, Lazlo)

## Domain Context

- **Business domain**: Search & Relevance (Continuum Commerce Platform)
- **Platform**: Continuum
- **Upstream consumers**: API Proxy, consumer-facing web and mobile applications via API gateway
- **Downstream dependencies**: Feynman Search (Elasticsearch), Booster (next-gen search/ranking), Enterprise Data Warehouse (EDW)

## Stakeholders

| Role | Description |
|------|-------------|
| RAPI Team | Owning team; responsible for development, deployment, and on-call operations |
| Search & Discovery | Product stakeholders responsible for search quality and relevance metrics |
| Consumer Platform teams | Upstream consumers relying on accurate, fast search results |
| Data Science / ML | Teams providing ranking models and feature engineering for relevance scoring |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | -- | Architecture DSL (`Java / Vert.x`, `Java / Elasticsearch`) |
| Framework | Vert.x | -- | Architecture DSL container technology |
| Runtime | JVM | -- | Inferred from Java / Vert.x stack |
| Build tool | Gradle | -- | Standard for Continuum Java services |
| Package manager | Gradle | -- | -- |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Vert.x Core | -- | http-framework | Reactive, non-blocking HTTP server and event loop |
| Elasticsearch Client | -- | db-client | Client for querying Feynman Search Elasticsearch clusters |
| ML Ranking Libraries | -- | other | Machine-learned ranking model execution for relevance scoring |

Categories: `http-framework`, `orm`, `db-client`, `message-client`, `auth`, `logging`, `metrics`, `serialization`, `testing`, `ui-framework`, `state-management`, `validation`, `scheduling`

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. Exact versions are not available from architecture DSL alone; see the source repository dependency manifest for a full list.
