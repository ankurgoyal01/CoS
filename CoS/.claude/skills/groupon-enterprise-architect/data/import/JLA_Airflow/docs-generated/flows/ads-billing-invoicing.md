---
service: "JLA_Airflow"
title: "Ads Billing and Invoicing Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "ads-billing-invoicing"
flow_type: scheduled
trigger: "Daily cron at 13:10 UTC (`10 13 * * *`)"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "snaplogic-http"
  - "netsuite-integration-service"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# Ads Billing and Invoicing Pipeline

## Summary

The Ads Billing and Invoicing pipeline consists of two coordinated DAGs that run daily. The first DAG (`jla-pipeline-ads-billing`) ingests raw ads billing data from Teradata source schemas into the `ACCT_JLA_ADS_BILLING` table and simultaneously triggers a SnapLogic pipeline to transfer Salesforce contract PDFs to the NetSuite file cabinet. The second DAG (`jla-pipeline-ads-invoicing`) invokes the JLA Aggregation Service (AGGS) to aggregate the billing data, create invoice audit records, and stage invoices in `ACCT_JLA_INVOICE`/`ACCT_JLA_INVOICE_ITEM`, which are then created as invoice objects in NetSuite by the NetSuite integration service.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron — `jla-pipeline-ads-billing` at `10 13 * * *`; `jla-pipeline-ads-invoicing` at a separate schedule (both daily)
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Schedules and runs both ads pipeline DAGs | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes SQL ingestion against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores process UUID, process log state | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`) | Source (`user_gp.ads_billing`) and target (`ACCT_JLA_ADS_BILLING`) | `unknown_teradata_platform` (stub) |
| SnapLogic | Transfers Salesforce contract PDFs to NetSuite file cabinet | External (no architecture ref) |
| NetSuite Integration Service | Creates invoice objects in NetSuite ERP | `unknown_netsuiteintegrationservice_700f4412` (stub) |
| JLA AGGS (Aggregation Service) | Aggregates billing data and stages invoices | Internal JLA service |

## Steps

### Ads Billing DAG (`jla-pipeline-ads-billing`)

1. **Start pipeline**: Marks DAG start with `start_pipeline_ads_billing` empty operator.
   - From: Airflow scheduler

2. **Generate process UUID**: Creates a UUID `process_id` and pushes to XCom.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

3. **Create process log**: Inserts process tracking record via `ProcessLog.create()`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd` (`acct_jla_run_process`)
   - Protocol: JDBC/SQL

4. **Ingest ads billing data**: Executes `ingest_ads_billing.sql` against Teradata — reads from `user_gp` (ads) schema and writes to `ACCT_JLA_ADS_BILLING` in `dwh_fsa_prd`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

5. **Trigger Salesforce contract to NetSuite**: HTTP GET to SnapLogic (`http_snaplogic_sftons`) to pull Salesforce contract PDFs and upload to NetSuite file cabinet.
   - From: `continuumJlaAirflowOrchestrator`
   - To: SnapLogic endpoint
   - Protocol: HTTP GET

6. **Update process log**: Marks process as successful via `ProcessLog.success()`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

### Ads Invoicing DAG (`jla-pipeline-ads-invoicing`)

7. **Invoke AGGS aggregation service**: Calls the JLA Aggregation Service to aggregate `ACCT_JLA_ADS_BILLING`, create `ACCT_JLA_INVOICE_AUDIT` records, and stage invoices into `ACCT_JLA_INVOICE` / `ACCT_JLA_INVOICE_ITEM`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: JLA AGGS service
   - Protocol: HTTP

8. **NetSuite invoice creation**: AGGS calls the NetSuite integration service to create the staged invoice objects in NetSuite ERP.
   - From: AGGS / `continuumJlaAirflowOrchestrator`
   - To: NetSuite integration service
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ads billing SQL ingestion failure | `on_failure_callback` fires | Google Chat `ENGINEERING_ALERTS` alert; DAG fails |
| SnapLogic HTTP failure | `on_failure_callback` fires | Google Chat alert; ads billing DAG fails; invoicing DAG does not run |
| NetSuite invoice creation failure | `on_failure_callback` fires | Google Chat alert; invoice records remain staged in Teradata; manual rerun required |

## Sequence Diagram

```
Scheduler -> jla-pipeline-ads-billing: trigger (13:10 UTC daily)
jla-pipeline-ads-billing -> teradata (dwh_fsa_prd): ingest ads billing data -> ACCT_JLA_ADS_BILLING
jla-pipeline-ads-billing -> SnapLogic: HTTP GET (Salesforce contract PDF transfer)
jla-pipeline-ads-invoicing -> AGGS: invoke aggregation
AGGS -> teradata (dwh_fsa_prd): write ACCT_JLA_INVOICE_AUDIT, ACCT_JLA_INVOICE, ACCT_JLA_INVOICE_ITEM
AGGS -> NetSuite integration service: create invoices in NetSuite
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [JLA ETL Pipeline](jla-etl-pipeline.md), [Customer Sync Pipeline](customer-sync.md)
- Confluence: https://confluence.groupondev.com/x/RUbpE
