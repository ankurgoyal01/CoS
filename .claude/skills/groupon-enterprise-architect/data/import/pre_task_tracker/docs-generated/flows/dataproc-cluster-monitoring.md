---
service: "pre_task_tracker"
title: "Dataproc Cluster Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "dataproc-cluster-monitoring"
flow_type: scheduled
trigger: "Airflow @continuous schedule on PRE_CLUSTER_TRACKER DAG"
participants:
  - "continuumPreTaskTracker"
  - "cloudPlatform"
  - "continuumJiraService"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# Dataproc Cluster Monitoring

## Summary

The `PRE_CLUSTER_TRACKER` DAG runs continuously and monitors Google Cloud Dataproc cluster health across multiple GCP projects. It detects two conditions: clusters that have been running longer than 8 hours (long-running) and clusters that have had no active jobs for more than 1 hour (idle). For each condition, it creates or resolves JSM alerts. The active GCP projects monitored depend on the Composer instance name (PIPELINES, CONSUMER, or INGESTION instance).

## Trigger

- **Type**: schedule
- **Source**: Airflow `@continuous` schedule on `PRE_CLUSTER_TRACKER` DAG (`max_active_runs=1`)
- **Frequency**: Continuous

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| PRE_CLUSTER_TRACKER DAG (DAG Definitions + Monitoring Logic) | Orchestrates cluster health checks | `continuumPreTaskTracker` |
| gcloud CLI (Dataproc API) | Provides cluster list, job list, and pipeline label data | `cloudPlatform` |
| Atlassian JSM | Receives alert create and resolve HTTP calls | `continuumJiraService` |

## Steps

### Long-running cluster detection

1. **Enumerate target projects**: Based on Composer `instance_name` prefix, selects the appropriate GCP project list:
   - `PIPELINES*` → `prj-grp-pipelines-dev-7536`, `prj-grp-pipelines-stable-19fd`, `prj-grp-pipelines-prod-bb85`
   - `CONSUMER*` → `prj-grp-revmgmt-prod-ef0c`, `prj-grp-revmgmt-stable-d4c2`, `prj-grp-ca-prod-160a`, `prj-grp-ca-stable-d620`
   - `INGESTION*` → `prj-grp-ingestion-dev-f4fa`, `prj-grp-ingestion-stable-dc79`, `prj-grp-ingestion-prod-59d0`
   - From: `continuumPreTaskTracker` (dagDefinitions)

2. **List running Dataproc clusters**: Executes `gcloud dataproc clusters list --region=us-central1 --filter="status.state = RUNNING"` for each target project; parses cluster name, start timestamp, master/worker instance counts and types
   - From: `continuumPreTaskTracker` (monitoringLogic / helper)
   - To: `cloudPlatform` (Dataproc API via gcloud CLI)
   - Protocol: gcloud CLI subprocess

3. **Identify long-running clusters**: Filters clusters where `(utcnow - start_timestamp).total_seconds() > 8 * 3600`
   - From: `continuumPreTaskTracker` (monitoringLogic)

4. **Fetch pipeline label**: For each long-running cluster, executes `gcloud dataproc clusters describe {cluster_name} --format="value(labels.pipeline)"` to retrieve the Airflow DAG ID label and Composer base URL
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `cloudPlatform` (Dataproc API via gcloud CLI)

5. **Fire long-running alert**: Creates JSM alert with `alias = "{project_id} | DATAPROC-LONG-RUNNING | {cluster_name}"`, including `ClusterName`, `Project`, `Cluster` (GCP Console URL), `StartTime`, `DAG_ID`, `Composer` link in `custom_details`
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)
   - Protocol: HTTPS REST

### Long-running cluster resolution

