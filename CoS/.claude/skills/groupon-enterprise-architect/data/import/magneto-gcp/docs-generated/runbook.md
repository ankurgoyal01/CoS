---
service: "magneto-gcp"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG status (`DLY_MAGNETO_*`) | Airflow UI / DAG run state | Per-table schedule | 12 hours (DAG timeout) |
| `magneto_metric_gcp` DAG | Airflow scheduled | Every 30 minutes | Not configured |
| `auto_renew_image_magneto` DAG | Airflow scheduled | Daily at 23:35 UTC | 12 hours |
| Slack `#dnd-ingestion-ops` | `trigger_event` on_failure_callback | Per DAG task failure | — |

---

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.data.magneto-gcp.sf_table_lag_by_date` | gauge | Days of lag between `consistent_before_hard` and current timestamp per Salesforce table | Operational procedure to be defined by service owner |
| `custom.data.magneto-gcp.hive_table_lag` | gauge | Latest update timestamp per Hive table in `dwh_manage.table_limits` | Operational procedure to be defined by service owner |

Metrics are tagged with: `region=us-central1`, `env`, `source=magneto-gcp`, `atom=magneto-gcp`, `service=<table>`, `component=app`, `agg_function`, `identifier`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Magneto GCP Ingestion | Grafana / InfluxDB (`custom.data.magneto-gcp.*`) | Operational procedure to be defined by service owner |
| Airflow DAG monitoring | Google Cloud Composer UI | Available via Composer environment in each GCP project |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG task failure | Any task in `DLY_MAGNETO_*` fails | warning | Slack alert to `#dnd-ingestion-ops`; check Airflow task logs; retry task |
| Audit failure (count mismatch) | `MAGNETO-*-audit` DAG: Salesforce count > Hive count | warning | Email to `dnd-ingestion@groupon.com` from `magneto-audit-results@groupon.com`; investigate Hive load completeness |
| Dataproc cluster leak | Cluster not deleted after 1h idle (`max_idle=1h`) | warning | Manually delete orphaned cluster via `gcloud dataproc clusters delete` |
| Image expiry | Custom Dataproc image older than 55 days | info | `auto_renew_image_magneto` DAG handles renewal automatically; check DAG if image family unavailable |

---

## Common Operations

### Restart Service

magneto-gcp does not run as a persistent service. To re-run a failed ingestion:

1. Open Cloud Composer for the target environment (dev/stable/prod).
2. Locate the failed DAG — naming convention: `DLY_MAGNETO_SOX_<table>` or `DLY_MAGNETO_<table>`.
3. Clear the failed task(s) in the Airflow UI to trigger a retry, or trigger a new DAG run.
4. If the Dataproc cluster was left running (check `max_idle` policy), delete it manually before restarting: `gcloud dataproc clusters delete <cluster-name> --region=us-central1 --project=<project>`.

### Scale Up / Down

To increase Dataproc cluster size for a specific table during peak periods:

1. Set the Airflow Variable `MAGNETO_NUM_WORKERS_PEAK` to the desired worker count.
2. Optionally set `MAGNETO_MASTER_MACHINE_TYPE_PEAK` and `MAGNETO_WORKER_MACHINE_TYPE_PEAK` if machine type change is needed.
3. Variables take effect on the next DAG run. Clear the variable after peak period to revert to per-table defaults.

For permanent cluster size changes, update the `num_workers` key for the table in `orchestrator/magneto/config/dag_factory_config.yaml` and redeploy.

### Database Operations

**Update watermark (force re-extract from a specific point):**

```sql
UPDATE dwh_manage.table_limits
SET consistent_before_soft = '<desired_start_timestamp>'
WHERE schema_name = 'Hive_gcp' AND table_name = '<table_name>';
```

Run via MySQL client using ODBC credentials from GCP Secret Manager (`magneto-odbc`). This resets the extraction window start; the next DAG run will extract from the updated watermark.

**Check current table lag:**

