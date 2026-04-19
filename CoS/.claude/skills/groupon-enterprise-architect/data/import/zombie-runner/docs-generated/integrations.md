---
service: "zombie-runner"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 1
---

# Integrations

## Overview

Zombie Runner integrates with eight external systems as downstream targets of the ETL pipelines it orchestrates, and one internal Groupon service (Jira) for operational alerting. All integrations are outbound — Zombie Runner calls out to each system from operator adapters; no system calls back into Zombie Runner. Integration protocols vary by target: HDFS CLI, HiveQL, ODBC/JDBC, S3 SDK, HTTP REST, and Salesforce SDK.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| HDFS | Hadoop FS CLI | Reads/writes distributed files for ETL data movement and staging | yes | `hdfsStorage` |
| Hive Warehouse | HiveQL / CLI | Executes SQL queries for extraction, transformation, and table management | yes | `hiveWarehouse` |
| EDW / Teradata | ODBC/JDBC, BTEQ, TPT | Extracts and loads tabular data from the Enterprise Data Warehouse | yes | `edw` |
| Snowflake | ODBC + AWS S3 Stage | Loads data via staged S3 COPY INTO workflows | yes | `snowflake` |
| AWS S3 / EMR | boto3 SDK | Stages data to S3 buckets; submits EMR streaming steps for large HDFS-to-S3 copies | yes | `cloudPlatform` |
| Solr | HTTP (Solr Admin API) | Creates, swaps, loads, and clears Solr search cores | no | `solrCluster` |
| Salesforce | REST (simple-salesforce) | Reads and writes Salesforce CRM objects via API tasks | no | `salesForce` |
| External REST APIs | HTTP REST | Calls arbitrary HTTP endpoints for data ingestion and distribution | no | `continuumZombieRunnerExternalTargets` |

### HDFS Detail

- **Protocol**: `hadoop fs` CLI subprocess calls (`-text`, `-cat`, `-ls`, `-put`, `-mv`, `-rmr`, `-mkdir`, `-copyFromLocal`, `-copyToLocal`)
- **Base URL / SDK**: `hadoop` binary resolved from `PATH`; WebHDFS REST at `http://<hdfs_host>/webhdfs/v1` for cross-cluster distribution
- **Auth**: Kerberos (cluster-level, pre-configured on Dataproc image)
- **Purpose**: Primary distributed storage layer — reads source data, writes intermediate and final output tables, and moves files between directories
- **Failure mode**: Task raises `RuntimeError` with the stderr output; workflow retries up to configured `attempts`
- **Circuit breaker**: No

### Hive Warehouse Detail

- **Protocol**: `hive -e "<query>"` subprocess; table metadata via `hive_util.py`
- **Base URL / SDK**: `hive` binary resolved from `PATH`; Dataproc Metastore configured at cluster creation time via `--dataproc-metastore`
- **Auth**: Cluster-level Kerberos / service account
- **Purpose**: HiveQL queries for SELECT, INSERT INTO, CREATE TABLE, DROP TABLE; `SHOW PARTITIONS`, `DESCRIBE` for metadata inspection
- **Failure mode**: Task raises exception on non-zero subprocess exit code
- **Circuit breaker**: No

### EDW / Teradata Detail

- **Protocol**: ODBC via `pyodbc`; BTEQ and TPT via subprocess with templates in `shared/resource/teradata-bteq.tpl` and `shared/resource/teradata-tpt.tpl`
- **Base URL / SDK**: DSN configured in `~/.odbc.ini` (`ODBCINI` env var); Teradata JDBC JARs in `shared/resource/jars/` (`terajdbc4.jar`, `tdgssconfig.jar`)
- **Auth**: DSN username/password, optionally encrypted via `decrypt_key` setting
- **Purpose**: Enterprise data warehouse extraction and loading; supports Sqoop for parallel bulk export
- **Failure mode**: Task raises exception; ODBC connection errors surface in stderr
- **Circuit breaker**: No

### Snowflake Detail

