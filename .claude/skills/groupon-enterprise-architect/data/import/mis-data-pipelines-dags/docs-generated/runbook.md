---
service: "mis-data-pipelines-dags"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Cloud Composer Airflow web UI DAG status | http | Per DAG run (cron-driven) | Per Airflow task timeout |
| Dataproc cluster status (GCP Console) | GCP API | On-demand | N/A |
| Data quality check alerts (email to `mds-alerts@groupondev.opsgenie.net`) | email | Per archival DAG run | N/A |
| Jenkins build status | CI | Per commit/push | Per build |
| Deal count day-over-day threshold check (±5%) | batch | Per archival DAG run | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Deal count day-over-day (NA US) | gauge | DQC metric `gdoop_na_us_deals_dod` on `grp_gdoop_mars_mds_db.mds_production` | Outside -5% / +5% triggers email alert |
| Deal count day-over-day (NA CA) | gauge | DQC metric `gdoop_na_ca_deals_dod` | Outside -5% / +5% triggers email alert |
| Deal count day-over-day (EMEA) | gauge | Similar DQC metrics for EMEA countries | Outside -5% / +5% triggers email alert |
| Deal count day-over-day (APAC) | gauge | Similar DQC metrics for APAC countries | Outside -5% / +5% triggers email alert |
| Spark job execution logs | log | Stackdriver Logging — `dataproc.logging.stackdriver.job.driver.enable=true` enabled on all clusters | N/A |
| YARN container logs | log | `dataproc.logging.stackdriver.job.yarn.container.enable=true` on all clusters | N/A |
| Zombie Runner stats | log | Written to `/home/mds-archive/zombie/zombie_runner_zrstat.log` on archival clusters | N/A |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cloud Composer Airflow UI | GCP Cloud Composer | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/` |
| GCP Dataproc Cluster Management | GCP Console | GCP Console > Dataproc > Clusters, project `prj-grp-mktg-eng-prod-e034` |
| DeployBot Deployment History | DeployBot | `https://deploybot.groupondev.com/MIS/mis-data-pipelines-dags` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| MDS archival DQC failure (NA) | US or CA deal count DoD change outside ±5% | warning | Check archival DAG run in Composer; verify MDS API availability; inspect Hive partition |
| MDS archival DQC failure (EMEA) | EMEA country deal count DoD change outside ±5% | warning | Same as NA procedure for EMEA countries |
| MDS archival DQC failure (APAC) | APAC (AU) deal count DoD change outside ±5% | warning | Same as NA procedure for APAC countries |
| Zombie Runner error email | Error-level log event in archival workflow | warning | Check email to `mds-dev@groupon.com`; review Zombie Runner log at `/home/mds-archive/zombie/zombie_runner_zr.log` |
| Jenkins build failure | Any pipeline stage fails | warning | Slack `mis-deployment` channel; check Jenkins console; ping commit author |
| Airflow DAG task failure | Airflow task state = `failed` | warning | Check Composer Airflow UI for task logs; inspect Dataproc cluster logs in Stackdriver |

## Common Operations

### Restart Service

Airflow DAGs do not have a traditional "restart". To re-trigger a failed or missed DAG run:
1. Navigate to Cloud Composer Airflow UI
2. Select the DAG (e.g., `mds-archive-na`, `bloomreach-sem-cdp-feeds-cleanup`)
3. Use "Trigger DAG" or "Clear" task state to re-run failed tasks
4. Monitor task progress in the Airflow Graph or Task Instance view

### Scale Up / Down

**For Janus Streaming (persistent cluster):**
1. Update autoscaling policy `mds-janus-autoscaling-policy` in GCP Console (project `prj-grp-mktg-eng-prod-e034`, region `us-central1`)
2. Or update `orchestrator/config/prod/mds_janus_auto_scaling_policy.yaml` and redeploy

**For MDS Feeds cluster:**
1. Update autoscaling policy `mds-feeds-autoscaling-policy`
2. Or update `orchestrator/config/prod/mds_feeds_auto_scaling_policy.yaml` and redeploy

**For ephemeral clusters:**
1. Update `num_instances` in the relevant JSON config file under `orchestrator/config/prod/`
2. Deploy via Jenkins / DeployBot; the next DAG run will use the updated cluster config

