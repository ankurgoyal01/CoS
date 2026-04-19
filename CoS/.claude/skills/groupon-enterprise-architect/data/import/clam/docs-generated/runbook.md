---
service: "clam"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `heartbeat` metric (Wavefront) — `custom.clam.alive=1` | Metrics-based | Every streaming micro-batch (~1 min) | No HTTP endpoint |
| YARN application status — `yarn application -list \| grep Clam` | exec (shell) | Manual / gdoop-cron polling | N/A |

> CLAM has no HTTP health endpoint (`status_endpoint.disabled: true` in `.service.yml`). Health is determined by the presence of the YARN application in `RUNNING` state and by the `heartbeat` metric being emitted to Wavefront.

## Monitoring

### Metrics

All self-metrics are published under the namespace `custom.clam` with tags `source=clam`, `env=<env>`, `service=clam`, and `atom=executor.<executorId>`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.clam.processing-time` | timer | Duration of each Spark job (from job start to job end event), emitted per micro-batch | Operational procedures to be defined by service owner |
| `custom.clam.input-count` | gauge/aggregate | Number of Kafka input rows processed per streaming query progress event | Drop to 0 indicates upstream producer failure |
| `custom.clam.bad-data` | counter | Count of histogram records that failed parsing or validation | Spike indicates upstream schema change |
| `custom.clam.update-count` | counter | Count of TDigest group state updates (existing state merged with new data) | Operational procedures to be defined by service owner |
| `custom.clam.output-count` | counter | Count of aggregate records emitted per group state evaluation | Operational procedures to be defined by service owner |
| `custom.clam.speculative-task-count` | counter | Count of speculatively re-launched Spark tasks | Sustained spike may indicate executor performance degradation |
| `heartbeat` (alive=1) | gauge | Emitted every streaming progress event; tagged with `version.spark`, `version.java`, `version.clam`, `rate=60` | Absence of heartbeat for >2 minutes indicates job is down |
| `custom.clam.input-count.clocked` | counter | Input records counted at their event time (not wall clock time) — used for lag analysis | Significant lag indicates Kafka consumer falling behind |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CLAM main dashboard | Wavefront | https://groupon.wavefront.com/dashboards/clam |
| CLAM Kafka Stream dashboard | Wavefront | https://groupon.wavefront.com/dashboards/CLAM-Kafka-Stream |
| Custom CLAM view | Wavefront | https://groupon.wavefront.com/u/5W4R9m04Xh?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CLAM job not running | YARN application `Clam` not in `RUNNING` state for >2 min | P1 | gdoop-cron should auto-restart; if not, run deploy or manual `submit-clam.sh` |
| Heartbeat absent | `heartbeat.alive` not received for >2 min | P1 | Check YARN job status; check Kafka broker connectivity |
| PagerDuty service | Escalation target | — | https://groupon.pagerduty.com/services/PNFF95G |

## Common Operations

### Restart Service

1. SSH to the job-submitter host for the target colo (e.g., `gdoop-metrics-job-submitter1.snc1`).
2. Check if the job is running: `yarn application -list | grep Clam`
3. Kill the current instance if running: `yarn application -kill <applicationId>`
4. gdoop-cron will automatically resubmit within 1 minute via `submit-clam.sh <env> <region>`.
5. To force immediate submission: run `/home/svc_clam/releases/current/submit-clam.sh <env> <region>` as `svc_clam`.
6. Verify the job reaches `RUNNING` state: `yarn application -list | grep Clam`

### Deploy New Release (Ansible)

```
cd ansible/
ansible-playbook submit.yml \
  -i hosts.yml \
  --limit production:snc \
  -e "version=2.1.25 env=prod region=snc"
