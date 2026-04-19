---
service: "janus-muncher"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `muncher-lag-monitor` Airflow DAG | Spark job (scheduled) | Every 20 minutes | Dataproc auto-delete TTL: 1500 s |
| `muncher-ultron_watch_dog` Airflow DAG | Spark job (scheduled) | Every 20 minutes | Dataproc auto-delete TTL: 1500 s |
| `muncher-backfill` Airflow DAG (BackfillMonitor class) | Spark job (scheduled) | Every 10 minutes | Dataproc auto-delete TTL: 1500 s |
| Wavefront dashboard `janus-muncher--sma` | Metrics dashboard | Continuous | — |
| PagerDuty `janus-prod-alerts@groupon.pagerduty.com` | Alert | On-demand | Immediate (P1) |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.data.backfill-triggered-quantity` | gauge | Set to 1 when a backfill is triggered, 0 otherwise | > 2 alerts in a short window — escalate to PDE team |
| Muncher job running duration | gauge | Total wall-clock duration of each MuncherMain Spark job | Operational threshold defined by service owner |
| Corrupt record quantity | gauge | Count of corrupt Parquet records detected per run (when `corruptRecordCheck = true`) | Any non-zero value should be investigated |
| Lag monitor metrics | gauge | Published by `LagMonitor` Spark class when processing lag is detected | Defined by SMA dashboard threshold |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| janus-muncher--sma | Wavefront | https://groupon.wavefront.com/dashboards/janus-muncher--sma |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Backfill triggered | `custom.data.backfill-triggered-quantity = 1` fired more than 2 times | warning | Escalate to PDE team; check Airflow DAG `muncher-delta` for failures and watermark lag |
| Dedup excluded events | `alertExcludedEvents = true` + events excluded | warning | Email to `platform-data-eng@groupon.com`; review dedup logs in Dataproc job driver output; check for schema changes in Janus Metadata API |
| PagerDuty — production alert | Muncher pipeline failure or lag threshold exceeded | critical | See PagerDuty runbook at `https://groupon.pagerduty.com/services/P25RQWA` |
| Airflow task failure | Any Airflow task other than `delete_cluster` or `delete_backfill_cluster_*` fails | warning/critical | Email to `platform-data-eng@groupon.com`; check Cloud Composer DAG run logs |

## Common Operations

### Restart / Rerun a Failed Delta Job

1. Navigate to Cloud Composer (Airflow UI) for the relevant environment.
2. Locate the `muncher-delta` or `muncher-delta-sox` DAG.
3. Clear the failed DAG run to trigger a re-execution, or trigger a new DAG run manually.
4. Monitor Dataproc job logs in the GCP Console for the `prj-grp-janus-prod-0808` project.
5. Verify watermark advancement via the Wavefront dashboard or by querying Ultron State API.

### Trigger a Backfill

1. The `muncher-backfill` DAG runs every 10 minutes and auto-detects lag via `BackfillMonitor`.
2. To manually trigger: navigate to `muncher-backfill` in Airflow and trigger a new DAG run with `runType = backfill`.
3. Backfill cluster uses 25 worker nodes (`e2-highmem-8`) — monitor GCP quota.
4. An email alert is sent to `platform-data-eng@groupon.com` and `edw-dev-ops@groupon.com` when backfill is triggered.

### Scale Up Delta Cluster

1. Update `muncher_delta_worker_config` in `orchestrator/janus_config/config_prod.py` (increase `num_instances`).
2. Deploy via Jenkins pipeline (merge to `main`, then promote to production via deploy-bot manual gate).
3. New cluster size takes effect on next DAG run.

### Hive Partition Repair

1. The `muncher-hive-partition-creator` DAG runs hourly (schedule: `20 * * * *`) and adds new partitions automatically.
2. For manual repair: trigger the `muncher-hive-partition-creator` DAG from Airflow UI.
3. Hive password is fetched automatically from GCP Secret Manager (`janus-hive-credentials` secret).
4. Verify partitions in Hive: `SHOW PARTITIONS grp_gdoop_pde.junoHourly;`

### Ultron DB Cleanup

The `muncher-ultron-db-cleaner` DAG runs periodically and purges Ultron MySQL records older than 30 days for all configured job names. To trigger manually, run the DAG from Airflow UI.

### Replay Merge

