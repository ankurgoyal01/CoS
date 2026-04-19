---
service: "suggest"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [suggestService, continuumLocalDictionaryFiles]
---

# Architecture Context

## System Context

The Suggest service sits inside Groupon's MBNXT search domain. It is consumed by the MBNXT search client as the autocomplete/typeahead backend. The service calls Google BigQuery for its primary data (suggestion indexes, ranking metrics, and prefix indexes), the Groupon Division API for geographic division metadata, and an Elastic APM server for distributed tracing. Local filesystem files (`continuumLocalDictionaryFiles`) act as fallback data when BigQuery is unavailable. Prometheus scrapes the `/metrics` endpoint for operational telemetry.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Suggest API Service | `suggestService` | Backend | Python / FastAPI | 1.0.0 | Provides suggestion and query preprocessing APIs, and manages dictionary refresh jobs |
| Local Dictionary Files | `continuumLocalDictionaryFiles` | Filesystem | CSV / JSON / TXT | — | Fallback dictionaries and ML model files bundled in the Docker image |

## Components by Container

### Suggest API Service (`suggestService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `suggest_apiRoutes` | FastAPI routers for `GET /suggestions`, `POST /query-preprocessing`, and admin endpoints | FastAPI |
| `suggestionService` | Coordinates the suggestion pipeline: preprocessing, division resolution, parallel query and category suggestion generation | Python |
| `queryPreprocessingService` | Cleans queries, detects locality, applies typo correction, predicts search radius, flags adult content, identifies best search terms | Python |
| `locationService` | Extracts locality from query text; finds nearest Groupon divisions by Haversine distance | Python |
| `suggestionRankingService` | Scores and ranks candidate suggestion strings using text-similarity and engagement-metric features | Python |
| `dictionaryManager` | Loads, caches, and periodically refreshes all in-memory dictionaries (typo list, locality BK-Tree, categories, queries, ranking metrics, intent words, stopwords, merchants, GPS coordinates, prefix index) | Python |
| `suggest_bigQueryService` | Executes SQL queries against BigQuery tables for suggestion index, ranking index, and prefix index data | Python |
| `divisionClient` | Makes HTTP GET requests to the Groupon Division API to retrieve division coordinates | Python / HTTP |
| `suggest_jobScheduler` | Manages three periodic async background jobs that trigger dictionary refresh tasks | Python / AsyncIO |
| `observabilityMiddleware` | Exposes Prometheus metrics (high-resolution latency histograms) and integrates Elastic APM tracing middleware | Prometheus / Elastic APM |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `suggest_apiRoutes` | `suggestionService` | Calls suggestion pipeline | direct |
| `suggest_apiRoutes` | `queryPreprocessingService` | Calls preprocessing pipeline | direct |
| `suggestionService` | `locationService` | Finds nearest divisions | direct |
| `suggestionService` | `suggestionRankingService` | Ranks candidate suggestions | direct |
| `suggestionService` | `dictionaryManager` | Reads cached dictionaries | direct |
| `queryPreprocessingService` | `locationService` | Detects locality | direct |
| `queryPreprocessingService` | `dictionaryManager` | Uses dictionaries and stopwords | direct |
| `locationService` | `dictionaryManager` | Reads GPS and locality dictionaries | direct |
| `suggestionRankingService` | `dictionaryManager` | Reads ranking metrics | direct |
| `suggest_jobScheduler` | `dictionaryManager` | Triggers periodic refresh tasks | direct |
| `dictionaryManager` | `suggest_bigQueryService` | Loads dictionaries from BigQuery | direct |
| `dictionaryManager` | `divisionClient` | Loads division coordinates | HTTP |
| `dictionaryManager` | `continuumLocalDictionaryFiles` | Loads fallback files | filesystem |
| `suggestService` | `continuumLocalDictionaryFiles` | Loads fallback dictionaries | filesystem |

## Architecture Diagram References

- System context: `contexts-suggest`
- Container: `containers-suggest`
- Component: `components-suggest-service`
