---
service: "AudienceCalculationSpark"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for AudienceCalculationSpark.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Sourced Audience Ingestion](sourced-audience-ingestion.md) | Batch | spark-submit by AMS | Ingests a sourced audience from CSV, Hive query, or custom SQL into a Hive table and reports results to AMS |
| [Identity Transform](identity-transform.md) | Batch | spark-submit by AMS | Executes a SQL transform on an existing audience table to create a calculated audience (CA) Hive table |
| [Published Audience Publication](published-audience-publication.md) | Batch | spark-submit by AMS | Builds segmented PA Hive tables, generates CSV/feedback/deal-bucket artifacts, writes payload to Cassandra or Bigtable |
| [Joined Audience](joined-audience.md) | Batch | spark-submit by AMS | Runs SA custom query and PA publication in a single Spark job without persisting the SA table separately |
| [Batch Published Audience](batch-published-audience.md) | Batch | spark-submit by AMS | Publishes multiple PAs from a shared cached base query in one job run |
| [Published Audience CSV Regeneration](published-audience-csv-regeneration.md) | Batch | spark-submit by AMS | Regenerates PA segment CSV files from existing Hive tables without recalculating the audience |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

All flows span `continuumAudienceCalculationSpark` and `continuumAudienceManagementService`. The two architecture dynamic views capture the primary multi-component flows:

- **SA-to-PA standard flow**: `dynamic-sa-to-pa-sourcedAudienceFlow` — see [Sourced Audience Ingestion](sourced-audience-ingestion.md) and [Published Audience Publication](published-audience-publication.md)
- **Joined audience flow**: `dynamic-joined-audience-sourcedAudienceFlow` — see [Joined Audience](joined-audience.md)