1. Ensure replay input data is staged in the replay GCS paths under `gs://grpn-dnd-prod-pipelines-pde/.../muncherReplay/mergePrep/`.
2. Trigger the `muncher-replay-merge-prep` DAG, then `muncher-replay-merge` DAG in sequence.
3. Replay status checkpoint is maintained at `gs://prod-us-janus-operational-bucket/janus_replay/checkpoint/`.
4. Stale replay status older than 12 hours (`janusReplayStatusStaleDuration = 12h`) is ignored.

## Troubleshooting

### Delta job lag — watermark not advancing

- **Symptoms**: Wavefront shows increasing lag; `muncher-backfill` is being triggered repeatedly; Ultron watermark is stale
- **Cause**: Input files not yet available in GCS (upstream Yati delay); Spark job exceeded Dataproc TTL (4 hours); resource contention on cluster
- **Resolution**: Check Dataproc job driver logs for exceptions; verify input GCS paths are populated for the expected `ds`/`hour`; check Ultron State API for the job entry (`JunoHourlyGcp`); consider scaling backfill cluster to catch up

### Deduplication excluded events alert email received

- **Symptoms**: Email from `svc_janus_gcp@groupon.com` with subject `SNC1-Production:: Muncher deduplication excluded events`
- **Cause**: Event key skew exceeded `eventKeySkewThreshold = 25000`; schema change in upstream events; new event type without a registered Janus schema
- **Resolution**: Review Dataproc driver logs for the excluded event types and counts; check Janus Metadata API for schema coverage; consult with data producers if schema changed unexpectedly

### Hive partitions missing for recent hours

- **Symptoms**: Analytics queries on `grp_gdoop_pde.junoHourly` or `grp_gdoop_pde.janus_all` return no data for recent hours despite GCS files existing
- **Cause**: `muncher-hive-partition-creator` DAG failed or was not triggered; HiveServer2 connection issue
- **Resolution**: Check `muncher-hive-partition-creator` DAG in Airflow for failures; manually trigger the DAG; verify HiveServer2 connectivity at `analytics.data-comp.prod.gcp.groupondev.com:8443`

### Small files accumulation in output partitions

- **Symptoms**: Large number of small Parquet files in GCS output partitions; Hive query performance degradation
- **Cause**: Many incremental runs writing small file sets; compaction DAG not running
- **Resolution**: Trigger the `compactor_sox_yati` (SOX) or equivalent non-SOX compaction DAG; this runs `SmallFilesCompactor` to merge small files using `YatiSoxCompactor` or `SimpleCompactor`

### Ultron WatchDog detecting orphaned job instances

- **Symptoms**: `muncher-ultron_watch_dog` DAG submitting `WatchDog` Spark class repeatedly; Ultron shows running instances for stale DAG run IDs
- **Cause**: Dataproc cluster was deleted but Ultron state was not updated; Airflow DAG run was cleared without completing the Spark job
- **Resolution**: WatchDog automatically resolves stale Ultron state; monitor Wavefront for normalisation; if problem persists, manually clear stale Ultron entries via `UltronDbCleaner`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Muncher pipeline fully stopped; no data flowing to Janus All or Juno Hourly | Immediate | PagerDuty `janus-prod-alerts@groupon.pagerduty.com`; Slack `janus-robots`; team `dnd-ingestion` |
| P2 | Significant lag (> 2 hours); partial output missing | 30 min | Slack `janus-robots`; `platform-data-eng@groupon.com` |
| P3 | Single run failure recovered by backfill; minor metric gaps | Next business day | `platform-data-eng@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCS (input) | Spark job fails to read input files; `muncher-lag-monitor` DAG publishes lag metric | Airflow DAG retries; `muncher-backfill` DAG auto-triggers to recover |
| Ultron State API | `muncher-ultron_watch_dog` queries Airflow and Ultron for inconsistencies | Watchdog Spark class resolves orphaned state entries |
| Janus Metadata API | Spark job fails during `JanusMetadataService` initialisation | No automatic fallback; requires DAG re-run after API recovery |
| Hive Metastore | `muncher-hive-partition-creator` task fails | Hive data missing from query results; manual DAG re-trigger after HiveServer2 recovery |
| SMTP Relay | Alert emails silently fail to deliver | Metrics and PagerDuty remain operational as primary alerting channels |
