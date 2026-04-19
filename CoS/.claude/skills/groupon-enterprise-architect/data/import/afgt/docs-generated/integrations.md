---
service: "afgt"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 3
---

# Integrations

## Overview

AFGT integrates with six external systems and three internal Airflow-based systems. The dominant integration pattern is outbound batch read from Teradata EDW via BTEQ and JDBC/Sqoop, with secondary integrations to GCP-managed services (Dataproc, GCS, Dataproc Metastore, Secret Manager) and outbound HTTP/webhook calls for validation and alerting. There is no inbound integration pattern — the pipeline is initiated exclusively by Airflow scheduler.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Teradata EDW (`teradata.groupondev.com`) | BTEQ / JDBC (Sqoop) | Source of all global financial transaction, dimension, attribution, OGP, and segment data | yes | `edw` |
| Google Cloud Dataproc | GCP API | Managed ephemeral compute cluster for running Pig/Shell/Hive/Sqoop batch jobs | yes | `googleCloudDataproc_faedcd55` |
| Google Cloud Storage (IMA bucket) | GCS API | Stores Hive table data, pipeline artifacts, initialization scripts | yes | `googleCloudStorage_833c2c21` |
| Dataproc Metastore Service | GCP API | Provides Hive Metastore for Dataproc cluster | yes | `dataprocMetastoreService_4d45a58a` |
| Google Secret Manager | GCP API | Stores Teradata password (`ub_ma_emea_password_file`) copied into Dataproc cluster at startup | yes | `googleSecretManager_5c1727f9` |
| Optimus Prime API | HTTP POST | Triggers validation job run after pipeline stage completion | no | `optimusPrime` |
| Google Chat | HTTPS webhook | Posts pipeline completion and failure alerts to the RMA Google Chat space | no | `googleChat` |

### Teradata EDW Detail

- **Protocol**: BTEQ (Basic Teradata Query) for staging DML; JDBC via Sqoop for bulk export to Hive
- **Base URL / SDK**: DSN `teradata.groupondev.com`, port 1025, CHARSET UTF8; JDBC driver `com.teradata.jdbc.TeraDriver`; connection manager `org.apache.sqoop.manager.GenericJdbcManager`
- **Auth**: Username/password from environment variables `USER_TD=ub_ma_emea` and `USER_TD_PASS` (sourced from `ub_ma_emea_password_file.txt` secret)
- **Purpose**: Reads and transforms financial transaction data across multiple staging steps; Sqoop exports the final transfer table to GCS
- **Failure mode**: BTEQ task fails and Airflow retries once after 1800 seconds; failure triggers Google Chat alert and `trigger_event` callback
- **Circuit breaker**: No — relies on Airflow retry configuration

### Google Cloud Dataproc Detail

- **Protocol**: GCP API via `DataprocCreateClusterOperator` / `DataprocSubmitJobOperator` / `DataprocDeleteClusterOperator`
- **Base URL / SDK**: Airflow `airflow.providers.google.cloud.operators.dataproc`; region `us-central1`
- **Auth**: Service accounts per environment — `loc-sa-consumer-dataproc@prj-grp-consumer-dev-14a6.iam.gserviceaccount.com` (dev), `loc-sa-consumer-dataproc@prj-grp-revmgmt-prod-ef0c.iam.gserviceaccount.com` (prod)
- **Purpose**: Provides ephemeral compute cluster (`afgt-sb-td`) for executing Shell/Pig/Hive/Sqoop batch jobs
- **Failure mode**: Cluster creation failure blocks all downstream tasks; Airflow retries once; delete_cluster runs on all completion paths
- **Circuit breaker**: No

### Optimus Prime API Detail

- **Protocol**: HTTP POST
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-west-2.aws.groupondev.com` (from `afgt_vars.json`); Airflow `HttpOperator` with `http_conn_id="ep-prod-gcp-us-central1"`
- **Auth**: `user-id: rpadala` header; TLS verification disabled (`verify: False`)
- **Purpose**: Triggers Optimus Prime validation job `6497` to validate pipeline output after staging stages complete
- **Failure mode**: Task failure does not block `afgt_sqoop_tmp` or downstream tasks (runs in parallel with `afgt_td_tmp` and `gspace_alert_td`)
- **Circuit breaker**: No

### Google Chat Webhook Detail

- **Protocol**: HTTPS POST (curl)
- **Base URL / SDK**: Webhook URL from `gspace_rma` field in `afgt_vars.json`; posts JSON `{"text": "..."}` payload
- **Auth**: Pre-authorized webhook URL (token embedded in URL)
- **Purpose**: Posts completion messages for TD and Hive stages; posts failure alerts via `on_failure_callback`
- **Failure mode**: Non-critical; alert failure does not block pipeline
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Apache Airflow (Cloud Composer) | Airflow scheduler | Hosts and schedules the `afgt_sb_td` DAG; manages task state and retry | `airflowPlatform_e52e347b` |
| `DLY_OGP_FINANCIAL_varRUNDATE_0003` DAG | PythonSensor (`CheckRuns.check_daily_completion`) | Precheck — ensures daily OGP financial data is ready before AFGT starts | internal Airflow |
| `go_segmentation` DAG | PythonSensor (`CheckRunsLegacy.monitoring_task`) | Precheck — ensures GO segmentation pipeline has completed | internal Airflow |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `rma-gmp-wbr-load` DAG | `TriggerDagRunOperator` | Triggered by AFGT after `hive_load` completes to process GMP/WBR reports |
| BI / reporting tools | Hive / Spark / query engine | Reads `ima.analytics_fgt` for revenue management, marketing attribution, and business intelligence reporting |

> Upstream consumers of `ima.analytics_fgt` beyond `rma-gmp-wbr-load` are tracked in the central architecture model and IMA data catalog.

## Dependency Health

- **Teradata EDW**: No health check endpoint; failures surfaced via BTEQ non-zero exit codes, which fail the Dataproc Pig job; Airflow retries the failed task once after 30 minutes
- **Google Cloud Dataproc**: Cluster creation and deletion managed by GCP; failures are surfaced as Airflow operator exceptions; `idle_delete_ttl` of 1800s (dev/stable) or 3600s (prod) acts as a safety net against orphaned clusters
- **Google Secret Manager**: Secrets are copied at cluster startup via `CopySecretOperator`; failure blocks the pipeline before any compute jobs start
- **Optimus Prime / Google Chat**: Non-critical paths; failures do not block the main data flow
