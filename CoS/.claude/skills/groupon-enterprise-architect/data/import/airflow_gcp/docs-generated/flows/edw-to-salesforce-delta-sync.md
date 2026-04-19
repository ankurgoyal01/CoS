---
service: "airflow_gcp"
title: "EDW-to-Salesforce Delta Sync"
generated: "2026-03-03"
type: flow
flow_name: "edw-to-salesforce-delta-sync"
flow_type: scheduled
trigger: "Airflow cron schedule (varies per DAG)"
participants:
  - "airflowGcp_dagDefinitions"
  - "airflowGcp_dagHelpers"
  - "airflowGcp_teradataConnector"
  - "airflowGcp_salesforceHook"
  - "airflowGcp_gcsIo"
  - "continuumSfdcEtlWorkingStorageGcs"
  - "salesForce"
  - "continuumTeradataEdwStub"
architecture_ref: "dynamic-airflow-gcp-dwh-dag-sync"
---

# EDW-to-Salesforce Delta Sync

## Summary

The EDW-to-Salesforce Delta Sync is the pattern used by DAGs that need to compare current Salesforce field values against the authoritative Teradata EDW state before submitting updates. Both data sources are extracted in parallel to GCS, the two datasets are joined to produce a delta (only records where values differ or are missing from Salesforce), and the delta is submitted to the Salesforce Bulk API. This pattern avoids re-writing unchanged records and minimizes Salesforce API consumption. The canonical instance of this pattern is `dwh_dag`; `rad_deal_score_dag` is another example.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow cron scheduler on Cloud Composer
- **Frequency**: Varies per DAG instance (examples: `dwh_dag` — daily at 07:00 UTC; `rad_deal_score_dag` — monthly on days 2–3 at 02:00 UTC)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Definitions | Defines task graph with parallel SF + EDW extract branches converging on delta task | `airflowGcp_dagDefinitions` |
| DAG Helpers | Executes SOQL query, EDW query, GCS reads/writes, and delta computation | `airflowGcp_dagHelpers` |
| Teradata Connector | Executes domain-specific SQL query against Teradata EDW | `airflowGcp_teradataConnector` |
| Salesforce Hook | Issues SOQL query; submits and polls Salesforce Bulk API job | `airflowGcp_salesforceHook` |
| GCS I/O Utilities | Stages all intermediate CSV files during the run | `airflowGcp_gcsIo` |
| SFDC ETL Working Storage | Stores all staging and result CSV files | `continuumSfdcEtlWorkingStorageGcs` |
| Salesforce | Provides current field values via SOQL; receives bulk update | `salesForce` |
| Teradata EDW | Provides authoritative source-of-truth data | `continuumTeradataEdwStub` |

## Steps

1. **Generate run UUID**: Produces a unique run ID used to namespace all GCS object keys for this execution.
   - From: `airflowGcp_dagDefinitions`
   - To: Airflow XCom store
   - Protocol: Airflow internal (XCom)

2. **Extract current Salesforce values to GCS** (parallel with step 3): Issues a SOQL query for the relevant SF object and target fields; writes results as a CSV to GCS under `{uuid}/{dag_id}/sf_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_salesforceHook`
   - To: `salesForce` (SOQL), then `continuumSfdcEtlWorkingStorageGcs` (write)
   - Protocol: HTTPS (Salesforce REST), then GCS API

3. **Extract EDW data to GCS** (parallel with step 2): Executes the DAG-specific SQL query against Teradata; streams rows to GCS as `{uuid}/{dag_id}/teradata_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_teradataConnector`
   - To: `continuumTeradataEdwStub` (query), then `continuumSfdcEtlWorkingStorageGcs` (write)
   - Protocol: JDBC (teradatasql), then GCS API

