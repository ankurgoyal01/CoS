---
service: "janus-metric"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG task status | Airflow UI / DAG state | Per-run (hourly / daily / weekly) | 5-hour auto-delete TTL |
| SMA gauge `custom.data.janus-metric-failure` | gauge (0=ok, 1=fail) | Per Spark run | — |
| SMA gauge `custom.data.juno-metric-failure` | gauge (0=ok, 1=fail) | Per Spark run | — |
| Wavefront dashboard | dashboard | Real-time | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.data.janus-metric-failure` | gauge | 0 = Janus metric run succeeded; 1 = failure in volume/quality/catfood cube generation | 1 |
| `custom.data.juno-metric-failure` | gauge | 0 = Juno metric run succeeded; 1 = failure in Juno volume cube generation | 1 |
| `custom.data.janus-raw-metric-duration` | gauge/timer | Duration of Janus raw metric processing run | Operationally defined |
| `custom.data.janus-metric-duration` | timer | End-to-end duration of Janus volume/quality metric run | Operationally defined |
| `custom.data.juno-metric-duration` | timer | End-to-end duration of Juno volume metric run | Operationally defined |

Tags applied to all metrics: `env`, `source` (`janus-metric`), `atom` (artifact version), `service` (`janus-metric`), `component` (`app`), `class` (Scala class name).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Janus Metric SMA | Wavefront | https://groupon.wavefront.com/dashboards/janus-metric--sma |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Janus Metric Failure | `custom.data.janus-metric-failure` = 1 | critical | Check Airflow DAG task logs; verify Janus API and GCS availability; see Troubleshooting below |
| Juno Metric Failure | `custom.data.juno-metric-failure` = 1 | critical | Check `juno-metric` DAG task logs; verify Janus API and GCS availability |
| PagerDuty service | `janus-prod-alerts@groupon.pagerduty.com` | critical | https://groupon.pagerduty.com/services/P25RQWA |

## Common Operations

### Restart Service

janus-metric has no long-running process to restart. To re-trigger a failed run:
1. Open the Airflow UI for the relevant environment
2. Navigate to the DAG (`janus-metric`, `janus-raw-metric`, `juno-metric`, or `janus-cardinality-topN`)
3. Clear the failed task or trigger a new DAG run
4. The Airflow operator will create a new Dataproc cluster, run the Spark job, and delete the cluster

### Scale Up / Down

Cluster sizing is defined in `orchestrator/janus_config/config_prod.py`:
1. Update `janus_metric_worker_config`, `juno_metric_worker_config`, or `janus_cardinality_worker_config` with new `num_instances` or `machine_type_uri`
2. Deploy the updated DAG files via the standard Jenkins pipeline
3. The next DAG run will use the new cluster configuration

### Backfill

The `JanusMetricsUltronRunner` supports a `backfill` mode argument (third CLI arg = `"backfill"` instead of `"regular"`). Trigger a Dataproc job manually with `"backfill"` as the third argument to reprocess files going back 1 day.

### Database Operations

janus-metric does not own a database. To inspect persisted metric data:
- Query the Janus Metadata Service (`janus-web-cloud`) API or its underlying MySQL database directly
- Ultron watermark state can be inspected via the Ultron API using the job names listed in [Configuration](configuration.md)

## Troubleshooting

### Airflow DAG task fails at `spark_job`
- **Symptoms**: Spark job task red in Airflow; email failure notification sent to `platform-data-eng@groupon.com`
- **Cause**: GCS input files unavailable, Janus API returning non-204, Ultron API unavailable, or Dataproc cluster creation failure
- **Resolution**:
  1. Check Airflow task logs in Stackdriver (`dataproc:dataproc.logging.stackdriver.job.driver.enable=true`)
  2. Verify GCS bucket accessibility for the Dataproc service account
  3. Verify `janus-web-cloud` health and that `/janus/api/v1/metrics/*` endpoints return 204
  4. Verify Ultron API availability at `ultron-api.production.service`
  5. Re-trigger the DAG run after resolving the root cause

### Janus API returns non-204
- **Symptoms**: Log message `Cannot persisted the volume cube in the db. Response Code: Failure`; `custom.data.janus-metric-failure` gauge = 1
- **Cause**: Janus Metadata Service API error (database issue, payload size, schema mismatch)
- **Resolution**: Check `janus-web-cloud` service health; review payload in logs (first 2000 chars logged); contact `janus-web-cloud` team

### Dataproc cluster creation fails
- **Symptoms**: `create_cluster` task fails in Airflow; Spark job never starts
- **Cause**: GCP quota exhaustion, VPC subnet issue, or service account permission error
- **Resolution**: Check GCP console for cluster creation errors in `prj-grp-janus-prod-0808`; verify service account IAM permissions; retry — up to 3 retries configured (`create_cluster_retries=3`)

### Ultron watermark not advancing (files reprocessed)
- **Symptoms**: Same Parquet files processed multiple times; duplicate metric entries in Janus
- **Cause**: Ultron `FileStatus.FAILED` was not cleared; Ultron API inconsistency
- **Resolution**: Check Ultron API for stuck watermark state under the affected job name; contact Data Engineering team

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All metric DAGs failing — no metrics ingested | Immediate | `janus-prod-alerts@groupon.pagerduty.com` / `#janus-robots` |
| P2 | Single DAG failing — partial metric gap | 30 min | `platform-data-eng@groupon.com` / `#janus-robots` |
| P3 | Cardinality or non-critical job delayed | Next business day | `platform-data-eng@groupon.com` |

- **Owner's Manual**: https://github.groupondev.com/dnd-gcp-migration-ingestion/janus-metric/wiki/Owner's-Manual
- **Architecture doc**: https://docs.google.com/document/d/16G01i4nfFt0_YkPL3Fn-Cva2jHZvoO9Lss0eOWHj9X8
- **PagerDuty**: https://groupon.pagerduty.com/services/P25RQWA

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `janus-web-cloud` | `GET /janus/api/v1/` — expect 204 | No fallback; job fails and retries on next DAG run |
| Ultron API (`ultron-api.production.service`) | Query watermark state for a known job name | No fallback; job fails to identify new files |
| GCS buckets | `gsutil ls gs://grpn-dnd-prod-pipelines-pde/...` | No fallback; Spark job fails with file read exception |
| SMA metrics gateway | HTTP GET to `metricsGateway` host | Non-critical; metric submission failure does not fail the Spark job |
