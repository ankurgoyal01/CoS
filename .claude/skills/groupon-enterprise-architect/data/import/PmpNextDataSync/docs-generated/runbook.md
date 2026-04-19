---
service: "PmpNextDataSync"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Description |
|---------------------|------|-------------|
| Airflow DAG success/failure | Airflow UI / alerting | Primary health signal — DAG task state in Cloud Composer |
| Dataproc job status | GCP Dataproc console | Spark job state per cluster in `prj-grp-mktg-eng-prod-e034` region `us-central1` |
| Stackdriver logs | Cloud Logging | YARN container and driver logs streamed to Google Cloud Logging |

> No HTTP health endpoint is exposed. Health is inferred from Airflow DAG run state and Dataproc job status.

## Monitoring

### Metrics

> No evidence found in codebase of custom metrics instrumentation. Observability relies on Airflow/Dataproc platform metrics.

| Metric | Source | Description |
|--------|--------|-------------|
| DAG run duration | Airflow | Time from DAG start to completion |
| Spark job duration | Dataproc | Per-task Spark job wall time |
| SLA miss | Airflow | `sla_miss_callback` is configured on all DAGs; alerts when tasks exceed SLA |

### Dashboards

> No evidence found in codebase of dedicated Grafana or Datadog dashboards.

### Alerts

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| DAG task failure | Airflow task fails after retries | critical | Email sent to `cadence-arbitration@groupondev.opsgenie.net`; investigate Dataproc logs |
| DAG SLA miss | Task exceeds SLA duration | warning | `dag_sla_miss_alert` callback fires; check Dataproc cluster size and data volume |
| DAG task retry | Airflow task retrying | warning | Email sent to alert address; usually transient (GitHub API or Dataproc timeout) |

## Common Operations

### Restart a Failed DAG Run

1. Open Cloud Composer Airflow UI for the affected environment.
2. Navigate to the failing DAG (e.g., `medallion-prod-na`, `dispatcher-prod-na`).
3. Clear the failed task to trigger a retry.
4. Monitor Dataproc console (`prj-grp-mktg-eng-prod-e034`, `us-central1`) to confirm cluster creation and job submission.
5. Verify Hudi table write completes by checking GCS path `gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze/<table_name>`.

### Trigger a Full Load for a Specific Flow

1. Modify the relevant flow YAML in `DataSyncConfig/<env>/<flow>.yaml` — set `full_load: true` for the target sync job (or remove `read_checkpoint_column`).
2. Commit and push to the `main` branch (the Spark job fetches YAML from GitHub at runtime).
3. Trigger the DAG run manually via Airflow UI or wait for the next scheduled execution.
4. After the full load completes, revert the YAML change to resume incremental mode.

### Scale Up Dataproc Cluster

Cluster sizes are defined in JSON configs under `orchestrator/config/prod/<region>/`. To scale:
1. Modify `worker_config.num_instances` or `machine_type_uri` in the relevant config JSON.
2. Deploy the updated config via Jenkins (pushes updated DAG files to Composer bucket).
3. The next DAG run will use the new cluster configuration.

### Deploy Updated DataSyncCore JAR

1. Increment the version in `DataSyncCore/build.sbt` (or use SNAPSHOT for development).
2. Run `sbt publish` or trigger the Jenkins build — JAR is published to Artifactory.
3. Update `jar_file_uris` in the relevant Airflow DAG JSON config to reference the new JAR URL.
4. Deploy the config via Jenkins; next DAG run will download the new JAR.

### Add a New Sync Flow

1. Create a new YAML file in `DataSyncConfig/na-prod/` or `DataSyncConfig/emea-prod/` following the schema in [Configuration](configuration.md).
2. If using the medallion DAG, no DAG change is needed — `pmp-medallion-na.py` dynamically lists YAML files from the GitHub API and creates Spark tasks per file.
3. If a new Airflow DAG is needed, add a Python file in `orchestrator/` and a JSON config in `orchestrator/config/prod/<region>/`.
4. Deploy via Jenkins.

## Troubleshooting

### GitHub Config Fetch Fails

- **Symptoms**: Spark job fails at startup with `Failed to read Config from Git after 5 attempts`.
- **Cause**: GitHub Enterprise API is unreachable, or `git_token` is expired/invalid, or the YAML file path does not exist.
- **Resolution**: Verify the GitHub API token in `application-prod.yaml` is valid. Check that the YAML file exists at the expected path in the `Push/PmpNextDataSync` repo on the `main` branch. Check GitHub Enterprise API availability.

### JDBC Connection Failure

- **Symptoms**: Spark job fails with JDBC connection error on a specific source database.
- **Cause**: PostgreSQL host is unreachable, database credentials in `secrets.json` are stale, or the read-only replica is down.
- **Resolution**: Verify the JDBC URL is accessible from the Dataproc cluster subnet. Rotate credentials in `secrets.json` and redeploy the JAR. Confirm read-replica health in GCP Cloud SQL or the relevant managed database service.

### Hudi Write Fails

- **Symptoms**: Spark job fails during the Hudi write step with a conflict or filesystem error.
- **Cause**: Concurrent writes to the same Hudi table (multiple DAG runs), or GCS permission issue.
- **Resolution**: Ensure `max_active_runs=1` is set on the DAG (all DAGs in this service have this). Check GCS IAM permissions for the Dataproc service account. For corruption, use Hudi CLI to inspect table state.

### Checkpoint Divergence

- **Symptoms**: Duplicate records appear in downstream silver tables, or rows are skipped.
- **Cause**: Checkpoint was committed but Hudi write failed (or vice versa) — should not occur as checkpoint is committed after a successful write.
- **Resolution**: Check the `hudi__checkpoint_table` in the Hudi bronze lake. Manually reset or clear the checkpoint record for the affected job, then trigger a full load run.

### Dataproc Cluster Fails to Create

- **Symptoms**: `create_cluster` task fails; downstream Spark tasks never run.
- **Cause**: GCP quota exhaustion, VPC subnet capacity, or init script failure.
- **Resolution**: Check GCP quota for the region and project. Review Dataproc cluster creation logs in Cloud Logging. The `delete_cluster` task will still run (TriggerRule.ALL_DONE), so no dangling clusters.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Bronze Hudi lake not updated; downstream campaign dispatch stalled | Immediate | cadence-arbitration via OpsGenie |
| P2 | Single flow failing; partial data available | 30 min | cadence-arbitration via OpsGenie |
| P3 | DAG SLA miss but eventual success | Next business day | data-platform-team |

## Dependencies Health

| Dependency | How to Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise API | `curl -H "Authorization: Bearer <token>" https://api.github.groupondev.com/repos/Push/PmpNextDataSync/contents/DataSyncConfig/na-prod/` | Job retries 5 times; no fallback after that — job fails |
| PostgreSQL databases | Check read replica status in GCP Cloud SQL console | Job fails; checkpoint not committed; re-runs from last watermark |
| GCS / Hudi lake | `gsutil ls gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze/` | No fallback; write fails and job retries |
| Artifactory | Check `https://artifactory.groupondev.com` availability | Cluster creation fails; no fallback |