6. **List open long-running alerts**: Fetches open JSM alerts from `pre_cluster_tracker / check_long_running_clusters` source
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumJiraService` (JSM API)

7. **Re-check long-running status**: For each open alert, re-fetches the long-running cluster list for the project; if cluster is no longer in the list, resolves the JSM alert
   - From: `continuumPreTaskTracker` (monitoringLogic / integrationHooks)
   - To: `cloudPlatform` (gcloud) and `continuumJiraService` (JSM resolve)

### Idle cluster detection

8. **Identify idle clusters**: For running clusters older than `cluster_idle_lookback` (1 hour), executes `gcloud dataproc jobs list --cluster={cluster_name}` and checks:
   - If any job is in `RUNNING` state → cluster is busy
   - If no jobs, checks `max(stateStartTime)` across all jobs; if idle for more than 1 hour → idle
   - Skips clusters with `dataproc-ephemeral` in their summary (ad-hoc clusters)
   - From: `continuumPreTaskTracker` (monitoringLogic / helper)
   - To: `cloudPlatform` (gcloud CLI)

9. **Fire idle cluster alert**: Creates JSM alert with `alias = "{project_id} | DATAPROC-IDLE | {cluster_name}"` and cluster details
   - From: `continuumPreTaskTracker` (integrationHooks)
   - To: `continuumJiraService` (JSM API)

### Idle cluster resolution

10. **Re-check idle status and resolve**: Fetches open idle alerts; re-checks `get_cluster()` and `is_idle()`; if cluster is no longer idle, calls `jsm.resolve()` with the alert alias
    - From: `continuumPreTaskTracker` (monitoringLogic / integrationHooks)
    - To: `cloudPlatform` + `continuumJiraService`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `gcloud` CLI subprocess returns empty or invalid JSON | `json.loads()` raises `JSONDecodeError` | Task fails; next continuous cycle retries |
| Alert message does not match expected `target_project | ... | cluster_name` format | Alert is skipped (`process = False`) | Alert is not resolved until matching project is in scope |
| Ephemeral (ad-hoc) cluster detected | Skipped via `if "dataproc-ephemeral" in summary: continue` | No false idle alert for ephemeral clusters |
| `get_dag_id()` pipeline label not found | Returns `"Pipeline label not found or empty"` | Alert still created with missing DAG ID; does not block alert |

## Sequence Diagram

```
Scheduler -> PRE_CLUSTER_TRACKER: Trigger (@continuous)
PRE_CLUSTER_TRACKER -> gcloud CLI: dataproc clusters list (per target project)
gcloud CLI --> PRE_CLUSTER_TRACKER: cluster list (JSON)
PRE_CLUSTER_TRACKER -> PRE_CLUSTER_TRACKER: filter long-running (>8h)
PRE_CLUSTER_TRACKER -> gcloud CLI: dataproc clusters describe (pipeline label)
gcloud CLI --> PRE_CLUSTER_TRACKER: pipeline DAG ID
PRE_CLUSTER_TRACKER -> JSM API: POST /alerts (DATAPROC-LONG-RUNNING)
PRE_CLUSTER_TRACKER -> gcloud CLI: dataproc jobs list (per cluster)
gcloud CLI --> PRE_CLUSTER_TRACKER: job list (JSON)
PRE_CLUSTER_TRACKER -> PRE_CLUSTER_TRACKER: is_idle() check
PRE_CLUSTER_TRACKER -> JSM API: POST /alerts (DATAPROC-IDLE)
PRE_CLUSTER_TRACKER -> JSM API: GET open long-running alerts
PRE_CLUSTER_TRACKER -> gcloud CLI: Re-check cluster list
PRE_CLUSTER_TRACKER -> JSM API: resolve (if cluster gone)
PRE_CLUSTER_TRACKER -> JSM API: GET open idle alerts
PRE_CLUSTER_TRACKER -> gcloud CLI: Re-check cluster and jobs
PRE_CLUSTER_TRACKER -> JSM API: resolve (if no longer idle)
```

## Related

- Related flows: [Airflow Task Failure Detection and Alerting](airflow-task-failure-alerting.md)
- Constants: `orchestrator/const.py` — `summary_fmt_long_running`, `summary_fmt_idle_cluster`, `cluster_idle_lookback`, `dataproc_url`
