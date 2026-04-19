---
service: "ad-inventory"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` | http | Per load balancer poll | — |
| `GET /grpn/status` | http | Disabled in v4 service portal poller | — |
| Kubernetes readiness probe | exec/http | Per Kubernetes config | — |

To verify service liveness manually:
```
curl -v "https://ad-inventory.production.service.us-central1.gcp.groupondev.com/heartbeat.txt"
```

## Monitoring

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ad-inventory app metrics | Wavefront | https://groupon.wavefront.com/dashboard/ad-inventory-app-metrics |
| ad-inventory SMA metrics | Wavefront | https://groupon.wavefront.com/dashboard/ad-inventory--sma |
| ad-inventory overview | Wavefront | https://groupon.wavefront.com/dashboard/ai |
| Unified WF dashboard | Wavefront | https://groupon.wavefront.com/u/WGMgCkJzYC?t=groupon |
| Application logs | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/discover — filter: `us-*:filebeat-ad-inventory--*` |

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Placement request count | counter | Number of `/ai/api/v1/placement` requests served | — |
| Sponsored listing click count | counter | Number of sponsored click events processed | — |
| Report run status | gauge | Quartz job execution outcomes (QUEUED / RUNNING / COMPLETED / KILLED) | Failed/stalled runs trigger email alerts |
| JVM heap usage | gauge | JVM memory consumption | OOM kills observed with `MALLOC_ARENA_MAX` not set; configured to 4 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Report Fetch Failed | DFP/LiveIntent/Rokt report download fails | warning | Check Kibana for recoverable errors (timeouts); if unrecoverable, escalate to ai-reporting@groupon.com |
| Placement Response Errors | Elevated 5xx or error rate on `/ai/api/v1/placement` | critical | Check Kibana error logs; verify no active deployments on frontend; contact ads-eng@groupon.com |
| PagerDuty alert | Service-level alert | critical | https://groupon.pagerduty.com/services/PS4HL4Y |

## Common Operations

### Restart Service

Deployments are managed via Deploybot. To restart the service:
1. Navigate to https://deploybot.groupondev.com/sox-inscope/ad-inventory
2. Re-deploy the current production artifact to force a rolling restart
3. Monitor Wavefront and Kibana for error rate changes during rollout

### Scale Up / Down

1. Update `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/api/production-us-central1.yml`
2. Submit PR, merge to `main`, and deploy via Deploybot
3. HPA will handle automatic scaling between min/max bounds based on CPU utilization target of 50%

### Cache Refresh

To force a full audience cache refresh without restarting:
```
DELETE /admin/v1/caches?amsecret=<secret>
```
This clears and reloads both `audienceCache` and `audienceTargetCache` from MySQL and GCS.

### Configuration Reset

To reload configuration without restarting:
```
PUT /admin/v1/reset/config?amsecret=<secret>
```

### Database Operations

- Schema migrations run automatically on service startup via JTier migrations (Liquibase)
- Migration scripts are in the `src/main/resources/db` git submodule
- Manual backfill of report data: use `DELETE /ai/api/v1/reporting/backfill` (via `AiReportingResource`) or the `ReportBackfillJob` triggered via the scheduler API

## Troubleshooting

### Report Fetch Failed

- **Symptoms**: Report instance status stuck in `QUEUED` or `RUNNING`; alert email sent to ai-reporting@groupon.com; Kibana shows error log entries for `DFPScheduleImportJob` or `S3FileDownloaderTask`
- **Cause**: Network timeout connecting to Google Ad Manager; DFP API rate limit; S3 access denied; LiveIntent token expiry
- **Resolution**: Check Kibana (`us-*:filebeat-ad-inventory--*`) for the error type. If timeout/recoverable: Quartz will retry on next schedule. If credentials expired: update config secrets and redeploy. If unrecoverable: escalate to ai-reporting@groupon.com.

### Placement Response Errors

- **Symptoms**: Frontend ad slots empty or returning errors; elevated 5xx on `/ai/api/v1/placement`
- **Cause**: Redis cache unavailable; MySQL connectivity issue; audience data corruption; DFP report data missing
- **Resolution**: Check Kibana error logs at `us-*:filebeat-ad-inventory--*`. Verify no concurrent frontend deployments. If Redis is down, admin cache refresh will fail — restart service. If MySQL is unavailable, check DaaS status. Contact ads-eng@groupon.com.

### OOM / Container Killed

- **Symptoms**: Kubernetes restarts container pods; OOM events in Kubernetes events
- **Cause**: `MALLOC_ARENA_MAX` not set correctly; heap pressure during large report CSV processing
- **Resolution**: Verify `MALLOC_ARENA_MAX=4` is present in deployment env vars. Consider increasing memory limits in `.meta/deployment/cloud/components/worker/production-us-central1.yml` for the worker component.

### Audience Cache Stale

- **Symptoms**: Ad placements not reflecting recent audience changes; new audiences not appearing in placement responses
- **Cause**: `AudienceLoadJob` failed or was not scheduled; GCS bloom filter files not updated
- **Resolution**: Trigger manual cache refresh: `DELETE /admin/v1/caches?amsecret=<secret>`. Verify `AudienceLoadJob` Quartz schedule in the Quartz job store via MySQL.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no ad placements served | Immediate | PagerDuty: https://groupon.pagerduty.com/services/PS4HL4Y; Slack: ai-engineering (#CF8G3HBBP) |
| P2 | Degraded placement serving or report pipeline stalled | 30 min | ads-eng@groupon.com; PagerDuty |
| P3 | Non-critical report failure or metric anomaly | Next business day | ai-reporting@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (DaaS) | Check DaaS status page; JDBI connection pool will fail fast | Service cannot serve placements or persist clicks without MySQL |
| Redis | `DELETE /admin/v1/caches` response; check Redisson pool errors in Kibana | Placement serving falls back to slower MySQL audience lookups (if implemented) |
| Google Ad Manager (DFP) | `DFPScheduleImportJob` Kibana logs | Report pipeline stalls; no fallback; alert email triggered |
| GCS | `GCPClient` errors in Kibana | Bloom filter loads fail; audience cache cannot be refreshed |
| CitrusAd | `SponsoredListingService` error logs in Kibana | Click events persisted in MySQL but not forwarded to CitrusAd |
| AMS | `AMSClient` error logs | Audience create/update requests rejected; existing audiences unaffected |
