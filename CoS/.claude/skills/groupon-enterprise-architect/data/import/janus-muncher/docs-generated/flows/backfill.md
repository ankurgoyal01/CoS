---
service: "janus-muncher"
title: "Backfill Flow"
generated: "2026-03-03"
type: flow
flow_name: "backfill"
flow_type: event-driven
trigger: "muncher-backfill Airflow DAG on 10-minute schedule; job triggered when BackfillMonitor detects lag"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "hdfsStorage"
  - "metricsStack"
architecture_ref: "dynamic-janusMuncherDeltaProcessing"
---

# Backfill Flow

## Summary

The backfill flow recovers missing or lagging hourly windows when the `muncher-delta` pipeline falls behind. The `muncher-backfill` Airflow DAG runs every 10 minutes. It first provisions a small Dataproc cluster to run `BackfillMonitor`, which checks whether a backfill is needed. If lag is detected (the monitor Spark job exits successfully indicating a gap), a second larger Dataproc cluster is created and `MuncherMain` is submitted with `runType = backfill`. If no backfill is needed, metrics are published and the monitor cluster is deleted. Email alerts and backfill-triggered metrics are emitted whenever an actual backfill run is initiated.

## Trigger

- **Type**: schedule (with conditional branch)
- **Source**: Airflow Cloud Composer — DAG `muncher-backfill` and `muncher-backfill-sox`
- **Frequency**: Every 10 minutes (`*/10 * * * *`); `max_active_runs = 1`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack | Defines conditional backfill DAG with BranchPythonOperator-style branching | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Dataproc Job Launcher | Creates monitor cluster; conditionally creates backfill cluster | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| Workflow Monitoring | Sends backfill-triggered email and metric; sends no-backfill metric | `continuumJanusMuncherOrchestrator` → `airflowMonitoring` |
| BackfillMonitor (Spark) | Detects lag condition; succeeds if no backfill needed (skip); fails to trigger backfill branch | `continuumJanusMuncherService` → `watchdogJobs` |
| MuncherMain Runner (backfill mode) | Runs `MuncherMain` with `runType = backfill`; calls `muncherJob.backfill(1)` | `continuumJanusMuncherService` → `muncherMainRunner` |
| GCS (HDFS) | Source input and output for backfill run | `hdfsStorage` |
| Telegraf / SMA Gateway | Receives `custom.data.backfill-triggered-quantity` metric | `metricsStack` |

## Steps

1. **Schedule DAG run**: Airflow schedules `muncher-backfill` every 10 minutes.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher`
   - Protocol: Airflow task dependency

2. **Create monitor cluster**: A small single-node Dataproc cluster (`muncher-backfill-monitor-cluster-{ts}`) is created with `n1-standard-2` master; auto-delete TTL 1500 s.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

3. **Run BackfillMonitor Spark job**: Submits `com.groupon.janus.muncher.watchdog.BackfillMonitor` class with config `muncher-prod`. The monitor checks whether the current watermark is behind. If no backfill is needed, the job succeeds; if backfill is required, the job fails (triggering the backfill branch via `trigger_rule = all_failed`).
   - From: `dataprocJobLauncher`
   - To: `watchdogJobs` → `BackfillMonitor`
   - Protocol: Dataproc Spark job

4. **Branch — no backfill needed**: `send_backfill_not_triggered_metric` PythonOperator executes; publishes `custom.data.backfill-triggered-quantity = 0` to InfluxDB.
   - From: `airflowMonitoring`
   - To: `metricsStack`
   - Protocol: InfluxDB HTTP

5. **Branch — backfill needed (BackfillMonitor job failed)**: `send_backfill_triggered_metric` PythonOperator executes; publishes `custom.data.backfill-triggered-quantity = 1`; sends email alert to `platform-data-eng@groupon.com` and `edw-dev-ops@groupon.com` with subject `{env}: Janus GCP Backfill triggered`.
   - From: `airflowMonitoring`
   - To: `metricsStack` + SMTP relay
   - Protocol: InfluxDB HTTP + SMTP

6. **Delete monitor cluster**: Monitor cluster is deleted after backfill metric/email tasks complete (`trigger_rule = one_success`).
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

7. **Create backfill cluster** (backfill branch only): A larger 25-worker Dataproc cluster (`muncher-backfill-cluster-{ts}`) is created with 25 × `e2-highmem-8` workers.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

8. **Submit MuncherMain (backfill mode)**: `DataprocSubmitJobOperator` submits `MuncherMain` with args `[dag_run_id, version, muncher-prod, backfill]`. The `runType = backfill` causes `MuncherMain.runMuncher` to call `muncherJob.backfill(1)`.
   - From: `dataprocJobLauncher`
   - To: `muncherMainRunner`
   - Protocol: Dataproc Spark job

9. **Execute backfill delta job**: Identical processing to the [Delta Processing Flow](delta-processing.md) (read canonical input, deduplicate, write Janus All, write Juno Hourly) but targeting the lagging hourly window(s). The larger cluster accommodates catching up on multiple windows.
   - From: `muncherMainRunner`
   - To: `hdfsStorage` (read + write)
   - Protocol: Hadoop FileSystem API / GCS

10. **Delete backfill cluster**: Cluster deleted on success (`delete_backfill_cluster_on_success`) and on failure (`delete_backfill_cluster_on_failure`, `trigger_rule = all_failed`).
    - From: `dataprocJobLauncher`
    - To: Google Cloud Dataproc API
    - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BackfillMonitor job succeeds (no lag) | No-backfill metric published; monitor cluster deleted | No action; next 10-minute check will evaluate again |
| BackfillMonitor job fails (lag detected) | Backfill-triggered metric and email sent; backfill cluster created; `MuncherMain backfill` submitted | Backfill processes lagging window; metric resets on next successful delta run |
| Backfill Spark job exception | Dataproc job fails; `delete_backfill_cluster_on_failure` triggered; Airflow task fails | Email alert to team; `muncher-backfill` will retry on next 10-minute schedule |
| More than 2 backfill alerts received | Operational alert: escalate to PDE team | Manual investigation of upstream Yati delay or cluster resource issue required |

## Sequence Diagram

```
Airflow -> Dataproc API: Create muncher-backfill-monitor-cluster-{ts}
Dataproc API -> BackfillMonitor: Run Spark job (class=BackfillMonitor)
BackfillMonitor --> Dataproc API: SUCCESS (no lag) or FAILURE (lag detected)
alt No lag
  Airflow -> InfluxDB: POST custom.data.backfill-triggered-quantity=0
else Lag detected
  Airflow -> InfluxDB: POST custom.data.backfill-triggered-quantity=1
  Airflow -> SMTPRelay: Send backfill-triggered email
  Airflow -> Dataproc API: Create muncher-backfill-cluster-{ts} (25 workers)
  Dataproc API -> MuncherMain: Submit Spark job (runType=backfill)
  MuncherMain -> GCS: Read input, write Janus All + Juno Hourly (same as delta flow)
  MuncherMain --> Dataproc API: Job complete
  Airflow -> Dataproc API: Delete backfill cluster
end
Airflow -> Dataproc API: Delete monitor cluster
```

## Related

- Architecture dynamic view: `dynamic-janusMuncherDeltaProcessing`
- Related flows: [Delta Processing](delta-processing.md), [Watchdog and Lag Monitoring](watchdog-lag-monitoring.md)
