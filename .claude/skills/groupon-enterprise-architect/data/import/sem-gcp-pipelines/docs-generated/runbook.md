---
service: "sem-gcp-pipelines"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG task status (GCP Composer UI) | UI / GCP Composer monitoring | Per DAG schedule | Per DAG timeout |
| PagerDuty alert via `trigger_event` callback | webhook | On DAG task failure | Immediate |
| GCP Stackdriver / Cloud Logging | log-based | Continuous | N/A |

Status endpoint is disabled (`status_endpoint: disabled: true` in `.service.yml`). Health is monitored via Airflow DAG task success/failure states and PagerDuty alerts.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DAG task success/failure | status | Airflow task-level pass/fail for each pipeline step | Any failure triggers PagerDuty |
| Dataproc cluster lifecycle | status | Cluster create/delete events visible in GCP Cloud Console | Cluster stuck in creating/deleting state |
| GCP Cloud Logging job driver output | log | Spark job stdout/stderr logged to Stackdriver | Error patterns in logs |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| S2S Cloud | Wavefront | `https://groupon.wavefront.com/dashboards/da-s2s-cloud` |
| S2S Detailed | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-da-s2s-detailed` |
| S2S SMA | Wavefront | `https://groupon.wavefront.com/dashboard/da-s2s--sma` |
| ELK / Kibana | Kibana | `https://logging-us.groupondev.com/app/kibana#/dashboard/db48cda0-e6c8-11e9-b152-e96244fd5c54` |
| Airflow (dev) | GCP Composer | `https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com` |
| Airflow (stable) | GCP Composer | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com` |
| Airflow (prod) | GCP Composer | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG task failure | Any Airflow task triggers `on_failure_callback: trigger_event` | P2 | Check Airflow logs; inspect Dataproc job logs in GCP Cloud Console; retry DAG run |
| Dataproc cluster stuck | Cluster not reaching RUNNING state within expected time | P2 | Check GCP Console for quota issues or subnet capacity; delete stuck cluster manually and retry |
| Keyword submission failure | `submit_keywords` PySpark job fails | P2 | Check GCS data partition exists for target_date/country; check Message Bus connectivity |

Alert notification channel: `sem-application-alerts@groupon.pagerduty.com` (PagerDuty service `PFA1RPI`), GChat space `AAAAYDlPZ8Q`.

## Common Operations

### Restart / Re-trigger a DAG Run

1. Open the Airflow Composer UI for the relevant environment (see Dashboard links above).
2. Navigate to the failing DAG.
3. Clear the failed task(s) using "Clear" in the Airflow task detail view, or trigger a new DAG run from the UI.
4. Monitor task logs via the Airflow UI or GCP Cloud Logging.

### Trigger a DAG Manually

1. Open the Airflow Composer UI.
2. Navigate to the target DAG.
3. Click "Trigger DAG" (play button), optionally providing a `gs_path` parameter for GTTD feed splitting DAGs.

### Scale Up Dataproc Cluster Workers

Cluster worker count is defined in `cluster_config_{env}.json`. To add workers:
1. Update `cluster_config.worker_config.num_instances` in the relevant config file.
2. Commit, raise a PR, and deploy via Jenkins.
3. All subsequent DAG runs will use the new cluster configuration.

### Add or Rotate Secrets

1. Add/update the secret value in the private repo `sem-gcp-secrets` (in the appropriate environment files folder).
2. Create a PR in `sem-gcp-secrets` for approval.
3. After merge, run `git submodule update --remote` in the `sem-gcp-pipelines-secrets` repo.
4. Update `region.hcl` in the relevant environment folder.
5. Apply via Terrabase:
   ```
   terrabase gcp-login envs/prod
   terrabase plan envs/prod
   terrabase apply envs/prod
   ```

### Database Operations

> Not applicable — this service does not own any relational databases. Data is stored in GCS.

## Troubleshooting

### DAG Task Fails at `create_dataproc_cluster`

- **Symptoms**: Airflow task `create_dataproc_cluster` fails with quota or network error
- **Cause**: GCP quota exceeded in `us-central1-f` zone, or subnet capacity issue
- **Resolution**: Check GCP Console for quota limits and active clusters; delete any stuck clusters from previous runs; check subnet IP availability in `sub-vpc-prod-sharedvpc01-us-central1-private`

### DAG Task Fails at `load_secrets`

- **Symptoms**: Pig job step `load_secrets` fails
- **Cause**: Secret `sem_common_jobs` missing or access denied; cluster service account lacks Secret Manager access
- **Resolution**: Verify `sem_common_jobs` secret exists in GCP Secret Manager for the target project; confirm service account `loc-sa-c-sem-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com` has `roles/secretmanager.secretAccessor`

### Keyword Submission: `Data partition is not available`

- **Symptoms**: `submit_keywords` job logs "Data partition is not available. No keyword is submitted."
- **Cause**: Upstream keyword generation Spark job did not produce output for the expected GCS path (region/country/target_date partition missing)
- **Resolution**: Check GCS path for the target_date partition; re-run the upstream keyword generation DAG; verify the target_date parameter is correct

### Databreakers API: HMAC Signature Failure

- **Symptoms**: Databreakers client returns non-200 response or exception
- **Cause**: HMAC key for the target country is stale, or `hmac_timestamp` drift is too large
- **Resolution**: Rotate the Databreakers account key via the Secrets process; verify the Dataproc cluster system clock is accurate

### Message Bus: `ConnectionError: Attempting send without a connection`

- **Symptoms**: `SubmitKeywords` raises `ConnectionError`
- **Cause**: Message Bus STOMP connection failed during `mbus_client.connect()`
- **Resolution**: Verify Message Bus host/port in the job params JSON file; check Message Bus service availability; verify credentials (`MESSAGE_BUS.USERNAME`, `MESSAGE_BUS.PASSWORD`) are correct

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All SEM/Display pipelines down — no feeds delivered to ad platforms | Immediate | SEM Engineering on-call via PagerDuty PFA1RPI |
| P2 | One or more pipeline DAGs failing — partial feed delivery | 30 min | SEM Engineering on-call; mailing list sem-devs@groupon.com |
| P3 | Non-critical pipeline delayed or producing warnings | Next business day | sem-devs@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Composer | Check Airflow Composer UI and GCP Console status | Contact GCP support; pipelines paused until resolved |
| GCP Dataproc | Check GCP Console for cluster status and quota | Reduce concurrent DAG runs; check alternative zones |
| GCP Secret Manager | `gcloud secrets versions access latest --project={project}` | Pipeline jobs will fail; rotate credentials and retry |
| Deal Catalog Service | Check service status via internal service portal | Job returns `None` for affected deals; feed may be incomplete |
| Marketing Deal Service (MDS) | Check service status | Feed dispatch fails; DAG task fails and retries |
| Message Bus | Check STOMP connection in job logs | Keyword submission fails; re-trigger DAG after MB recovery |
