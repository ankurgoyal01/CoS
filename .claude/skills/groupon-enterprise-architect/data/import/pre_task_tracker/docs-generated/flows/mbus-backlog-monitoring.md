---
service: "pre_task_tracker"
title: "MBUS Backlog Monitoring and DAG Trigger"
generated: "2026-03-03"
type: flow
flow_name: "mbus-backlog-monitoring"
flow_type: scheduled
trigger: "Cron schedule 0 * * * * on mbus_backlog_monitor DAG (production only, PIPELINES Composer only)"
participants:
  - "continuumPreTaskTracker"
  - "cloudPlatform"
  - "continuumPreTaskTrackerAirflowDb"
architecture_ref: "dynamic-pre-task-tracker-sla-update-flow"
---

# MBUS Backlog Monitoring and DAG Trigger

## Summary

The `mbus_backlog_monitor` DAG runs hourly in production on PIPELINES Composer instances and monitors Groupon's internal message bus (MBUS) queue backlogs. It queries Prometheus metrics via the Grafana API proxy for a set of 30+ MBUS topic addresses and compares current message counts against a threshold of 10,000 messages per queue. When a backlog exceeds the threshold, the corresponding catch-up data pipeline DAG is triggered (if not already running), effectively acting as an auto-remediation mechanism for MBUS processing backlogs.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron `0 * * * *` on DAG `mbus_backlog_monitor`; only active when `IS_PIPELINES_ENV=True` (i.e., `GCP_PROJECT` contains `pipelines`) and `ENV=prod`; `schedule=None` in dev/staging
- **Frequency**: Hourly (production); manual trigger only (dev/staging)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| mbus_backlog_monitor DAG | Orchestrates backlog checks and conditional DAG triggering | `continuumPreTaskTracker` |
| Grafana / Prometheus API | Provides `mbus_broker_queue_MessageCount` metric values | `cloudPlatform` |
| GCP Secret Manager | Stores `grafana_secrets` (URL, token, datasource UID) | `cloudPlatform` |
| Airflow Metadata Database | Checked for currently-running DAG runs before triggering | `continuumPreTaskTrackerAirflowDb` |
| Target pipeline DAGs | Triggered when their MBUS topic backlog exceeds threshold | `continuumPreTaskTracker` |

## Steps

1. **Load Grafana configuration**: Retrieves `grafana_secrets` from GCP Secret Manager; extracts `GRAFANA_URL`, `GRAFANA_TOKEN`, and `DATASOURCE_UID`
   - From: `continuumPreTaskTracker` (dagDefinitions / integrationHooks)
   - To: `cloudPlatform` (GCP Secret Manager)
   - Protocol: GCP SDK

2. **Group MBUS mappings by address**: Deduplicates the `MBUS_TO_DAG_MAPPINGS` list by `mbus_address` to avoid querying Prometheus multiple times for the same address
   - From: `continuumPreTaskTracker` (monitoringLogic)

3. **Query Prometheus for backlog count**: For each unique MBUS address, sends a PromQL query to Grafana:
   ```
   max by(mbus_queue) (max_over_time(
     mbus_broker_queue_MessageCount{
       mbus_address="{address}", mbus_queue=~"{queue_pattern}"
     }[5m]
   ))
   ```
   Parses the `value[1]` from the Prometheus response as the current backlog count
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `cloudPlatform` (Grafana API proxy at `{GRAFANA_URL}/api/datasources/proxy/uid/{uid}/api/v1/query`)
   - Protocol: HTTPS REST (Bearer token auth)

4. **Evaluate threshold**: Compares backlog count against `threshold` (10,000 for all configured addresses); identifies DAGs that should be triggered
   - From: `continuumPreTaskTracker` (monitoringLogic)

5. **Check if target DAG is already running**: For each DAG that should be triggered, queries Airflow SQLAlchemy session to count `DagRun` records in `RUNNING` state for that `dag_id`; marks `should_trigger=False` if already running
   - From: `continuumPreTaskTracker` (monitoringLogic)
   - To: `continuumPreTaskTrackerAirflowDb` (PostgreSQL via SQLAlchemy)
   - Protocol: SQLAlchemy session

