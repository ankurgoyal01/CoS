---
service: "audienceDerivationSpark"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Audience Derivation Spark.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Nightly Audience Derivation](nightly-audience-derivation.md) | scheduled | Cron (daily, per-region) | End-to-end nightly pipeline: ops submits Spark job, loads YAML config from HDFS, executes multi-step SQL tempview chain, writes derived users/bcookie tables to Hive |
| [AMS Field Sync](ams-field-sync.md) | scheduled | Post-derivation (automatic) or manual Fabric task | Reads derived Hive table schema and synchronizes field metadata to the AMS MySQL database |
| [LINK SAD Base Table Generation](link-sad-base-table-generation.md) | scheduled | Cron or manual spark-submit | Reads current system tables from Hive and builds LINK SAD optimization base-table datasets for deal targeting |
| [CQD Field Validation](cqd-field-validation.md) | scheduled | Manual Fabric task or scheduled | Validates CQD field definitions against current Hive table schemas and AMS field state; reports discrepancies |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

- The **Nightly Audience Derivation** flow connects `continuumAudienceDerivationOps` → `continuumAudienceDerivationSpark` → `hdfsStorage` → `hiveMetastore` → `amsApi`. This is documented as a dynamic view in the central architecture model: `nightly_derivation_flow`.
- Downstream of derivation, `continuumAudienceDerivationSpark` feeds `cassandraCluster` and `bigtableIngestion` via the `audiencepayloadspark` dependency — those flows are owned by the payload delivery pipeline.
