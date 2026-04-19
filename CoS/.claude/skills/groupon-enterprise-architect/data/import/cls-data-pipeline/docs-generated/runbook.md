---
service: "cls-data-pipeline"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN dashboard — `http://cerebro-resourcemanager2.snc1:8088/cluster/apps/RUNNING` (filter: `cls_realtime`) | HTTP (manual) | On demand | — |
| `PipelineMonitorJob` — runs `yarn application -status <app_id>` for each registered job | exec (scheduled batch) | Scheduled manually | — |
| Wavefront metrics dashboards | Metrics (external) | Continuous | — |

## Monitoring

### Metrics

> No evidence found in codebase for in-process metric emission (no Wavefront client, Micrometer, or StatsD calls in source). Metrics are inferred from YARN application state and Wavefront dashboards configured externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CLS General | Wavefront | https://groupon.wavefront.com/dashboards/cls#_v01(g:(an:OFF,d:691200,ls:!t,s:1615342756,w:'8d')) |
| PTS NA Pipeline | Wavefront | https://groupon.wavefront.com/u/ymJ223zrBN |
| PTS EMEA Pipeline | Wavefront | https://groupon.wavefront.com/u/LZkHVkzgLp |
| Proximity NA Pipeline | Wavefront | https://groupon.wavefront.com/u/sfxYX8Bm2x |
| Proximity EMEA Pipeline | Wavefront | https://groupon.wavefront.com/u/4wfnSqqsPM |
| GSS NA Pipeline | Wavefront | https://groupon.wavefront.com/u/q3vZhR43jM |
| GSS EMEA Pipeline | Wavefront | https://groupon.wavefront.com/u/dV2JmXS1Wm |
| Cerebro YARN Cluster | YARN | http://cerebro-resourcemanager2.snc1:8088/cluster/apps/RUNNING |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Kafka offset error | Kafka consumer group falls behind or offset becomes invalid | warning/critical | Restart the affected streaming job (see Start Spark Job below) |
| Spark job killed | YARN application moves to KILLED or FAILED state | critical | Restart the affected streaming job |
| Pipeline not running | `PipelineMonitorJob` detects a non-`RUNNING` YARN app state | critical | PagerDuty alert to `consumer-location-service@groupon.pagerduty.com`; restart failed job |

Alert notifications are sent via email to `cls-engineering@groupon.com` and paged to `consumer-location-service@groupon.pagerduty.com`.

## Common Operations

### Restart Service

To restart a streaming job:

1. SSH to Cerebro job submitter:
   ```bash
   ssh svc_cls@cerebro-job-submitter1.snc1
   ```
2. Find the application ID on the Cerebro dashboard or via `yarn application -list`.
3. Kill the running job:
   ```bash
   yarn application -kill <application_id>
   ```
4. Start the appropriate job (see per-pipeline start commands below).

### Scale Up / Down

Dynamic allocation is used (`spark.dynamicAllocation.enabled=true`). The min/max executor range is currently `3–3` (fixed). To scale:

1. Edit the spark-submit command to adjust `--conf spark.dynamicAllocation.minExecutors=<N>` and `--conf spark.dynamicAllocation.maxExecutors=<M>`.
2. Kill the current job and restart with the new parameters.

### Start Spark Job — Per Pipeline

#### PTS NA
```bash
export SPARK_HOME=/var/groupon/spark-2.4.0 && /var/groupon/spark-2.4.0/bin/spark-submit \
  --deploy-mode cluster --master yarn --queue cls_realtime \
  --executor-memory 10g --driver-memory 12g --executor-cores 2 \
  --conf spark.shuffle.service.enabled=true \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.dynamicAllocation.minExecutors=3 \
  --conf spark.dynamicAllocation.maxExecutors=3 \
  --conf spark.hadoop.hive.enforce.bucketing=false \
  --conf spark.hadoop.hive.enforce.sorting=false \
  --files /var/groupon/spark-2.4.0/conf/hive-site.xml \
  --class com.groupon.cls.stream.job.impl.PtsLocationJob \
  /home/svc_cls/kafka-pipeline-job/cls-data-pipeline-assembly-1.3.0.jar \
  --numOfpartitions 80 --kafka_broker kafka-aggregate.snc1:9092 \
  --topics_input mobile_notifications --batch_interval 60 \
  --groupId kafka_cls_mpts_na --offsetReset latest \
  --deploy_for_dc na --topics_output cls_coalesce_pts_na \
  --output_kafka_broker kafka.snc1:9092 --enableKafkaOutput
```

