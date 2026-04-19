---
service: "vespa-indexer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search / Relevance"
platform: "Continuum"
team: "relevance-infra@groupon.com"
status: active
tech_stack:
  language: "Python"
  language_version: "3.12"
  framework: "FastAPI"
  framework_version: "0.118.0"
  runtime: "Uvicorn"
  runtime_version: "0.24.0"
  build_tool: "Docker / Helm"
  package_manager: "pip"
---

# Vespa Indexer Overview

## Purpose

Vespa Indexer is a Python service that retrieves deal and option data from Groupon systems and feeds it to Vespa for search and recommendation. It operates in three modes: consuming real-time deal update events from MessageBus (STOMP), running scheduled full refreshes from MDS feed files stored in GCS, and streaming ML feature updates from BigQuery. The service ensures the Vespa search index remains consistent with the Groupon deal catalog and up to date with the latest ML ranking signals.

## Scope

### In scope

- Consuming deal-update messages from the Groupon MessageBus topic `jms.topic.mars.mds.genericchange` and indexing changes in Vespa
- Scheduled daily full deal refresh: streaming deal UUIDs from GCS MDS feed, fetching full deal data from MDS REST API, and writing documents to Vespa
- Scheduled ML feature refresh: querying BigQuery feature tables and partially updating Vespa documents with the latest feature values
- On-demand manual indexing of specific deal UUIDs via the `POST /indexing/index-deals` endpoint
- Computing derived Vespa fields: `is_local`, `is_goods`, `option_duration_days`, `status` (ACTIVE/INACTIVE)
- Unicode sanitisation and type coercion before writing to Vespa

### Out of scope

- Querying Vespa for search results (read path owned by the search/recommendation services)
- Managing the Vespa schema or cluster configuration
- Publishing deal data to MDS or maintaining the canonical deal catalog
- ML model training or feature computation (features are read from BigQuery, not computed here)

## Domain Context

- **Business domain**: Search / Relevance
- **Platform**: Continuum
- **Upstream consumers**: Kubernetes CronJobs (`continuumVespaIndexerCronJobs`) trigger scheduled endpoints; operators call the indexing endpoint manually
- **Downstream dependencies**: `vespaCluster` (document writes), `continuumMarketingDealService` (MDS REST API for deal data), `cloudPlatform` / GCS (MDS feed files), `bigQuery` (ML feature tables), `messageBus` (deal update events)

## Stakeholders

| Role | Description |
|------|-------------|
| Relevance Infrastructure | Owns and operates this service; contact relevance-infra@groupon.com |
| Search / Recommendation teams | Consumers of the Vespa index populated by this service |
| Data Science / ML | Producers of BigQuery feature tables read by this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.12 | `Dockerfile` (`FROM python:3.12-slim`) |
| Framework | FastAPI | 0.118.0 | `requirements.txt` |
| Runtime | Uvicorn (ASGI) | 0.24.0 | `requirements.txt` |
| Build tool | Docker | - | `Dockerfile` |
| Package manager | pip | - | `requirements.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `pyvespa` | 0.61.0 | db-client | Vespa document indexing via HTTP API |
| `stomp.py` | 8.2.0 | message-client | MessageBus consumption over STOMP protocol |
| `google-cloud-storage` | 2.10.0 | db-client | GCS streaming of MDS feed files |
| `google-cloud-bigquery` | 3.13.0 | db-client | BigQuery queries for ML feature tables |
| `httpx` | 0.25.2 | http-framework | Async HTTP client for MDS REST API calls |
| `pydantic` | 2.5.0 | validation | Domain model validation and settings |
| `pydantic-settings` | 2.2.1 | validation | Environment-variable-based configuration |
| `prometheus_fastapi_instrumentator` | 7.0.0 | metrics | Prometheus metrics exposition at `/metrics` |
| `python-dotenv` | 1.0.0 | validation | `.env` file loading for local dev |
| `pytest` | 7.4.3 | testing | Unit and integration test framework |
| `pytest-asyncio` | 0.21.1 | testing | Async test support |
| `black` / `isort` / `flake8` / `mypy` | 23.11.0 / 5.12.0 / 6.1.0 / 1.7.1 | testing | Code quality and static analysis |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `requirements.txt` for a full list.