6. **Push results to XCom**: Pushes the full results list (including `should_trigger` flags) to Airflow XCom for the `trigger_dags` task to consume
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: `continuumPreTaskTrackerAirflowDb` (XCom via Airflow)
   - Protocol: Airflow XCom

7. **Trigger target DAGs**: Retrieves the `dags_to_trigger` list from XCom; for each entry with `should_trigger=True`, creates a `TriggerDagRunOperator` dynamically and executes it with `conf` including `triggered_by`, `mbus_address`, `backlog_count`, and `reason`; `wait_for_completion=False` (fire-and-forget)
   - From: `continuumPreTaskTracker` (dagDefinitions)
   - To: `continuumPreTaskTrackerAirflowDb` (creates new `DagRun` record)
   - Protocol: Airflow internal

## Monitored MBUS Topics (sample)

| MBUS Address | Threshold | Triggered DAG |
|--------------|-----------|---------------|
| `jms.topic.salesforce.address.delete` | 10,000 | `HLY_MBUS_SF_ADDRESS_DEL_varPARTITION_ID1` |
| `jms.topic.gdpr.account.v1.erased` | 10,000 | `hly_gdpr_rtf_requests_varpartition_id1` |
| `jms.topic.division_updates` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.dealCatalog.deals.v1.update` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.identity_service.identity.v1.c2.event` | 10,000 | `WF_HLY_USERS_EXT_MBUS_varPARTITION_ID_001246810121416182023` |
| `jms.topic.InventoryProducts.Created.Goods` | 10,000 | `HLY_EXTRACT_GIS_INV_PRODUCTS_varPARTITION_ID_104` |
| `jms.topic.dealCatalog.deals.v1.paused` | 10,000 | `HLY_EXT_MBUS_DEALS_PAUSED_UNPAUSED_varPARTITION_ID1_406` |

(30+ total mappings defined in `orchestrator/mbus_backlog_monitor_dag.py`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Grafana API request fails (`RequestException`) | Exception raised and re-raised after logging | `check_backlogs` task fails; DAG marks failed |
| Prometheus returns no data for an address | Returns `None` backlog count; treated as within threshold | No DAG triggered for that address |
| Target DAG is already running | `should_trigger=False` set; no trigger attempted | Deduplication prevents overlapping runs |
| `IS_PIPELINES_ENV=False` (shared Composer) | DAG object is set to `None`; DAG is not registered with Airflow | Entire DAG does not exist on non-pipelines instances |
| `GCP_PROJECT` env var not set | `ValueError` raised in `get_secret()` | `check_backlogs` task fails at startup |

## Sequence Diagram

```
Scheduler -> mbus_backlog_monitor: Trigger (0 * * * *, prod only)
mbus_backlog_monitor -> Secret Manager: GET grafana_secrets
Secret Manager --> mbus_backlog_monitor: {GRAFANA_URL, GRAFANA_TOKEN, DATASOURCE_UID}
mbus_backlog_monitor -> Grafana API: GET /api/datasources/proxy/.../query?query=mbus_broker_queue_MessageCount{...}
Grafana API --> mbus_backlog_monitor: backlog count
mbus_backlog_monitor -> mbus_backlog_monitor: count > 10000?
mbus_backlog_monitor -> Airflow DB: SELECT dag_run WHERE dag_id=... AND state=RUNNING
Airflow DB --> mbus_backlog_monitor: running count
mbus_backlog_monitor -> mbus_backlog_monitor: push dags_to_trigger to XCom
mbus_backlog_monitor -> Airflow DB: TriggerDagRunOperator (creates new DagRun)
```

## Related

- Related flows: [Airflow Task Failure Detection and Alerting](airflow-task-failure-alerting.md)
- Source: `orchestrator/mbus_backlog_monitor_dag.py`
