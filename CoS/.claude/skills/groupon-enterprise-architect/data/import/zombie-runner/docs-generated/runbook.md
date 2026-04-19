---
service: "zombie-runner"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

Zombie Runner has no HTTP health endpoint — it is a CLI process, not a long-running service. The health of a workflow execution is determined by the process exit code and the task status records written to the filesystem state store.

| Mechanism | Type | Description |
|-----------|------|-------------|
| Process exit code | exec | `zombie_runner run` exits 0 on success, non-zero on failure |
| Workflow state store | filesystem | Check checkpoint files in the workflow directory for task status |
| Dry-run validation | exec | `zombie_runner run <dir> --dry-run=true` validates context resolution without executing |

## Monitoring

### Metrics

> No evidence found in codebase of a centralized metrics system (e.g., Prometheus, Datadog) instrumented in Zombie Runner itself. Task execution statistics are written to the MySQL metadata store via `ZrHandler` (disabled in the Dataproc fork via `ZrDummyMetaTableUpdate`). The `influxdb==5.3.1` library is present in requirements but no direct InfluxDB instrumentation was found in the reviewed source files.

| Metric (internal) | Type | Description |
|-------------------|------|-------------|
| `execute/duration` | gauge | Task wall-clock execution time in seconds (written via `_statput`) |
| `__assertions` | counter | Total number of assertions evaluated for a task |
| `__failed_assertions` | counter | Number of failed assertions for a task |
| `num_solr_records_inserted_<core>` | counter | Records loaded into a Solr core by `SolrLoadFromFileTask` |

### Dashboards

> No evidence found in codebase. Dashboard configuration is not managed in this repository.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Task assertion failure | `fail: true` assertion evaluates to false | critical | Check assertion logs; review data quality issue; re-run workflow after fix |
| EMR step failure | EMR step enters `FAILED`, `CANCELLED`, or `INTERRUPTED` state | critical | Check EMR step logs in AWS Console; verify S3 bucket permissions and prefix |
| Workflow exits non-zero | `zombie_runner run` process exits with non-zero code | critical | Check stdout/stderr on the cluster node; review `/var/log/zombie_runner.log` |
| HDFS file not found | `HDFS_FILE_NOT_FOUND` error code raised | warning | Verify upstream task produced the expected HDFS output path |
| HDFS zero-length file | `HDFS_ZERO_LENGTH_FILE` error code raised | warning | Verify source data is not empty; check upstream pipeline output |

> Jira issues labeled `zombie_runner_generated` are created automatically by workflows that invoke the `JiraServer` integration for operational alerting.

## Common Operations

### Start a Workflow

1. Provision or reuse a Dataproc cluster with the `zombie-runner` image family
2. SSH into the cluster primary node: `gcloud compute ssh --zone <zone> "<cluster-name>-m" --tunnel-through-iap --project <project>`
3. Switch to root: `sudo su`
4. Copy workflow files to `/root` (or set `ZOMBIERC` and `ODBCINI` for a user home directory): `gsutil cp -r gs://<bucket>/<workflow>/* /root`
5. Run the workflow: `zombie_runner run /root/<workflow_dir>/`

### Run a Specific Task

```
zombie_runner run /path/to/workflow/ --task=<task_name>
```

This runs only the named task and its upstream dependencies.

### Dry-Run Validation

```
zombie_runner run /path/to/workflow/ --dry-run=true
```

Validates that all context variables resolve correctly without executing any task operators.

### Restart a Failed Workflow

1. Identify the failed task from stdout/stderr output
2. Fix the root cause (data issue, configuration error, dependency outage)
3. Re-run the full workflow or target the specific task: `zombie_runner run /path/to/workflow/ --task=<failed_task_name>`

> Note: Full restartability (skipping already-completed tasks on re-run) is not yet implemented in the Dataproc fork.

### Scale Up Parallelism

Increase the `--parallelism` flag or add more resource slots in the workflow `resources` section:

```
zombie_runner run /path/to/workflow/ --parallelism=8
```

