---
service: "AudiencePayloadSpark"
title: Runbook
generated: "2026-03-03"
type: runbook
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Resource Manager UI: `http://cerebro-resourcemanager1.snc1:8088/cluster/apps` | HTTP / manual | On demand | — |
| Splunk log query — see Monitoring section | Log search | On demand | — |

> No automated health check endpoint. Job health is assessed via YARN application status and Splunk logs.

## Monitoring

### Metrics

> No evidence found in codebase of a metrics framework (Prometheus, StatsD, Datadog agent). Job-level metrics are captured in Splunk via Log4j.

### Dashboards

> Operational procedures to be defined by service owner.

### Alerts

> Operational procedures to be defined by service owner. Production email/pager alerting code is present in source (`EmailUtil.sendPagerAlert`) but commented out in `PAPayloadAggregatorMain` for SAD unfinished PA detection.

## Common Operations

### Deploy a New JAR

1. Build locally: `sbt clean assembly`
2. Deploy to target environment:
   ```
   fab production:na deploy
   fab staging:na deploy
   ```
3. Verify symlink `AudiencePayloadSpark-assembly-current.jar` is updated on the submitter host.

### Submit an Attribute Upload Job

Full upload of all users' attributes from the latest system table:
```
fab production:na upload_attributes:users
```

Delta upload (upload entries in `table1` but not in `table2`; remove entries in `table2` but not in `table1`):
```
fab production:na upload_attributes:users,table1,table2
```

### Submit a PA Membership Upload Job

Upload scheduled user PA memberships from the last 2 days:
```
fab production:na batch_upload_pas:users,-2,true
```

Delete scheduled PA memberships from the last 2 days:
```
fab production:na batch_delete_pas:users,-2,true
```

Upload all (scheduled + unscheduled) PA memberships from last 2 days:
```
fab production:na batch_upload_pas:users,-2,false
```

### Submit a SAD Aggregation Job

Aggregate user SADs from last 7 days (slow mode, unlimited PAs):
```
fab production:na upload_pas_agg:users,-7,sad
```

Aggregate user SADs from last 7 days, limit to 50 PAs, fast mode:
```
fab production:na upload_pas_agg:users,-7,sad,fast,50
```

Aggregate bcookie NonSADs from last 10 days:
```
fab production:na upload_pas_agg:bcookie,-10,nonsad
```

### Submit a CA Attributes Upload to Redis

```
fab production:na upload_ca_redis:users
fab production:emea upload_ca_redis:users,calibration  # full reconciliation
```

### Database Operations

**Check Cassandra write activity**: Monitor YARN job logs; verify Cassandra row counts post-job.

**Redis calibration (full reconcile)**: Run `upload_ca_redis:users,calibration` to scan all Redis keys and remove any not in today's `cia_realtime.user_attr_daily` table. This is slower than the default delta mode.

**Keyspaces locking row cleanup**: If a `HiveToKeyspaceWriter` job fails and the locking row `writing` is not cleaned up:
1. Connect to Keyspaces: `USE audience_service;`
2. Verify locking row exists: `SELECT * FROM <sad_table> WHERE id='writing';`
3. Delete manually if stale: `DELETE FROM <sad_table> WHERE id='writing';`

## Troubleshooting

### SAD PAs Contain Unfinished Ones
- **Symptoms**: `PAPayloadAggregatorMain` throws `"SAD PAs contains unfinished ones. Unfinished PA list: [...]"`
- **Cause**: One or more SAD PAs are still in `PUBLICATION_IN_PROGRESS` state when the aggregation job runs
- **Resolution**: Wait for PA publication to complete; re-run the aggregation job with the same parameters

### SADs Contain Duplicate PAs
- **Symptoms**: `PAPayloadAggregatorMain` throws `"Some SADs contains duplicate available PAs. The SAD list are: [...]"`
- **Cause**: The SAD definition contains duplicate PA entries in AMS
- **Resolution**: Investigate the SAD definition in AMS API; remove duplicate PAs; re-run the job

### Keyspaces Locking Row Already Exists
- **Symptoms**: `HiveToKeyspaceWriter` throws `"writing row already exists! Check for existing run."`
- **Cause**: A previous job run did not clean up the locking row (either still running or crashed before shutdown hook executed)
- **Resolution**: Verify no job is actively running in YARN; manually delete the `writing` row from the Keyspaces SAD table

### Redis Mass Deletion Guard Triggered
- **Symptoms**: `CAAttributeRedisWriterMain` throws `"The diff to yesterday is too large. diffCount=..., diffRatio=..."`
- **Cause**: Today's `cia_realtime.user_attr_daily` Hive table contains more than 10% fewer consumers than yesterday
- **Resolution**: Investigate the source Hive table for data issues; if legitimate (e.g., table refresh), run in `calibration` mode: `fab production:na upload_ca_redis:users,calibration`

### Search Logs on Splunk

General payload job logs:
```
sourcetype=gdoop_app source=/var/groupon/log/gdoop/audiencepayload-Main.log host="cerebro-*"
```

CA attributes uploader:
```
index=main sourcetype=gdoop_app source=/var/groupon/log/gdoop/audiencepayload-Main.log \
  host="cerebro-*" "production-na-upload-ca-attributes"
```

### Debug Redis Data

Connect to Redis cluster:
```
redis-cli -h <redis-host> -p <port>
```

Check latest version metadata:
```
GET latest-version
GET name-<version-sha256>
GET type-<version-sha256>
```

Check a specific consumer's attributes:
```
GET <consumer_id>
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Attribute payload not written to Cassandra — audience data stale | Immediate | Audience Management team |
| P2 | PA membership aggregation delayed — downstream targeting degraded | 30 min | Audience Management team |
| P3 | CA Redis attributes delayed — minor RTCIA attribute staleness | Next business day | Audience Management team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Cassandra cluster | YARN job exit code; monitor Cassandra host status | Re-run Fabric job after Cassandra recovery |
| AWS Keyspaces | YARN job exit code; check locking row state | Manual cleanup of locking row; re-run `HiveToKeyspaceWriter` |
| GCP Bigtable | YARN job exit code; check Bigtable console | Re-run derivation or CA Bigtable job |
| Redis cluster | Connect via `redis-cli`; run `info` / `dbsize` | Re-run CA Redis upload; use `calibration` mode for full reconcile |
| AMS API | Test `GET /getSourcedAudience/1?type=system` | Specify system table name explicitly via `--system-table` CLI flag |
| Hive / YARN | Check Resource Manager UI; `hdfs dfs -ls /user/audiencedeploy/` | Wait for cluster recovery; re-submit job |
