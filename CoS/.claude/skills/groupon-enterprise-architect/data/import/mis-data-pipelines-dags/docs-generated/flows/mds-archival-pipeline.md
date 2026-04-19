---
service: "mis-data-pipelines-dags"
title: "MDS Archival Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "mds-archival-pipeline"
flow_type: scheduled
trigger: "Cron schedule per region: NA at 10 minutes past every 3rd hour (01:10–23:10), EMEA at 20 minutes past every 3rd hour (00:20–23:20), APAC at 40 minutes past every 3rd hour (02:40–23:40)"
participants:
  - "misDags_dagOrchestrator"
  - "misDags_dataprocJobConfig"
  - "misDags_archivalScripts"
  - "continuumMarketingDealService"
  - "cloudPlatform"
  - "edw"
  - "loggingStack"
architecture_ref: "dynamic-mis-dags-core-flow"
---

# MDS Archival Pipeline

## Summary

The MDS Archival Pipeline is a scheduled Airflow DAG that runs three times daily per region (NA, EMEA, APAC) and pulls a full snapshot of deal data from the Marketing Deal Service API for each country/brand combination. It uploads the raw deals JSON to GCS as both a flat (latest) file and a compressed (date-partitioned) archive, then registers the data as Hive partitions in `grp_gdoop_mars_mds_db`. A CDE Spark data quality check validates that deal counts do not change by more than ±5% day-over-day, alerting the MIS team if thresholds are breached. This pipeline is the foundation for all downstream deal analytics, Tableau dashboards, and the Deals Cluster job.

## Trigger

- **Type**: schedule
- **Source**: Airflow Scheduler (Cloud Composer)
- **Frequency**: Every 3 hours per region (8 times per day); NA: `10 1-23/3 * * *`, EMEA: `20 0-23/3 * * *`, APAC: `40 2-23/3 * * *`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Orchestrator | Reads config, manages Zombie Runner cluster lifecycle, sequences tasks | `misDags_dagOrchestrator` |
| Dataproc Job Config | Provides cluster names, country lists, schedules, and DQ check job parameters | `misDags_dataprocJobConfig` |
| Archival Scripts | Executes `processor.yml` Zombie Runner workflow tasks (download, upload, Hive partition creation) | `misDags_archivalScripts` |
| Marketing Deal Service | Source of deal snapshot data per country/brand | `continuumMarketingDealService` |
| GCP Cloud Platform (Dataproc + GCS) | Zombie Runner cluster compute; GCS storage target | `cloudPlatform` |
| Enterprise Data Warehouse (Hive) | Receives new partitions in `mds_flat_production`, `mds_archive_production`, `mds_production` | `edw` |
| Logging Stack (Stackdriver) | Receives Zombie Runner and cluster execution logs | `loggingStack` |

## Steps

1. **Load Configuration**: DAG Orchestrator reads `orchestrator/config/{env}/mds_archive_cluster_and_jobs_config.json` to determine cluster names, country lists (NA: US,CA; EMEA: UK,NL,DE,FR,PL,IT,AE,BE,IE,ES; APAC: AU), schedules, GCS paths, and Metastore endpoint.
   - From: `misDags_dagOrchestrator`
   - To: `misDags_dataprocJobConfig`
   - Protocol: File I/O

2. **Create Zombie Runner Cluster**: DAG Orchestrator provisions a Zombie Runner GCE VM cluster (e.g., `mds-archive-archival-na-zombie-cluster`) using a custom GCE image (`zombie-runner-dev`); initialization script `initialise_zombie_dirs.sh` from GCS runs on startup; cluster loads TLS certificates and artifact archive from GCS.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (GCP Dataproc / GCE)
   - Protocol: GCP REST API

3. **Prepare Work Directory**: `prepare_dump` Zombie Runner task creates local working directory on the cluster and captures the current date.
   - From: `misDags_archivalScripts`
   - To: Zombie Runner cluster (local)
   - Protocol: Shell exec

4. **Download MDS Deal Data**: `get_mds_data` Zombie Runner task calls the MDS API endpoint with mTLS certificates for each country/brand combination. Retries up to `max_http_attempts: 3` on HTTP 503 or non-zero curl status.
   - From: `misDags_archivalScripts` (Zombie Runner cluster)
   - To: `continuumMarketingDealService` at `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com/deals.json?client=mds_archive&country={country}&brand={brand}&stream=true&delimited=newline&inactive=true&show=all`
   - Protocol: HTTPS/JSON with mTLS

