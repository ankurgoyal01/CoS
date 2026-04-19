---
service: "airflow_gcp"
title: "EDW-to-Salesforce Direct Sync"
generated: "2026-03-03"
type: flow
flow_name: "edw-to-salesforce-direct-sync"
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

# EDW-to-Salesforce Direct Sync

## Summary

The EDW-to-Salesforce Direct Sync pattern is used by DAGs that do not need to compare current Salesforce values before updating. These DAGs extract data from Teradata EDW (or Hive), write the result directly to GCS, and submit the entire result set as a Salesforce Bulk API insert or upsert job. This is simpler than the delta sync pattern and is appropriate when the EDW is the authoritative source and all returned records should be written to Salesforce unconditionally. Examples include `aggregated_refunds_data_dag`, `sf_deal_alerts_dag`, `high_refunder_dag`, and `sf_supply_pyramid_dag`.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow cron scheduler on Cloud Composer
- **Frequency**: Varies per DAG instance (examples below)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Definitions | Defines linear task graph: extract → upload → save results → cleanup | `airflowGcp_dagDefinitions` |
| DAG Helpers | Executes EDW query and GCS writes; coordinates task data passing via XCom | `airflowGcp_dagHelpers` |
| Teradata Connector | Executes domain-specific SQL query against Teradata EDW | `airflowGcp_teradataConnector` |
| Salesforce Hook | Submits and polls Salesforce Bulk API job (insert or upsert) | `airflowGcp_salesforceHook` |
| GCS I/O Utilities | Stages query result CSV and result output files | `airflowGcp_gcsIo` |
| SFDC ETL Working Storage | Stores staging and result CSV files | `continuumSfdcEtlWorkingStorageGcs` |
| Salesforce | Receives bulk insert or upsert job from Salesforce Hook | `salesForce` |
| Teradata EDW | Provides source data for all direct-sync DAGs | `continuumTeradataEdwStub` |

## Steps

1. **Generate run UUID**: Produces a unique run ID to namespace all GCS keys for this execution.
   - From: `airflowGcp_dagDefinitions`
   - To: Airflow XCom store
   - Protocol: Airflow internal (XCom)

