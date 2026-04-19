---
service: "jdbc-refresh-api-longlived"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumRangerDbMysql"
    type: "mysql"
    purpose: "Apache Ranger policy storage and authorization metadata"
  - id: "continuumSoxRangerDbMysql"
    type: "mysql"
    purpose: "SOX-scoped Apache Ranger policy storage"
  - id: "continuumBuckets"
    type: "gcs"
    purpose: "Dataproc staging buckets, initialization scripts, and Ranger secrets"
  - id: "continuumSoxBuckets"
    type: "gcs"
    purpose: "SOX-scoped GCS buckets for staging and secrets"
  - id: "continuumGcsBucket"
    type: "gcs"
    purpose: "Dedicated platform GCS bucket resources"
---

# Data Stores

## Overview

This platform uses two primary data store categories: Cloud SQL for MySQL instances (one per environment lane — standard and SOX) that back Apache Ranger authorization, and GCS buckets for Dataproc staging artifacts, cluster initialization scripts, and KMS-encrypted Ranger secrets. The Dataproc clusters themselves use HDFS for transient job data and integrate with the Dataproc Metastore Service for Hive catalog persistence. BigQuery is the downstream analytical data store that backend clusters read from and write to.

## Stores

### Ranger DB MySQL (`continuumRangerDbMysql`)

| Property | Value |
|----------|-------|
| Type | Cloud SQL for MySQL |
| Architecture ref | `continuumRangerDbMysql` |
| Purpose | Stores Apache Ranger authorization policies and audit metadata for analytics, pipelines, OP, and Tableau backend clusters |
| Ownership | owned |
| MySQL version | MYSQL_5_7 |
| Instance name (prod) | `prod-ranger-mysql-db` |
| Machine tier (prod) | `db-n1-highmem-8` |
| Network | Private IP only (`vpc-prod-sharedvpc01`) |
| Backups | Enabled with binary logging |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Ranger policies | Define access rules for databases, tables, columns | policy name, resource path, user/group, permissions |
| Ranger audit | Records access audit events from backend clusters | user, resource, action, result, timestamp |

#### Access Patterns

- **Read**: Backend clusters read Ranger policies at query execution time via JDBC from `dataproc:ranger.cloud-sql.instance.connection.name`
- **Write**: Ranger Admin UI (running on the backend cluster master) writes new policies and updates
- **Indexes**: Managed internally by Ranger schema migrations

### SOX Ranger DB MySQL (`continuumSoxRangerDbMysql`)

| Property | Value |
|----------|-------|
| Type | Cloud SQL for MySQL |
| Architecture ref | `continuumSoxRangerDbMysql` |
| Purpose | Stores SOX-scoped Apache Ranger policies for controlled, SOX-compliant workloads |
| Ownership | owned |
| MySQL version | MYSQL_5_7 |
| Network | Private IP only (SOX VPC) |
| Backups | Enabled with binary logging |

#### Access Patterns

- **Read**: SOX backend cluster reads SOX-specific Ranger policies via JDBC
- **Write**: SOX Ranger Admin UI on the SOX backend cluster master

### GCS Staging and Initialization Buckets (`continuumBuckets`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `continuumBuckets` |
| Purpose | Hosts Dataproc staging objects, cluster initialization action scripts, and KMS-encrypted Ranger credential files |
| Ownership | owned |
| Bucket naming pattern | `grp-dpc-{env_short_name}-{env_stage}-analytics-backend` (analytics), `grp-dpc-{env_short_name}-{env_stage}-ll-analytics-proxy` (proxy), `grpn-dnd-{env_short_name}-{env_stage}-ranger` (secrets), `grpn-dnd-{env_short_name}-{env_stage}-solr` (audit) |
| Lifecycle | 30-day delete rule on staging buckets |
| Access control | Uniform bucket-level access; `roles/storage.objectAdmin` granted to `loc-sa-dataproc-longlived-jdbc` service account |

#### Key Stored Objects

| Object path pattern | Purpose |
|--------------------|---------|
| `initialization-actions/jdbc-long-lived-cluster/knox/knox.sh` | Knox gateway initialization script |
| `initialization-actions/jdbc-long-lived-cluster/analytics-proxy-configure.sh` | Proxy cluster configuration script |
| `initialization-actions/jdbc-long-lived-cluster/configure-analytics-backend.sh` | Analytics backend initialization script |
| `initialization-actions/jdbc-long-lived-cluster/configure-pipelines-backend.sh` | Pipelines backend initialization script |
| `initialization-actions/jdbc-long-lived-cluster/configure-analytics-op-backend.sh` | OP backend initialization script |
| `initialization-actions/jdbc-long-lived-cluster/configure-analytics-tableau-backend.sh` | Tableau backend initialization script |
| `ranger/ranger-admin-password.encrypted` | KMS-encrypted Ranger admin password |
| `ranger/mysql-root-password.encrypted` | KMS-encrypted MySQL root password |

#### Access Patterns

- **Read**: Dataproc cluster nodes read initialization scripts at startup time; backend clusters read encrypted secrets via `dataproc:ranger.admin.password.uri` and `dataproc:ranger.cloud-sql.root.password.uri`
- **Write**: Terraform Terragrunt apply writes encrypted secrets to the ranger bucket via `gsutil cp`

### SOX GCS Buckets (`continuumSoxBuckets`)

| Property | Value |
|----------|-------|
| Type | GCS |
| Architecture ref | `continuumSoxBuckets` |
| Purpose | SOX-specific staging and secrets buckets |
| Ownership | owned |

## Caches

> No evidence found in codebase. The OWNERS_MANUAL.md explicitly states "No cache is enabled at the moment."

## Data Flows

- Backend clusters read curated datasets from BigQuery Warehouse via Spark SQL/JDBC and write results back to BigQuery
- Ranger secrets (passwords) are encrypted by Cloud KMS, stored in GCS, and read by Dataproc cluster startup via `dataproc:ranger.*` properties
- Ranger audit logs are written to GCS Solr bucket paths (`dataproc:solr.gcs.path`) and indexed by the Solr component on each backend cluster
- Staging buckets accumulate Dataproc job artifacts, subject to 30-day lifecycle deletion
