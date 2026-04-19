---
service: "cls-gcp-dags"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. `cls-gcp-dags` has no HTTP health endpoint. Pipeline health is monitored via the Airflow UI and GCP Cloud Monitoring dashboards provided by Cloud Composer. DAG run status (success/failed/running) is the primary health indicator.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Cloud Composer Airflow UI — DAG run status | Airflow UI / GCP Console | On demand | Not applicable |
| GCP Cloud Monitoring — Composer environment metrics | GCP monitoring | Continuous | Not applicable |

## Monitoring

### Metrics

> No evidence found in codebase. Specific metric names, alert thresholds, and dashboard links are not discoverable from the architecture DSL alone. Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DAG run success rate | gauge | Ratio of successful DAG runs to total scheduled runs | Operational procedures to be defined by service owner. |
| Task duration | histogram | Time taken per Airflow task (validation, load) | Operational procedures to be defined by service owner. |
| DAG run failure count | counter | Number of failed DAG runs in a window | Operational procedures to be defined by service owner. |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cloud Composer Environment | GCP Console / Cloud Monitoring | GCP Console — project-specific link |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG run failure | DAG run status = failed | warning | Check Airflow task logs; inspect Data Validation Task output for schema errors |
| Scheduler not running | No DAG runs triggered within expected window | critical | Check Cloud Composer environment health; verify Cloud Scheduler job status |

## Common Operations

### Restart Service

`cls-gcp-dags` is stateless (DAG definitions only). To restart pipeline execution:

1. Log in to GCP Console and navigate to the Cloud Composer environment.
2. Open the Airflow UI from the Composer environment page.
3. Locate the affected CLS DAG in the DAG list.
4. If a DAG run is in a failed or stuck state, clear the failed task(s) via the Airflow UI (Browse > DAG Runs > select run > Clear).
5. Alternatively, trigger a new manual DAG run from the Airflow UI (Trigger DAG button).

### Scale Up / Down

Scaling is managed by the Cloud Composer environment configuration, not by this DAG repository.

1. Log in to GCP Console and navigate to Cloud Composer.
2. Edit the Composer environment to adjust worker node count or resource sizing.
3. Airflow-level parallelism can be tuned via Airflow Variables (`max_active_runs`, `concurrency`) — set via the Airflow UI (Admin > Variables).

### Database Operations

> Not applicable. `cls-gcp-dags` does not own a database. If curated output data needs to be reprocessed, re-trigger the affected DAG run(s) via the Airflow UI with the appropriate execution date.

## Troubleshooting

### DAG Run Fails at Data Validation Task

- **Symptoms**: DAG run marked as failed; `dagDataValidationTask` task shows a red status in the Airflow UI.
- **Cause**: Source data completeness check failed (missing records or unexpected schema) or the source data feed was delayed/unavailable.
- **Resolution**: Check the Airflow task logs for the `dagDataValidationTask` to see the specific validation error. Verify that the upstream source data is available and matches the expected schema. Clear the failed task and retry once source data is confirmed correct.

### DAG Run Fails at Curated Load Task

- **Symptoms**: DAG run marked as failed; `dagLoadTask` task shows a red status; `dagDataValidationTask` succeeded.
- **Cause**: Write failure to the curated downstream storage target — possible GCP permissions error, quota exhaustion, or connectivity issue.
- **Resolution**: Check the Airflow task logs for the `dagLoadTask`. Verify GCP IAM permissions for the Composer service account on the target storage resource. Check GCP quota limits. Clear the task and retry after resolving the underlying issue.

### DAG Not Being Triggered by Scheduler

- **Symptoms**: No DAG runs appear in the expected time window; the DAG appears paused or the schedule is not firing.
- **Cause**: DAG is paused in Airflow, Cloud Scheduler job is disabled, or the Composer scheduler is unhealthy.
- **Resolution**: In the Airflow UI, verify the DAG is not paused (toggle on the DAG list page). Check the Cloud Scheduler job status in the GCP Console. Review the Composer environment health in Cloud Monitoring.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | No CLS DAG runs completing; curated data entirely unavailable | Immediate | CLS Data Engineering team |
| P2 | Individual DAG run failures; partial data unavailability | 30 min | CLS Data Engineering team |
| P3 | Single task retry needed; data eventually consistent | Next business day | CLS Data Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google Cloud Composer | GCP Console — Composer environment status; Cloud Monitoring alerts | No automated fallback; manually trigger catch-up runs when restored |
| Google Cloud Scheduler | GCP Console — Cloud Scheduler job status | Manually trigger DAG via Airflow UI |
| Curated downstream storage | GCP Console — BigQuery/GCS availability; write test | No fallback; pipeline will fail and must be retried |
