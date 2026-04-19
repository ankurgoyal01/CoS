---
service: "coupons-commission-dags"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["airflow-variables", "config-files"]
---

# Configuration

## Overview

coupons-commission-dags uses two configuration mechanisms: an Airflow Variable (`env`) that selects the active environment at DAG load time, and per-environment JSON config files stored under `orchestrator/config/{env}/` for each DAG. The JSON files define all operational parameters: GCP project, region, cluster specs, schedule intervals, Spark JAR URIs, Spark job properties, and default DAG run parameters. There are no Helm values, Vault secrets, or external config stores referenced in the codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Selects the active environment config directory (`dev`, `stable`, `prod`); loaded at DAG parse time via `Variable.get("env")` | yes | none | Airflow Variable store |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flags are used.

## Config Files

All config files are JSON and live under `orchestrator/config/{env}/`:

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/config/{env}/coupons_comm_report_sourcing.json` | JSON | Monthly sourcing DAG: GCP project, cluster name, schedule, cluster config, Spark JAR URI and args |
| `orchestrator/config/{env}/coupons_comm_report_transform.json` | JSON | Monthly transform DAG: GCP project, cluster name, schedule, cluster config, Spark JAR URI and args |
| `orchestrator/config/{env}/coupons_comm_report_agg.json` | JSON | Monthly aggregation DAG: GCP project, cluster name, schedule, cluster config, Spark JAR URI and args |
| `orchestrator/config/{env}/coupons_comm_report_dailyawin_sourcing.json` | JSON | Daily Awin sourcing DAG: GCP project, cluster name, schedule, accounts list, Spark JAR URI and args |
| `orchestrator/config/{env}/coupons_comm_report_dailyawin_transform.json` | JSON | Daily Awin transform DAG: GCP project, cluster name, schedule, reports list, Spark JAR URI and args |
| `orchestrator/config/{env}/coupons_comm_report_dailyawin_agg.json` | JSON | Daily Awin aggregation DAG: GCP project, cluster name, schedule, reports list, Spark JAR URI and args |

### Key JSON config fields (all DAGs)

| Field | Purpose | Example (prod) |
|-------|---------|----------------|
| `id` | Airflow DAG ID | `coupons-comm-report-sourcing` |
| `project_id` | GCP project for Dataproc cluster | `prj-grp-c-common-prod-ff2b` |
| `region` | GCP region for Dataproc cluster | `us-central1` |
| `cluster_name` | Name of the ephemeral Dataproc cluster | `cpns-comm-rpt-sourcing-prod-cluster` |
| `schedule_interval` | Airflow cron schedule or `None` | `0 2 1 * *` (monthly), `0 2 * * *` (daily) |
| `cluster_config.gce_cluster_config.service_account` | GCP service account for Dataproc VMs | `loc-sa-c-coupons-comm-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com` |
| `cluster_config.gce_cluster_config.subnetwork_uri` | VPC subnetwork for Dataproc cluster | `sub-vpc-prod-sharedvpc01-us-central1-private` |
| `cluster_config.software_config.image_version` | Dataproc image version | `1.5-debian10` |
| `cluster_config.metastore_config.dataproc_metastore_service` | Dataproc Metastore reference | `projects/prj-grp-datalake-prod-8a19/.../grpn-dpms-prod-analytics` |
| `jobs.spark_job1.job_config.jar_file_uris` | Spark assembly JAR URL from Artifactory | See Integrations |
| `jobs.spark_job1.job_config.main_class` | Spark main class to execute | `com.groupon.accountingautomation.SourcingMainJob` |
| `jobs.spark_job1.job_config.args` | Spark CLI arguments | `--sourcing_start_date`, `--sourcing_end_date`, `--accounts_to_run` |
| `labels.service` | GCP resource label for cost attribution | `coupons-commission-reporting` |

### DAG default parameters

| Parameter | DAG | Default value | Purpose |
|-----------|-----|---------------|---------|
| `sourcing_start_date` | Monthly sourcing | 12 months before last day of previous month | Start of data window for sourcing |
| `sourcing_end_date` | Monthly sourcing | Last day of previous month | End of data window for sourcing |
| `accounts_to_run` | Monthly sourcing | Full list of ~80 affiliate accounts (IR, AWIN, Partnerize, eBay, Skimlinks, etc.) | Comma-separated affiliate account identifiers |
| `processing_end_date` | Monthly transform, monthly agg | Last day of previous month | End of processing window |
| `reports_to_run` | Monthly transform, monthly agg | `IR_NA,IR_INTL,AWIN_NA,AWIN_INTL,Partnerize_NA,...` | Comma-separated report group identifiers |
| `accounts_to_run` | Daily Awin sourcing | 25 DailyAwin accounts across multiple countries | Comma-separated Awin-specific account identifiers |
| `reports_to_run` | Daily Awin transform, daily Awin agg | `DailyAwin_NA,DailyAwin_INTL` | Report groups for daily Awin pipeline |

## Secrets

> No evidence found in codebase of explicit secret references. GCP authentication is handled via the Dataproc VM service account bound in `cluster_config.gce_cluster_config.service_account`, managed externally in GCP IAM.

## Per-Environment Overrides

| Setting | dev (`prj-grp-consumer-dev-14a6`) | stable (`prj-grp-c-common-stable-c036`) | prod (`prj-grp-c-common-prod-ff2b`) |
|---------|-----------------------------------|-----------------------------------------|--------------------------------------|
| `schedule_interval` | `None` (monthly DAGs paused) | `None` (monthly DAGs paused) | Cron-scheduled (active) |
| `is_paused_upon_creation` | `True` (monthly) / `False` (daily) | `True` (monthly) / `False` (daily) | `True` (monthly) / `False` (daily) |
| JAR channel | Artifactory `snapshots/` | Artifactory `releases/` | Artifactory `releases/` |
| Metastore | `grpn-dpms-dev-analytics` | `grpn-dpms-stable-analytics` | `grpn-dpms-prod-analytics` |
| Service account | `loc-sa-consumer-dataproc@prj-grp-consumer-dev-14a6` | `loc-sa-c-coupons-comm-dataproc@prj-grp-c-common-stable-c036` | `loc-sa-c-coupons-comm-dataproc@prj-grp-c-common-prod-ff2b` |
| Spark `env` property | `staging` | `staging` | `prod` |
