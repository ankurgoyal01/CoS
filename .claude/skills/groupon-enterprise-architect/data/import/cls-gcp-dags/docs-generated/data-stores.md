---
service: "cls-gcp-dags"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcp-curated-storage"
    type: "bigquery or equivalent GCP storage"
    purpose: "Curated downstream storage target written to by the Curated Load Task"
---

# Data Stores

## Overview

`cls-gcp-dags` is a data pipeline orchestration service. It does not own a primary operational database. The Curated Load Task (`dagLoadTask`) writes validated outputs to curated downstream GCP storage targets (such as BigQuery tables or GCP storage buckets); however, those stores are owned by downstream consumers, not by this service. The Data Validation Task (`dagDataValidationTask`) reads from source datasets to validate completeness and schema expectations before loading.

No specific data store identifiers, table names, migration paths, or connection strings are modeled in the architecture DSL for this service.

## Stores

### Curated Downstream Storage (external ownership)

| Property | Value |
|----------|-------|
| Type | GCP storage (BigQuery or equivalent — no evidence of specific store type in codebase) |
| Architecture ref | Not modeled in `continuumClsGcpDags` DSL |
| Purpose | Receives curated, validated CLS data outputs from the Curated Load Task |
| Ownership | external (owned by downstream data consumers) |
| Migrations path | No evidence found in codebase. |

#### Key Entities

> No evidence found in codebase. No table schemas, entity names, or key fields are discoverable from the architecture DSL alone.

#### Access Patterns

- **Read**: The Data Validation Task reads source datasets to validate completeness and schema expectations prior to load.
- **Write**: The Curated Load Task writes validated CLS data to curated downstream storage targets after successful validation.
- **Indexes**: No evidence found in codebase.

## Caches

> No evidence found in codebase. No caches are modeled or referenced for this service.

## Data Flows

Data flows through the pipeline sequentially: Cloud Scheduler emits a trigger, which the Schedule Trigger component (`dagScheduleTrigger`) receives and passes to the Task Orchestrator (`dagTaskOrchestrator`). The orchestrator dispatches the Data Validation Task (`dagDataValidationTask`) to validate source datasets, and upon success, the validated dataset is handed to the Curated Load Task (`dagLoadTask`) for writing to curated downstream storage. See [Flows](flows/index.md) for the detailed step-by-step flow.
