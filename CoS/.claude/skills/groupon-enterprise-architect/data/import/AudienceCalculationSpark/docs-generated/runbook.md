---
service: "AudienceCalculationSpark"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Resource Manager UI | HTTP — `http://cerebro-resourcemanager-vip.snc1:8088/cluster/apps` | On-demand | N/A |
| AMS job status | HTTP GET to AMS SA/PA status endpoints | On-demand | N/A |

> No automated health check endpoint exists for this service — it is a batch job, not a long-running server. Health is assessed by monitoring YARN application status and AMS lifecycle state.

## Monitoring

### Metrics

> No evidence found in codebase for a metrics instrumentation library (no Prometheus, Datadog, or StatsD client). Job durations are logged via the internal `Profiler` utility.

| Metric (logged) | Type | Description |
|----------------|------|-------------|
| `importAudienceDuration` | Duration (log) | Total elapsed time for a SA import job |
| `IdentityTransformDuration` | Duration (log) | Total elapsed time for a CA identity transform job |
| `publish` | Duration (log) | Elapsed time for PA publish step |
| `edwFeedback` | Duration (log) | Elapsed time for EDW feedback generation |
| `cacheDataFrame` | Duration (log) | Time to cache Spark DataFrame |
| `saveSourcedAudienceTableInHive` | Duration (log) | Time to write SA Hive table |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Submit a Spark Job Manually

1. SSH to submitter host: `ssh audiencedeploy@cerebro-job-submitter1.snc1`
2. Set Spark home: `export SPARK_HOME=/var/groupon/spark-2.0.1`
3. Run `spark-submit` with the appropriate `--class` and JSON payload argument:
   - SA: `--class com.groupon.audienceservice.SourcedAudience.AudienceImporterMain`
   - ID/CA: `--class com.groupon.audienceservice.IdentityTransform.IdentityTransformMain`
   - PA: `--class com.groupon.audienceservice.PublishedAudience.AudiencePublisherMain`
   - Joined: `--class com.groupon.audienceservice.JoinedAudience.AudienceJoinedMain`
4. Monitor at `http://cerebro-resourcemanager-vip.snc1:8088/cluster/apps` — search by SA/PA ID or job name

### Deploy a New JAR

1. Publish to Nexus: `sbt publish`
2. Run: `./deploy.sh <stage> <realm> <jartype> <version>`
3. Verify symlink updated: `ls -la /home/audiencedeploy/ams/swf/AudienceCalculationSpark-assembly-current.jar`

### Add YARN Queue Capacity

1. Contact the Data Systems team (see [CerebroV2 wiki](https://wiki.groupondev.com/CerebroV2#Contact))
2. Request additional vcores on the `audience` queue (NA) or `audience_emea` queue (EMEA)
3. Optionally increase per-job vcore count from AMS config to use new capacity

## Troubleshooting

### Job stuck in ACCEPTED state (not starting)

- **Symptoms**: YARN application stays in `ACCEPTED` state; no executors allocated
- **Cause**: YARN queue is at vcore capacity — all 1400 NA or 1000 EMEA vcores are in use
- **Resolution**: Wait for running jobs to complete, or contact Data Systems to add queue capacity; see `README.md` — Adding Capacity section

### Job fails with "Could not update SA/PA to IN_PROGRESS"

- **Symptoms**: Spark job exits immediately with exit code 1; AMS reports job as failed
- **Cause**: Outbound HTTPS PUT to AMS `updateSourcedAudienceInProgress` or `updatePublishedAudienceInProgress` failed
- **Resolution**: Check AMS health at the configured VIP host; verify Cloud Conveyer TLS certs on the submitter host; retry by manually resubmitting the job

### Job fails with "No primary key provided"

- **Symptoms**: SA import fails early; AMS receives FAILED result
- **Cause**: Workflow input JSON is missing both `consumer_id` and `bcookie` field definitions
- **Resolution**: Verify the SA definition in AMS includes at least one of `consumer_id` or `bcookie` as a field; correct and resubmit

### Job fails with "Required field(s) ... are missing in CSV"

- **Symptoms**: CSV-type SA fails during HDFS field validation
- **Cause**: Uploaded CSV header does not contain all fields declared in the SA definition
- **Resolution**: Re-upload the CSV with the correct headers matching the declared fields

### PA has wrong segment counts

- **Symptoms**: Default segment table has all rows labelled `"default"` instead of test labels
- **Cause**: Known segmentation bug described in README — default PA table segment column misconfiguration
- **Resolution**: Verify segment column values in the default Hive table; confirm non-default segments were created before the default union; re-run PA job

### Sourced audience has duplicates

- **Symptoms**: SA job reports failure with message "Your audience failed because it contains duplicate consumer_id/bcookie"
- **Cause**: Uploaded CSV or Hive query returned duplicate primary keys (more than 1 duplicate)
- **Resolution**: De-duplicate the source data and resubmit the SA job; use `SELECT DISTINCT` in custom queries to avoid this

### Bigtable write failure

- **Symptoms**: PA job fails during `publishPaMembership` step; stack trace shows Bigtable exception
- **Cause**: GCP service account credentials stale, network connectivity to GCP, or Bigtable instance unavailable
- **Resolution**: Check GCS bucket `grpn-dnd-prod-analytics-grp-audience` for service account JSON; verify GCP project `prj-grp-mktg-eng-prod-e034` and instance `grp-prod-bigtable-rtams-ins` are accessible

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All SA/PA jobs failing — audience delivery blocked | Immediate | Audience Management team |
| P2 | Subset of jobs failing (specific regions or audience types) | 30 min | Audience Management team |
| P3 | Individual job failure; retryable | Next business day | Audience Management team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AMS (continuumAudienceManagementService) | `GET <amsHost>/getPublishedAudience/1` | Job exits; no fallback |
| YARN / CerebroV2 | YARN RM UI at `http://cerebro-resourcemanager-vip.snc1:8088` | Job cannot start |
| Hive Warehouse | Spark `executeSelectQuery("USE <db>")` | Job fails and reports FAILED to AMS |
| GCP Bigtable | `BigtableHandler.get(...)` constructor | PA job fails if realtime=true; non-realtime jobs unaffected |
| Cassandra | spark-cassandra-connector connection | PA job fails; no fallback |