- **Protocol**: Two-phase: (1) S3 upload via `boto3` or EMR streaming step, (2) COPY INTO via Snowflake ODBC driver using `snowflake-load.tpl`
- **Base URL / SDK**: `snowflake_stage_loc` (S3 bucket), `snf_ext_stage_name` (Snowflake external stage name), ODBC DSN
- **Auth**: S3 credentials via IAM role (on Dataproc / EMR); Snowflake via ODBC DSN credentials
- **Purpose**: Final data load destination for analytics pipelines; supports truncate-before-load, column truncation, null replacement, and custom file formats
- **Failure mode**: Raises exception; cleans up S3 prefix on load failure
- **Circuit breaker**: No

### AWS S3 / EMR Detail

- **Protocol**: AWS SDK (`boto3`) for S3 uploads; EMR `add_job_flow_steps` API for large HDFS-to-S3 copies using Hadoop streaming
- **Base URL / SDK**: `boto3.client("s3")`, `boto3.client("emr")`
- **Auth**: IAM role attached to Dataproc / EMR cluster service account
- **Purpose**: Staging layer for Snowflake loads; also used for cleaning up staging prefixes after load
- **Failure mode**: EMR step failure raises exception; S3 prefix cleanup attempted before re-raise
- **Circuit breaker**: No; `wait_for_step_completion` polls with max 300 attempts at 10-second intervals

### Solr Detail

- **Protocol**: HTTP GET/POST to Solr Admin API (`/solr/admin/cores`) and update endpoint (`/solr/{core_name}/update/json`)
- **Base URL / SDK**: `http://{solr_host}:{solr_port}` (configurable per task)
- **Auth**: None (anonymous by default)
- **Purpose**: Manages Solr search indexes — creates cores, swaps active/standby cores, bulk-loads CSV data in batches, deletes all documents
- **Failure mode**: Non-2XX response raises `RuntimeError`
- **Circuit breaker**: No

### Salesforce Detail

- **Protocol**: REST via `simple-salesforce` library
- **Base URL / SDK**: `simple_salesforce==1.12.6`
- **Auth**: Salesforce API credentials configured in task parameters
- **Purpose**: Reads and writes Salesforce CRM objects (e.g., accounts, contacts) as part of CRM data pipelines
- **Failure mode**: Library raises exception on API errors
- **Circuit breaker**: No

### External REST APIs Detail

- **Protocol**: HTTP GET, PUT, POST via `requests.Session`
- **Base URL / SDK**: `base_url` configured per `RestGetTask` / `RestUploadTask` task definition
- **Auth**: Optional HTTP Basic Auth (`username`, `password` in task configuration)
- **Purpose**: Generic HTTP ingestion (fetch data from REST APIs to local files) and distribution (upload processed data to external endpoints)
- **Failure mode**: Non-2XX response raises exception
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Jira (continuumJiraService) | HTTP REST (Jira API v2) | Creates and updates operational issues during workflow alerting flows; labels issues `zombie_runner_generated` | `continuumJiraService` |

### Jira Detail

- **Protocol**: HTTP REST to `rest/api/2/issue`, `rest/api/2/search`, `rest/api/2/issueLink`
- **Auth**: HTTP Basic Auth with base64-encoded token (`Authorization: Basic <token>`)
- **Purpose**: Operational alerting — creates Jira issues in the EDW project when pipelines detect data quality failures or other alertable conditions; supports add comment, add attachment, add remote link, and add issue link operations
- **Failure mode**: `requests.post` / `get` exceptions propagate to the calling task

## Consumed By

> Upstream consumers are tracked in the central architecture model. Zombie Runner is invoked by data engineers directly via CLI on Dataproc cluster nodes, and by automation scripts (e.g., Airflow DAGs, shell scripts) that SSH into cluster nodes and execute `zombie_runner run <workflow_dir>`.

## Dependency Health

Zombie Runner has no built-in health check mechanism for its downstream dependencies. All dependency failures surface as exceptions during task execution, which trigger the configured retry logic (`attempts` and `cooldown` settings). There are no circuit breakers or timeout wrappers beyond the `timeout` setting in the workflow YAML, and the `max_attempts` / `sleep_seconds` polling configuration in `EMROperations.wait_for_step_completion`.
