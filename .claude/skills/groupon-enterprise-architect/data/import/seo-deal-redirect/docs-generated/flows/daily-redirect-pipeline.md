---
service: "seo-deal-redirect"
title: "Daily Redirect Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "daily-redirect-pipeline"
flow_type: batch
trigger: "Airflow cron schedule 0 5 15 * * (5:00 AM UTC, 15th of month)"
participants:
  - "continuumSeoDealRedirectDag"
  - "continuumSeoDealRedirectJobs"
  - "continuumSeoHiveWarehouse"
  - "gcpDataproc"
  - "gcpCloudStorage"
  - "seoDealApi"
architecture_ref: "containers-seoDealRedirect"
---

# Daily Redirect Pipeline

## Summary

The daily redirect pipeline is the top-level Airflow DAG (`redirect-workflow`) that coordinates all steps required to compute and publish SEO deal redirects. It provisions a transient GCP Dataproc cluster, runs a sequence of Hive ETL and PySpark jobs to map expired deals to live deals and publish the results, then tears down the cluster. The entire pipeline runs on a scheduled cadence and sends a completion email notification when finished.

## Trigger

- **Type**: schedule
- **Source**: GCP Cloud Composer (Airflow) cron expression `0 5 15 * *`
- **Frequency**: Monthly (5:00 AM UTC on the 15th of each month)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Deal Redirect DAG | Orchestrator — schedules all tasks, manages cluster lifecycle, sends notifications | `continuumSeoDealRedirectDag` |
| Execution Date Resolver | Computes `run_date`, `prev_date`, `purge_date` and stores in XCom | `executionDateResolver` (component of DAG) |
| Dataproc Orchestrator | Provisions Dataproc cluster and submits all Hive and PySpark jobs | `dataprocOrchestrator` (component of DAG) |
| SEO Deal Redirect Jobs | Hive ETL scripts and PySpark jobs executing on Dataproc | `continuumSeoDealRedirectJobs` |
| SEO Hive Warehouse | Staging and output Hive tables | `continuumSeoHiveWarehouse` |
| GCP Dataproc | Compute infrastructure for Spark/Hive execution | `gcpDataproc` (stub) |
| GCP Cloud Storage | Source CSV reference data and Parquet output storage | `gcpCloudStorage` (stub) |
| SEO Deal API | Receives redirect attribute updates | `seoDealApi` (stub) |
| Completion Notifier | Sends completion email to `computational-seo@groupon.com` | `notificationSender` (component of DAG) |

## Steps

1. **Compute execution dates**: The `executionDateResolver` computes `run_date`, `prev_date`, and `purge_date` from the Airflow execution context and stores them in XCom.
   - From: `dagDefinition`
   - To: `executionDateResolver`
   - Protocol: Airflow task dependency

2. **Create Dataproc cluster**: The `dataprocOrchestrator` creates a transient Dataproc cluster (`seo-deal-redirect`) with 1 master + 2 workers (`n1-standard-8`). Init actions load TLS certificates from GCP Secret Manager and install required pip packages.
   - From: `dataprocOrchestrator`
   - To: `gcpDataproc`
   - Protocol: GCP Dataproc API

3. **Load reference data**: Submits Hive jobs to load PDS blacklist (`load_pds_blacklist`), deal exclusion list (`load_excl_raw_list`, `load_excl_list`), and manual redirects (`load_manual_redirects_raw`, `load_manual_redirects`) from GCS CSVs into Hive staging tables.
   - From: `dataprocOrchestrator`
   - To: `hiveEtlScripts` → `continuumSeoHiveWarehouse`
   - Protocol: HiveQL over Dataproc

4. **Extract daily deal data**: Submits Hive job `get_daily_deals` to populate `grp_gdoop_seo_db.daily_deals` by joining EDW source tables and filtering out excluded deals and blacklisted PDS categories.
   - From: `dataprocOrchestrator`
   - To: `hiveEtlScripts` → `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

5. **Map expired deals to live deals**: Submits Hive jobs `map_expired_to_live` (and optionally `map_expired_to_live_pre_2019`) to produce `daily_expired_to_live_deal_mapping`. See [Expired-to-Live Mapping](expired-to-live-mapping.md).
   - From: `dataprocOrchestrator`
   - To: `hiveEtlScripts` → `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

