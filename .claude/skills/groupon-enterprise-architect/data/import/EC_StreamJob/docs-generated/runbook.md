---
service: "EC_StreamJob"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Resource Manager UI | HTTP (manual check) | On-demand | N/A |
| `http://gdoop-resourcemanager2.snc1:8088/cluster/apps/RUNNING` | HTTP browser | Manual | N/A |
| `http://gdoop-resourcemanager2.dub1:8088/cluster/apps/RUNNING` | HTTP browser | Manual | N/A |

> No programmatic health check endpoint exists. The job's liveness is determined by checking the YARN running applications list.

## Monitoring

### Metrics

> No evidence found in codebase. No metrics instrumentation (e.g., Prometheus, StatsD, New Relic agent) was found in the application code. Spark internal metrics are available via the YARN/Spark UI.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Start the Job

After deploying the JAR, SSH to the appropriate job-submitter host and run:

**NA (snc1):**
```bash
ssh gdoop-job-submitter5.snc1
cd ~/stream_staging/   # or stream_production/
$SPARK_HOME/bin/spark-submit \
  --master yarn --executor-memory 1g --queue public \
  --driver-memory 1g --executor-cores 4 \
  --class com.groupon.sparkStreamJob.RealTimeJob \
  EC_StreamJob.jar NA staging RealTimeJobNA
```

**EMEA (dub1):**
```bash
export SPARK_HOME=/var/groupon/spark-2.0.1   # required on dub1
ssh gdoop-job-submitter1.dub1
cd ~/stream_production_emea/
$SPARK_HOME/bin/spark-submit \
  --master yarn --executor-memory 1g --queue public \
  --driver-memory 1g --executor-cores 4 \
  --class com.groupon.sparkStreamJob.RealTimeJob \
  EC_StreamJob.jar EMEA prod RealTimeJobEMEA
```

### Stop the Job

1. Locate the application ID in YARN UI (`http://gdoop-resourcemanager2.snc1:8088/cluster/apps/RUNNING`)
2. Kill via YARN: `yarn application -kill {applicationId}`

### Restart Service

1. Stop the job using the YARN kill command above
2. Re-run the `spark-submit` command as described in "Start the Job"

### Scale Up / Down

Scaling is manual. To change executor count or memory, stop the job and re-submit with updated `--num-executors`, `--executor-memory`, or `--executor-cores` flags.

### Deploy (New Version)

```bash
# Staging
cap staging deploy VERSION=1.10 TYPE=release

# EMEA staging
cap emea_staging deploy VERSION=1.10 TYPE=release

# Production NA
cap production deploy VERSION=1.10 TYPE=release

# Production EMEA
cap production_emea deploy VERSION=1.10 TYPE=release
```

### Rollback to a Specific Version

Re-deploy the target version using the same Capistrano command with the previous version number. The symlink `EC_StreamJob.jar` on the job-submitter host will be relinked to that version. Then restart the job.

### Database Operations

> Not applicable. This service owns no data stores.

## Troubleshooting

### Batch Processing Falling Behind (Queue Pile-Up)
- **Symptoms**: Increasing scheduling delay visible in Spark Streaming UI; YARN job consuming more memory
- **Cause**: TDM API response times exceed the 19-second batch timeout, or Kafka lag is growing faster than processing rate
- **Resolution**: Check TDM API health at the target VIP (`targeted-deal-message-app-vip.snc1` or `.dub1`). Backpressure is enabled and will auto-reduce consumption rate. If sustained, consider increasing executor count or TDM API capacity.

### Job Not Appearing in YARN Running Apps
- **Symptoms**: `spark-submit` completed but no entry in `http://gdoop-resourcemanager2.snc1:8088/cluster/apps/RUNNING`
- **Cause**: Job may have failed at startup (bad colo/env args, JAR not found, Kafka broker unreachable) or YARN queue capacity exceeded
- **Resolution**: Review `spark-submit` stdout/stderr. Verify JAR exists at `~/stream_{env}/EC_StreamJob.jar`. Validate colo and env arguments are exactly `NA`/`EMEA` and `staging`/`prod`.

### Avro Decode Failures
- **Symptoms**: Exceptions printed to driver logs referencing `AvroUtil.transform()`; events not reaching TDM
- **Cause**: Janus metadata API unreachable or schema version mismatch
- **Resolution**: Verify the Janus metadata API URL is reachable (`JanusBaseURL.PROD.getUrl` or `http://janus-metadata-management-app.dub1` for EMEA prod). Engage the Data Engineering / Janus team.

### Request Interrupted Errors in Logs
- **Symptoms**: Log message `Request interrupted, error {message}` followed by a stack trace
- **Cause**: The 19-second batch timeout (`MAX_DELAY`) was reached before all TDM HTTP futures completed
- **Resolution**: Check TDM API latency and availability. The batch was abandoned and Kafka offsets advanced; affected events will not be retried. This is expected behavior under TDM degradation.

### EMEA Job Failing with Spark Version Error
- **Symptoms**: Spark version incompatibility errors on dub1 cluster
- **Cause**: dub1 cluster may still use Spark 1.6 by default
- **Resolution**: Ensure `export SPARK_HOME=/var/groupon/spark-2.0.1` is set before running `spark-submit` on dub1.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Job not running — no events reaching TDM | Immediate | Emerging Channels team |
| P2 | Job running but high batch delay / large Kafka lag | 30 min | Emerging Channels team |
| P3 | Elevated request timeout errors in logs | Next business day | Emerging Channels team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka (`janus-tier2`) | Check Kafka consumer group lag: `kafka-consumer-groups.sh --group EC_StreamJobKafKaNAGroup` | No fallback; job stalls if Kafka is unreachable |
| Janus metadata API | HTTP GET to `JanusBaseURL.PROD.getUrl` | No fallback; Avro decoding fails silently per event |
| TDM API (VIP) | `curl http://targeted-deal-message-app-vip.snc1/v1/updateUserData` | Batch times out after 19 seconds; no retry |
| YARN cluster | YARN Resource Manager UI | No fallback; job cannot run without YARN |
