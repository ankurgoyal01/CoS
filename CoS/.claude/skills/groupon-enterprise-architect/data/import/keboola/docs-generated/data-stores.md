---
service: "keboola"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Analytics destination for transformed datasets produced by Keboola pipelines"
---

# Data Stores

## Overview

Keboola Connection does not own any primary data stores. It acts as a managed pipeline intermediary: data is extracted from source systems, transformed in-flight within the Keboola runtime, and written to BigQuery as the destination analytics warehouse. Keboola's internal staging storage (used during pipeline execution) is managed entirely by the Keboola vendor platform and is not accessible or configurable by Groupon.

## Stores

### BigQuery (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` |
| Purpose | Analytics destination — receives all transformed datasets produced by Keboola ETL pipelines |
| Ownership | external |
| Migrations path | Not applicable |

#### Key Entities

> No evidence found in codebase. Specific BigQuery dataset and table names are not documented in the repository. Table schemas are defined within Keboola pipeline configurations.

#### Access Patterns

- **Read**: Not applicable from Keboola's perspective; BigQuery is a write destination.
- **Write**: Batch load of transformed datasets via HTTPS/Batch Load protocol, performed by `kbcDestinationWriters`.
- **Indexes**: Not applicable.

## Caches

> Not applicable. No caching layer is used or documented.

## Data Flows

Data flows through the Keboola pipeline in a linear sequence:

1. Raw data is extracted from Salesforce CRM into the Keboola internal staging area by the `kbcExtractionConnectors`.
2. The `kbcTransformationEngine` reads staged data, applies configured transformation and augmentation logic, and produces transformed datasets.
3. The `kbcDestinationWriters` batch-loads transformed datasets into BigQuery via HTTPS.

See [Pipeline Run Flow](flows/pipeline-run-flow.md) for the complete end-to-end flow.
