---
service: "audienceDerivationSpark"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Resource Manager API: `GET http://cerebro-resourcemanager-vip.snc1:8088/ws/v1/cluster/apps` | http | On-demand | — |
| `fab listjobs` | exec (Python `requests` call to RM API) | On-demand | — |
| Cron log: `/home/audiencedeploy/ams/derivation/derivation_cron.log` | file | Post-run | — |

> No automated health check endpoint is exposed by this service. Job health is verified by checking YARN application status or Splunk logs after each run.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| YARN application state | gauge | State of Spark application: RUNNING, FINISHED, FAILED, KILLED | FAILED or KILLED = incident |
| Cron log error count | counter | Number of ERROR lines in `derivation_cron.log` | Any error = investigation |
| Job duration | gauge | Time from submission to FINISHED state | No formal threshold documented |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| YARN Resource Manager UI | YARN | `http://cerebro-resourcemanager1.snc1:8088` (tracking URL provided per-job by RM API) |
| Sparklint UI (per running job) | Spark | `{amHostHttpAddress_hostname}:23763` (evidenced in `resourcemanager_util.py`) |
| Splunk execution logs | Splunk | Search: `sourcetype=gdoop_app source=/var/groupon/log/gdoop/audiencederivation-Main.log host="cerebro-*" "AudienceDerivation"` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Derivation job FAILED | YARN finalStatus = FAILED | critical | Check Splunk logs; re-submit job if transient; investigate HDFS/Hive availability |
| Derivation job KILLED | YARN finalStatus = KILLED | warning | Check if manually killed or preempted; re-submit if appropriate |
| Cron not triggered | No new YARN app at expected time | warning | Check crontab on `cerebro-audience-job-submitter1.snc1`; verify cron daemon is running |
| AMS field sync failure | Log output shows sync error after derivation | warning | Run `fab {stage}:{region} sync_ams_fields` manually; escalate to AMS API team if API is down |

## Common Operations

### Restart Service (Re-submit a Failed Job)

1. SSH to the job submitter host:
   ```
   ssh audiencedeploy@cerebro-audience-job-submitter1.snc1
   ```
2. Navigate to the deployment directory:
   ```
   cd /home/audiencedeploy/ams/derivation/na/
   ```
3. Re-submit the failed job:
   ```
   ./submit_derivation.py --stage production --region na --job users
   ```
   or for EMEA:
   ```
   cd /home/audiencedeploy/ams/derivation/emea/
   ./submit_derivation.py --stage production --region emea --job bcookie
   ```
4. Monitor via `fab listjobs` or YARN UI.

### Deploy a New Version

1. Build locally:
   ```
   sbt clean assembly
   ```
2. Deploy to target environment and region:
   ```
   fab production:na deploy
   ```
   This uploads the JAR, Python scripts, and YAML config dirs to HDFS.

### Manual Kickoff via Fabric

```
fab production:na kickoff:users
fab production:na kickoff:bcookie
fab production:emea kickoff:users
fab production:emea kickoff:bcookie
```

### Scale Up / Down

Dynamic executor allocation is configured at spark-submit time. To change the executor count range, modify the `--conf spark.dynamicAllocation.minExecutors` and `--conf spark.dynamicAllocation.maxExecutors` values in `submit_derivation.py` and re-deploy.

For driver or executor memory changes, modify `--driver-memory` and `--executor-memory` arguments in `submit_derivation.py` or `field_sync.py` and re-deploy.

### Sync AMS Fields Manually

```
# Add new fields, update existing, list deletable (no deletion):
fab production:na sync_ams_fields

# Also delete extra fields from AMS DB:
fab production:na sync_ams_fields:syncDelete
```

### Sync AMS CQD Fields

```
fab staging:na sync_ams_cqd_fields:hive_table=cia_realtime.user_attr_daily,ams_table=cia_realtime.user_attr_daily,cqdconfig=amsNAUserAttrDaily.csv,create=false,update=true
```

### Database Operations

- **New derived table**: Defined automatically by `generalTableQueries` in YAML config; the `CREATE TABLE` DDL is executed by the Spark job
- **Dropping old timestamped tables**: Managed externally; no cleanup logic observed in this repo
- **Field backfill**: Re-run `fab {stage}:{region} sync_ams_fields` after schema changes

### List Recent Derivation Jobs

```
fab listjobs
```

This queries the YARN Resource Manager API and displays the 25 most recent `audiencedeploy` jobs with their state and tracking URLs.

## Troubleshooting

### Job Fails at YAML Config Load

- **Symptoms**: Spark job fails immediately at startup; exception mentioning HDFS path not found
- **Cause**: YAML config files were not uploaded to HDFS before job submission, or wrong stage/region path
- **Resolution**: Run `fab {stage}:{region} deploy` to upload YAML configs to HDFS; verify path `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/{configDir}/` exists

### SQL Tempview Step Failure

- **Symptoms**: Job fails mid-execution; Splunk shows `AnalysisException` or `SparkException` on a specific tempview step
- **Cause**: Source Hive table schema changed (added/removed column) or source table is missing
- **Resolution**: Check Hive table availability; update corresponding YAML config SQL if schema changed; re-deploy and re-submit

### AudiencePayloadSpark JAR Not Found

- **Symptoms**: CI build fails with dependency resolution error for `audiencepayloadspark`
- **Cause**: `AudiencePayloadSpark` snapshot JAR not published to Nexus
- **Resolution**: Rebuild and publish `AudiencePayloadSpark` to Nexus; then re-build this project

### Field Sync Discrepancy

- **Symptoms**: AMS shows fields that are no longer in derived table, or missing new fields
- **Cause**: Derivation YAML was modified but field sync was not run
- **Resolution**: Run `fab {stage}:{region} sync_ams_fields`; use `syncDelete` option only if confirmed extra fields should be removed

### YARN Job Preemption

- **Symptoms**: Job is KILLED; YARN shows preemption reason
- **Cause**: YARN queue capacity exceeded; higher-priority jobs preempted this job
- **Resolution**: Re-submit during off-peak hours; consider adjusting YARN queue priority or minimum executor allocation

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All derivation jobs failing; audience tables not updated; CRM targeting stale | Immediate | Audience Management Engineering team |
| P2 | One region or job type failing; partial audience freshness | 30 min | Audience Management Engineering team |
| P3 | AMS field sync failure; no impact on derived tables | Next business day | Audience Management Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| YARN | `fab listjobs` (queries RM API) or direct RM UI at `http://cerebro-resourcemanager1.snc1:8088` | No automatic fallback; re-submit when YARN recovers |
| HDFS | `hdfs dfs -ls hdfs://cerebro-namenode/user/audiencedeploy/derivation/` | No automatic fallback; job cannot start without config |
| Hive Metastore | Spark SQL connection attempt at job start | No automatic fallback; job fails if Hive is unavailable |
| AMS API | Post-derivation sync step result in job logs | Field sync can be re-run manually; does not block derived table availability |
