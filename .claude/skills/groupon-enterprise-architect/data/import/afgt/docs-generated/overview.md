---
service: "afgt"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Revenue Management Analytics / Business Intelligence"
platform: "Continuum / GCP Data Engineering"
team: "dnd-bia-data-engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Apache Airflow"
  framework_version: "2.x"
  runtime: "Google Cloud Dataproc"
  runtime_version: "1.5 (zombie-runner image)"
  build_tool: "Jenkins (java-pipeline-dsl)"
  package_manager: "pip (Airflow providers)"
---

# AFGT Overview

## Purpose

AFGT (Analytics Financial Global Transactions) is a daily scheduled data pipeline owned by the Revenue Management Analytics team. It extracts raw global financial transaction data from Groupon's Teradata Enterprise Data Warehouse, applies multi-step enrichment logic (activation/deactivation, deal attribution, payment type, segmentation, OGP, RFM scoring), and loads a final denormalized analytics table (`ima.analytics_fgt`) into the IMA Hive data lake on Google Cloud Storage. This dataset underpins revenue management, marketing attribution, and business intelligence reporting across all Groupon markets.

## Scope

### In scope
- Daily extraction of transaction records from `user_edwprod.fact_gbl_transactions` in Teradata
- Staging and enrichment across multiple BTEQ/Hive pipeline stages (`sb_afgt_stg1` through `sb_afgt_stg4`)
- Deal dimension enrichment from `sb_rmaprod.afgt_deal`
- Payment type classification (`sb_pay_type`)
- Activation and deactivation flag computation (`sb_act_deact`, `update_deact`)
- ILS (Instant Local Sale) and WOW subsidy discount enrichment
- Order attribution join via `sb_rmaprod.afgt_goa` view sourced from `user_groupondw.gbl_order_attribution`
- RMA deals and promotions staging (`sb_rma_deals`, `sb_rma_promos`)
- Sqoop import of Teradata staging table (`sb_rmaprod.analytics_fgt_transfer_gcp`) into Hive staging (`ima.analytics_fgt_tmp_zo`)
- Final Hive load into `ima.analytics_fgt` partitioned by `transaction_date` and `country_id`
- OGP (Offer Gross Profit) enrichment from `user_edwprod.fact_gbl_ogp_transactions`
- RFM segment enrichment from `ima.user_rfm_segment_act_react`
- Post-pipeline trigger of the `rma-gmp-wbr-load` downstream DAG
- Optimus Prime validation job triggering
- Google Chat and email alerting on completion and failure

### Out of scope
- Real-time or near-real-time transaction processing
- Writing back to Teradata production tables (read-only from EDW)
- Serving query APIs or HTTP endpoints
- Consumer-facing UI or merchant-facing UI
- Ownership of `user_edwprod.fact_gbl_transactions` or upstream EDW tables

## Domain Context

- **Business domain**: Revenue Management Analytics / Business Intelligence
- **Platform**: Continuum / GCP Data Engineering
- **Upstream consumers**: `rma-gmp-wbr-load` downstream DAG; BI/reporting tools consuming `ima.analytics_fgt`
- **Downstream dependencies**: Teradata EDW (`user_edwprod`, `sb_rmaprod`, `user_groupondw`), Google Cloud Dataproc, Google Cloud Storage (IMA bucket), Dataproc Metastore, Optimus Prime API, Google Chat webhook, Apache Airflow platform, `go_segmentation` DAG, `DLY_OGP_FINANCIAL_varRUNDATE_0003` DAG

## Stakeholders

| Role | Description |
|------|-------------|
| Pipeline Owner | Revenue Management Analytics team (`rev_mgmt_analytics@groupon.com`) |
| Platform Team | dnd-bia-data-engineering — operates and deploys the pipeline |
| BI/Reporting Consumers | Teams consuming `ima.analytics_fgt` for revenue and marketing attribution reporting |
| SRE | Monitors via Slack channel `rma-pipeline-notifications` and Google Chat space |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `orchestrator/afgt_td.py` — Airflow DAG source |
| Framework | Apache Airflow | 2.x | `DataprocCreateClusterOperator`, `TriggerDagRunOperator` imports |
| Runtime | Google Cloud Dataproc | 1.5 (zombie-runner image) | `orchestrator/config/rm_afgt_connex_config.json` — `image_uri` field |
| Build tool | Jenkins | — | `Jenkinsfile` using `java-pipeline-dsl` shared library |
| Query engine | Hive (Tez) | — | `source/sql/hive_load_final.hql` — `hive.execution.engine=tez` |
| Extract tool | Sqoop | — | `scripts/td_to_hive.sh` |
| Extract tool | BTEQ | — | `scripts/afgt_td_extract.sh`, `scripts/sb_afgt_stg1.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `airflow.providers.google.cloud.operators.dataproc` | Airflow 2.x | scheduling | Create/delete Dataproc clusters and submit jobs |
| `airflow.operators.trigger_dagrun` | Airflow 2.x | scheduling | Trigger downstream DAG `rma-gmp-wbr-load` |
| `airflow.providers.http.operators.http` | Airflow 2.x | http-client | POST to Optimus Prime validation API |
| `airflow.sensors.python` | Airflow 2.x | scheduling | Precheck sensors for upstream DAG completion |
| `operators.copy_secret_operator` | internal | auth | Copies secrets from Secret Manager into Dataproc cluster |
| `preutils.Impl` | internal | scheduling | `trigger_event` / `resolve_event` for on-failure/on-success callbacks |
| `check_runs_plugin` / `check_runs_plugin1` | internal | scheduling | `CheckRuns.check_daily_completion` for OGP and segmentation precheck |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
