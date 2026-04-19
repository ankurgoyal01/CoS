---
service: "campaign-performance-spark"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Resource Manager app state (`cerebro-resourcemanager-vip.snc1:8088/cluster`) | HTTP (manual / Wavefront) | Wavefront polling | n/a |
| HDFS/GCS status marker file (`app_status`) | File existence check via `QueryTerminator` | 10 seconds (internal) | n/a |
| `KafkaLagChecker metricLag` cron | exec (cron) | Every 1 minute | n/a |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `kafka.lag` (tagged by `topic`, `partition`) | gauge | Per-partition consumer lag between Kafka end offsets and stored processed offsets | Wavefront alert "Campaign Performance Kafka Lag" |
| `deduppedCount` | counter | Number of unique `(campaign, metric, user)` events per micro-batch after deduplication | Wavefront alert "Campaign Performance Processed Event Count Alert" |
| `dbBatchWrite` | histogram/timer | Time (ns) to write a partition of metrics to PostgreSQL | Wavefront alert "Campaign Performance High DB Latency" |
| `cacheRefresh` | timer | Time (ns) to reload the dedup cache from HDFS/GCS | Internal; visible in Wavefront |
| `dbClean` | timer | Time (ns) for a full DB retention cleanup pass | Internal; visible in Wavefront |
| `dbCleanNumDeleted` | gauge | Total rows deleted in the last `DBCleaner` run | Wavefront alert "Campaign Performance DB Size Near Quota" |
| `RowFilteringMapper.processed` | Spark accumulator | Total Janus rows processed before filtering | Internal |
| `RowFilteringMapper.filtered` | Spark accumulator | Total Janus rows dropped by the event-type filter | Wavefront alert "Campaign Performance Filtered Event Count" |
| Spark batch duration | Spark streaming metrics | Time taken for each 1-minute micro-batch to complete | Wavefront alert "Campaign Performance Job Execution Time Exceeds 1 Minute" |

