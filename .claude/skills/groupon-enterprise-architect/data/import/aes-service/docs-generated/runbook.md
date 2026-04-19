---
service: "aes-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` | http | Kubernetes liveness/readiness | Not specified in source |
| `GET /grpn/status` (disabled) | http | — | — |
| Kubernetes pod readiness | http | Cluster default | Cluster default |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Audience job success (per audience) | gauge | Whether a specific audience has run successfully in the past 25 hours | Alert if not successful in 25 hours |
| Audience job failure count | counter | Number of failed audience export attempts | Warning when retry limit (3) exceeded |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AES Service Dashboard | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/be7te7tm4s7b4d/aes-service-dashboard |
| ELK Application Logs | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/lOUlH |
| ELK AES Log Search | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/kRIB8 |
| MBus Erasure Topic | Wavefront | https://groupon.wavefront.com/u/nmRN3zFDQF?t=groupon |
| MBus ELK | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/v30b9 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `aes-service Audience {country} ERROR name:{name} id:{id} {target}` | Audience has not run successfully in 25 hours | Warning | Check ELK logs with `data.args.aesId={id}`; resolve error; run audience manually via `/api/v1/metadata/{id}/executeJob` |
| Scheduled Audience Job completed with failure | Job pipeline completed with at least one failed stage | Warning (severity 3) | Check ELK logs; determine failed stage from `jobSubStatus` |
| Retry limit exceeded for Scheduled Audience Job | Job failed after 3 retries | Warning (severity 2) | Check ELK logs; job will not retry until next scheduled run; manual execution required |
| Failed to create Scheduled Audience in AES | CIA creation succeeded but AES DB insert failed | Warning (severity 2) | Manually insert row in `aes_service.aes_metadata`; verify attributes match CIA record |
| Failed to create/update scheduled audience in CIA | CIA API call failed during audience creation/update | Warning (severity 4) | Verify CIA service health; retry API call |

All Grafana alerts are tagged `service=aes-service` and searchable at: https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/alerting/list?search=label:service%3Daes-service

## Common Operations

### Restart Service

1. Access the Kubernetes cluster context for AES.
2. Run `kubectl get pods` to list pods.
3. Delete the affected pod: `kubectl delete pod <pod-name>` — Kubernetes will reschedule automatically.
4. For VM-based environments: `sudo sv stop jtier && sudo sv start jtier`.
5. Verify recovery via `/heartbeat.txt` and Grafana dashboard.

### Run an Audience Manually

1. Open the production Swagger UI: `https://aes-service.production.service.us-central1.gcp.groupondev.com/swagger/`
2. Locate `GET /api/v1/metadata/{id}/executeJob`
3. Enter the AES audience ID and click **Execute** once.
4. Monitor ELK logs with `data.args.aesId={id}` to confirm job start.

> Click execute ONCE only — re-execution may cause duplicate uploads to ad partners.

### Scale Up / Down

1. Update `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml`.
2. Redeploy via DeployBot.
3. Or use `kubectl scale deployment/aes-service --replicas=N` for immediate manual scaling.

### Database Operations

- **Schema migrations**: Managed by JTier migrations bundle at startup.
- **Manual data fix**: For failed audience creation, insert a row directly into `aes_service.aes_metadata` with correct attributes (see `doc/TROUBLESHOOTING.md`).
- **Development DB access**: Use SSH port forwarding per README instructions (ports 63333–63335).

### Recover Stuck Quartz Triggers

1. Call `GET /api/v1/scheduledAudiences/recoverTriggers?lowAesId={N}&highAesId={M}` to recover triggers in error state for the specified AES ID range.
2. Verify trigger recovery in ELK logs.

## Troubleshooting

### Scheduled Audience Job Failed
- **Symptoms**: ELK error log "Scheduled Audience Job completed with failure"; audience not updated on ad platform
- **Cause**: Failure at any pipeline stage (CIA fetch, Cerebro read, delta compute, partner API call)
- **Resolution**: Check ELK logs → identify `jobSubStatus` → address root cause → run audience manually after fix

### Retry Limit Exceeded
- **Symptoms**: ELK error "Retry limit is exceeded for the scheduled audience job"; audience stuck
- **Cause**: Persistent failure of a pipeline stage across 3 consecutive retry attempts
- **Resolution**: Investigate root cause; fix underlying issue; manually trigger job via `/api/v1/metadata/{id}/executeJob`

### CIA API Failures
- **Symptoms**: "Failed to create or update the scheduled audience in CIA" in ELK; audience not created
- **Cause**: CIA service unavailable or returning errors
- **Resolution**: Check CIA service health; wait for CIA recovery; retry audience creation API call

### Facebook API Failures
- **Symptoms**: "Failed to create custom audience in Facebook" or "Received not successful Facebook response for updating users" in ELK
- **Cause**: Facebook API outage, rate limiting, or token expiry
- **Resolution**: Check Facebook API status; verify `accessToken` validity; allow retry cycle to recover

### Database Latency or Connectivity
- **Symptoms**: High API response times; job timeouts; JDBC errors in ELK
- **Cause**: DaaS PostgreSQL performance issue or connectivity loss
- **Resolution**: Check if problem is single-host or all-hosts; restart pod if single-host; escalate to GDS team for multi-host; verify DB connection locally

### Scheduled Audiences Not Processing
- **Symptoms**: Multiple audiences stuck in IN_PROGRESS or no jobs starting
- **Cause**: Quartz scheduler not running; service restart; DB query lock
- **Resolution**: Verify pod health; restart service; check for long-running queries; contact AES team

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down, no audiences exporting | Immediate | da-alerts@groupon.com / PagerDuty PW2Z1UF |
| P2 | Degraded — major partner(s) not receiving audience updates | 30 min | da-alerts@groupon.com |
| P3 | Individual audience jobs failing | Next business day | da-communications@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| CIA | ELK log queries; Grafana alerts | AES stores audience state locally; CIA-dependent operations retry |
| Facebook Ads | ELK job logs; `POST /api/v1/audiences/updateFBCache` | Job retries up to 3 times; alert fires after 25 hours |
| Google Ads | ELK job logs | Job retries up to 3 times; alert fires after 25 hours |
| Microsoft Bing Ads | ELK job logs | Job retries up to 3 times |
| TikTok Ads | ELK job logs | Job retries up to 3 times |
| Cerebro/Hive | ELK JDBC errors; IDFA tables pre-imported to S2S DB as mitigation | Device-ID lookups degrade if S2S tables are stale |
| MBus | MBus Elk + Wavefront dashboard | Consumer can be re-enabled via `runErasureService` / `runConsentService` flags |