4. **Compute and save delta**: Reads both CSVs from GCS; joins on record ID; yields records where EDW value differs from Salesforce value or where EDW has records absent from Salesforce; writes delta CSV to GCS under `{uuid}/{dag_id}/delta_btw_sf_and_edw_gcs_key.csv`.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_gcsIo`
   - To: `continuumSfdcEtlWorkingStorageGcs`
   - Protocol: GCS API

5. **Submit Salesforce bulk update**: Reads delta CSV from GCS in batches of 50,000; submits Salesforce Bulk API update job for the target SF object; returns job ID and batch IDs via XCom.
   - From: `airflowGcp_salesforceHook` via `airflowGcp_gcsIo`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce Bulk API v1)

6. **Save bulk results and resubmit failures**: Polls Salesforce for bulk job completion; downloads per-batch result records; saves combined results to GCS (`bulk_upload_all_results.csv`); re-submits any individually failed records.
   - From: `airflowGcp_salesforceHook` and `airflowGcp_dagHelpers`
   - To: `salesForce` (poll + resubmit), `continuumSfdcEtlWorkingStorageGcs` (write results)
   - Protocol: HTTPS (Salesforce Bulk API v1), then GCS API

7. **Cleanup GCS staging files** (parallel with step 8): Deletes all three temporary CSVs (`sf_gcs_key.csv`, `teradata_gcs_key.csv`, `delta_btw_sf_and_edw_gcs_key.csv`) from GCS.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_gcsIo`
   - To: `continuumSfdcEtlWorkingStorageGcs`
   - Protocol: GCS API

8. **Update Salesforce General Settings timestamp** (parallel with step 7): Writes the last-successful-run timestamp to the DAG's corresponding Salesforce General Settings record.
   - From: `airflowGcp_salesforceHook`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce REST API)

## DAGs Using This Pattern

| DAG ID | SF Object | Key Fields | Schedule |
|--------|-----------|-----------|----------|
| `dwh_dag` | `Account` | `DWH_Merchant_ID__c` | Daily 07:00 UTC |
| `rad_deal_score_dag` | `Account` | `RAD_Score__c` | Monthly days 2–3 at 02:00 UTC |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SOQL query failure | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; email alert |
| Teradata query failure | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; email alert |
| Empty delta (no changes) | Delta CSV is empty; bulk job submitted with zero records | DAG completes successfully; no Salesforce updates made |
| Bulk job submission failure | `retries=0` on submit task; fails immediately | DAG run fails; email alert |
| Individual record failure within bulk job | Re-submitted once via `resubmit_failed_records_to_sf_using_previous_results` | If re-submission fails, `AirflowException` raised |

## Sequence Diagram

```
Airflow Scheduler -> airflowGcp_dagDefinitions: Trigger DAG on cron schedule
airflowGcp_dagDefinitions -> airflowGcp_dagHelpers: Invoke parallel extract tasks
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Query SF for current field values (SOQL)
airflowGcp_salesforceHook -> salesForce: SOQL SELECT
salesForce --> airflowGcp_salesforceHook: Current SF records
airflowGcp_salesforceHook -> airflowGcp_gcsIo: Write sf_gcs_key.csv
airflowGcp_dagHelpers -> airflowGcp_teradataConnector: Execute domain SQL query
airflowGcp_teradataConnector -> continuumTeradataEdwStub: SQL (JDBC)
continuumTeradataEdwStub --> airflowGcp_teradataConnector: Result rows
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write teradata_gcs_key.csv
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Read both CSVs; compute delta; write delta CSV
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Submit bulk update from delta CSV
airflowGcp_salesforceHook -> airflowGcp_gcsIo: Read delta CSV batches
airflowGcp_salesforceHook -> salesForce: POST Bulk API update job
salesForce --> airflowGcp_salesforceHook: Job/batch IDs
airflowGcp_dagHelpers -> salesForce: Poll job results
salesForce --> airflowGcp_dagHelpers: Results per batch
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write bulk_upload_all_results.csv
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Delete temp staging files
airflowGcp_dagHelpers -> salesForce: Update General Settings timestamp
```

## Related

- Architecture dynamic view: `dynamic-airflow-gcp-dwh-dag-sync`
- Related flows: [DWH DAG Data Synchronization](dwh-dag-sync.md), [EDW-to-Salesforce Direct Sync](edw-to-salesforce-direct-sync.md)
