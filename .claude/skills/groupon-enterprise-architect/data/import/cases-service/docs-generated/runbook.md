---
service: "cases-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | http | 10s (Kubernetes probe) | 40s initial delay |
| `GET /grpn/status` (port 8080) | http | on-demand | — |
| Kubernetes readiness probe (`/grpn/healthcheck`) | http | `periodSeconds: 10` | `delaySeconds: 40` |
| Kubernetes liveness probe (`/grpn/healthcheck`) | http | `periodSeconds: 10` | `delaySeconds: 40` |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Outgoing call failure rate | counter | Count of 5xx responses from downstream HTTP clients | > 100 failures in 4 minutes |
| Incoming API failure rate | counter | Count of 5xx responses from MCS itself | > 100 failures in 4 minutes |
| Incoming API P95 latency | histogram | 95th-percentile response time for inbound requests | > 10 seconds in 4 minutes |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MCS Staging | Wavefront | https://groupon.wavefront.com/dashboard/merchant-cases-staging |
| MCS Production | Wavefront | https://groupon.wavefront.com/dashboard/merchant-cases-production |
| MCS SMA | Wavefront | https://groupon.wavefront.com/dashboards/mx-merchant-cases--sma |
| Conveyor Cloud Application Metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics |
| Splunk (app logs) | Splunk | https://splunk-adhoc-us.groupondev.com/en-US/app/search/echo_be |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| MCS API Failures (Nagios) | Increased 500 responses from MCS | warning | Check Splunk for dependency failure patterns; contact MX Experience or downstream team |
| MCS API Response Time (Nagios) | Increased response time | info | Check Wavefront dashboard; investigate downstream dependency latency |
| Outgoing call rate alert (Wavefront) | Outgoing call failures > 100 in 4 min | warning | Identify failing `http.out` service in Wavefront; contact responsible service team |
| Incoming API status alert (Wavefront) | Incoming failures > 100 in 4 min | warning | Find RCA in Splunk; escalate to MX Experience team |
| Incoming API latency alert (Wavefront) | P95 latency > 10s in 4 min | warning | Check `http.out` and db-out in Wavefront for downstream bottlenecks |

## Common Operations

### Restart Service

**Cloud (Kubernetes)**:
```sh
# Force a rolling restart of the deployment
kubectl rollout restart deployment/<mcs-deployment-name> -n mx-merchant-cases-production
```

**On-prem (JTier / runit)**:
```sh
ssh merchant-cases-appN.snc1
sudo sv stop jtier
sudo sv start jtier
```

Verify after restart:
```sh
curl "localhost:8080/grpn/healthcheck"   # should return: OK
curl "localhost:8080/grpn/status"         # should return JSON with build info
```

### Scale Up / Down

**Cloud (Kubernetes) — immediate**:
```sh
kubectl scale --replicas=<N> deployment/<mcs-deployment-name> -n mx-merchant-cases-production
```

**Cloud — persistent** (update `minReplicas`/`maxReplicas` in deployment manifest):
1. Edit `.meta/deployment/cloud/components/app/<env-region>.yml`
2. Update `minReplicas` and/or `maxReplicas`
3. Commit and trigger a deploy

**On-prem** — add host to `Capfile` and deploy the current version.

### Database Operations

MCS does not own a relational database. All durable data is in Salesforce (managed externally). Redis stores are ephemeral — a Redis flush results in temporary loss of unread counts that are repopulated on next message bus events.

To flush Redis cache (staging only, with caution):
```sh
redis-cli -h casesservice-cache.us-central1.caches.stable.gcp.groupondev.com FLUSHDB
```

## Troubleshooting

### Service is Overloaded
- **Symptoms**: High P95 latency, Wavefront shows elevated request rate, pods CPU-throttled
- **Cause**: Sudden spike in Merchant Center traffic or a slow Salesforce API response causing thread exhaustion
- **Resolution**: Scale up replicas immediately via `kubectl scale`; check Wavefront `http.out` panel for Salesforce latency; communicate with downstream teams if traffic increase is sustained

### Slow or Unresponsive Salesforce
- **Symptoms**: Case API endpoints timeout (30s); Wavefront shows Salesforce `http.out` latency spike; Splunk shows `name=http.out data.service=salesforce` errors
- **Cause**: Salesforce API degradation, governor limit breach, or network connectivity issue
- **Resolution**: Check Salesforce Status page; reduce `maxRequestsPerHost` in config if governor limits are hit; alert Salesforce admin team; consider temporary feature degradation for non-critical endpoints

### MX Notification Service Down
- **Symptoms**: `NotsErrorLogData` log entries in Splunk; merchants not receiving notifications; case operations still succeed
- **Cause**: `mxNotificationService` unavailable
- **Resolution**: Case CRUD operations continue normally. Contact the Notifications team. Logs in Splunk: `sourcetype=mx-merchant-cases:*:app name=nots.error`

### Inbenta Knowledge API Down
- **Symptoms**: Knowledge management endpoints (`/km/*`) return errors; case management endpoints unaffected
- **Cause**: Inbenta API degradation or per-locale API key expiration
- **Resolution**: Check per-locale Inbenta API key validity; check Inbenta status page; knowledge endpoints degrade gracefully

### Service Not Responding After Deployment
- **Symptoms**: Health check returns non-200; Kubernetes pod in CrashLoopBackOff
- **Cause**: Misconfigured YAML (missing env var), bad Salesforce credentials, or JVM OOM
- **Resolution**: Check pod logs (`kubectl logs`); check runit log `/var/groupon/log/jtier/runit/current` (on-prem); check app log `/var/groupon/jtier/logs/jtier.steno.log`; rollback to previous version if config change is the cause

### Splunk Queries for Diagnosis

**Client response status (Production US)**:
```
index=* sourcetype="mcs:us:app" name="http.out" | stats count by data.service, data.status
```

**General exceptions (Production US)**:
```
index=main sourcetype=mcs:us:app exception
```

**Notification errors**:
```
sourcetype=mx-merchant-cases:*:app name=nots.error
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service fully down — merchants cannot create or view cases | Immediate | Merchant Experience team (`echo-dev+alerts@groupon.com`) → PagerDuty `PLT77QZ` |
| P2 | Degraded — case creation failing or high latency (> 10s) | 30 min | Merchant Experience team |
| P3 | Minor — knowledge management or notifications degraded; core cases functional | Next business day | Merchant Experience team |

SLA target: **99.5% availability**

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce CRM | Wavefront `http.out` panel; Splunk `data.service=salesforce` errors | No fallback — case CRUD unavailable |
| Redis | JTier health check bundle checks Jedis connectivity | Unread counts unavailable; case operations continue |
| Inbenta | Wavefront `http.out` for inbenta client; Splunk errors | Knowledge endpoints degrade; core case management unaffected |
| MX Notification Service | Splunk `nots.error` entries | Notifications not delivered; cases created/updated normally |
| Users Service | Wavefront `http.out` panel | Case operations requiring user context fail |
| M3 Merchant Service | Wavefront `http.out` panel | All case operations requiring merchant account fail |
