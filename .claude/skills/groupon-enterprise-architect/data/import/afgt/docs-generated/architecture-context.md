---
service: "afgt"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAfgtAirflowDag, continuumAfgtDataprocBatch, continuumAfgtHiveDataset]
---

# Architecture Context

## System Context

AFGT is a batch data engineering pipeline within the `continuumSystem` (Continuum Platform). It sits in the analytics/BI layer of Groupon's data infrastructure, consuming read-only data from the Enterprise Data Warehouse (Teradata EDW) and writing enriched financial transaction analytics into the IMA Hive data lake on Google Cloud Storage. It is scheduled and orchestrated by the shared Apache Airflow (Cloud Composer) platform and runs compute on ephemeral Google Cloud Dataproc clusters. It is consumed by downstream BI DAGs and reporting tools.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AFGT TD Airflow DAG | `continuumAfgtAirflowDag` | Orchestration / Batch | Python, Apache Airflow | 2.x | Daily orchestration DAG (`afgt_sb_td`) that runs AFGT transfer stages and Hive load tasks |
| AFGT Dataproc Batch Jobs | `continuumAfgtDataprocBatch` | Batch / Compute | Google Cloud Dataproc (Pig/Hive/Shell/Sqoop) | — | Ephemeral Dataproc cluster execution for shell, Sqoop, and Hive jobs |
| AFGT Hive Dataset | `continuumAfgtHiveDataset` | Database | Hive on GCS | — | Hive tables in IMA storage used for temporary and final AFGT tables |

## Components by Container

### AFGT TD Airflow DAG (`continuumAfgtAirflowDag`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Orchestrator (`afgtDagOrchestrator`) | Defines task graph and scheduling for `afgt_sb_td`; controls execution order of all tasks | Airflow DAG |
| Precheck Sensors (`afgtPrecheckSensors`) | Waits for upstream DAG completion signals (`DLY_OGP_FINANCIAL_varRUNDATE_0003` and `go_segmentation`) before execution | PythonSensor |
| Dataproc Cluster Lifecycle (`afgtDataprocClusterLifecycle`) | Creates and tears down the ephemeral Dataproc cluster (`afgt-sb-td`) for each run | DataprocCreateClusterOperator / DataprocDeleteClusterOperator |
| Dataproc Job Submission (`afgtDataprocJobSubmission`) | Submits Pig-wrapped shell and Hive jobs that invoke stage scripts and SQL | DataprocSubmitJobOperator |
| Notification & Trigger Adapters (`afgtNotificationAndTriggerAdapters`) | Sends Google Chat / email alerts and triggers downstream jobs via Optimus Prime API and TriggerDagRunOperator | BashOperator / HttpOperator / TriggerDagRunOperator |

### AFGT Dataproc Batch Jobs (`continuumAfgtDataprocBatch`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Stage Shell Job Runner (`afgtStageShellJobRunner`) | Runs stage scripts `sb_act_deact.sh`, `sb_deals.sh`, `sb_afgt_stg1.sh`, `sb_pay_type.sh`, `sb_afgt_stg2.sh`, `sb_afgt_stg3.sh`, `sb_afgt_intl_stg4.sh`, `sb_afgt_na_stg4.sh`, `sb_final_table.sh`, `update_deact.sh`, `sb_rma_deals.sh`, `sb_rma_promos.sh` to transform data in Teradata | Shell scripts (BTEQ) |
| Teradata Extraction Runner (`afgtTdExtractionScriptRunner`) | Runs `afgt_td_extract.sh` to stage a date-filtered snapshot of `sb_rmaprod.analytics_fgt` into the transfer table `sb_rmaprod.analytics_fgt_transfer_gcp` | BTEQ script |
| Teradata to Hive Sqoop Runner (`afgtSqoopImportRunner`) | Runs `td_to_hive.sh` to import `sb_rmaprod.analytics_fgt_transfer_gcp` from Teradata into Hive staging table `ima.analytics_fgt_tmp_zo` on GCS via Sqoop | Sqoop |
| Hive Load Runner (`afgtHiveLoadRunner`) | Runs `hive_load_final.hql` to join staging data with RFM segments and load the final `ima.analytics_fgt` table partitioned by `transaction_date` and `country_id` | Hive (Tez) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAfgtAirflowDag` | `continuumAfgtDataprocBatch` | Creates Dataproc cluster and submits all batch jobs | GCP API (Dataproc operators) |
| `continuumAfgtDataprocBatch` | `continuumAfgtHiveDataset` | Writes temporary staging table (`analytics_fgt_tmp_zo`) and final table (`analytics_fgt`) | Hive / GCS write |
| `continuumAfgtDataprocBatch` | `edw` | Reads transaction and dimension data from Teradata; stages AFGT data via BTEQ/Sqoop | JDBC / BTEQ / Sqoop |
| `continuumAfgtAirflowDag` | `optimusPrime` | Triggers validation job run after pipeline stages complete | HTTP POST (`api/v2/users/rpadala/jobs/6497/runs`) |
| `continuumAfgtAirflowDag` | `googleChat` | Posts completion and failure alerts to the RMA Google Chat space | HTTPS webhook (curl) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-afgt`
- Component (Airflow DAG): `components-afgt-airflow`
- Component (Dataproc Batch): `components-afgt-dataproc`
- Dynamic view (disabled in federation): `dynamic-afgt_td_to_hive_load`
