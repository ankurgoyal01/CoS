---
service: "airflow_gcp"
title: "DWH DAG Data Synchronization"
generated: "2026-03-03"
type: flow
flow_name: "dwh-dag-sync"
flow_type: scheduled
trigger: "Daily cron at 07:00 UTC (00 07 * * *)"
participants:
  - "airflowGcp_dagDefinitions"
  - "airflowGcp_dagHelpers"
  - "airflowGcp_teradataConnector"
  - "airflowGcp_salesforceHook"
  - "airflowGcp_gcsIo"
  - "airflowGcp_secretManager"
  - "continuumSfdcEtlWorkingStorageGcs"
  - "salesForce"
  - "continuumTeradataEdwStub"
architecture_ref: "dynamic-airflow-gcp-dwh-dag-sync"
---

# DWH DAG Data Synchronization

## Summary

The `dwh_dag` synchronizes the `DWH_Merchant_ID__c` field on Salesforce `Account` objects with the authoritative merchant ID mapping from the Teradata Enterprise Data Warehouse. The DAG extracts current values from both Salesforce and Teradata in parallel, computes the set of records where the two disagree or where Teradata has records missing from Salesforce, and submits a Salesforce Bulk API update job containing only the changed records. After the bulk job completes, results are saved to GCS and any failed records are re-submitted individually.

> Note: This DAG is paused upon creation and may no longer need active runs. The source table `user_edwprod.map_merchants_backfill` has not returned new merchants since August 2018 as the upstream source `dwh_base.merchants` (Citydeals) was deprecated. The DAG is documented here as the canonical example of the EDW-to-Salesforce delta sync pattern.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow cron scheduler on Cloud Composer
- **Frequency**: Daily at 07:00 UTC (`00 07 * * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Definitions | Defines task graph and wires up task dependencies for `dwh_dag` | `airflowGcp_dagDefinitions` |
| DAG Helpers | Executes query, GCS I/O, and diff operations shared across all tasks | `airflowGcp_dagHelpers` |
| Teradata Connector | Executes `sql/dwh_dag.sql` against `user_edwprod.map_merchants_backfill` | `airflowGcp_teradataConnector` |
| Salesforce Hook | Issues SOQL query to read current `Account.DWH_Merchant_ID__c` values; submits bulk update job | `airflowGcp_salesforceHook` |
| GCS I/O Utilities | Writes and reads staging CSVs; stores result files | `airflowGcp_gcsIo` |
| Secret Manager Utilities | Loads secrets and TLS certificates needed by connectors | `airflowGcp_secretManager` |
| SFDC ETL Working Storage | Holds all intermediate CSV files keyed by UUID run prefix | `continuumSfdcEtlWorkingStorageGcs` |
| Salesforce | Receives SOQL query; receives bulk update job | `salesForce` |
| Teradata EDW | Provides merchant ID mapping data | `continuumTeradataEdwStub` |

## Steps

1. **Generate run UUID**: Creates a unique identifier for this DAG run to namespace all GCS staging keys.
   - From: `airflowGcp_dagDefinitions`
   - To: Airflow XCom store
   - Protocol: Airflow internal (XCom)

2. **Load secrets**: Retrieves TLS certificates and runtime credentials from Google Secret Manager.
   - From: `airflowGcp_dagHelpers`
   - To: `airflowGcp_secretManager`
   - Protocol: direct (Python) — Google Secret Manager API

3. **Extract Salesforce data to GCS** (parallel with step 4): Issues SOQL query `SELECT Id, DWH_Merchant_ID__c FROM Account WHERE DWH_Merchant_ID__c != null`; writes result CSV to GCS under `{uuid}/dwh_dag/sf_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_salesforceHook`
   - To: `salesForce` (SOQL), then `continuumSfdcEtlWorkingStorageGcs` (write)
   - Protocol: HTTPS (Salesforce REST), then GCS API

4. **Extract Teradata data to GCS** (parallel with step 3): Executes `sql/dwh_dag.sql` against Teradata; streams rows via `teradatasql`; writes result CSV to GCS under `{uuid}/dwh_dag/teradata_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_teradataConnector`
   - To: `continuumTeradataEdwStub` (query), then `continuumSfdcEtlWorkingStorageGcs` (write)
   - Protocol: JDBC (teradatasql), then GCS API

5. **Compute delta**: Reads both staging CSVs from GCS; identifies records where `DWH_Merchant_ID__c` differs between Salesforce and Teradata, or where Teradata has records not present in Salesforce; writes delta CSV to GCS under `{uuid}/dwh_dag/delta_btw_sf_and_edw_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers`
   - To: `continuumSfdcEtlWorkingStorageGcs` (read SF CSV, read Teradata CSV, write delta CSV)
   - Protocol: GCS API

6. **Submit Salesforce bulk update**: Reads delta CSV from GCS; submits Salesforce Bulk API v1 update job for `Account` object with batch size 50,000; returns `job_id` and `ordered_batch_ids` via XCom.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_salesforceHook`
   - To: `continuumSfdcEtlWorkingStorageGcs` (read delta CSV), then `salesForce` (bulk job submit)
   - Protocol: GCS API, then HTTPS (Salesforce Bulk API v1)

7. **Save bulk update results to GCS**: Polls Salesforce for bulk job completion; retrieves per-batch results; writes results CSV to GCS (`bulk_upload_all_results.csv`); re-submits any failed records individually.
   - From: `airflowGcp_salesforceHook` and `airflowGcp_dagHelpers`
   - To: `salesForce` (poll results), `continuumSfdcEtlWorkingStorageGcs` (write results CSV), `salesForce` (resubmit failures)
   - Protocol: HTTPS (Salesforce Bulk API v1), then GCS API

8. **Cleanup GCS staging files** (parallel with step 9): Deletes temporary CSVs (`sf_gcs_key.csv`, `teradata_gcs_key.csv`, `delta_btw_sf_and_edw_gcs_key.csv`) from GCS.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_gcsIo`
   - To: `continuumSfdcEtlWorkingStorageGcs`
   - Protocol: GCS API

9. **Update Salesforce General Settings timestamp** (parallel with step 8): Updates the `dwh_dag` entry in the Salesforce General Settings object (`a05C000000FPFasIAH`) with the current run timestamp.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_salesforceHook`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce REST API)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce SOQL query failure | Airflow retries task once after 2-minute delay | If retry fails, DAG run marked failed; email alert to `sfint-dev-alerts@groupon.com` |
| Teradata query failure | Airflow retries task once after 2-minute delay | If retry fails, DAG run marked failed; email alert sent |
| GCS I/O failure | Airflow retries task once after 2-minute delay | If retry fails, DAG run marked failed; email alert sent |
| Bulk job submission failure | Task `submit_sf_bulk_update_request` has `retries=0`; fails immediately | DAG run marked failed; email alert sent |
| Records failing within bulk job | `resubmit_failed_records_to_sf_using_previous_results` re-submits each failed record | If resubmit fails, `AirflowException` is raised; DAG run marked failed |

