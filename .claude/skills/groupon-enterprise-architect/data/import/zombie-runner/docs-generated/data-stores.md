---
service: "zombie-runner"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumZombieRunnerStateStore"
    type: "filesystem"
    purpose: "Task execution state and context checkpoints"
  - id: "hdfsStorage"
    type: "hdfs"
    purpose: "Distributed file reads and writes for ETL data movement"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "HiveQL query execution and table metadata operations"
  - id: "edw"
    type: "jdbc-odbc"
    purpose: "Teradata and RDBMS data extraction and loading"
  - id: "snowflake"
    type: "snowflake"
    purpose: "Data loading via external S3 stage and COPY INTO"
---

# Data Stores

## Overview

Zombie Runner does not own a primary operational database. Instead, it interacts with multiple data platform stores as part of the pipelines it orchestrates. The only store Zombie Runner "owns" is the filesystem-backed workflow state store used for task checkpoint persistence. All other stores are external targets operated by the pipelines themselves.

## Stores

### Workflow State Store (`continuumZombieRunnerStateStore`)

| Property | Value |
|----------|-------|
| Type | Filesystem (local disk on Dataproc cluster node) |
| Architecture ref | `continuumZombieRunnerStateStore` |
| Purpose | Persists task completion state, output context, and checkpoint data for the running workflow |
| Ownership | owned |
| Migrations path | Not applicable — filesystem, no schema migrations |

#### Access Patterns

- **Read**: Reads checkpoint files at workflow startup to detect previously completed tasks
- **Write**: Writes task status and context key-value pairs after each task phase completes

---

### HDFS Storage (`hdfsStorage`)

| Property | Value |
|----------|-------|
| Type | HDFS (Hadoop Distributed File System) |
| Architecture ref | `hdfsStorage` |
| Purpose | Source and sink for ETL data movement; Zombie Runner reads raw data and writes processed output via `hadoop fs` CLI commands |
| Ownership | external / shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: `hadoop fs -text`, `hadoop fs -ls`, `hadoop fs -cat`, `hadoop fs -du` to enumerate and stream HDFS data
- **Write**: `hadoop fs -put`, `hadoop fs -copyFromLocal`, `hadoop fs -mv`, `hadoop fs -rmr` for data staging and output

---

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive Metastore + HDFS-backed tables |
| Architecture ref | `hiveWarehouse` |
| Purpose | Executes HiveQL queries for extraction, transformation, and loading of tabular data; also used for table schema inspection and partition management |
| Ownership | external / shared |
| Migrations path | Not applicable — DDL managed by individual pipeline workflows |

#### Access Patterns

- **Read**: `SELECT` queries executed via HiveTask or `hive -e` shell command; `SHOW PARTITIONS`, `DESCRIBE` via `hive_util.py`
- **Write**: `INSERT INTO`, `CREATE TABLE`, `DROP TABLE` via HiveTask operators

---

### EDW / Teradata (`edw`)

| Property | Value |
|----------|-------|
| Type | Teradata (JDBC/ODBC) and other RDBMS |
| Architecture ref | `edw` |
| Purpose | Extracts and loads tabular data using SQL task operators; BTEQ and TPT templates provided in `shared/resource/` |
| Ownership | external / shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: SQL `SELECT` via ODBC connections configured in `~/.odbc.ini` or `/etc/odbc.ini`
- **Write**: `INSERT`, bulk load via TPT (`teradata-tpt.tpl`), and BTEQ (`teradata-bteq.tpl`)

---

### Snowflake (`snowflake`)

| Property | Value |
|----------|-------|
| Type | Snowflake (cloud data warehouse) |
| Architecture ref | `snowflake` |
| Purpose | Loads data from HDFS or local disk into Snowflake tables via a two-phase process: stage data to S3 external stage, then execute COPY INTO |
| Ownership | external / shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: Uploads source data to an S3 bucket (`snowflake_stage_loc`), renders the `snowflake-load.tpl` Mako template into a multi-statement COPY INTO SQL sequence, and executes it against Snowflake via `pyodbc` / Snowflake ODBC driver

---

### MySQL Metadata Store (via `ZrHandler`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | Not in central architecture model (legacy internal store) |
| Purpose | Receives async workflow/task status records and context snapshots from `ZrHandler` during pipeline execution |
| Ownership | external / shared |
| Migrations path | `shared/resource/zrdb-0.0.1.sql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `TASK_STATUS` | Records task execution state per run | `job_name`, `wf_name`, `task_name`, `status`, `wf_id` |
| `WORKFLOW_STATUS` | Records overall workflow state per run | `job_name`, `wf_name`, `status`, `dateid` |
| `OUTPUT_CONTEXT` | Stores task-emitted context key-value pairs | `task_name`, `context_name`, `context_value` |
| `OUTPUT_STAT` | Stores numeric task statistics | `task_name`, `stat_name`, `stat_value` |
| `RUN_SOURCE_LIST` | Per-run data lineage source records | `task_name`, `stype`, `name`, `location` |
| `RUN_TARGET_LIST` | Per-run data lineage target records | `task_name`, `stype`, `name`, `location` |
| `SOURCE_LIST` | Latest source list per job/task | `job_name`, `task_name`, `stype`, `name`, `location` |
| `TARGET_LIST` | Latest target list per job/task | `job_name`, `task_name`, `stype`, `name`, `location` |

> In the active Dataproc fork, `ZrDummyMetaTableUpdate` is used and all MySQL writes are no-ops.

## Caches

> No evidence found in codebase. Zombie Runner uses no in-memory cache layer or external cache service.

## Data Flows

Zombie Runner acts as a data movement orchestrator. The canonical data flow for a Snowflake load pipeline is:

1. Data extracted from HDFS or Teradata/EDW via HiveTask or SQLTask
2. Intermediate output staged to local disk on the Dataproc cluster node
3. `SnowflakeWorker` uploads staged data to AWS S3 (`snowflake_stage_loc` bucket) — either directly via `boto3` or via an EMR streaming job for large HDFS files
4. Snowflake COPY INTO command executed to load from the S3 external stage into the target table
5. S3 prefix cleaned up post-load

For HDFS-to-HDFS distribution, `DistPushTask` uses WebHDFS REST to copy files between clusters via a FIFO pipe intermediary.
