---
service: "janus-muncher"
title: "Hive Partition Management Flow"
generated: "2026-03-03"
type: flow
flow_name: "hive-partition-management"
flow_type: scheduled
trigger: "muncher-hive-partition-creator Airflow DAG scheduled hourly at :20"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "hiveWarehouse"
architecture_ref: "components-continuumJanusMuncherService"
---

# Hive Partition Management Flow

## Summary

The Hive Partition Management flow ensures that Hive table metadata is kept in sync with the GCS Parquet files written by the delta processing pipeline. After each delta run writes new hourly output to GCS, the `muncher-hive-partition-creator` Airflow DAG submits a Spark job running the `MetadataManager` class. This class connects to HiveServer2 via JDBC and adds or repairs partitions for both the `janus_all` and `junoHourly` Hive tables in the `grp_gdoop_pde` (non-SOX) or `grp_gdoop_sox_db` (SOX) databases. Without this step, analytics queries on Hive would not see recently written data.

## Trigger

- **Type**: schedule
- **Source**: Airflow Cloud Composer — DAG `muncher-hive-partition-creator` and `muncher-hive-partition-creator-sox`
- **Frequency**: Non-SOX: hourly at :20 (`20 * * * *`); SOX: hourly at :15 (`15 * * * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack | Schedules `muncher-hive-partition-creator` DAG; injects Hive password via macro | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Dataproc Job Launcher | Creates Dataproc cluster; submits `MetadataManager` Spark job | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| MetadataManager (Spark) | Connects to HiveServer2 via JDBC; adds/repairs Hive table partitions | `continuumJanusMuncherService` → `muncherStorageAccessLayer` |
| GCP Secret Manager | Provides Hive JDBC password at DAG runtime | External (GCP) |
| Hive Metastore (HiveServer2) | Target for partition ADD/REPAIR DDL statements | `hiveWarehouse` |

## Steps

1. **Schedule DAG run**: Airflow schedules `muncher-hive-partition-creator` at `:20` past each hour.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher`
   - Protocol: Airflow task dependency

2. **Retrieve Hive password**: Airflow user-defined macro `janus_hive_password_retriever()` executes `gcloud secrets versions access latest --project=prj-grp-pipelines-prod-bb85 --secret=janus-hive-credentials` and extracts the `janus_non_sox_hive_password` key from the YAML secret value.
   - From: `orchestratorDagPack` (Airflow macro)
   - To: GCP Secret Manager
   - Protocol: gcloud CLI / GCP Secret Manager API

3. **Create Dataproc cluster**: A small single-node cluster (`muncher-hpc-cluster-{ts}`) is created with `n1-standard-2` master; auto-delete TTL 3600 s.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

4. **Submit MetadataManager Spark job**: `DataprocSubmitJobOperator` submits `com.groupon.janus.muncher.hive.MetadataManager` with args `[muncher-prod, {hive_password}, false]`.
   - From: `dataprocJobLauncher`
   - To: MetadataManager Spark class
   - Protocol: Dataproc Spark job submission

5. **Connect to HiveServer2**: `MetadataManager` opens a JDBC connection to `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true;transportMode=http;httpPath=gateway/pipelines-adhoc-query/hive` using credentials `svc_gcp_janus` / injected password. Falls back to secondary URL: `gateway/analytics-adhoc-query/hive`.
   - From: MetadataManager
   - To: `hiveWarehouse`
   - Protocol: JDBC over HTTPS (HiveServer2)

6. **Add/repair Janus All partitions**: Issues Hive DDL to add partitions for `grp_gdoop_pde.janus_all` (partitioned by `ds` and `hour`) for newly written GCS paths.
   - From: MetadataManager
   - To: `hiveWarehouse`
   - Protocol: JDBC SQL (HiveQL DDL)

7. **Add/repair Juno Hourly partitions**: Issues Hive DDL to add partitions for `grp_gdoop_pde.junoHourly` (partitioned by `eventDate`, `platform`, `eventDestination`) for newly written GCS paths.
   - From: MetadataManager
   - To: `hiveWarehouse`
   - Protocol: JDBC SQL (HiveQL DDL)

8. **Delete Dataproc cluster**: Cluster deleted after job completes (`trigger_rule = all_done`).
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCP Secret Manager access failure | gcloud CLI returns non-zero exit; Airflow macro fails | DAG task fails; partition update skipped; Hive table missing new partitions until manual trigger |
| HiveServer2 connection failure on primary URL | JDBC falls back to secondary server URL (second entry in `serverUrls` list) | Partition update proceeds via fallback; if both fail, MetadataManager throws JDBC exception |
| Both HiveServer2 URLs unavailable | MetadataManager Spark job fails | Airflow task fails; email alert sent; analytics queries return no data for missing partition window; manual DAG re-trigger required after HiveServer2 recovery |
| Partition already exists | Hive DDL `ADD IF NOT EXISTS` is idempotent | No error; partition is confirmed and operation completes normally |

## Sequence Diagram

```
Airflow -> GCPSecretManager: gcloud secrets versions access (janus-hive-credentials)
GCPSecretManager --> Airflow: Hive password value
Airflow -> Dataproc API: Create muncher-hpc-cluster-{ts}
Dataproc API -> MetadataManager: Submit Spark job (args=[muncher-prod, password, false])
MetadataManager -> HiveServer2: JDBC connect (ssl, http transport, svc_gcp_janus)
MetadataManager -> HiveServer2: ALTER TABLE grp_gdoop_pde.janus_all ADD PARTITION ...
HiveServer2 --> MetadataManager: OK
MetadataManager -> HiveServer2: ALTER TABLE grp_gdoop_pde.junoHourly ADD PARTITION ...
HiveServer2 --> MetadataManager: OK
Airflow -> Dataproc API: Delete cluster
```

## Related

- Architecture dynamic view: `components-continuumJanusMuncherService`
- Related flows: [Delta Processing](delta-processing.md), [Watchdog and Lag Monitoring](watchdog-lag-monitoring.md)
