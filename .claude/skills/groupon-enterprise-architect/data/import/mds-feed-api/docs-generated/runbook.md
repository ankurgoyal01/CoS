---
service: "mds-feed-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (port 8080) | http | Default JTier | Default JTier |
| Livy `/metrics/ping` | http (internal cron) | Hourly (via CheckBatchStateJob) | - |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Spark job batch state `dead` | counter | Tracks failed feed generation Spark jobs | Any dead batch triggers Wavefront alert |
| Gdoop file cleanup failures | counter | Tracks failures of old-data cleanup jobs | Any failure triggers Wavefront alert |
| Daily feed job failures | gauge | Count of feed job failures per day | Wavefront graph via `mds-feed` tag |
| HTTP request rate / error codes | histogram | JTier SMA HTTP in/out metrics | Standard SRE thresholds |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MDS Feed Service Cloud | Wavefront | `https://groupon.wavefront.com/dashboards/MDS-Feed-Service-Cloud` |
| API Logs | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/iKXIL` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Daily Failures Alert for MDS Feeds Spark Jobs | Any Spark batch transitions to `dead` state | critical | See Spark Job Troubleshooting section; check DataProc job via YARN UI or JupyterLab |
| Gdoop Files Cleanup Failures Alert | `CleanOldDataJob` fails to clean data from GCS | warning | Check Wavefront, review logs in Kibana, escalate to MIS Engineering |

- PagerDuty service: `https://groupon.pagerduty.com/services/PB2L7F5`
- Wavefront alerts filtered by tag `mds-feed`: `https://groupon.wavefront.com/u/T0dGTxx7cy?t=groupon`

## Common Operations

### Restart Service

```sh
kubectx mds-feed-production-central1
kubectl rollout restart statefulset <statefulset-name> -n mds-feed-production
kubectl get pods -n mds-feed-production
```

### Scale Up / Down

Scaling is managed by HPA. To manually override:
```sh
kubectx mds-feed-production-central1
kubectl scale statefulset <statefulset-name> --replicas=<N> -n mds-feed-production
```

### Re-trigger a Failed Upload

1. Call `GET /upload-batches/creationDate/{date}/state/dead` to find failed upload batches.
2. Extract the `feedUuid` from the failed batch.
3. Call `GET /upload/feed/{feedUuid}` to re-trigger upload of the most recent successful batch.
4. Call `GET /upload-batches/{uploadBatchUuid}` to confirm the new upload batch succeeded.

### Kill an Overloaded Spark Job

1. Find the job in the DataProc Resource Manager, verify app name `com.groupon.mars.feedservice.jobs.FeedServiceJob` and user `svc_mars_mds`.
2. Kill via UI or JupyterLab terminal:
   ```sh
   yarn application -kill <application_id>
   ```

### Database Operations

- Production secrets: `https://github.groupondev.com/mds-feeds/mds-feed-api-secrets`
- Staging connection:
  - App user: `mktg_feed_service_stg_app`, DBA user: `mktg_feed_service_stg_dba`
  - DB: `mktg_feed_service`, Schema: `mktg_feed_service`
  - Read-Write VIP: `mds-feed-rw-na-staging-db.gds.stable.gcp.groupondev.com`
  - Port: 5432 (pgbouncer transaction/session mode and direct DBA)
- Schema migrations are run automatically at startup via `PostgresMigrationBundle`
- For DB issues, contact GDS team via Slack `#gds-daas`

## Troubleshooting

### Spark Job Batch Stuck in Running State

- **Symptoms**: Batch record shows state `running` for an unusually long time; no progress in Wavefront
- **Cause**: Spark job may be deadlocked, waiting for resources, or the DataProc cluster is unresponsive
- **Resolution**: Check YARN Resource Manager; kill the stuck application using `yarn application -kill <application_id>`; the `CheckBatchStateJob` cron will update the batch state to `dead` on next poll

### API Pods Not Running

- **Symptoms**: HTTP requests fail; Kubernetes shows no running pods
- **Cause**: Pod crash loop, OOM kill, or deployment failure
- **Resolution**:
  ```sh
  kubectx mds-feed-production-central1
  kubectl get pods -n mds-feed-production
  kubectl describe pod <pod-name> -n mds-feed-production
  kubectl logs <pod-name> -n mds-feed-production
  ```
  Redeploy via Deploybot if pods are in CrashLoopBackOff.

### S3 Upload Credentials Issue

- **Symptoms**: S3 upload batches fail with access denied errors
- **Cause**: AWS credentials not present or expired on pods
- **Resolution**: Check `{JTIER_USER_HOME}/.aws/credentials` on each pod; test via `aws-cli`; rotate credentials via the secrets management process

### SFTP Upload Failure

- **Symptoms**: Upload batch transitions to `dead` with SFTP-related error
- **Cause**: Partner SFTP endpoint down, incorrect SSH key pair, or network policy misconfiguration
- **Resolution**: Check network policy at `.meta/deployment/cloud/components/api/network-policy-production-sftp.yml`; verify SSH key pair stored in DB is correct; re-trigger upload via `GET /upload/feed/{feedUuid}`

### Database Connection Issues

- **Symptoms**: API returns 500 errors; logs show JDBC connection failures
- **Cause**: PostgreSQL VIP unreachable, connection pool exhausted, or credentials invalid
- **Resolution**: Contact GDS team (`#gds-daas`); check pgbouncer status; verify secret values in `mds-feed-api-secrets`

### Mbus Publishing Failure

- **Symptoms**: `MbusPublishingException` in logs; downstream systems do not receive feed completion events
- **Cause**: Mbus broker unreachable or credentials invalid
- **Resolution**: Check Mbus broker connectivity; verify `mbus` configuration block credentials; feed data is still stored in DB, so re-publishing can be triggered by re-triggering upload or batch update

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / all feed generation stopped | Immediate | Marketing Services Engineering (`mis-engineering@groupon.com`), PagerDuty `PB2L7F5` |
| P2 | Degraded (subset of feeds failing) | 30 min | Marketing Services Engineering |
| P3 | Minor impact (single feed delayed) | Next business day | Marketing Services Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Apache Livy | Ping `/metrics/ping` hourly; alert on failure | No fallback; Spark job submission will fail until Livy is restored |
| PostgreSQL (DaaS) | JTier built-in connection pool health | No fallback; API will return 500 errors |
| GCS | GCP SDK connectivity check at startup | No fallback; dispatch URLs cannot be generated |
| S3 | AWS credential check | Upload batches fail; manual re-trigger after credential rotation |
| Mbus | `MbusWriter` lifecycle | Batch completion still recorded in DB; publishing can be retried |
