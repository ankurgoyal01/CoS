---
service: "bq_orr"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| https://status.cloud.google.com/ | External HTTP (GCP status page) | Manual / as needed | Not applicable |
| Airflow DAG run status (Cloud Composer UI) | Manual inspection | Per DAG schedule (daily) | Not applicable |

> This service has no HTTP health endpoint. The `.service.yml` defines `status_endpoint.prefix: http://` but specifies no path. Platform health is monitored via the GCP status page. DAG execution health is monitored through the Airflow UI in the Cloud Composer environment.

## Monitoring

### Metrics

> No evidence found in codebase.

No custom metrics are emitted by this service. DAG execution metrics (task duration, success/failure counts, retry rates) are provided natively by the Cloud Composer / Airflow UI.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GCP Status Dashboard | Google Cloud | https://status.cloud.google.com/ |
| BigQuery SLA | Google Cloud | https://cloud.google.com/bigquery/sla |
| BigQuery Confluence Page | Confluence | https://groupondev.atlassian.net/wiki/spaces/EDW/pages/80897540123/BigQuery |

### Alerts

> No evidence found in codebase.

No programmatic alerts are configured within this repository. Deployment notifications are sent to Slack:

- `rma-pipeline-notifications` — dev deployment events (start, complete, override)
- `grim---pit` — staging and production deployment events (start, complete, override)

## Common Operations

### Restart Service

This service has no long-running process to restart. DAGs are reloaded by Cloud Composer automatically when files change in the GCS DAG bucket. To force a DAG reload:

1. Re-trigger the Jenkins pipeline to re-upload DAG files to the target Composer bucket.
2. Cloud Composer will detect the updated files and reload the DAG within its standard sync interval.

### Scale Up / Down

> Operational procedures to be defined by service owner.

Scaling of DAG execution resources is managed by the Cloud Composer environment administrators, not by this repository.

### Deploy a New DAG

1. Add a new Python DAG file to the `orchestrator/` directory.
2. Define `default_args`, `DAG`, and task operators following the pattern in `orchestrator/hello_world.py`.
3. Commit and push to the main branch.
4. Jenkins automatically triggers the `dataPipeline` build and promotes through dev → staging → production (manual gate at production).

### Rollback a DAG

1. Revert the relevant commit in the repository.
2. Push the revert to trigger a new Jenkins build.
3. The previous DAG file version will be re-uploaded to Composer buckets through the standard promotion chain.

### Database Operations

> Not applicable

This service does not own any databases or require database migrations.

## Troubleshooting

### DAG fails to appear in Airflow UI after deployment

- **Symptoms**: Jenkins pipeline reports successful deployment, but the DAG is not visible in the Cloud Composer Airflow UI.
- **Cause**: Cloud Composer GCS sync interval has not elapsed, or the DAG file contains a Python syntax error that prevents parsing.
- **Resolution**: Check the Airflow scheduler logs in Cloud Composer for parse errors. Verify the file was uploaded to the correct bucket (`COMPOSER_DAGS_BUCKET` for the target environment). Wait for the next GCS sync cycle.

### DAG task fails with retry

- **Symptoms**: Airflow marks a task as `failed` after 1 retry (5-minute retry delay).
- **Cause**: Transient error in BigQuery execution, network issue, or permission denied on the target dataset.
- **Resolution**: Inspect the task logs in the Airflow UI. Check Google Cloud IAM permissions for the Composer service account. Verify the target BigQuery dataset and table exist. Re-trigger the DAG run manually if needed.

### Deployment pipeline fails

- **Symptoms**: Jenkins build fails; Slack notification to `grim---pit` or `rma-pipeline-notifications` with `complete` status showing failure.
- **Cause**: `deploybot_gcs` cannot reach the target Kubernetes cluster, the GCS bucket, or authentication has expired.
- **Resolution**: Check Jenkins build logs. Verify Kubernetes cluster connectivity for the target environment. Confirm GCS bucket name matches the expected value in `.deploy_bot.yml`. Escalate to EDW admin team at `edw-admin@groupon.com`.

### Cloud Composer / BigQuery platform outage

- **Symptoms**: DAG runs fail across all DAGs; GCP status page shows incident.
- **Cause**: Google Cloud Platform infrastructure issue.
- **Resolution**: Monitor https://status.cloud.google.com/. Raise a GCP support case via the Google Cloud Console Support page (Premium Support — P1 response within 15 minutes).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | BigQuery or Composer platform down, all DAGs failing | Immediate | GCP Premium Support (15-min SLA); edw-admin@groupon.com |
| P2 | Specific DAG failures, data pipeline delayed | 30 min | edw-admin@groupon.com; owner: rpadala |
| P3 | Deployment pipeline issue, no production impact | Next business day | edw-admin@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google BigQuery | https://status.cloud.google.com/ | No automated fallback; DAG tasks retry once (5-minute delay) then fail |
| Google Cloud Composer | https://status.cloud.google.com/ | No automated fallback; DAG execution paused until environment recovers |
| deploybot_gcs | Jenkins build log | Re-trigger Jenkins pipeline manually after resolving root cause |