All metrics are emitted to Telegraf/InfluxDB and surfaced in the [Wavefront Dashboard](https://groupon.wavefront.com/dashboard/campaign-performance). Wavefront alert tag: `campaign_performance`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Campaign Performance | Wavefront | `https://groupon.wavefront.com/dashboard/campaign-performance` |
| Kafka Topics | Wavefront | `https://groupon.wavefront.com/dashboard/kafka-topics` (cluster: `Kafka SNC1 Aggregate Production`, topic: `janus_all`) |
| Wavefront Alerts | Wavefront | `https://groupon.wavefront.com/u/n6RTm0R7SV` (tag: `campaign_performance`) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Campaign Performance Spark Job Active | Spark job not running on Cerebro | P1 / Sev 1 | Start the job; see [Starting the Application](#start-the-application) |
| Campaign Performance Processed Event Count Alert | Processed event count has dropped | P2 / Sev 2 | Verify job is running; check Janus volume on Kafka; check ELK error logs |
| Campaign Performance Job Execution Time Exceeds 1 Minute | Batch duration > 1 minute | P2 / Sev 2 | Check for slow executors; consider adding capacity |
| Campaign Performance Kafka Lag | Lag increasing or no data from lag checker | P2 / Sev 2 | Verify cron is running; check Telegraf data pipeline |
| Campaign Performance Failed Spark Job Stage | Spark stage failure count above threshold | P3 / Sev 3 | Spark auto-retries; if persistent, restart job |
| Campaign Performance DB Size Near Quota | DB size approaching quota | P3 / Sev 3 | Verify `DBCleaner` is running; contact GDS team to increase quota |
| Campaign Performance High DB Latency | `dbBatchWrite` timer above threshold | P3 / Sev 3 | Check GDS graphs in Wavefront dashboard |
| Campaign Performance Filtered Event Count | Filtered events higher than expected | P3 / Sev 3 | Check Wavefront and ELK logs for unusual filtering activity |
| HDFS Disk Space Near Quota grp_gdoop_pmp | HDFS disk usage close to 10TB quota | Nagios Sev 2 | Check HDFS usage; clean old cache/checkpoint dirs; request quota increase from GDoop team |

## Common Operations

### Start the Application

**Via Capistrano (preferred):**
```bash
cap snc1:production start_app
# or for staging:
cap snc1:staging start_app
```

**Manually on job submitter host:**
```bash
ssh svc_pmp@cerebro-job-submitter1.snc1
/home/svc_pmp/campaign-performance-spark-deploy/current/run/runCampaignPerformanceStreamingJob production
```

### Stop the Application (Graceful)

**Via Capistrano (preferred):**
```bash
cap snc1:production stop_app
```

**Manually (removes status marker file, triggers graceful shutdown):**
```bash
ssh svc_pmp@cerebro-job-submitter1.snc1
/home/svc_pmp/campaign-performance-spark-deploy/current/run/stopCampaignPerformanceStreamingJob production
```

### Force Stop the Application

```bash
ssh svc_pmp@cerebro-job-submitter1.snc1
/home/svc_pmp/campaign-performance-spark-deploy/current/run/forceStopCampaignPerformanceStreamingJob production
```

### Restart with DB Offsets

To resume from offsets stored in the `kafka_offsets` table (bypassing the Spark checkpoint):
```bash
# Pass use-offset=true as an argument in the start script
# Modify the `args` variable in runCampaignPerformanceStreamingJob before submitting
```

### Verify Spark Job Status

1. Open [Cerebro Resource Manager](http://cerebro-resourcemanager-vip.snc1:8088/cluster)
2. Search for `svc_pmp`
3. Find the latest application named `campaign-performance-{production|staging}-spark`
4. Check the **State** column (expected: `RUNNING`)

### Scale Up / Down

1. SSH to job submitter host as `svc_pmp`
2. Edit `runCampaignPerformanceStreamingJob`: adjust `--num-executors`, `--executor-memory`, `--executor-cores`, `--driver-memory`
3. Stop the current job gracefully
4. Restart with the updated script
5. For adding YARN queue capacity, submit a Hadoop capacity request to the GDoop team

### Database Operations

**Check DB retention cleanup:**
```sql
-- Count raw metric rows older than 7 days
SELECT count(*) FROM raw_rt_campaign_metrics WHERE created_at < NOW() - INTERVAL '7 days';
```

**Check DB size vs. quota:**
Contact GDS team via GDS Slack channel if `raw_rt_campaign_metrics` approaches quota.

**Run DB migrations:**
```bash
# Flyway-style migration scripts are in src/main/resources/db/up/
# Apply V1 through V4 migrations in order using the target database connection
```

### Check Kafka Lag Manually

```bash
java -cp "/home/svc_pmp/campaign-performance-spark-deploy/current/*" \
  -Dconfig.resource=conf/production.conf \
  com.groupon.mars.campaignperformance.utils.KafkaLagChecker printLag
```

### Clean HDFS Dedup Cache

```bash
# Check HDFS usage
ssh svc_pmp@cerebro-job-submitter3.snc1
hdfs dfs -du -h /user/grp_gdoop_pmp/

# Remove old cache files (run manually or via cleanCache script)
hdfs dfs -rm -r -skipTrash /user/grp_gdoop_pmp/campaign-perf-spark-outs/dedup_cache/<old-partition>

# Remove old checkpoints
hdfs dfs -rm -r -skipTrash /user/grp_gdoop_pmp/campaign-perf-spark-outs/spark_checkpoint-<archived-timestamp>
```

## Troubleshooting

### Spark Job Not Running

- **Symptoms**: Wavefront alert "Campaign Performance Spark Job Active" fires; no RUNNING app in YARN Resource Manager for `svc_pmp`
- **Cause**: Job crashed due to executor OOM, HDFS failure, Kafka data loss, or host failure; or was never started after a deployment
- **Resolution**: Start the job using the procedure above; check YARN STDERR diagnostics for the failed application if restart fails; engage dev team if error persists

### Kafka Lag Growing

- **Symptoms**: Wavefront alert "Campaign Performance Kafka Lag"; `kafka.lag` metric increasing over time
- **Cause 1**: Kafka lag checker cron not running on job submitter
- **Cause 2**: Spark job not consuming fast enough (slow executors, insufficient cores)
- **Cause 3**: Janus Kafka topic throughput spike
- **Resolution**: Verify cron via `crontab -l` on `cerebro-job-submitter2.snc1`; check latest cron log `kafka_lag_cron.<date>.out`; if job is slow, check for slow executors and consider adding capacity

### Batch Execution Time Exceeds 1 Minute

- **Symptoms**: Wavefront alert "Campaign Performance Job Execution Time Exceeds 1 Minute"; processing backlog forming
- **Cause**: Slow Cerebro executor nodes; HDFS read latency for dedup cache; DB write contention
- **Resolution**: Check Spark executor page for stragglers; restart job to get fresh executor assignment; increase `--num-executors` if persistent

### HDFS Disk Space Near Quota

- **Symptoms**: Nagios alert "HDFS Disk Space Near Quota grp_gdoop_pmp"
- **Cause**: Accumulated dedup cache files or archived checkpoints in `/user/grp_gdoop_pmp/`
- **Resolution**: Run `hdfs dfs -du -h /user/grp_gdoop_pmp/` to identify large directories; remove old dedup cache partitions and archived checkpoints; request quota increase from GDoop team if needed

### DB Size Near Quota

- **Symptoms**: Wavefront alert "Campaign Performance DB Size Near Quota"
- **Cause**: `DBCleaner` not running or not keeping up; unusual event volume spike
- **Resolution**: Verify `DBCleaner` is running (check service logs for "DB Cleaner task starting"); contact GDS team to increase space quota

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Spark job completely down; no campaign metrics being processed | Immediate | Push engineering on-call |
| P2 | Processing lag > 30 minutes; metrics stale | 30 min | Push engineering on-call |
| P3 | Metric anomalies (high filter rate, DB latency, failed stages) | Next business day | Push engineering dev team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka (`janus-all`) | `KafkaLagChecker printLag`; Wavefront Kafka Topics dashboard | `failOnDataLoss=true` in production (job fails on data loss); Spark checkpoint enables replay |
| PostgreSQL (`continuumCampaignPerformanceDb`) | Check GDS graphs in Wavefront dashboard | No fallback; writes fail and Spark retries the micro-batch |
| HDFS/GCS | `hdfs dfs -ls /user/grp_gdoop_pmp/` | Checkpoint and cache failures cause job failure; restart from DB offsets if checkpoint is corrupted |
| Telegraf / Influx | Check Wavefront metrics data lag | Metrics loss is non-fatal; job continues processing |
