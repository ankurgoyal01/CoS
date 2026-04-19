---
service: "autocomplete"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAutocompleteTermFiles"
    type: "embedded-files"
    purpose: "Packaged term and division datasets for suggestion generation"
---

# Data Stores

## Overview

The autocomplete service owns one data store: a set of embedded JSON/text resource files (`continuumAutocompleteTermFiles`) packaged with the service artifact. These files are loaded into memory at runtime and serve as the local fallback and locale-aware term corpus for suggestion generation. The service does not own any external databases, caches, or cloud storage buckets.

## Stores

### Autocomplete Term Files (`continuumAutocompleteTermFiles`)

| Property | Value |
|----------|-------|
| Type | embedded-files (JSON/Text) |
| Architecture ref | `continuumAutocompleteTermFiles` |
| Purpose | Provides local term data, locale mappings, and division recommendation resources consumed by `LocalQueryExecutor` and `RecommendedSearchesQueryExecutor` at runtime |
| Ownership | owned |
| Migrations path | Not applicable — files are updated via service deployments |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Term files | Locale-aware suggestion terms for local query execution | term text, locale, division |
| Division recommendation files | Division-level recommendation mappings | division id, recommendation terms |

#### Access Patterns

- **Read**: `LocalQueryExecutor` loads term files into memory at startup; `RecommendedSearchesQueryExecutor` reads recommendation term sources at request time.
- **Write**: Files are static at runtime. Updates are made by rebuilding and redeploying the service artifact.
- **Indexes**: Not applicable — files are read into in-memory data structures.

## Caches

> No evidence found in codebase. No Redis, Memcached, or explicit in-memory cache layer beyond the term files loaded at startup is defined in the architecture model.

## Data Flows

Term files are packaged inside the service artifact (JAR). At startup, `continuumAutocompleteService` loads these files into memory from `continuumAutocompleteTermFiles`. On each autocomplete request, the in-memory term data is queried directly without network I/O. No CDC, ETL, or replication process is modelled.
