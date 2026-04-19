---
service: "coupons_bi_airflow"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow scheduler heartbeat | exec (Cloud Composer monitoring) | 1 min | managed |
| DAG run success/failure status | Airflow UI / Cloud Monitoring alerts | per DAG schedule | managed |
| Cloud Composer environment health | GCP Cloud Console | continuous | managed |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DAG run success rate | gauge | Percentage of DAG runs completing successfully | Alert on repeated failures (>2 consecutive) |
| Task duration | histogram | Time taken per Airflow task | Alert on significant deviation from baseline |
| API call failure rate | counter | Failed calls to external APIs per DAG run | Alert on any non-retried failure |
| GCS write success | counter | Successful raw data landings to GCS | Alert on landing zone write failures |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cloud Composer Environment | GCP Cloud Console | Managed via GCP project console |
| Airflow DAG Overview | Airflow UI | Cloud Composer managed URL |
| Cloud Monitoring | GCP Cloud Monitoring | Managed via GCP project console |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG run failed | Airflow DAG run state = failed for 2+ consecutive runs | warning | Inspect Airflow task logs; check API availability; re-trigger manually if safe |
| Cloud Composer environment unhealthy | GCP environment status = unhealthy | critical | Escalate to Data Platform team; do not attempt manual restart |
| Secret Manager access denied | Authentication error from `google-cloud-secret-manager` | critical | Verify service account permissions; check secret rotation status |

## Common Operations

### Restart Service

Cloud Composer environments cannot be "restarted" like a traditional service. To recover a failed DAG run:

1. Navigate to the Airflow UI for the affected Cloud Composer environment.
2. Locate the failed DAG run in the DAG view.
3. Clear the failed task(s) to allow Airflow to re-schedule them.
4. Monitor the re-triggered run in the task log view.

### Scale Up / Down

Scaling is managed by the GCP Cloud Composer environment configuration. To scale:

1. Navigate to GCP Console > Cloud Composer > Environment Settings.
2. Adjust the number of worker nodes or the worker pod resource limits.
3. Changes apply to subsequent task executions without redeploying DAGs.

### Database Operations

- Teradata schema changes are managed by the data warehouse team, not by this service.
- BigQuery dataset and table schema changes are applied externally via the data platform tooling.
- To reprocess a date partition: clear the relevant Airflow task in the Airflow UI and allow it to re-execute.

## Troubleshooting

### DAG fails with API authentication error
- **Symptoms**: Task log shows `401 Unauthorized` or `403 Forbidden` from an external API
- **Cause**: API credential in GCP Secret Manager has expired, been rotated externally, or the service account lost permissions
- **Resolution**: Verify the secret version in GCP Secret Manager; update the secret if needed; clear and retry the failed task

### DAG fails with GCS write error
- **Symptoms**: Task log shows GCS permission denied or bucket not found errors
- **Cause**: Service account lacks Storage Object Creator permissions on the landing bucket, or bucket name is misconfigured in Airflow Variables
- **Resolution**: Verify IAM permissions for the Cloud Composer service account; verify the `GCS_LANDING_BUCKET` Airflow Variable value

### DAG fails with Teradata connection error
- **Symptoms**: Task log shows `teradatasql` connection refused or authentication failure
- **Cause**: Teradata host unreachable, password rotated, or `TERADATA_CONN_ID` Airflow Connection misconfigured
- **Resolution**: Verify the Airflow Connection for Teradata in the Airflow UI; test connectivity from Cloud Composer

### DAG takes significantly longer than baseline
- **Symptoms**: Task duration alerts fire; DAG run extends beyond its SLA window
- **Cause**: External API rate limiting, increased data volume, or Cloud Composer worker resource contention
- **Resolution**: Check external API rate limit headers in task logs; consider adjusting DAG schedule or batch size

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Cloud Composer environment down — all pipelines halted | Immediate | Data Platform team |
| P2 | Multiple DAGs failing — BI reporting data stale | 30 min | Coupons BI Engineers |
| P3 | Single DAG failing — partial data gap | Next business day | Coupons BI Engineers |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GA4 API | Check Airflow task logs for HTTP response codes | No fallback — data gap until resolved |
| Google Ads API | Check task logs for OAuth errors | No fallback |
| Teradata | Test via Airflow Connection UI | No fallback — load tasks skip until resolved |
| BigQuery | GCP Console > BigQuery status | No fallback |
| GCS | GCP Console > Cloud Storage status | No fallback — landing zone required |
| GCP Secret Manager | GCP Console > Secret Manager | No fallback — DAGs cannot authenticate without secrets |

> Operational procedures to be defined by service owner where not discoverable from code.