#### PTS EMEA
Same command as PTS NA with: `--kafka_broker kafka.dub1:9092 --groupId kafka_cls_mpts_emea --deploy_for_dc emea`

#### Proximity NA
```bash
--class com.groupon.cls.stream.job.impl.ProximityLocationJob \
--kafka_broker kafka.snc1:9092 --topics_input mobile_proximity_locations \
--groupId kafka_cls_prxmty_na --deploy_for_dc na
```

#### Proximity EMEA
Same as Proximity NA with: `--kafka_broker kafka.dub1:9092 --groupId kafka_cls_prxmty_emea --deploy_for_dc emea`

#### GSS NA
```bash
--class com.groupon.cls.stream.job.impl.GssDivJob \
--kafka_broker kafka-aggregate.snc1:9092 --topics_input global_subscription_service \
--groupId kafka_cls_gss_na --deploy_for_dc na
```

#### GSS EMEA
Same as GSS NA with: `--kafka_broker kafka.dub1:9092 --groupId kafka_cls_gss_emea --deploy_for_dc emea`

### Alternative: Shell Script Launch
```bash
ssh svc_cls@cerebro-job-submitter1.snc1
sh start_pts_na.sh       # or start_pts_emea.sh, start_proximity_na.sh, etc.
```

### Database Operations

Hive table DDL is executed inline by each streaming job on startup via `CREATE TABLE IF NOT EXISTS`. No migration scripts exist. For manual debugging:

- All history tables are partitioned on `record_date`. Always include `WHERE record_date = 'yyyy-MM-dd'` in queries to avoid full table scans.
- Production database: `grp_gdoop_cls_db`
- Staging database: `cls_staging`

## Troubleshooting

### Kafka Offset Error

- **Symptoms**: Job logs show `OffsetOutOfRangeException` or consumer group offset is missing/invalid
- **Cause**: The Kafka topic was compacted, the consumer group offset expired, or the job was restarted with `--offsetReset earliest` after a long gap
- **Resolution**: Restart the job with `--offsetReset latest` to resume from the most recent offset. If backfill is needed, use `--offsetReset earliest` in a staging environment.

### Spark Job Killed (YARN)

- **Symptoms**: YARN application shows `KILLED` or `FAILED` state in Cerebro dashboard; `PipelineMonitorJob` sends pager alert
- **Cause**: Out-of-memory error, preemption by higher-priority YARN queues, or executor failures exceeding the threshold
- **Resolution**:
  1. Check YARN logs via `yarn logs -applicationId <app_id>`
  2. If OOM: increase `--executor-memory` in the spark-submit command
  3. Restart the job using the appropriate start command or shell script

### Hive Table Write Failure

- **Symptoms**: Spark task fails with `HiveException` or `AnalysisException`; data missing from Hive partition
- **Cause**: Hive metastore unavailable, HDFS quota exceeded, or schema mismatch
- **Resolution**:
  1. Verify Hive metastore connectivity from Cerebro
  2. Check HDFS disk usage for `grp_gdoop_cls_db`
  3. Restart the streaming job; missing micro-batch data cannot be recovered without Kafka offset replay

### Pipeline Monitor Not Sending Alerts

- **Symptoms**: Jobs fail but no email/pager received
- **Cause**: `PipelineMonitorJob` is not scheduled, SMTP relay `smtp.snc1` is unreachable, or job registration table is stale
- **Resolution**:
  1. Verify `PipelineMonitorJob` is running as a scheduled batch job
  2. Check SMTP relay connectivity from Cerebro
  3. Manually inspect `grp_gdoop_cls_db.pipeline_monitoring_table` to confirm job registration entries exist

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All six streaming pipelines down; no location data ingested | Immediate | CLS team via PagerDuty: consumer-location-service@groupon.pagerduty.com |
| P2 | One or more regional pipelines down; partial data loss | 30 min | CLS team Slack: #consumer-location-ind |
| P3 | Minor pipeline lag or non-critical batch job failure | Next business day | CLS team email: cls-engineering@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka (input topics) | Check consumer group lag via Kafka tools or Wavefront dashboard | No fallback; streaming job halts if broker unreachable |
| Hive / HDFS | Check Cerebro cluster health; verify `hive-site.xml` is accessible | No fallback; writes fail silently per batch |
| YARN / Cerebro | Check `http://cerebro-resourcemanager2.snc1:8088/cluster/apps/RUNNING` | No fallback; jobs cannot run |
| SMTP relay (`smtp.snc1`) | Test SMTP connectivity from Cerebro job submitter | No fallback; alerts are not delivered |
