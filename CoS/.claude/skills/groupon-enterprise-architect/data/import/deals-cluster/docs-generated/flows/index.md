---
service: "deals-cluster"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Deals Cluster.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deals Cluster Job Execution](deals-cluster-job-execution.md) | batch | Daily crontab on Cerebro job submitter | Orchestrates the full deals clustering pipeline: loads deal catalog and EDW data, applies decorators and rules, writes clusters to PostgreSQL and HDFS. |
| [Top Clusters Job Execution](top-clusters-job-execution.md) | batch | Daily crontab after DealsClusterJob completes | Reads HDFS cluster output, applies top-cluster rules, deduplicates, and writes ranked top-performing clusters to PostgreSQL. |
| [Cluster Decoration Pipeline](cluster-decoration-pipeline.md) | batch | Sub-flow within DealsClusterJob, per country | Sequentially enriches the deal dataset with city, EDW, GP, sold gifts, gift PDS, deal score, ILS campaign, and promo price data. |
| [Rules Fetch at Job Startup](rules-fetch-at-startup.md) | synchronous | Job entry point, before Spark processing begins | Fetches deals clustering rules or top-cluster rules from the Rules API over HTTPS before any Spark processing begins. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The `DealsClusterJob` and `TopClustersJob` are sequential stages of a single daily pipeline:

1. `DealsClusterJob` writes cluster output to HDFS.
2. `TopClustersJob` reads that HDFS output and writes top clusters to PostgreSQL.
3. The **Deals Cluster API** (separate service) reads from PostgreSQL to serve clusters to consumers.

These cross-service data flows are tracked in the central architecture model under `continuumDealsClusterSparkJob`.