6. **Deduplicate and remove cycles**: Submits `dedup_expired_to_live` and `remove_cycles_expired_to_live` Hive jobs. See [Deduplication and Cycle Removal](deduplication-and-cycle-removal.md).
   - From: `dataprocOrchestrator`
   - To: `hiveEtlScripts` → `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

7. **Purge and populate final redirect table**: Submits Hive purge job (`purge_final_redirect_table`) then PySpark job `api_upload_table_population` to write `final_redirect_mapping` Parquet to GCS with full live deal URLs.
   - From: `dataprocOrchestrator`
   - To: `apiUploadTablePopulation` → `gcpCloudStorage`
   - Protocol: Spark / Parquet

8. **Repair Hive table**: Submits `MSCK REPAIR TABLE final_redirect_mapping` to register the new GCS partition in the Hive metastore.
   - From: `dataprocOrchestrator`
   - To: `hiveEtlScripts` → `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

9. **Upload redirects to SEO Deal API**: Submits PySpark job `api_upload`. See [API Upload](api-upload.md).
   - From: `dataprocOrchestrator`
   - To: `apiUploadJob` → `seoDealApi`
   - Protocol: HTTPS PUT

10. **Run non-active merchant deals job** (conditional): Submits PySpark job `find_non_active_merchant_deals`. See [Non-Active Merchant Deals](non-active-merchant-deals.md).
    - From: `dataprocOrchestrator`
    - To: `nonActiveMerchantDealsJob` → `seoDealApi`
    - Protocol: HTTPS PUT

11. **Delete Dataproc cluster**: Tears down the transient cluster to release GCP resources.
    - From: `dataprocOrchestrator`
    - To: `gcpDataproc`
    - Protocol: GCP Dataproc API

12. **Send completion notification**: Airflow `EmailOperator` sends a completion email to `computational-seo@groupon.com`.
    - From: `notificationSender`
    - To: email recipient
    - Protocol: SMTP (Airflow EmailOperator)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Dataproc cluster creation fails | Airflow marks task `failed`; DAG run aborts | No Hive or Spark jobs run; cluster is not created |
| Hive ETL task fails | Airflow marks the specific task `failed`; downstream tasks do not run | Pipeline stops at failed task; can be retried via Airflow task clear |
| PySpark job fails on Dataproc | Dataproc job exits with non-zero code; Airflow operator marks task `failed` | Downstream tasks (including API upload) do not run |
| API upload individual deal fails | HTTP error is logged per deal; job continues with remaining deals | Partial upload; failed deals retain previous redirect or no redirect |
| Cluster deletion fails | Airflow alerts; cluster may persist and incur cost | Manual deletion required via GCP Console |

## Sequence Diagram

```
Airflow Scheduler -> dagDefinition: Trigger DAG (cron 0 5 15 * *)
dagDefinition -> executionDateResolver: Compute run_date / prev_date / purge_date
executionDateResolver -> dataprocOrchestrator: Provide dates via XCom
dataprocOrchestrator -> gcpDataproc: Create Dataproc cluster
gcpDataproc -> hiveEtlScripts: Load reference data (exclusions, manual redirects)
hiveEtlScripts -> continuumSeoHiveWarehouse: Populate staging tables
hiveEtlScripts -> continuumSeoHiveWarehouse: Populate daily_deals
hiveEtlScripts -> continuumSeoHiveWarehouse: Populate expired-to-live mapping tables
hiveEtlScripts -> continuumSeoHiveWarehouse: Dedup and remove cycles
dataprocOrchestrator -> apiUploadTablePopulation: Submit Spark job
apiUploadTablePopulation -> gcpCloudStorage: Write final_redirect_mapping Parquet
hiveEtlScripts -> continuumSeoHiveWarehouse: MSCK REPAIR TABLE
dataprocOrchestrator -> apiUploadJob: Submit Spark job
apiUploadJob -> seoDealApi: HTTP PUT redirect updates (up to 1250/min)
dataprocOrchestrator -> nonActiveMerchantDealsJob: Submit Spark job (conditional)
nonActiveMerchantDealsJob -> seoDealApi: HTTP PUT non-active merchant redirects
dataprocOrchestrator -> gcpDataproc: Delete cluster
dataprocOrchestrator -> notificationSender: Trigger completion email
```

## Related

- Architecture container: `continuumSeoDealRedirectDag`
- Related flows: [Expired-to-Live Mapping](expired-to-live-mapping.md), [API Upload](api-upload.md), [Non-Active Merchant Deals](non-active-merchant-deals.md), [Deduplication and Cycle Removal](deduplication-and-cycle-removal.md)