2. **Extract EDW data to GCS**: Executes the DAG-specific SQL file against Teradata; streams result rows; writes output as `{uuid}/{dag_id}/teradata_gcs_key.csv` in GCS.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_teradataConnector`
   - To: `continuumTeradataEdwStub` (query), then `continuumSfdcEtlWorkingStorageGcs` (write)
   - Protocol: JDBC (teradatasql), then GCS API

3. **Submit Salesforce bulk job**: Reads the EDW result CSV from GCS in batches of 50,000; submits Salesforce Bulk API job (update, insert, or upsert depending on DAG); returns `job_id` and `ordered_batch_ids` via XCom.
   - From: `airflowGcp_salesforceHook` via `airflowGcp_gcsIo`
   - To: `salesForce`
   - Protocol: GCS API (read CSV), then HTTPS (Salesforce Bulk API v1)

4. **Save bulk results and resubmit failures**: Polls Salesforce for bulk job completion; writes combined results to GCS (`bulk_upload_all_results.csv`); re-submits failed records individually using the original EDW dataset as reference.
   - From: `airflowGcp_salesforceHook` and `airflowGcp_dagHelpers`
   - To: `salesForce` (poll + resubmit), `continuumSfdcEtlWorkingStorageGcs` (write results)
   - Protocol: HTTPS (Salesforce Bulk API v1), then GCS API

5. **Cleanup GCS staging files** (parallel with step 6): Deletes `teradata_gcs_key.csv` from GCS.
   - From: `airflowGcp_dagHelpers` via `airflowGcp_gcsIo`
   - To: `continuumSfdcEtlWorkingStorageGcs`
   - Protocol: GCS API

6. **Update Salesforce General Settings timestamp** (parallel with step 5): Writes last-successful-run timestamp to the DAG's Salesforce General Settings record.
   - From: `airflowGcp_salesforceHook`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce REST API)

## DAGs Using This Pattern

| DAG ID | SF Object | Key Fields | Schedule | Bulk Operation |
|--------|-----------|-----------|----------|---------------|
| `aggregated_refunds_data_dag` | `Opportunity` | `Total_Deal_Units_Sold__c`, `Total_Refunds_Units__c`, `Current_Month_Units_Sold__c`, `Current_Month_Units_Refunded__c` | Daily 13:00 UTC | update |
| `sf_deal_alerts_dag` | `Deal_Alert__c` | `Opportunity__c`, `Alert_Type__c`, `Alert_Description__c`, `Alert_Priority__c`, `Deal_UUID__c`, `Due_Date__c`, and others | Weekly Thursday 10:00 UTC | upsert (external ID: `Id`) |
| `high_refunder_dag` | `Account` | `High_Refunder__c` | Bi-monthly on day 10 (even months) 08:00 UTC | update (serial concurrency) |
| `sf_supply_pyramid_dag` | `Account` | `TMC_Wave__c` | Monthly day 1 18:00 UTC | update |
| `ogp_and_vouchers_sold_mtd_qtd_ytd_dag` | `Opportunity` | OGP and voucher MTD/QTD/YTD metrics | Scheduled (see DAG file) | update |
| `ogp_and_vouchers_sold_last_year_dag` | `Opportunity` | OGP and voucher last-year metrics | Scheduled | update |
| `last_voucher_sold_na_dag` | `Account` | Last voucher sold date (NA) | Scheduled | update |
| `last_voucher_sold_intl_dag` | `Account` | Last voucher sold date (INTL) | Scheduled | update |
| `customer_satisfaction_dag` | Salesforce custom object | Customer satisfaction score | Scheduled | update |
| `cs_contacts_per_unit_dag` | Salesforce custom object | CS contacts per unit | Scheduled | update |
| `intl_refunds_oppty_dag` | `Opportunity` | International refund opportunity flags | Scheduled | update |
| `intl_refunds_multi_deal_dag` | `Opportunity` | Multi-deal refund flags | Scheduled | update |
| `gp_repeatability_dag` | Salesforce custom object | GP repeatability metrics | Scheduled | update |
| `md_acc_prioritization_na_dag` | `Account` | Merchant account prioritization score (NA) | Scheduled | update |
| `md_acc_prioritization_intl_dag` | `Account` | Merchant account prioritization score (INTL) | Scheduled | update |
| `mindbody_booking_status_dag` | Salesforce custom object | Mindbody booking status | Scheduled | update |
| `da_consistent_refunders_dag` | Salesforce custom object | Consistent refunder flags | Scheduled | update |
| `da_longtail_refund_offenders_dag` | Salesforce custom object | Longtail refund offender flags | Scheduled | update |
| `da_uk_deal_investigations_dag` | Salesforce custom object | UK deal investigation flags | Scheduled | update |
| `da_redemption_offender_dag` | Salesforce custom object | Redemption offender flags | Scheduled | update |
| `low_engagement_mc_onboarding_dag` | Salesforce custom object | Low engagement MC onboarding flags | Scheduled | update |
| `sf_five_nvr_fields_dag` | Salesforce custom object | Five NVR metric fields | Scheduled | update |
| `sf_is_giftable_deal_dag` | Salesforce custom object | Giftable deal flag | Scheduled | update |
| `gp_field_aggregated_dag` | Salesforce custom object | GP field aggregation metrics | Scheduled | update |
| `l2_tt2_category_dag` | Salesforce custom object | L2 TTD category data | Scheduled | update |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata query failure | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; email alert |
| Empty query result | Zero-row CSV submitted to Bulk API; job completes with 0 records processed | DAG completes successfully; no Salesforce updates |
| Bulk job submission failure | `retries=0`; fails immediately | DAG run fails; email alert to `sfint-dev-alerts@groupon.com` |
| Individual record failure within bulk job | `resubmit_failed_records_to_sf_using_previous_results` re-submits once | If re-submission fails, `AirflowException` raised; DAG fails |
| GCS write failure | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; email alert |

## Sequence Diagram

```
Airflow Scheduler -> airflowGcp_dagDefinitions: Trigger DAG on cron schedule
airflowGcp_dagDefinitions -> airflowGcp_dagHelpers: Invoke EDW extract task
airflowGcp_dagHelpers -> airflowGcp_teradataConnector: Execute domain SQL
airflowGcp_teradataConnector -> continuumTeradataEdwStub: SQL query (JDBC)
continuumTeradataEdwStub --> airflowGcp_teradataConnector: Result rows
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write teradata_gcs_key.csv to GCS
airflowGcp_dagHelpers -> airflowGcp_salesforceHook: Submit bulk job from result CSV
airflowGcp_salesforceHook -> airflowGcp_gcsIo: Read teradata_gcs_key.csv batches
airflowGcp_salesforceHook -> salesForce: POST Bulk API job (insert/update/upsert)
salesForce --> airflowGcp_salesforceHook: Job ID, batch IDs
airflowGcp_dagHelpers -> salesForce: Poll job results
salesForce --> airflowGcp_dagHelpers: Batch results
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Write bulk_upload_all_results.csv
airflowGcp_dagHelpers -> airflowGcp_gcsIo: Delete teradata_gcs_key.csv
airflowGcp_dagHelpers -> salesForce: Update General Settings timestamp
```

## Related

- Architecture dynamic view: `dynamic-airflow-gcp-dwh-dag-sync`
- Related flows: [DWH DAG Data Synchronization](dwh-dag-sync.md), [EDW-to-Salesforce Delta Sync](edw-to-salesforce-delta-sync.md), [Secrets Reload](secrets-reload.md)
