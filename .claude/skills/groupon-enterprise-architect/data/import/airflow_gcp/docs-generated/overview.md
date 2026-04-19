---
service: "airflow_gcp"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Salesforce Data Integration"
platform: "Continuum"
team: "sfint-dev@groupon.com"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Apache Airflow"
  framework_version: "2.x (Cloud Composer managed)"
  runtime: "Google Cloud Composer"
  runtime_version: "managed"
  build_tool: "Jenkins"
  package_manager: "pip"
---

# Airflow GCP (SFDC ETL) Overview

## Purpose

The Airflow GCP service (also known as SFDC ETL) is a scheduled data pipeline orchestration system that synchronizes Groupon's Teradata Enterprise Data Warehouse and Hive analytics cluster with Salesforce CRM. It extracts merchant, deal, refund, and customer data from internal data sources on configurable schedules, stages intermediate datasets in Google Cloud Storage, computes delta records requiring updates, and bulk-loads the results into Salesforce objects via the Salesforce Bulk API. The service ensures that Salesforce field values reflect the latest state of Groupon's operational and analytics data, enabling sales and account management teams to work with accurate deal and merchant information.

## Scope

### In scope

- Scheduled extraction of data from Teradata EDW via SQL queries
- Scheduled extraction of data from Hive analytics cluster via JDBC
- Intermediate dataset staging in Google Cloud Storage (CSV format)
- Delta computation between Salesforce current state and EDW/Hive source data
- Bulk insert and update of Salesforce objects (`Account`, `Opportunity`, `Deal_Alert__c`, and others) via Salesforce Bulk API
- Periodic reload of runtime secrets from GCS into Airflow Variables
- Management of Hive JDBC SSL truststore certificates
- Per-environment configuration (development, staging, production) for all connections and variable values

### Out of scope

- Real-time event streaming or CDC-based sync (all pipelines are scheduled batch jobs)
- Salesforce UI interaction or workflow automation beyond field updates
- Primary ownership of source data in Teradata or Hive (this service is a consumer only)
- Serving of any HTTP API to external callers
- Data transformation beyond delta computation (no complex business logic or enrichment)

## Domain Context

- **Business domain**: Salesforce Data Integration (SFDC ETL)
- **Platform**: Continuum
- **Upstream consumers**: Salesforce CRM (receives all bulk updates); Airflow DAGs UI monitoring dashboards
- **Downstream dependencies**: Teradata EDW (`teradata.groupondev.com`), Hive analytics cluster (`analytics.data-comp.prod.gcp.groupondev.com:8443`), Salesforce (`groupon.my.salesforce.com`), Google Cloud Storage, Google Secret Manager

## Stakeholders

| Role | Description |
|------|-------------|
| SFDC ETL Engineering team | Owns DAG development, deployment, and oncall; contact: sfint-dev@groupon.com |
| Sales / Account Management | Consumers of Salesforce data kept current by this service |
| Data Engineering | Owners of the Teradata EDW and Hive source tables queried by DAGs |
| SRE / Platform | Manages Cloud Composer infrastructure and GCS buckets |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | DAG source files, `config_helper.py` |
| Framework | Apache Airflow | 2.x (Composer managed) | `airflow.decorators`, `airflow.models.DAG` imports in all DAG files |
| Runtime | Google Cloud Composer | managed | README.md — Prod shared Composer bucket path |
| Build tool | Jenkins | shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd` | `Jenkinsfile` |
| Package manager | pip | — | Python ecosystem |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `simple-salesforce` | — | http-framework | Salesforce REST API queries (SOQL) |
| `salesforce-bulk` | — | http-framework | Salesforce Bulk API batch inserts and updates |
| `teradatasql` | — | db-client | Teradata EDW SQL query execution |
| `pandas` | — | serialization | DataFrame intermediary for EDW and Hive result sets |
| `jaydebeapi` | — | db-client | Hive JDBC connector (via Cloudera JDBC driver) |
| `google-cloud-storage` | — | db-client | GCS bucket read/write for staging CSVs |
| `smart-open` | — | db-client | Streaming GCS object read for secrets loading |
| `apache-airflow-providers-google` | — | scheduling | `GCSHook` for GCP authentication in config helper |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