### Delete a Cluster After Use

```
gcloud dataproc clusters delete <cluster-name> --region=<region>
```

Clusters with `--max-idle=12h` auto-delete after 12 hours of inactivity.

### Database Operations

SQL task schemas and DDL are managed per-pipeline in the individual workflow YAML files. The MySQL metadata store schema is initialized via `zombie_runner/shared/resource/zrdb-0.0.1.sql`.

## Troubleshooting

### Task Fails with Permission Error

- **Symptoms**: Subprocess exits with non-zero code; stderr contains "Permission denied"
- **Cause**: Zombie Runner is not running as root, or ODBC / workflow files are not readable by the current user
- **Resolution**: Run as root (`sudo su`); or set `ODBCINI` and `ZOMBIERC` to user-specific paths; verify file permissions with `ls -la`

### ODBC Connection Failure

- **Symptoms**: Task fails with ODBC connection error in stderr
- **Cause**: DSN not defined in `odbc.ini`, wrong credentials, or network connectivity to database host
- **Resolution**: Check `cat ~/.odbc.ini` for DSN definition; test with `isql -v <DSN> <user> <password>`; verify network reachability from the cluster node

### Spark Job Fails

- **Symptoms**: `SparkSubmit` task exits non-zero; "spark job failed with code N" in logs
- **Cause**: SPARK_HOME not set, missing JARs, insufficient cluster resources, or application error
- **Resolution**: Verify `SPARK_HOME` env var or `spark-home` context key; check Spark driver and executor logs in the Dataproc YARN UI or GCS log bucket

### EMR Step Times Out or Fails

- **Symptoms**: `wait_for_step_completion` exceeds `max_attempts` (300 attempts × 10 seconds = 50 minutes) or EMR step enters failed state
- **Cause**: Large data volume, EMR cluster unavailable, or S3 permissions issue
- **Resolution**: Check EMR step logs in AWS Console; verify `emr_cluster_name` is correct and the cluster is in RUNNING/WAITING state; verify IAM role permissions on S3 bucket

### Context Variable Not Resolved

- **Symptoms**: Task fails with "Invalid context variable [X]" or variable appears as literal `${X}` in output
- **Cause**: Variable not defined in `context` section, not emitted by an upstream task, and not passed via `--<key>=<value>` CLI flag
- **Resolution**: Run with `--dry-run=true` to see all unresolved variables; add the variable to the workflow `context` or pass it via CLI

### Workflow Hangs / Tasks Never Complete

- **Symptoms**: Workflow appears to run but no task output appears; process does not exit
- **Cause**: Circular dependency in the DAG, a FIFO pipe deadlock in data movement tasks, or a blocked database query
- **Resolution**: Check the DAG for circular dependencies using `--dry-run=true`; kill the process (`Ctrl+C`); check HDFS and database for blocking long-running queries

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Production data pipeline completely blocked; downstream SLA at risk | Immediate | GCP Migration Tooling POD — Slack: `#gcp-groupon-tooling-pod` |
| P2 | Specific task operator failing; partial pipeline output | 30 min | GCP Migration Tooling POD — JIRA: `DPGM` board |
| P3 | Non-critical pipeline delayed; no downstream SLA impact | Next business day | File issue in JIRA `DPGM` board |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| HDFS | `hadoop fs -ls /` from cluster node | No fallback; tasks fail and retry |
| Hive Metastore | `hive -e "show databases"` from cluster node | No fallback; HiveTasks fail |
| Snowflake | Test ODBC connection: `isql -v <snowflake_dsn>` | No fallback; SnowflakeTasks fail |
| AWS S3 | `aws s3 ls s3://<bucket>` with correct IAM role | No fallback; staging fails |
| Solr | `curl http://<solr_host>:<solr_port>/solr/admin/cores?action=STATUS` | No fallback; SolrTasks fail |
| Jira | `curl <jira_base_url>/rest/api/2/serverInfo` | No fallback; alert task fails (non-critical) |