5. **Upload Deals to GCS**: `upload_deals_to_gcp` Zombie Runner task uploads the raw deals file to the flat GCS path (`gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/mds_flat_{env}/country_partition={country}/brand_partition={brand}/`), compresses it with gzip, and uploads the compressed file to the archive path (`mds_archive_{env}/dt={dt}/country_partition={country}/brand_partition={brand}/`).
   - From: `misDags_archivalScripts`
   - To: `cloudPlatform` (GCS)
   - Protocol: gsutil

6. **Register Hive Partitions**: `create_hive_partitions` Zombie Runner HiveTask adds `IF NOT EXISTS` partitions to `mds_flat_{env}` and `mds_archive_{env}` tables.
   - From: `misDags_archivalScripts`
   - To: `edw` (Hive Metastore via Zombie Runner HiveTask)
   - Protocol: Hive SQL (HQL)

7. **Load Hive Managed Table**: `load_hive_table` Zombie Runner HiveTask uses JSON SerDe to `INSERT OVERWRITE` into `mds_production` table partition (`dt`, `country_partition`, `brand_partition`) from the flat table.
   - From: `misDags_archivalScripts`
   - To: `edw`
   - Protocol: Hive SQL (HQL)

8. **Run Data Quality Check**: Airflow submits a CDE Spark job (`com.groupon.push.dq.DqDriver`) on the same cluster to validate deal counts against the HOCON config in `mds-archive/data-quality-checks/config/{env}/archival_{region}.conf`. Checks day-over-day count change for each country; sends email alert to `mds-alerts@groupondev.opsgenie.net` if ±5% threshold is breached.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (Dataproc Spark), `edw` (Hive query)
   - Protocol: Spark submit / Hive SQL

9. **Clean Up Local Files**: `clean_local_file` Zombie Runner task removes the local raw and compressed deal files from the cluster working directory.
   - From: `misDags_archivalScripts`
   - To: Zombie Runner cluster (local)
   - Protocol: Shell exec

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MDS API returns HTTP 503 or non-zero exit | Shell retry loop up to `max_http_attempts: 3` | DAG task fails after max retries; Zombie Runner error email sent |
| GCS upload fails (`gsutil cp` non-zero exit) | Script exits immediately (`exit 1`) | Task fails; DAG run marked failed |
| Hive partition creation fails | Zombie Runner task fails; no retry | DAG task fails; subsequent HiveTask steps skipped |
| DQ check threshold breached (DoD > ±5%) | CDE Spark job sends email alert to `mds-alerts@groupondev.opsgenie.net`, cc `mis-engineering@groupon.com` | Alert sent; DAG marks DQ task as failed |
| Zombie Runner cluster unavailable | Airflow operator retries per DAG task retry config | DAG fails if cluster cannot be provisioned |

## Sequence Diagram

```
Airflow Scheduler -> misDags_dagOrchestrator: Trigger archival DAG (cron)
misDags_dagOrchestrator -> misDags_dataprocJobConfig: Load mds_archive_cluster_and_jobs_config.json
misDags_dagOrchestrator -> cloudPlatform: Create Zombie Runner cluster (GCE)
cloudPlatform -> cloudPlatform: Run initialise_zombie_dirs.sh init action
misDags_archivalScripts -> continuumMarketingDealService: GET /deals.json?client=mds_archive&country=US&brand=groupon (mTLS)
continuumMarketingDealService --> misDags_archivalScripts: Newline-delimited JSON deals
misDags_archivalScripts -> cloudPlatform: gsutil cp raw file to mds_flat_production/
misDags_archivalScripts -> cloudPlatform: gsutil cp compressed file to mds_archive_production/dt=YYYYMMDD/
misDags_archivalScripts -> edw: ALTER TABLE mds_flat_production ADD PARTITION(...)
misDags_archivalScripts -> edw: INSERT OVERWRITE TABLE mds_production PARTITION(...)
misDags_dagOrchestrator -> cloudPlatform: Submit CDE Spark DQ check job
cloudPlatform -> edw: SELECT dt, count(*) FROM mds_production WHERE dt IN (today, yesterday)
cloudPlatform --> misDags_dagOrchestrator: DQ result (pass/fail)
misDags_dagOrchestrator -> loggingStack: Emit execution logs
```

## Related

- Architecture dynamic view: `dynamic-mis-dags-core-flow`
- Related flows: [Archival Cleanup and Tableau Refresh](archival-cleanup-tableau-refresh.md), [Deals Cluster Job](deals-cluster-job.md)
