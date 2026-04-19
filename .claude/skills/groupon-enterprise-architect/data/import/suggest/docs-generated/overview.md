---
service: "suggest"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search / Relevance"
platform: "MBNXT"
team: "rapi@groupon.com"
status: active
tech_stack:
  language: "Python"
  language_version: "3.12"
  framework: "FastAPI"
  framework_version: "0.115.12"
  runtime: "uvicorn"
  runtime_version: "0.34.2"
  build_tool: "Docker"
  package_manager: "pip"
---

# Suggest Service Overview

## Purpose

The Suggest service provides real-time search query suggestions and category recommendations to Groupon's MBNXT frontend. It combines location-aware division matching, historical search-popularity data from BigQuery, NLP-based text processing, and an ML-based search radius predictor to return ranked, relevant suggestions as users type. It also exposes a standalone query-preprocessing endpoint used by the search pipeline to clean queries, detect localities, predict search radius, and flag adult content.

## Scope

### In scope

- Real-time suggestion retrieval via `GET /suggestions` (query suggestions and category suggestions)
- Query preprocessing pipeline via `POST /query-preprocessing` (typo correction, locality detection, radius prediction, adult-content detection, category detection, best-search-terms generation)
- Location-aware division resolution using Haversine distance
- In-memory dictionary management with scheduled BigQuery refresh (daily)
- BK-Tree fuzzy matching for typo correction and locality identification
- ML-based search radius prediction using an ONNX-quantized sentence transformer and a scikit-learn classifier
- Prometheus metrics and Elastic APM tracing

### Out of scope

- Full-text search execution (handled by Groupon search backends)
- Deal or merchant ranking beyond suggestion surface
- User authentication or session management
- Event publishing or consumption (service is fully synchronous)

## Domain Context

- **Business domain**: Search / Relevance
- **Platform**: MBNXT
- **Upstream consumers**: MBNXT search client (`searchClient_3c1a`) calling `GET /suggestions` and `POST /query-preprocessing`
- **Downstream dependencies**: Google BigQuery (suggestion and ranking indexes), Groupon Division API (`https://api.groupon.com/v2/divisions.json`), local fallback CSV/JSON/TXT files, Elastic APM, Prometheus

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | acameramartinez |
| Team contact | rapi@groupon.com |
| Maintainer label | relevance-infra@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.12 | `.python-version`, `Dockerfile` |
| Framework | FastAPI | 0.115.12 | `requirements.txt` |
| Runtime | uvicorn | 0.34.2 | `requirements.txt`, `app/main.py` |
| Build tool | Docker (multi-stage) | python:3.12-slim | `Dockerfile` |
| Package manager | pip | — | `requirements.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| fastapi | 0.115.12 | http-framework | REST API server and routing |
| uvicorn | 0.34.2 | http-framework | ASGI server |
| pydantic | 2.11.4 | validation | Request/response schema validation |
| google-cloud-bigquery | 3.34.0 | db-client | Reads suggestion index and ranking tables from BigQuery |
| elastic-apm[fastapi] | >=6.22.0 | metrics | Distributed tracing via Elastic APM |
| prometheus-fastapi-instrumentator | 7.1.0 | metrics | Prometheus metrics exposition |
| pybktree | 1.1 | search | BK-Tree for O(log n) Levenshtein-based typo/locality fuzzy matching |
| python-Levenshtein | 0.27.1 | search | Edit-distance computation for BK-Tree |
| nltk | 3.9.1 | nlp | Lemmatization via WordNetLemmatizer |
| onnxruntime | 1.17.3 | ml | CPU inference for quantized ONNX sentence transformer |
| transformers | 4.57.3 | ml | Tokenizer for ONNX encoder |
| scikit-learn | 1.6.1 | ml | Radius classifier (joblib-serialised) |
| h3 | 4.1.2 | geo | Lat/lon to H3 hex-cell conversion for radius prediction |
| numpy | 1.26.4 | ml | Numerical array operations |
| pandas | 2.2.3 | db-client | BigQuery result processing |
| requests | 2.32.3 | http-client | HTTP calls to Groupon Division API |
| RapidFuzz | 3.13.0 | search | Fast fuzzy-string matching utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `requirements.txt` for a full list.