```

Add `-e "delete_hdfs=true"` if the deployment includes breaking changes to the TDigest state schema (requires HDFS checkpoint deletion).

### Scale Up / Down

1. Update `EXECUTORS_COUNT`, `EXECUTORS_CORES`, or `EXECUTORS_MEMORY` in `src/conf/env/<env>-<colo>/env.sh.conf`.
2. Commit, build, and deploy a new release using the Ansible playbook.
3. Alternatively, modify the submission command directly on the job-submitter host and restart the job manually.

### Database Operations (HDFS Checkpoint)

- **View checkpoint state**: `hdfs dfs -ls /user/grp_gdoop_metrics/clam_spark_app/checkpoint/`
- **Delete checkpoint (clean restart)**: `hdfs dfs -rm -r /user/grp_gdoop_metrics/clam_spark_app/checkpoint/`
  - This causes the job to restart from the latest available Kafka offsets. Use only when HDFS state is corrupt or after a breaking state schema change.
  - Trigger via Ansible: add `-e "delete_hdfs=true"` to the `submit.yml` playbook command.

## Troubleshooting

### Job not restarting after failure
- **Symptoms**: YARN application `Clam` is absent from `yarn application -list`; heartbeat metric absent from Wavefront.
- **Cause**: gdoop-cron is not running or misconfigured; or the gdoop-cron config at `/home/svc_clam/gdoop-cron/config.yml` is stale.
- **Resolution**: Verify gdoop-cron is running on the job-submitter host (`/usr/local/etc/init.d/gdoop-cron status`). Re-run the Ansible `submit.yml` playbook to refresh the config and restart gdoop-cron.

### Kafka consumer lag / high processing time
- **Symptoms**: `custom.clam.processing-time` elevated; input-count.clocked shows events with timestamps significantly behind wall clock; output-count low relative to expected input.
- **Cause**: Kafka consumer lag building up; typically caused by Kafka broker slowness, insufficient executors, or a large backlog after a restart.
- **Resolution**: Check Kafka broker health. Consider temporarily increasing `repartitionCount` or executor count. If lagging after a clean restart from deleted checkpoint, allow time for the Kafka backlog to drain.

### Bad data spike
- **Symptoms**: `custom.clam.bad-data` counter increasing rapidly.
- **Cause**: Upstream producer changed the histogram JSON schema — missing required fields (`compression`, `service`, `aggregates`, `bucket_key`) or invalid JSON.
- **Resolution**: Identify the upstream producer emitting malformed messages. CLAM will silently discard bad-data records and continue processing valid records; no manual intervention needed unless the bad-data rate is 100%.

### HDFS checkpoint corruption
- **Symptoms**: Job fails to start with a Spark exception referencing checkpoint state deserialization; repeated crash-restart loop.
- **Cause**: Checkpoint was written with a different version of the TDigest class (Kryo serialization incompatibility) or HDFS write was interrupted.
- **Resolution**: Delete the checkpoint directory (`hdfs dfs -rm -r /user/grp_gdoop_metrics/clam_spark_app/checkpoint/`) and redeploy. The job will restart from latest Kafka offsets.

### Speculative task count elevated
- **Symptoms**: `custom.clam.speculative-task-count` increasing; overall job processing time normal or slightly elevated.
- **Cause**: One or more executors running slower than others (GC pressure, hardware issue, skewed partition).
- **Resolution**: Speculation is enabled by design (`spark.speculation=true`); monitor for persistent degradation. If a specific executor is consistently slow, check YARN node manager status on that host.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | CLAM job down — aggregates not published to Kafka; downstream metric dashboards stale | Immediate | metrics-team (PagerDuty: PNFF95G; Slack: CFJLD6L31) |
| P2 | Job running but high bad-data rate or significant consumer lag | 30 min | metrics-team@groupon.com |
| P3 | Elevated speculative task count; minor processing delay | Next business day | metrics-team@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka broker | `kafka.snc1:9092` — use Kafka CLI or broker metrics; check CLAM `input-count` metric | CLAM will fail and gdoop-cron will retry; no fallback processing — aggregates are lost while Kafka is down |
| HDFS (gdoop) | `hdfs dfs -ls /user/grp_gdoop_metrics/` | Clean restart from latest Kafka offsets after deleting checkpoint; potential for duplicate or missed aggregates |
| Metrics Gateway | Check `heartbeat` metric presence in Wavefront | Self-metrics are lost; streaming pipeline continues unaffected |
