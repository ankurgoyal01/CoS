---
service: "airflow_gcp"
title: "Secrets Reload"
generated: "2026-03-03"
type: flow
flow_name: "secrets-reload"
flow_type: scheduled
trigger: "Monthly on day 1 at 10:00 UTC (0 10 1 * *)"
participants:
  - "airflowGcp_dagDefinitions"
  - "airflowGcp_configHelper"
  - "airflowGcp_gcsIo"
  - "airflowGcp_secretManager"
  - "continuumSfdcEtlWorkingStorageGcs"
architecture_ref: "dynamic-airflow-gcp-dwh-dag-sync"
---

# Secrets Reload

## Summary

The `secrets_reloader_dag` is a maintenance DAG that refreshes runtime secrets stored as Airflow Variables without requiring a code redeployment. It runs monthly on the first day of each month. The DAG reads the `secrets/variable-secrets.json` blob from the environment-specific GCS bucket and calls `Variable.set()` for each key-value pair found, making the latest credential values available to all subsequent DAG runs. This pattern decouples secret rotation from code deployments.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow cron scheduler on Cloud Composer
- **Frequency**: Monthly on day 1 at 10:00 UTC (`0 10 1 * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Definitions | Defines the `secrets_reloader_dag` task graph | `airflowGcp_dagDefinitions` |
| Config Helper | `load_secrets_into_variables()` — reads GCS bucket name from JSON config then reads secrets blob | `airflowGcp_configHelper` |
| GCS I/O Utilities | Streams `secrets/variable-secrets.json` from the working GCS bucket | `airflowGcp_gcsIo` |
| Secret Manager Utilities | Certificate reload (planned, not yet implemented — `TODO` comment in source) | `airflowGcp_secretManager` |
| SFDC ETL Working Storage | Stores the `secrets/variable-secrets.json` blob | `continuumSfdcEtlWorkingStorageGcs` |

## Steps

1. **Generate run UUID**: Creates a unique run ID (passed via XCom, though not used by subsequent tasks in this DAG).
   - From: `airflowGcp_dagDefinitions`
   - To: Airflow XCom store
   - Protocol: Airflow internal (XCom)

2. **Reload secrets**: Calls `load_secrets_into_variables()` from `config_helper.py`:
   a. Reads `orchestrator/config/{env}/variables.json` to determine the environment-specific GCS bucket name (`gcs_bucket_name_{env}`).
   b. Opens `gs://{bucket}/secrets/variable-secrets.json` via `smart_open` using `GCSHook(gcp_conn_id="sfdc_etl_gcloud_connection")`.
   c. Iterates over every key-value pair in the JSON blob and calls `Variable.set(key, value)` on the Airflow Variables store.
   - From: `airflowGcp_configHelper`
   - To: `continuumSfdcEtlWorkingStorageGcs` (read secrets blob)
   - Protocol: GCS API via `smart_open`

3. **[TODO] Reload certificates**: Certificate rotation from Google Secret Manager is planned but not yet implemented (marked as `TODO` in `secrets_reloader_dag.py`).
   - From: `airflowGcp_secretManager`
   - To: not yet implemented
   - Protocol: Google Secret Manager API (planned)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS read failure (secrets blob not found) | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; email alert to `sfint-dev-alerts@groupon.com` |
| GCP authentication failure (`sfdc_etl_gcloud_connection` invalid) | Airflow retries task once after 2 minutes | If retry fails, DAG run fails; subsequent DAG runs using stale credentials may fail |
| Malformed secrets JSON | Python JSON parse error raises exception | DAG run fails; Airflow Variables retain previous values; email alert |

## Sequence Diagram

```
Airflow Scheduler -> airflowGcp_dagDefinitions: Trigger secrets_reloader_dag monthly
airflowGcp_dagDefinitions -> airflowGcp_configHelper: Call load_secrets_into_variables()
airflowGcp_configHelper -> airflowGcp_configHelper: Read variables.json; resolve bucket name
airflowGcp_configHelper -> airflowGcp_gcsIo: Open gs://{bucket}/secrets/variable-secrets.json
airflowGcp_gcsIo -> continuumSfdcEtlWorkingStorageGcs: GET secrets blob
continuumSfdcEtlWorkingStorageGcs --> airflowGcp_gcsIo: JSON payload
airflowGcp_configHelper -> Airflow Variables: Variable.set(key, value) for each secret
Airflow Variables --> airflowGcp_configHelper: Variables updated
```

## Related

- Architecture dynamic view: `dynamic-airflow-gcp-dwh-dag-sync`
- Related flows: [EDW-to-Salesforce Direct Sync](edw-to-salesforce-direct-sync.md), [EDW-to-Salesforce Delta Sync](edw-to-salesforce-delta-sync.md)
