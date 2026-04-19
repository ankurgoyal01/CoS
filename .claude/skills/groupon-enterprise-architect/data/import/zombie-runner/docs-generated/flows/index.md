---
service: "zombie-runner"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Zombie Runner.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Workflow Execution](workflow-execution.md) | batch | CLI `zombie_runner run <dir>` invocation | End-to-end flow from CLI entry to DAG construction, parallel task orchestration, and state persistence |
| [Hive ETL Task](hive-etl-task.md) | batch | Task node scheduled by orchestrator | HiveTask operator executes HiveQL queries for extraction or loading against the Hive Warehouse |
| [Spark Job Submission](spark-job-submission.md) | batch | Task node scheduled by orchestrator | SparkSubmit operator builds and executes a `spark-submit` command on the cluster |
| [Snowflake Data Load](snowflake-data-load.md) | batch | Task node scheduled by orchestrator | Two-phase pipeline: stage source data to AWS S3, then execute Snowflake COPY INTO |
| [Solr Index Build](solr-index-build.md) | batch | Task node scheduled by orchestrator | Creates a Solr core, loads data from a CSV file in batches, swaps into production |
| [HDFS Distribution Push](hdfs-distribution-push.md) | batch | Task node scheduled by orchestrator | Copies files between HDFS clusters using WebHDFS REST via a FIFO pipe intermediary |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

The primary cross-service dynamic view is defined in the Structurizr architecture model:

- `dynamic-zombie-runner-workflow-execution` — traces the internal component flow from `zrCli` through `zrWorkflowReader`, `zrDagBuilder`, `zrTaskOrchestrator`, `zrOperatorAdapters`, and `zrWorkflowStatePersistence`

All Zombie Runner flows are batch processes initiated by CLI invocation. Cross-service interactions occur when operator adapters call out to `hdfsStorage`, `hiveWarehouse`, `edw`, `snowflake`, `solrCluster`, `salesForce`, `continuumJiraService`, or `continuumZombieRunnerExternalTargets`.