### Database Operations

**Drop old Hive partitions (manual cleanup):**
```sql
ALTER TABLE grp_gdoop_mars_mds_db.mds_archive_production DROP PARTITION (dt < '20230101');
ALTER TABLE grp_gdoop_mars_mds_db.mds_production DROP PARTITION (dt < '20230101');
```
Automated cleanup runs daily at 09:00 UTC via the `mds-archive-cleanup` DAG using retention thresholds: 92 days for flat/production, 732 days for archive.

**Manual archival run for a specific country:**
```bash
bash mds-archive/archival/run.sh US groupon <zombierc_path>
```

## Troubleshooting

### Archival DAG fails — MDS download step
- **Symptoms**: `get_mds_data` task fails with non-zero exit or HTTP 503; archival DAG run marked failed in Composer
- **Cause**: MDS API (`marketing-deal-service.production.service`) unavailable or TLS certificate expired
- **Resolution**: Verify MDS API availability; check TLS certificate validity in GCP Secret Manager (`mis_certificate`); re-trigger DAG after fix

### Janus Streaming job stops processing
- **Symptoms**: Kafka consumer group `mds_janus_msk_prod_3` lag increases; Redis queue not growing; Spark UI shows no active batches
- **Cause**: Janus Spark Streaming job may have failed or cluster was auto-deleted (idle TTL 3600s); or Kafka topic was unreachable
- **Resolution**: Check Dataproc cluster `dataproc-ephemeral-cluster-mds-janus` state in GCP Console; restart via Airflow DAG trigger; check MSK Kafka topic health

### Data quality check alerts for deal count
- **Symptoms**: Email alert from `noreply@groupon.com` to `mds-alerts@groupondev.opsgenie.net` about DoD threshold breach
- **Cause**: Significant change in active deal count — may indicate a real business event (large deal batch added/removed) or an archival pipeline failure (missing partition)
- **Resolution**: Compare `dt` partition counts in `grp_gdoop_mars_mds_db.mds_production` for current vs previous day; verify archival DAG ran successfully for that date/country

### Bloomreach feed cleanup fails
- **Symptoms**: `bloomreach-sem-cdp-feeds-cleanup` DAG fails at `bloomreach_sem_cdp_feeds_cleanup` task
- **Cause**: `dataproc-cluster-mds-feeds` cluster not running; GCS bucket permissions issue
- **Resolution**: Verify MDS Feeds cluster is running in GCP Console; check service account permissions on bucket `grpn-dnd-prod-analytics-bloomreach-sem-cdp-feeds`

### Tableau refresh fails
- **Symptoms**: Tableau extract not updated after archival tableau workflow completes
- **Cause**: `refreshapi-vip.snc1` endpoint unreachable or returning error (curl call is silent — no error handling)
- **Resolution**: Manually trigger Tableau extract refresh at `http://<REFRESH_API_VIP>/ExtractAPI/extractData?id=<EXTRACT_ID>&user=<SERVICE_USER>`; check VIP availability

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Janus streaming stopped — deal IDs not enqueuing; batch worker starved | Immediate | MIS Engineering (`mis-engineering@groupon.com`), OpsGenie `mds-alerts@groupondev.opsgenie.net` |
| P2 | Archival DAG failing — deal data not landing in Hive; downstream analytics stale | 30 min | MIS Engineering |
| P3 | Individual DQC threshold breach or Tableau refresh failure | Next business day | MIS Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Marketing Deal Service API | `curl` with mTLS to `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`; check HTTP 200 | Retry up to 3 times; DAG fails if all retries exhausted |
| GCP Dataproc | GCP Console > Dataproc > Clusters; check cluster state | Airflow task retries; ephemeral clusters recreated on next DAG run |
| GCP Secret Manager | `gcloud secrets versions access latest` on each cert secret | Cluster init fails; Janus streaming and MDS archival cannot start |
| Kafka / MSK (Janus tier-2) | Check consumer group lag `mds_janus_msk_prod_3` via MSK console | No fallback; streaming job halts |
| Hive / EDW | Spark job HiveContext connectivity check at job startup | Job fails; DAG task marked failed |