```sql
SELECT table_name, consistent_before_hard,
  TIMESTAMPDIFF(day, consistent_before_hard, CURRENT_TIMESTAMP()) AS lag_days
FROM dwh_manage.table_limits
WHERE content_group = 'salesforce' AND schema_name = 'Hive_gcp'
ORDER BY lag_days DESC;
```

---

## Troubleshooting

### Dataproc cluster creation failure
- **Symptoms**: `create_cluster` task fails; Airflow log shows `gcloud dataproc clusters create` error
- **Cause**: Quota exceeded, subnet misconfiguration, or invalid custom image
- **Resolution**: Check GCP quotas in `prj-grp-ingestion-<env>-*`; verify subnet `sub-vpc-<env>-sharedvpc01-us-central1-private` exists; check that custom image family `magneto-prod` exists in compute project

### Secret retrieval failure
- **Symptoms**: `copy_secrets` task fails; Dataproc Pig job exits non-zero
- **Cause**: Secret does not exist or service account lacks Secret Manager access
- **Resolution**: Verify secrets `magneto-zrc2`, `airflow-variables-magneto-odbc`, `airflow-variables-magneto-salesforce` exist in the pipelines project (`prj-grp-pipelines-<env>-*`); verify service account IAM binding

### Salesforce extract timeout or 0-record extract
- **Symptoms**: `EXTRACT_SF_<table>_PART_N` task times out or produces empty staging table
- **Cause**: Salesforce API rate limit, credentials expired, or extraction window too large
- **Resolution**: Check Salesforce API log; re-run with a narrowed window by adjusting `consistent_before_soft`; check `magneto-salesforce` secret validity

### Schema drift — new Salesforce column not in Hive
- **Symptoms**: Preprocess task (`PREPROCESS_SF_<table>`) logs `new_sf_columns` detected; subsequent load may fail if column types mismatch
- **Cause**: Salesforce object gained new fields not yet in Hive target table
- **Resolution**: The Replicator automatically issues `ALTER TABLE ... ADD COLUMNS CASCADE` for new columns. If the DDL change fails, manually run the ALTER on the Hive table via the Dataproc Hive job and re-trigger the DAG.

### Validation audit failure email received
- **Symptoms**: Email from `magneto-audit-results@groupon.com` reports Salesforce count > Hive count for an interval
- **Cause**: Incomplete extract or Hive merge missed records
- **Resolution**: Check the audit DAG (`MAGNETO-SOX-<table>-audit` or `MAGNETO-NONSOX-<table>-audit`) in Airflow for the failed interval; inspect `megatron_validation_stats`; re-run the ingestion DAG for the missing interval

### Custom Dataproc image expired
- **Symptoms**: `auto_renew_image_magneto` DAG `check_latest_image` task routes to `recreate_image_task`
- **Cause**: Latest image in family `magneto-prod` is older than 55 days
- **Resolution**: The DAG handles renewal automatically by cloning the latest image. If the `recreate_image_task` fails, manually create a new image from the latest source: `gcloud compute images create dp-magneto-<date> --family=magneto-prod --source-image=<latest> --project=<compute-project>`.

---

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All Salesforce ingestion pipelines down (Composer unavailable or GCS inaccessible) | Immediate | dnd-ingestion team via `#dnd-ingestion-ops` |
| P2 | Multiple tables failing to ingest (>24h lag on SOX tables) | 30 min | dnd-ingestion on-call; check Slack `#dnd-ingestion-ops` |
| P3 | Single NON-SOX table delayed or audit mismatch email | Next business day | dnd-ingestion team via email |

---

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce API | Implicit — `PREPROCESS_SF_*` task failure indicates connectivity issue | No fallback; DAG fails and alerts |
| Google Cloud Dataproc | `create_cluster` task — failure surfaces in Airflow logs | No fallback; DAG fails; `max_idle=1h` prevents cluster leaks |
| GCS (staging buckets) | Implicit — GCS SDK errors surface as task failures | No fallback |
| MySQL table_limits | Implicit — ODBC connection failure surfaces in preprocess task | No fallback; watermark window cannot be computed |
| Telegraf metrics gateway | Separate `magneto_metric_gcp` DAG; failure does not impact ingestion | Metrics gap only; no ingestion impact |
