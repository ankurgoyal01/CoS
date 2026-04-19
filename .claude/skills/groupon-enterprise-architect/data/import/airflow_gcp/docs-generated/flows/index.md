---
service: "airflow_gcp"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Airflow GCP (SFDC ETL).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [EDW-to-Salesforce Delta Sync](edw-to-salesforce-delta-sync.md) | scheduled | Airflow cron schedule (varies per DAG) | Queries Teradata EDW, extracts current Salesforce state, computes delta, and bulk-updates Salesforce. Used by `dwh_dag`, `rad_deal_score_dag`, and others. |
| [EDW-to-Salesforce Direct Sync](edw-to-salesforce-direct-sync.md) | scheduled | Airflow cron schedule (varies per DAG) | Queries Teradata EDW and directly bulk-inserts or bulk-upserts results into Salesforce without delta computation. Used by `aggregated_refunds_data_dag`, `sf_deal_alerts_dag`, `high_refunder_dag`, `sf_supply_pyramid_dag`, and others. |
| [DWH DAG Data Synchronization](dwh-dag-sync.md) | scheduled | Daily at 07:00 UTC (`00 07 * * *`) | Full extract-compare-update cycle for the `dwh_dag`: reads `Account.DWH_Merchant_ID__c` from Salesforce and from Teradata, computes the delta, and bulk-updates Salesforce. This flow has a corresponding architecture dynamic view. |
| [Secrets Reload](secrets-reload.md) | scheduled | Monthly on day 1 at 10:00 UTC (`0 10 1 * *`) | Reads the secrets JSON blob from GCS and sets corresponding Airflow Variables, refreshing runtime credentials without a redeployment. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The DWH DAG sync flow has a corresponding Structurizr dynamic view:

- `dynamic-airflow-gcp-dwh-dag-sync` — see [DWH DAG Data Synchronization](dwh-dag-sync.md)

All flows in this service cross the Continuum platform boundary into external systems: Salesforce (destination), Teradata EDW (source), and Google Cloud Storage (staging). No cross-service flows exist within the Continuum internal service mesh.
