---
service: "zombie-runner"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumZombieRunner, continuumZombieRunnerStateStore, continuumZombieRunnerExternalTargets]
---

# Architecture Context

## System Context

Zombie Runner lives within the **Continuum Platform** (`continuumSystem`) — Groupon's core commerce and data engine. It operates as an on-demand ETL orchestration runtime launched on Google Cloud Dataproc cluster nodes. Data engineers invoke the CLI directly on a cluster master node, or automation scripts trigger it with workflow directories. Zombie Runner has no persistent service boundary of its own; it runs as a process, reads a YAML workflow, drives task execution against downstream data systems, and exits. It interacts with all major data storage and service layers: HDFS, Hive, EDW (Teradata), Snowflake, Solr, Salesforce, AWS S3/EMR, Jira, and arbitrary HTTP REST endpoints.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Zombie Runner | `continuumZombieRunner` | Application | Python | local-snapshot / tagged | Python ETL orchestration runtime that parses workflow YAML, constructs DAGs, and executes task operators on cluster nodes |
| Workflow State Store | `continuumZombieRunnerStateStore` | Database / FileSystem | Filesystem | — | Filesystem-backed persistence for task status and output context checkpoints |
| External REST API Targets | `continuumZombieRunnerExternalTargets` | External | HTTP | — | HTTP endpoints used by REST and distribution push tasks |

## Components by Container

### Zombie Runner (`continuumZombieRunner`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| CLI Entry Point (`zrCli`) | Parses command-line commands (`run`, `help`) and dispatches to handlers; exposes `zombie_runner` and `zombie_daemon` console scripts | Python Module |
| Workflow Reader (`zrWorkflowReader`) | Loads workflow YAML from a directory, resolves includes and namespacing, and emits task, resource, and settings definitions | Python Module |
| DAG Builder (`zrDagBuilder`) | Builds dependency graphs and workflow objects from parsed task definitions using `networkx` | Python Module |
| Task Orchestrator (`zrTaskOrchestrator`) | Coordinates runnable DAG nodes, manages resource budgets, retries, async task execution, and lifecycle state transitions (execute / cleanup / dryrun) | Python Module |
| Operator Adapters (`zrOperatorAdapters`) | Implements concrete task operators: HiveTask, SparkSubmit, SQLBase, SnowflakeWorker, SolrTask, SalesforceTask, RestGetTask, RestUploadTask, ShellTask, DataTask, HadoopTask, NopTask, FailTask | Python Modules |
| Workflow State Persistence (`zrWorkflowStatePersistence`) | Persists task completion / cleanup context and workflow status into filesystem checkpoints; asynchronously logs to MySQL via `ZrHandler` | Python Module |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `zrCli` | `zrWorkflowReader` | Reads workflow directory and resolves YAML definitions | direct (in-process) |
| `zrWorkflowReader` | `zrDagBuilder` | Constructs workflow model and dependency DAG | direct (in-process) |
| `zrDagBuilder` | `zrTaskOrchestrator` | Emits runnable nodes for execution | direct (in-process) |
| `zrTaskOrchestrator` | `zrOperatorAdapters` | Runs task-specific operator logic | direct (in-process) |
| `zrTaskOrchestrator` | `zrWorkflowStatePersistence` | Persists node status and output context | direct (in-process) |
| `continuumZombieRunner` | `continuumZombieRunnerStateStore` | Writes and reads task execution state and context checkpoints | Filesystem I/O |
| `continuumZombieRunner` | `cloudPlatform` | Runs workflow and task execution commands on cluster nodes | GCP SDK / gcloud |
| `continuumZombieRunner` | `hdfsStorage` | Reads and writes distributed files via HDFS commands | Hadoop FS CLI |
| `continuumZombieRunner` | `hiveWarehouse` | Executes Hive queries and table metadata operations | HiveQL / CLI |
| `continuumZombieRunner` | `edw` | Extracts and loads tabular data via JDBC/ODBC and Sqoop | ODBC/JDBC |
| `continuumZombieRunner` | `snowflake` | Loads data into Snowflake through staged copy workflows | S3 stage + SQL |
| `continuumZombieRunner` | `solrCluster` | Creates, swaps, loads, and clears Solr cores | HTTP (Solr Admin API) |
| `continuumZombieRunner` | `salesForce` | Reads and writes Salesforce objects via API tasks | REST (simple-salesforce) |
| `continuumZombieRunner` | `continuumZombieRunnerExternalTargets` | Calls external REST services for ingestion and distribution | HTTP REST |
| `continuumZombieRunner` | `continuumJiraService` | Creates and updates operational issues during alerting flows | HTTP REST (JIRA API v2) |

## Architecture Diagram References

- Component: `components-continuum-zombie-runner`
- Dynamic workflow execution: `dynamic-zombie-runner-workflow-execution`
