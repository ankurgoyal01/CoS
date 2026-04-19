---
service: "zombie-runner"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Engineering / ETL Orchestration"
platform: "Continuum (GCP Migration)"
team: "GCP Migration Tooling POD"
status: active
tech_stack:
  language: "Python"
  language_version: "2.7 / 3.x"
  framework: "Custom ETL orchestration runtime"
  framework_version: "local-snapshot (tagged releases)"
  runtime: "Google Cloud Dataproc"
  runtime_version: "Dataproc custom image (family: zombie-runner)"
  build_tool: "setuptools + Jenkins"
  package_manager: "pip"
---

# Zombie Runner Overview

## Purpose

Zombie Runner is a Python-based ETL orchestration runtime originally developed at Groupon and now adapted to run on Google Cloud Platform's Dataproc service. It reads workflow definitions written in YAML, constructs a dependency DAG from declared task relationships, and executes those tasks in parallel (respecting resource budgets) using a library of built-in operator adapters. The service exists to coordinate multi-step data pipelines that extract, transform, and load data across Hive, Spark, Snowflake, Teradata/EDW, Solr, Salesforce, HDFS, and external REST endpoints.

## Scope

### In scope

- Parsing YAML workflow files (`tasks.yml`) and resolving task class names, dependencies, settings, resources, and context variables
- Building and traversing directed acyclic graphs (DAGs) of task nodes
- Orchestrating parallel task execution with resource-slot budgeting and retry logic
- Providing operator adapters for: HiveTask, SparkSubmit, SQL/ODBC tasks (Teradata, PostgreSQL, MySQL), SnowflakeTask, SolrTask (create/swap/load/delete core), SalesforceTask, RestGetTask, RestUploadTask, ShellTask, HadoopTask, DataTask (HDFS data movement), and DistPushTask
- Persisting task execution state and output context to filesystem checkpoints
- Async logging of workflow and task status to a MySQL metadata store via `ZrHandler`
- Generating Jira issues for operational alerts during workflow runs
- Staging and loading data to AWS S3 and Snowflake external stages via EMR steps
- Distributing files between HDFS clusters via WebHDFS (DistPush)
- CLI entry points: `zombie_runner run` and `zombie_daemon`

### Out of scope

- Workflow scheduling / cron triggering (Zombie Runner is invoked externally, e.g., by Airflow or shell scripts)
- Cluster provisioning beyond providing a custom Dataproc image
- StreamingTask operator (not yet implemented in the Dataproc fork)
- EmailTask operator (not yet implemented in the Dataproc fork)
- Restartability / checkpointed workflow resumption (not yet implemented)

## Domain Context

- **Business domain**: Data Engineering / ETL Orchestration
- **Platform**: Continuum (GCP migration tooling)
- **Upstream consumers**: Data engineers and pipeline authors who invoke `zombie_runner run <workflow_dir>` on Dataproc cluster nodes; Airflow or shell automation that triggers the CLI
- **Downstream dependencies**: Hive Warehouse, HDFS, Snowflake, Teradata/EDW (JDBC/ODBC), Solr Cluster, Salesforce, AWS S3/EMR, JIRA, external REST HTTP services

## Stakeholders

| Role | Description |
|------|-------------|
| Data Engineers | Author YAML workflow files and run pipelines via the CLI |
| GCP Migration Tooling POD | Own and maintain the Zombie Runner codebase and Dataproc image |
| EDW / Analytics Teams | Consumers of data loaded by Zombie Runner pipelines |
| Platform / Infra | Manage Dataproc cluster provisioning and GCP project resources |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 2.7 / 3.x | `Jenkinsfile` (python:2.7.18 Docker image), `.ci.yml` (python-2.7.1), `setup.py` |
| Framework | Custom ETL runtime | local-snapshot / tagged | `setup.py` |
| Runtime | Google Cloud Dataproc | Custom image family | `README.md` (`--image=family/zombie-runner`) |
| Build tool | setuptools + Jenkins | — | `setup.py`, `Jenkinsfile` |
| Package manager | pip | — | `requirements.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `boto3` | 1.34.89 | cloud-client | AWS S3 and EMR operations for Snowflake staging and data movement |
| `pyyaml` | 6.0.1 | serialization | Parsing workflow YAML definitions and task configuration |
| `requests` | 2.30.0 | http-client | REST task adapters, WebHDFS operations, Solr and Jira API calls |
| `networkx` | 3.1 | scheduling | DAG construction and dependency graph traversal |
| `pydot` | 2.0.0 | scheduling | DAG visualization / graph rendering |
| `simple-salesforce` | 1.12.6 | db-client | Salesforce object read/write via API tasks |
| `pyodbc` | 5.1.0 | db-client | ODBC database connectivity for Teradata and other SQL sources |
| `mysqlclient` | 2.2.4 | db-client | MySQL connectivity for metadata logging (`ZrHandler`) |
| `psycopg2-binary` | 2.8.6 | db-client | PostgreSQL connectivity for SQL task operators |
| `mako` | 1.3.0 | serialization | Rendering Snowflake load SQL templates (`snowflake-load.tpl`) |
| `paramiko` | 3.4.0 | auth | SSH operations for remote cluster interactions |
| `influxdb` | 5.3.1 | metrics | Metrics emission for task statistics |
| `zeep` | 4.0.0 | http-client | SOAP/WSDL-based integration support |
| `nose` | 1.3.7 | testing | Unit test runner (`nosetests`) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `requirements.txt` for a full list.
