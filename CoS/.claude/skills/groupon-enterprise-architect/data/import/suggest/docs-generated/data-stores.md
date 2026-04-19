---
service: "suggest"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "bigQuery_9a2f"
    type: "bigquery"
    purpose: "Primary source for suggestion indexes and ranking metrics"
  - id: "continuumLocalDictionaryFiles"
    type: "filesystem"
    purpose: "Fallback dictionaries and bundled ML model files"
---

# Data Stores

## Overview

The Suggest service does not own a persistent database. Its data strategy is built around two layers: a primary BigQuery read-only integration that loads suggestion indexes and ranking metrics into in-memory dictionaries at startup and on a daily schedule, and a set of bundled local files that serve as offline fallbacks. All in-memory dictionaries are held in `DictionaryManager` class-level attributes for O(1) lookup during request handling. The service owns no tables and performs no writes.

## Stores

### Google BigQuery (`bigQuery_9a2f`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery_9a2f` (external stub) |
| Purpose | Primary source for suggestion query index and suggestion ranking engagement metrics |
| Ownership | external |
| Migrations path | Not applicable — read-only; tables owned by the data platform |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `prj-grp-dataview-prod-1ff9.product_analytics.query_by_division_index` | Per-division ranked query index (primary suggestion source) | `division` (STRING), `queries` (STRING — JSON array of `[query, search_order]` tuples) |
| `prj-grp-dataview-prod-1ff9.product_analytics.suggestion_ranking_index` | User engagement metrics per (division, search string, suggestion) tuple | `division`, `searchString`, `suggestionView`, `searchCount`, `suggestionClicks`, `dealClicks`, `dealPurchased` |
| `prj-grp-relevance-dev-2867.fs.suggest_prefix` | Prefix-to-query scoring index for prefix-based suggestions | `division`, `prefix`, `query`, `score_final` |

#### Access Patterns

- **Read**: Full table scans executed at startup and on each scheduled refresh. Queries load all rows for all divisions into memory. No row-level filters are applied at the BigQuery layer (filtering happens in-process).
- **Write**: None. The service is read-only with respect to BigQuery.
- **Indexes**: Not applicable — BigQuery partitioning and clustering is managed by the data platform.

---

### Local Dictionary Files (`continuumLocalDictionaryFiles`)

| Property | Value |
|----------|-------|
| Type | filesystem (bundled in Docker image) |
| Architecture ref | `continuumLocalDictionaryFiles` |
| Purpose | Fallback data when BigQuery is unavailable; bundled ML model artifacts |
| Ownership | owned (bundled into the Docker image at build time) |
| Migrations path | `data/` directory in the service repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `data/typo_dictionary.txt` | Known correct-form words for BK-Tree typo correction | One word/phrase per line |
| `data/cities.csv` | City names with GPS coordinates and US state, for locality detection | `city_name` (TSV col 0), `lat` (col 1), `lon` (col 2), `state` (col 3) |
| `data/categories.json` | Product categories with GP scores, keyed by search term | `{ "<term>": [{ "cft_cat_name": "...", "gp": 0.0 }] }` |
| `data/query-category-mapping.json` | 3,498 query-to-category-UUID mappings for category detection | `[{ "guid": "...", "query": "...", "description": "..." }]` |
| `data/intent_words.txt` | Special intent keywords that bypass normal suggestion matching | One word per line |
| `data/stopwords.txt` | Words filtered from queries before typo correction | One word per line |
| `data/adult_content_words.txt` | Terms used to flag adult-content queries | One term per line |
| `data/merchants.txt` | Known merchant names for merchant detection in query preprocessing | One merchant per line |
| `data/suggest_queries_index.csv` | Fallback query index when BigQuery is unavailable | `division`, `queries` (JSON) |
| `data/suggestions_ranking_index.csv` | Fallback ranking metrics when BigQuery is unavailable | `division`, `searchString`, `suggestionView`, `searchCount`, `suggestionClicks`, `dealClicks`, `dealPurchased` |
| `data/radius_classifier.joblib` | Scikit-learn ML classifier for search radius prediction | joblib-serialized model |
| `data/radius_cat_encoder.joblib` | Categorical encoder for H3 region features | joblib-serialized encoder |
| `onnx_encoder/model.int8.onnx` | INT8-quantized ONNX sentence transformer for radius prediction | ONNX model file |
| `onnx_encoder/config.json` | Tokenizer configuration for the ONNX encoder | JSON config |

#### Access Patterns

- **Read**: All files are read once at startup during `DictionaryManager.load_dictionaries()`. Dictionary refresh jobs (BigQuery-backed) do not re-read local files unless BigQuery fails.
- **Write**: None. Files are static and bundled at image build time.
- **Indexes**: BK-Tree indexes are built in memory at startup from `typo_dictionary.txt` and `cities.csv` contents.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `DictionaryManager` class attributes | in-memory | Holds all loaded dictionaries (typo BK-Tree, locality BK-Tree, categories, queries, ranking metrics, GPS coordinates, intent words, stopwords, merchants, prefix index) for O(1) request-time access | Refreshed daily by scheduled jobs; no explicit TTL |

## Data Flows

1. At service startup, `DictionaryManager.load_dictionaries()` concurrently loads all dictionaries — BigQuery is attempted first; local files are used as fallback on failure.
2. Three `JobScheduler` instances run daily (86,400-second interval) to refresh `queries_dict` (from `query_by_division_index`), `suggestions_ranking_dict` (from `suggestion_ranking_index`), and `suggest_prefix_index` (from `suggest_prefix`) independently.
3. GPS coordinates for divisions are loaded from the Groupon Division API at startup only (no scheduled refresh).
4. Request handling reads exclusively from the in-memory `DictionaryManager` — no per-request data store calls are made.