## Sequence Diagram

```
Airflow Scheduler -> airflowGcp_dagDefinitions: Trigger dwh_dag on schedule
airflowGcp_dagDefinitions -> airflowGcp_dagHelpers: Invoke shared ETL routines
airflowGcp_dagHelpers -> airflowGcp_secretManager: Load secrets and certificates
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Query Account.DWH_Merchant_ID__c (SOQL)
airflowGcp_salesforceHook -> salesForce: GET /query?q=SELECT Id, DWH_Merchant_ID__c FROM Account
salesForce --> airflowGcp_salesforceHook: Account records CSV
airflowGcp_salesforceHook -> airflowGcp_gcsIo: Write sf_gcs_key.csv to GCS
airflowGcp_dagHelpers -> airflowGcp_teradataConnector: Execute dwh_dag.sql
airflowGcp_teradataConnector -> continuumTeradataEdwStub: SQL query (JDBC)
continuumTeradataEdwStub --> airflowGcp_teradataConnector: Merchant ID rows
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write teradata_gcs_key.csv to GCS
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Read both CSVs; compute delta; write delta_btw_sf_and_edw_gcs_key.csv
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Submit bulk update (Account, delta CSV)
airflowGcp_salesforceHook -> airflowGcp_gcsIo: Read delta CSV batches
airflowGcp_salesforceHook -> salesForce: POST /bulk/v1/job (Bulk API update)
salesForce --> airflowGcp_salesforceHook: Job ID, batch IDs
airflowGcp_dagHelpers -> salesForce: Poll bulk job status
salesForce --> airflowGcp_dagHelpers: Job results
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write bulk_upload_all_results.csv
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Delete temporary staging CSVs
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Update SF General Settings timestamp
airflowGcp_salesforceHook -> salesForce: Update General_Setting__c record
```

## Related

- Architecture dynamic view: `dynamic-airflow-gcp-dwh-dag-sync`
- Related flows: [EDW-to-Salesforce Delta Sync](edw-to-salesforce-delta-sync.md), [EDW-to-Salesforce Direct Sync](edw-to-salesforce-direct-sync.md)
