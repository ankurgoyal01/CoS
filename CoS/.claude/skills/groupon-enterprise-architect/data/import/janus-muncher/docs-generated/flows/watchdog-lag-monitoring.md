---
service: "janus-muncher"
title: "Watchdog and Lag Monitoring Flow"
generated: "2026-03-03"
type: flow
flow_name: "watchdog-lag-monitoring"
flow_type: scheduled
trigger: "muncher-lag-monitor DAG (every 20 min) and muncher-ultron_watch_dog DAG (every 20 min)"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "metricsStack"
architecture_ref: "components-continuumJanusMuncherOrchestrator"
---

# Watchdog and Lag Monitoring Flow

## Summary

Two independent monitoring DAGs provide continuous operational safety for the Janus Muncher pipeline. The `muncher-lag-monitor` DAG detects processing lag by running the `LagMonitor` Spark class, which checks watermark state and publishes lag metrics to the SMA/Telegraf gateway. The `muncher-ultron_watch_dog` DAG detects inconsistencies between Airflow DAG run states and Ultron job entries by querying the Airflow REST API for incomplete DAG runs and running the `WatchDog` Spark class to reconcile orphaned Ultron state entries. Both DAGs run independently every 20 minutes and have SOX variants. Together they form the operational safety net that triggers backfill actions and prevents stale Ultron state from blocking future delta runs.

## Trigger

- **Type**: schedule
- **Source**: Airflow Cloud Composer — `muncher-lag-monitor` / `muncher-lag-monitor-sox` and `muncher-ultron_watch_dog` / `muncher-ultron_watch_dog-sox`
- **Frequency**: Both run every 20 minutes (`*/20 * * * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack (lag monitor) | Schedules `muncher-lag-monitor` DAG | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Airflow DAG Pack (watchdog) | Schedules `muncher-ultron_watch_dog` DAG; queries Airflow REST API for incomplete runs | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Workflow Monitoring | Executes `retrieve_all_incomplete_muncher_instances()` macro to get lagging Airflow DAG run IDs | `continuumJanusMuncherOrchestrator` → `airflowMonitoring` |
| Dataproc Job Launcher | Creates single-node Dataproc clusters for each monitor job | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| LagMonitor (Spark) | Reads Ultron watermark; computes lag; publishes lag metrics | `continuumJanusMuncherService` → `watchdogJobs` |
| WatchDog (Spark) | Receives incomplete Airflow run IDs; queries Ultron for stale entries; resolves orphaned state | `continuumJanusMuncherService` → `watchdogJobs` |
| Ultron State Client | Source of watermark and job state queried by both LagMonitor and WatchDog | `continuumJanusMuncherService` → `muncherUltronClient` |
| SMA Metrics Reporter | Publishes lag metrics from LagMonitor | `continuumJanusMuncherService` → `muncherMetricsReporter` |
| Telegraf / SMA Gateway | Receives lag and watchdog metrics | `metricsStack` |
| Airflow REST API (Cloud Composer) | Queried by `retrieve_all_incomplete_muncher_instances()` for queued/running DAG runs | External (Cloud Composer) |

## Lag Monitor — Steps

1. **Schedule DAG run**: Airflow schedules `muncher-lag-monitor` at every 20-minute boundary.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher`
   - Protocol: Airflow task dependency

2. **Create monitor cluster**: Small single-node Dataproc cluster (`muncher-lag-monitor-cluster-{ts}`) created with `n1-standard-2`; auto-delete TTL 1500 s.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

3. **Submit LagMonitor Spark job**: `com.groupon.janus.muncher.watchdog.LagMonitor` submitted with args `[muncher-prod, artifact_version]`.
   - From: `dataprocJobLauncher`
   - To: `watchdogJobs` (LagMonitor class)
   - Protocol: Dataproc Spark job submission

4. **Compute lag**: LagMonitor queries Ultron State API for the current high-watermark of `JunoHourlyGcp`; computes difference from current time.
   - From: `watchdogJobs`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS)

5. **Publish lag metrics**: `muncherMetricsReporter` publishes computed lag value to the SMA/Telegraf gateway.
   - From: `muncherMetricsReporter`
   - To: `metricsStack`
   - Protocol: HTTP (InfluxDB line protocol)

6. **Delete cluster**: Cluster deleted after job completes (`trigger_rule = all_done`).
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

## Watchdog — Steps

