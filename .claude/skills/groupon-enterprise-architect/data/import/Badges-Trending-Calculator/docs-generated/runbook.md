---
service: "badges-trending-calculator"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://<host>:8070/grpn/status` | http | Framework-managed | Framework-managed |
| Airflow DAG run status (`badges-trending-calculator-job`) | Airflow UI / API | Daily at 03:22 UTC | DAG SLA |
| Kafka consumer lag (Wavefront dashboard) | metrics | Continuous | — |
| Spark Streaming UI (via YARN ResourceManager) | UI | On-demand | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Kafka consumer lag (`mds_janus_msk_dev`) | gauge | Number of unconsumed messages on `janus-tier1` | Elevated lag = processing falling behind |
| Active Spark batches | gauge | Number of active micro-batches in Spark Streaming UI | >1 sustained = queueing |
| Spark batch processing time | histogram | Time to process one micro-batch | Must be < batch interval (600s) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Main service dashboard | Wavefront | https://groupon.wavefront.com/u/l7d2ZYFl6P?t=groupon |
| Kafka lag monitor | Wavefront | https://groupon.wavefront.com/u/ttGsZf8fH8?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Job not running | Airflow DAG last run failed or no active Dataproc job | critical | Manually trigger DAG; check logs |
| Kafka offset out of range | Spark logs show `OffsetOutOfRangeException` | critical | Request Kafka team to reset offset for `janus-tier1` with client id `mds_janus_msk_dev`; restart job |
| Processing lag growing | Active batch count > 1 sustained or processing time > batch interval | warning | Consider restarting job or increasing `--batch_interval` / executor resources |

PagerDuty: https://groupon.pagerduty.com/services/PDONLHN

## Common Operations

### Restart Service

1. Open the Airflow DAG UI for the target environment (links in `doc/OWNERS_MANUAL.md`).
2. Trigger the `badges-trending-calculator-job` DAG manually.
3. The DAG will: delete the existing cluster → create a new cluster → submit the Spark job.
4. Monitor the Dataproc jobs list until the new job UUID appears.
5. Paste the job UUID into GCP Log Explorer to verify startup logs.

> For staging and production: use the Airflow DAG UI directly (not the DAG runs console page — triggering from the console does not work in staging/prod).

### Scale Up / Down

1. Update executor resource parameters in `orchestrator/config/{env}/badges_trending_calculator.json`:
   - `spark.executor.memory` (currently `6g`)
   - `spark.executor.cores` (currently `2`)
   - `spark.executor.instances` (currently `8`)
   - `--batch_interval` arg (currently `600` seconds)
2. Deploy the updated orchestrator config via Deploybot.
3. Restart the job (see above) for changes to take effect.

### Database Operations

Redis keys are managed by the job itself. There are no migration scripts. To inspect or clear badge keys:
- Use the RaaS shuttle in the `badges-service` namespace to connect to the Redis instances.
- Filter the RaaS dashboard (https://pages.github.groupondev.com/data/raas/elasticache/list.html) by `badges`.
- Key patterns: `bds3|*` (production), `staging|*` (staging).

## Troubleshooting

### Kafka Offset Out Of Range

- **Symptoms**: Spark streaming logs show `OffsetOutOfRangeException` or `kafka.common.OffsetOutOfRangeException`; job fails or stalls.
- **Cause**: Kafka has expired or compacted the offsets stored by the consumer group `mds_janus_msk_dev`.
- **Resolution**: Contact the Kafka team (https://services.groupondev.com/services/kafka) to reset the offset for the `janus-tier1` topic with client id `mds_janus_msk_dev`. After reset, restart the job or wait for the daily restart.

### Kafka Offset Not Catching Up / General Debugging

- **Symptoms**: Processing lag grows; Redis badge keys are stale; Kafka lag monitor shows increasing lag.
- **Cause**: Job may not be running, or micro-batch processing time exceeds batch interval.
- **Resolution**:
  1. Check Airflow to confirm the job is running. Start manually if not.
  2. Check GCP Log Explorer for the current job UUID — look for errors.
  3. Open YARN ResourceManager via the Dataproc cluster console → click ApplicationMaster → open Spark UI.
  4. Check the Streaming tab: active batch count should be 1 or fewer; processing time < 600s.
  5. If tasks are queuing: restart the job (combines all unconsumed batches) or increase `--batch_interval` / executor resources.

### Redis Connection Failures

- **Symptoms**: Log lines with `JedisConnectionException` or `Lettuce exception occurred`; Redis keys not updating.
- **Cause**: Redis cluster is unavailable or connection pool exhausted.
- **Resolution**: Verify Redis cluster health via the RaaS dashboard. If pool exhaustion is suspected, increase `maxTotal` in `redisConfig.clusterConfig` and redeploy.

### Watson Service Errors

- **Symptoms**: Log lines with `Watson Service threw exception` / `ClientProtocolException`; deals not appearing in badge rankings (missing division/channel enrichment).
- **Cause**: Watson KV (`watson-api--dealkv`) is unavailable or returning non-2xx responses.
- **Resolution**: Check Watson KV service status. Affected rows are skipped (empty division/channel); they will not appear in ranked lists until Watson recovers and the next batch processes new purchase events for those deals.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Job not running; no badge data updating | Immediate | badges-service@groupon.pagerduty.com |
| P2 | Job running but processing lag >30 min | 30 min | deal-catalog-dev@groupon.com |
| P3 | Individual deal badges missing (Watson errors) | Next business day | deal-catalog-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Janus Kafka | Check Kafka consumer lag on Wavefront (`ttGsZf8fH8`) | None — job stalls if Kafka is unreachable |
| Watson KV | HTTP 200 from `/v1/dds/buckets/relevance-item-intrinsic/...` | Affected deals skipped (no badge ranking) |
| Bhuvan geo-places | HTTP 200 from `/geoplaces/v1.3/divisions` | Previously cached `Divison_Supported` key in Redis continues to be used |
| Redis | `GET Divison_Supported` returns non-empty | No fallback — Redis is critical path for both reads and writes |
