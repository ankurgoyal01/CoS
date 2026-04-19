---
service: "cls-optimus-jobs"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["optimus-job-params", "yaml-job-context", "hive-session-vars"]
---

# Configuration

## Overview

CLS Optimus Jobs are configured through three mechanisms:

1. **YAML job context blocks** — each job YAML file contains a `context:` block with default values for `local_dir`, `hdfs_dir`, `record_date`, `start_date`, `end_date`, and `record_month`. These defaults are overridden at runtime by Optimus parameter injection.
2. **Optimus runtime parameters** — date range parameters are injected by the Optimus scheduler at job execution time using Bash expressions (e.g., `date -d "1 day ago" '+%Y-%m-%d'`).
3. **Hive session variables** — HQL statements set Hive execution properties at the start of each task via `SET` statements.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `start_date` | Start date for Teradata data extraction window (YYYY-MM-DD) | yes (delta jobs) | `date -d "1 day ago" '+%Y-%m-%d'` (previous day) | Optimus param (Bash type) |
| `end_date` | End date for Teradata data extraction window (YYYY-MM-DD) | yes (delta jobs) | `date '+%Y-%m-%d'` (current day) | Optimus param (Bash type) |
| `record_date` | Partition date written to Hive target tables (YYYY-MM-DD) | yes | `date '+%Y-%m-%d'` (current day) | Optimus param (Bash type) |
| `record_month` | Month partition key derived from record_date (YYYY-MM) | yes (coalesce jobs) | Derived from context YAML | YAML context block |
| `janus_record_date` | Janus dataset partition date for CDS Janus delta job (YYYY-MM-DD) | yes (`CDS_Data_NA_from_janus_delta`) | `date -d "1 day ago" '+%Y-%m-%d'` (previous day) | Optimus param (Bash type) |
| `hour` | Hour filter for GRP20 Janus data export | yes (`GRP20_Data_from_NA`) | `date -d '3 hours ago' "+%k"` | Optimus param (Bash type) |
| `loadkey` | Unique Optimus execution key used to namespace `local_dir` and `hdfs_dir` | yes | Injected by Optimus runtime | Optimus internal |
| `local_dir` | Local sandbox directory on Optimus worker for temporary file storage | yes | `/var/groupon/optimus/sandbox/<job_id>/${loadkey}` | YAML context block |
| `hdfs_dir` | HDFS sandbox path for job working files | yes | `hdfs://cerebro-namenode.snc1:8020/user/optimus_app/sandbox/<job_id>/${loadkey}` | YAML context block |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flags are used by this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `coalesce_billing_na.yml` | YAML | Optimus job definition for billing NA backfill coalesce |
| `coalesce_billing_na_delta.yml` | YAML | Optimus job definition for billing NA delta coalesce |
| `coalesce_billing_emea.yml` | YAML | Optimus job definition for billing EMEA backfill coalesce |
| `coalesce_billing_emea_delta.yml` | YAML | Optimus job definition for billing EMEA delta coalesce |
| `coalesce_shipping_na.yml` | YAML | Optimus job definition for shipping NA backfill coalesce |
| `coalesce_shipping_na_delta.yml` | YAML | Optimus job definition for shipping NA delta coalesce |
| `coalesce_shipping_emea.yml` | YAML | Optimus job definition for shipping EMEA backfill coalesce |
| `coalesce_shipping_emea_delta.yml` | YAML | Optimus job definition for shipping EMEA delta coalesce |
| `coalesce_cds_na_delta.yml` | YAML | Optimus job definition for CDS NA delta coalesce |
| `CDS_Data_NA_from_janus_delta.yml` | YAML | Optimus job definition for CDS Janus NA delta ingestion |
| `cls-billing-na-delta` (text) | Plain text (Optimus export) | Billing NA delta ingestion job steps and parameters |
| `cls-billing-na-backfill` (text) | Plain text (Optimus export) | Billing NA backfill ingestion job steps |
| `cls-billing-emea-backfill` (text) | Plain text (Optimus export) | Billing EMEA backfill ingestion job steps |
| `cls_billing_emea-delta` (text) | Plain text (Optimus export) | Billing EMEA delta ingestion job steps |
| `Shipping_data_from_NA_delta` (text) | Plain text (Optimus export) | Shipping NA delta ingestion job steps |
| `Shipping_data_from_EMEA_delta` (text) | Plain text (Optimus export) | Shipping EMEA delta ingestion job steps |
| `CDS_Data_from_NA_delta` (text) | Plain text (Optimus export) | CDS NA delta ingestion job steps |
| `GRP20_Data_from_NA` (text) | Plain text (Optimus export) | GRP20 Janus NA location data ingestion job steps |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Teradata DSN credentials (`shipping_Data_Jobs`) | Authenticates Optimus `SQLExport` tasks against Teradata NA/EMEA | Optimus DSN configuration |
| Hive DSN credentials (`hive_underjob`, `shipping_hive_access_underjob`, `cds_hive_access_underjob`) | Authenticates HQLExecute tasks against Cerebro Hive | Optimus DSN configuration |

> Secret values are NEVER documented. Only names and purposes.

## Hive Session Configuration

All HQL task blocks set the following Hive session properties at the start of each step:

| Property | Value | Purpose |
|----------|-------|---------|
| `hive.tez.container.size` | `8192` | Tez container memory in MB |
| `hive.tez.java.opts` | `-Xmx6000M` | JVM heap for Tez tasks |
| `hive.execution.engine` | `tez` | Use Apache Tez execution engine |
| `tez.queue.name` | `public` | YARN queue for Tez containers |
| `hive.exec.dynamic.partition.mode` | `nostrict` | Allows dynamic partition inserts without requiring at least one static partition |
| `hive.support.concurrency` | `true` | Enables concurrent Hive operations |
| `hive.enforce.bucketing` | `true` | Enforces bucketing configuration |
| `hive.txn.manager` | `org.apache.hadoop.hive.ql.lockmgr.DbTxnManager` | Transaction manager for ACID operations |

## Per-Environment Overrides

- **Staging**: Jobs are configured to use `cls_staging` database and staging Hive tables. The `record_date` and date range params are set to recent dates for validation. Jobs run on the staging Optimus environment.
- **Production**: Jobs use `grp_gdoop_cls_db` and live Teradata DSNs. Date parameters default to previous-day/current-day Bash expressions. Jobs run on the production Optimus environment at `optimus.groupondev.com`.
- **Manual re-run**: Operators substitute the `date` Bash command with `echo '<YYYY-MM-DD>'` in the Optimus UI to feed a specific historical date.