1. **Schedule DAG run**: Airflow schedules `muncher-ultron_watch_dog` at every 20-minute boundary.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher` + `airflowMonitoring`
   - Protocol: Airflow task dependency

2. **Query Airflow REST API for incomplete runs**: The user-defined macro `retrieve_all_incomplete_muncher_instances()` queries the Cloud Composer REST API endpoint `{airflow_api_url}/api/v1/dags/{dag_name}/dagRuns?execution_date_gte={lookback_start}` for each of the three monitored DAGs (`muncher-delta`, `muncher-backfill`, `muncher-hive-partition-creator`). Lookback window: 16 hours (`airflow_lookback_hours = 16`). Returns comma-separated string of queued or running DAG run IDs.
   - From: `airflowMonitoring`
   - To: Cloud Composer Airflow REST API (`https://d1336eb9b0674114bc79436fc9ce0103-dot-us-central1.composer.googleusercontent.com/api/v1/...`)
   - Protocol: HTTPS (Google-auth authorised session with `cloud-platform` scope); retried up to 3 times with 3 s delay

3. **Create watchdog cluster**: Single-node Dataproc cluster (`muncher-ultron-watch-dog-cluster-{ts}`) created with `n1-highmem-4`; auto-delete TTL 1500 s.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

4. **Submit WatchDog Spark job**: `com.groupon.janus.muncher.watchdog.WatchDog` submitted with args `[muncher-prod, {incomplete_run_ids}, 8, artifact_version]`. Ultron lookback window: 8 hours (`ultron_lookback_hours = 8`).
   - From: `dataprocJobLauncher`
   - To: `watchdogJobs` (WatchDog class)
   - Protocol: Dataproc Spark job submission

5. **Query Ultron for stale entries**: WatchDog queries Ultron State API for all running job instances within the 8-hour lookback; compares against the list of incomplete Airflow run IDs.
   - From: `watchdogJobs`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS)

6. **Resolve orphaned Ultron state**: For Ultron job entries whose corresponding Airflow DAG run ID is not in the incomplete runs list (i.e., the DAG run has finished or been cleared), WatchDog marks the Ultron entry as failed/resolved.
   - From: `watchdogJobs`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS)

7. **Publish watchdog metrics**: WatchDog publishes metrics about the number of orphaned entries resolved.
   - From: `muncherMetricsReporter`
   - To: `metricsStack`
   - Protocol: HTTP (InfluxDB line protocol)

8. **Delete watchdog cluster**: Cluster deleted after job completes.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Airflow REST API returns non-200 after 3 retries | Exception raised in macro; Airflow task fails | Watchdog Spark job not submitted; DAG task fails; email alert sent |
| Ultron State API unreachable | LagMonitor / WatchDog Spark job fails | Cluster is deleted; Airflow task fails; alert sent; lag data gap on dashboard |
| No incomplete Airflow runs found | Empty string passed to WatchDog; WatchDog has no entries to reconcile | WatchDog exits cleanly; no Ultron state changes |
| WatchDog Spark job fails | Airflow task fails; on_failure_callback sends email | Orphaned Ultron entries remain until next 20-minute run succeeds |

## Sequence Diagram

```
--- Lag Monitor ---
Airflow -> Dataproc API: Create muncher-lag-monitor-cluster-{ts}
Dataproc API -> LagMonitor: Submit Spark job
LagMonitor -> UltronStateAPI: GET watermark for JunoHourlyGcp
UltronStateAPI --> LagMonitor: Watermark timestamp
LagMonitor -> TelegrafGateway: POST lag metric
Airflow -> Dataproc API: Delete cluster

--- Watchdog ---
Airflow (macro) -> AirflowRestAPI: GET dagRuns for muncher-delta, muncher-backfill, muncher-hive-partition-creator
AirflowRestAPI --> Airflow (macro): List of queued/running run IDs
Airflow -> Dataproc API: Create muncher-ultron-watch-dog-cluster-{ts}
Dataproc API -> WatchDog: Submit Spark job (args=[config, incomplete_run_ids, 8, version])
WatchDog -> UltronStateAPI: GET running job instances (lookback 8h)
UltronStateAPI --> WatchDog: Ultron job entries
WatchDog -> UltronStateAPI: PATCH orphaned entries to failed/resolved
WatchDog -> TelegrafGateway: POST watchdog metrics
Airflow -> Dataproc API: Delete cluster
```

## Related

- Architecture dynamic view: `components-continuumJanusMuncherOrchestrator`
- Related flows: [Delta Processing](delta-processing.md), [Backfill](backfill.md)
